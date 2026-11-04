with

components as (

    select * from {{ ref('int_product_components') }}

),

final as (

    select
        product_id,
        max(iff(depth = 0, component_product_name, null)) as product_name,
        max(iff(depth = 0, component_level, null)) as product_level,

        sum(iff(component_level = 'single', component_quantity, 0)) as singles_per_product,
        count_if(component_level = 'single') as single_product_count,
        -- the single is only named when the product holds one kind (not a shipper or mixed pack)
        iff(
            count_if(component_level = 'single') = 1,
            max(iff(component_level = 'single', component_product_id, null)),
            null
        ) as single_product_id,
        iff(
            count_if(component_level = 'single') = 1,
            max(iff(component_level = 'single', component_product_name, null)),
            null
        ) as single_product_name,

        -- packs inside the product, not the product itself; null when there's no pack level
        nullif(sum(iff(component_level = 'pack' and depth > 0, component_quantity, 0)), 0) as packs_per_product

    from components
    group by product_id

)

select * from final
