-- A company can reference shared entities (null company_detail_id) or its own, never
-- another company's. Returns one row per violating reference; passes when empty.

with

contacts as (select * from {{ ref('stg_confido__contacts') }}),
global_customers as (select * from {{ ref('stg_confido__global_customers') }}),
distribution_centers as (select * from {{ ref('stg_confido__distribution_centers') }}),
items as (select * from {{ ref('stg_confido__items') }}),
products as (select * from {{ ref('stg_confido__products') }}),
relationships as (select * from {{ ref('stg_confido__product_relationships') }}),
shipping_configs as (select * from {{ ref('stg_confido__product_shipping_configs') }}),
prices as (select * from {{ ref('stg_confido__product_prices') }}),

violations as (

    select 'contact -> global customer' as reference, contacts.contact_id::text as id
    from contacts
    inner join global_customers
        on contacts.global_customer_id = global_customers.global_customer_id
    where global_customers.company_detail_id != contacts.company_detail_id

    union all

    select 'contact -> distribution center', contacts.contact_id::text
    from contacts
    inner join distribution_centers
        on contacts.distribution_center_id = distribution_centers.distribution_center_id
    where distribution_centers.company_detail_id != contacts.company_detail_id

    union all

    select 'distribution center -> global customer', distribution_centers.distribution_center_id::text
    from distribution_centers
    inner join global_customers
        on distribution_centers.global_customer_id = global_customers.global_customer_id
    where global_customers.company_detail_id != distribution_centers.company_detail_id

    union all

    select 'product -> item', products.product_id::text
    from products
    inner join items
        on products.item_id = items.item_id
    where items.company_detail_id != products.company_detail_id

    union all

    select 'product relationship parent -> child', relationships.product_relationship_id::text
    from relationships
    inner join products as parents
        on relationships.parent_product_id = parents.product_id
    inner join products as children
        on relationships.child_product_id = children.product_id
    where parents.company_detail_id != children.company_detail_id

    union all

    select 'shipping config product -> shipping product', shipping_configs.product_id || ' -> ' || shipping_configs.shipping_product_id
    from shipping_configs
    inner join products
        on shipping_configs.product_id = products.product_id
    inner join products as shipping_products
        on shipping_configs.shipping_product_id = shipping_products.product_id
    where shipping_products.company_detail_id != products.company_detail_id

    union all

    select 'shipping config -> global customer', shipping_configs.product_id || ' @ ' || shipping_configs.global_customer_id
    from shipping_configs
    inner join products
        on shipping_configs.product_id = products.product_id
    inner join global_customers
        on shipping_configs.global_customer_id = global_customers.global_customer_id
    where global_customers.company_detail_id != products.company_detail_id

    union all

    select 'shipping config -> distribution center', shipping_configs.product_id || ' @ ' || shipping_configs.distribution_center_id
    from shipping_configs
    inner join products
        on shipping_configs.product_id = products.product_id
    inner join distribution_centers
        on shipping_configs.distribution_center_id = distribution_centers.distribution_center_id
    where distribution_centers.company_detail_id != products.company_detail_id

    union all

    select 'price -> global customer', prices.product_price_id::text
    from prices
    inner join products
        on prices.product_id = products.product_id
    inner join global_customers
        on prices.global_customer_id = global_customers.global_customer_id
    where global_customers.company_detail_id != products.company_detail_id

    union all

    select 'price -> distribution center', prices.product_price_id::text
    from prices
    inner join products
        on prices.product_id = products.product_id
    inner join distribution_centers
        on prices.distribution_center_id = distribution_centers.distribution_center_id
    where distribution_centers.company_detail_id != products.company_detail_id

)

select * from violations
