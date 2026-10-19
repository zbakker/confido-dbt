with

invoice_items as (

    select * from {{ ref('int_invoice_items_enriched') }}

),

final as (

    select
        invoice_item_id,
        invoice_id,
        invoice_number,
        company_detail_id,

        product_id,
        product_name,
        product_mapping_status,

        global_customer_id,
        global_customer_name,
        global_customer_mapping_status,

        distribution_center_id,
        distribution_center_name,

        item_remote_id,
        item_name,
        customer_remote_id,
        contact_name,

        amount,
        is_deduction,
        currency_code,

        paid_on_date,
        is_paid,
        invoice_created_at

    from invoice_items
    where is_paid

)

select * from final
