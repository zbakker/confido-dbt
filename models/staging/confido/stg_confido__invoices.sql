with

source as (

    select * from {{ source('confido', 'invoices') }}

),

renamed as (

    select
        id as invoice_id,
        number as invoice_number,
        trim(customer_remote_id) as customer_remote_id,
        subsidiary_id,
        company_detail_id,
        check_remit_item_id,
        upper(trim(currency)) as currency_code,
        paid_on_date::date as paid_on_date,
        created_at,
        _updated_at as _synced_at

    from source

)

select * from renamed
