with

source as (

    select * from {{ source('confido', 'items') }}

),

renamed as (

    select
        id as item_id,
        trim(remote_id) as item_remote_id,
        name as item_name,
        company_detail_id,
        _updated_at as _synced_at

    from source

)

select * from renamed
