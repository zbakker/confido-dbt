with

invoices as (

    select * from {{ ref('int_invoices_enriched') }}

),

invoice_items as (

    select * from {{ ref('int_invoice_items_enriched') }}

),

quantities as (

    select * from {{ ref('int_invoice_items_quantities') }}

),

-- billed vs expected, using only the lines that have an expected amount (a product,
-- a case and a case price); non-product lines like discounts and trade spend have no
-- expected amount, so they're left out of both sides
line_checks as (

    select
        invoice_items.invoice_id,
        count(invoice_items.product_id) as product_line_count,
        coalesce(sum(iff(invoice_items.product_id is not null, invoice_items.amount, 0)), 0)
            as product_amount,

        count(quantities.expected_amount) as checked_line_count,
        coalesce(sum(iff(quantities.expected_amount is not null, invoice_items.amount, 0)), 0)
            as checked_billed_amount,
        coalesce(sum(quantities.expected_amount), 0) as checked_expected_amount,

        count_if(quantities.quantity_price_check = 'not_a_case_price') as not_a_case_price_line_count

    from invoice_items
    inner join quantities
        on invoice_items.invoice_item_id = quantities.invoice_item_id
    group by invoice_items.invoice_id

),

final as (

    select
        invoices.invoice_id,
        invoices.invoice_number,
        invoices.company_detail_id,
        invoices.company_name,

        invoices.global_customer_id,
        invoices.global_customer_name,
        invoices.global_customer_mapping_status,
        invoices.distribution_center_id,
        invoices.distribution_center_name,
        invoices.customer_remote_id,
        invoices.contact_id,
        invoices.contact_name,

        invoices.line_count,
        invoices.gross_amount,
        invoices.deduction_amount,
        invoices.net_amount,
        invoices.currency_code,

        coalesce(line_checks.product_line_count, 0) as product_line_count,
        coalesce(line_checks.product_amount, 0) as product_amount,
        coalesce(line_checks.checked_line_count, 0) as checked_line_count,
        coalesce(line_checks.checked_billed_amount, 0) as checked_billed_amount,
        coalesce(line_checks.checked_expected_amount, 0) as checked_expected_amount,
        coalesce(line_checks.checked_billed_amount, 0)
            - coalesce(line_checks.checked_expected_amount, 0) as amount_variance,
        coalesce(line_checks.not_a_case_price_line_count, 0) as not_a_case_price_line_count,

        -- a non-case quantity (a dollar figure or lump sum) makes the expected amount
        -- meaningless, so it wins over the variance
        case
            when coalesce(line_checks.checked_line_count, 0) = 0 then 'no_checkable_lines'
            when line_checks.not_a_case_price_line_count > 0 then 'has_non_case_quantity'
            when abs(line_checks.checked_billed_amount - line_checks.checked_expected_amount)
                <= 0.01 * abs(line_checks.checked_expected_amount) then 'matches_expected'
            else 'differs_from_expected'
        end as invoice_amount_check,

        invoices.paid_on_date,
        invoices.is_paid,
        invoices.invoice_created_at

    from invoices
    left join line_checks
        on invoices.invoice_id = line_checks.invoice_id
    -- same population as fct_invoice_items
    where invoices.is_paid

)

select * from final
