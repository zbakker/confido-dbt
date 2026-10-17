with

source as (

    select * from {{ source('confido', 'invoice_items') }}

),

renamed as (

    select
        id as invoice_item_id,
        invoice_id,
        trim(item_remote_id) as item_remote_id,
        quantity,
        unit_price,
        -- source is a float with sub-cent noise on some rows; round to cents
        round(total_amount, 2)::number(38, 2) as amount,
        _updated_at as _synced_at

    from source

)

select * from renamed
