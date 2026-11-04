with

invoice_items as (

    select * from {{ ref('int_invoice_items_enriched') }}

),

packaging as (

    select * from {{ ref('int_products_packaging') }}

),

-- forecast_version_id rows are forecast scenarios, not what was actually configured
shipping_configs as (

    select * from {{ ref('stg_confido__product_shipping_configs') }}
    where forecast_version_id is null

),

prices as (

    select * from {{ ref('stg_confido__product_prices') }}
    where forecast_version_id is null

),

lines as (

    select
        invoice_items.invoice_item_id,
        invoice_items.product_id,
        invoice_items.global_customer_id,
        invoice_items.distribution_center_id,
        invoice_items.invoice_created_at::date as invoice_date,
        invoice_items.quantity,
        invoice_items.unit_price,
        invoice_items.amount,
        packaging.product_level as invoiced_product_level,
        packaging.singles_per_product as singles_per_invoiced_product

    from invoice_items
    left join packaging
        on invoice_items.product_id = packaging.product_id

),

-- singles and packs ship in the case their shipping config names: the most
-- specific config (DC, then customer, then default) in effect on the invoice date
shipping_config_matches as (

    select
        lines.invoice_item_id,
        shipping_configs.shipping_product_id

    from lines
    inner join shipping_configs
        on lines.product_id = shipping_configs.product_id
        and shipping_configs.effective_date <= lines.invoice_date
        and (shipping_configs.global_customer_id is null
            or shipping_configs.global_customer_id = lines.global_customer_id)
        and (shipping_configs.distribution_center_id is null
            or shipping_configs.distribution_center_id = lines.distribution_center_id)
    where lines.invoiced_product_level in ('single', 'pack')
    qualify row_number() over (
        partition by lines.invoice_item_id
        order by
            shipping_configs.distribution_center_id is not null desc,
            shipping_configs.global_customer_id is not null desc,
            shipping_configs.effective_date desc,
            shipping_configs._synced_at desc
    ) = 1

),

-- cases and shippers are invoiced at case level already
line_cases as (

    select
        lines.*,
        case
            when lines.invoiced_product_level in ('case', 'shipper') then lines.product_id
            else shipping_config_matches.shipping_product_id
        end as case_product_id,
        case
            when lines.invoiced_product_level in ('case', 'shipper') then 'invoiced_product'
            when shipping_config_matches.shipping_product_id is not null then 'shipping_config'
        end as case_source

    from lines
    left join shipping_config_matches
        on lines.invoice_item_id = shipping_config_matches.invoice_item_id

),

-- same precedence as shipping configs: DC, then customer, then default price
price_matches as (

    select
        line_cases.invoice_item_id,
        prices.price as expected_case_price

    from line_cases
    inner join prices
        on line_cases.case_product_id = prices.product_id
        and prices.effective_date <= line_cases.invoice_date
        and (prices.global_customer_id is null
            or prices.global_customer_id = line_cases.global_customer_id)
        and (prices.distribution_center_id is null
            or prices.distribution_center_id = line_cases.distribution_center_id)
    qualify row_number() over (
        partition by line_cases.invoice_item_id
        order by
            prices.distribution_center_id is not null desc,
            prices.global_customer_id is not null desc,
            prices.effective_date desc,
            prices._synced_at desc
    ) = 1

),

converted as (

    select
        line_cases.invoice_item_id,
        line_cases.invoiced_product_level,
        -- the invoiced product says what level the quantity is in; cases and
        -- shippers are both counted as cases
        case
            when line_cases.invoiced_product_level in ('case', 'shipper') then 'case'
            else line_cases.invoiced_product_level
        end as quantity_uom,

        line_cases.case_product_id,
        case_packaging.product_name as case_product_name,
        case_packaging.single_product_id,
        case_packaging.single_product_name,
        line_cases.case_source,
        case_packaging.singles_per_product as singles_per_case,
        case_packaging.packs_per_product as packs_per_case,

        (
            line_cases.quantity * line_cases.singles_per_invoiced_product
            / nullif(case_packaging.singles_per_product, 0)
        )::number(38, 4) as case_quantity,

        price_matches.expected_case_price,
        line_cases.unit_price,
        line_cases.amount

    from line_cases
    left join packaging as case_packaging
        on line_cases.case_product_id = case_packaging.product_id
    left join price_matches
        on line_cases.invoice_item_id = price_matches.invoice_item_id

),

final as (

    select
        invoice_item_id,
        invoiced_product_level,
        quantity_uom,
        case_product_id,
        case_product_name,
        case_source,
        singles_per_case,
        packs_per_case,
        single_product_id,
        single_product_name,

        case_quantity,
        (case_quantity * packs_per_case)::number(38, 4) as pack_quantity,
        (case_quantity * singles_per_case)::number(38, 4) as single_quantity,

        expected_case_price,
        -- what the line should have been billed: the rolled-up case quantity at the
        -- expected case price. For lines billed as singles or packs this tests the
        -- product_relationships factors; for lines billed as cases it tests the unit
        (case_quantity * expected_case_price)::number(38, 2) as expected_amount,
        -- the case count the dollars imply, independent of the quantity field
        (amount / nullif(expected_case_price, 0))::number(38, 4) as implied_case_quantity,

        -- only checkable when the quantity is in cases. Within 1% is the list price;
        -- up to 2x either way is a customer price difference with a plausible case
        -- count; beyond that the quantity isn't cases (lump-sum lines with quantity 1
        -- and the line total as unit price, or the GEN_ batch with unit price 1)
        case
            when quantity_uom != 'case' or expected_case_price is null then 'no_case_price'
            when abs(unit_price - expected_case_price) <= 0.01 * expected_case_price
                then 'matches_case_price'
            when unit_price between 0.5 * expected_case_price and 2 * expected_case_price
                then 'differs_from_case_price'
            else 'not_a_case_price'
        end as quantity_price_check

    from converted

)

select * from final
