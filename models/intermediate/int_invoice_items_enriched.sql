with

invoice_items as (

    select * from {{ ref('stg_confido__invoice_items') }}

),

invoices as (

    select * from {{ ref('int_invoices_enriched') }}

),

item_mapping as (

    select * from {{ ref('int_items_mapped_to_products') }}

),

joined as (

    select
        invoice_items.invoice_item_id,
        invoice_items.invoice_id,
        invoices.invoice_number,
        invoices.company_detail_id,

        item_mapping.product_id,
        item_mapping.product_name,
        case
            when item_mapping.item_id is null then 'unknown_item'
            else item_mapping.product_mapping_status
        end as product_mapping_status,

        invoices.global_customer_id,
        invoices.global_customer_name,
        invoices.global_customer_mapping_status,

        invoices.distribution_center_id,
        invoices.distribution_center_name,

        invoice_items.item_remote_id,
        item_mapping.item_id,
        item_mapping.item_name,
        invoices.customer_remote_id,
        invoices.contact_id,
        invoices.contact_name,

        invoice_items.quantity,
        invoice_items.unit_price,
        invoice_items.amount,
        -- assumes negative lines are deductions (e.g. EDLP, spoils, early pay discount)
        invoice_items.amount < 0 as is_deduction,
        invoices.currency_code,

        invoices.paid_on_date,
        invoices.is_paid,
        invoices.invoice_created_at

    from invoice_items
    left join invoices
        on invoice_items.invoice_id = invoices.invoice_id
    left join item_mapping
        on invoices.company_detail_id = item_mapping.company_detail_id
        and invoice_items.item_remote_id = item_mapping.item_remote_id

)

select * from joined
