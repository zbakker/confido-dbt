with

source as (

    select * from {{ source('confido', 'product_prices') }}

),

renamed as (

    select
        id as product_price_id,
        product_id,
        amount as price,
        global_customer_id,
        distribution_center_id,
        forecast_version_id,
        effective_at as effective_date,
        _updated_at as _synced_at

    from source

)

select * from renamed
