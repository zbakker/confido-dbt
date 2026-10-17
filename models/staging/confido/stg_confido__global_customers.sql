with

source as (

    select * from {{ source('confido', 'global_customers') }}

),

renamed as (

    select
        id as global_customer_id,
        _uuid as global_customer_uuid,
        name as global_customer_name,
        is_distributor,
        company_detail_id,
        _updated_at as _synced_at

    from source

)

select * from renamed
