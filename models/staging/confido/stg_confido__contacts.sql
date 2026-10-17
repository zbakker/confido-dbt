with

source as (

    select * from {{ source('confido', 'contacts') }}

),

renamed as (

    select
        id as contact_id,
        trim(remote_id) as contact_remote_id,
        trim(parent_remote_id) as parent_contact_remote_id,
        global_customer_id,
        distribution_center_id,
        name as contact_name,
        company_detail_id,
        _updated_at as _synced_at

    from source

)

select * from renamed
