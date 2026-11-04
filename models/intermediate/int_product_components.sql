with recursive

products as (

    select * from {{ ref('stg_confido__products') }}

),

relationships as (

    select * from {{ ref('stg_confido__product_relationships') }}

),

-- walk down the hierarchy from every product, multiplying quantities per level;
-- every product is also its own component (1 x itself, depth 0)
components (product_id, component_product_id, component_quantity, depth) as (

    select
        product_id,
        product_id,
        1::number(38, 4),
        0

    from products

    union all

    select
        components.product_id,
        relationships.child_product_id,
        (components.component_quantity * relationships.child_quantity)::number(38, 4),
        components.depth + 1

    from components
    inner join relationships
        on components.component_product_id = relationships.parent_product_id
    -- guards against a cycle in the source data
    where components.depth < 10

),

-- when type is null assume pack when there is a child else single
product_levels as (

    select
        product_id,
        product_name,
        case
            when product_type = 'CaseV2' then 'case'
            when product_type = 'ShipperProduct' then 'shipper'
            when exists (
                select 1
                from relationships
                where relationships.parent_product_id = products.product_id
            ) then 'pack'
            else 'single'
        end as product_level

    from products

),

-- a component reachable by two paths (e.g. directly and via a nested pack) is summed
final as (

    select
        components.product_id,
        components.component_product_id,
        product_levels.product_name as component_product_name,
        product_levels.product_level as component_level,
        sum(components.component_quantity) as component_quantity,
        min(components.depth) as depth

    from components
    inner join product_levels
        on components.component_product_id = product_levels.product_id
    group by all

)

select * from final
