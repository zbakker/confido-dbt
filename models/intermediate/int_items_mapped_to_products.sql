with

items as (

    select * from {{ ref('stg_confido__items') }}

),

products as (

    select * from {{ ref('stg_confido__products') }}

),

products_per_item as (

    select
        item_id,
        count(*) as linked_product_count,
        min(product_id) as product_id,
        min(product_name) as product_name

    from products
    where item_id is not null
    group by item_id

),

final as (

    select
        items.item_id,
        items.company_detail_id,
        items.item_remote_id,
        items.item_name,
        coalesce(products_per_item.linked_product_count, 0) as linked_product_count,
        --only interested in item to product when we have exactly one product
        case
            when products_per_item.linked_product_count = 1
                then products_per_item.product_id
        end as product_id,

        case
            when products_per_item.linked_product_count = 1
                then products_per_item.product_name
        end as product_name,

        -- easier debugging when we have multiple products linked to an item
        case
            when products_per_item.linked_product_count = 1 then 'mapped'
            when products_per_item.linked_product_count > 1 then 'ambiguous_item'
            else 'no_linked_product'
        end as product_mapping_status

    from items
    left join products_per_item
        on items.item_id = products_per_item.item_id

)

select * from final
