with

source as (

    select * from {{ source('confido', 'products') }}

),

renamed as (

    select
        id as product_id,
        _uuid as product_uuid,
        name as product_name,
        type as product_type,
        item_id,
        product_family_id,
        upc,
        cleaned_upc,
        internal_item_number,
        ship_with_product_relationship_id,
        company_detail_id,
        updated_at as product_updated_at,
        _updated_at as _synced_at

    from source

)

select * from renamed
