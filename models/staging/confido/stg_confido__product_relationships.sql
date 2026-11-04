with

source as (

    select * from {{ source('confido', 'product_relationships') }}

),

renamed as (

    select
        id as product_relationship_id,
        product_id as parent_product_id,
        child_product_id,
        quantity as child_quantity,
        _updated_at as _synced_at

    from source

)

select * from renamed
