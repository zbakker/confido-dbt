with

source as (

    select * from {{ source('confido', 'product_shipping_configs') }}

),

renamed as (

    select
        product_id,
        shipping_product_id,
        global_customer_id,
        distribution_center_id,
        forecast_version_id,
        effective_at as effective_date,
        _updated_at as _synced_at

    from source

)

select * from renamed
