with

source as (

    select * from {{ source('confido', 'confido_distribution_centers') }}

),

renamed as (

    select
        id as distribution_center_id,
        _uuid as distribution_center_uuid,
        name as distribution_center_name,
        global_customer_id,
        muffin_location_id,
        company_detail_id,
        _updated_at as _synced_at

    from source

)

select * from renamed
