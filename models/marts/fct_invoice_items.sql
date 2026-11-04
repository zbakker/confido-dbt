with

invoice_items as (

    select * from {{ ref('int_invoice_items_enriched') }}

),

quantities as (

    select * from {{ ref('int_invoice_items_quantities') }}

),

final as (

    select
        invoice_items.invoice_item_id,
        invoice_items.invoice_id,
        invoice_items.invoice_number,
        invoice_items.company_detail_id,
        invoice_items.company_name,

        invoice_items.product_id,
        invoice_items.product_name,
        invoice_items.product_mapping_status,
        quantities.invoiced_product_level,

        invoice_items.global_customer_id,
        invoice_items.global_customer_name,
        invoice_items.global_customer_mapping_status,

        invoice_items.distribution_center_id,
        invoice_items.distribution_center_name,

        invoice_items.item_id,
        invoice_items.item_remote_id,
        invoice_items.item_name,
        invoice_items.customer_remote_id,
        invoice_items.contact_id,
        invoice_items.contact_name,

        invoice_items.quantity,
        quantities.quantity_uom,
        invoice_items.unit_price,

        quantities.case_product_id,
        quantities.case_product_name,
        quantities.case_source,
        quantities.packs_per_case,
        quantities.singles_per_case,
        quantities.single_product_id,
        quantities.single_product_name,

        quantities.case_quantity,
        quantities.pack_quantity,
        quantities.single_quantity,
        quantities.expected_case_price,
        quantities.expected_amount,
        quantities.implied_case_quantity,
        quantities.quantity_price_check,

        invoice_items.amount,
        invoice_items.is_deduction,
        invoice_items.currency_code,

        invoice_items.paid_on_date,
        invoice_items.is_paid,
        invoice_items.invoice_created_at

    from invoice_items
    left join quantities
        on invoice_items.invoice_item_id = quantities.invoice_item_id
    where invoice_items.is_paid

)

select * from final
