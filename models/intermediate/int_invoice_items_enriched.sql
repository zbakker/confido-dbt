with

invoice_items as (

    select * from {{ ref('stg_confido__invoice_items') }}

),

invoices as (

    select * from {{ ref('stg_confido__invoices') }}

),

distribution_centers as (

    select * from {{ ref('stg_confido__distribution_centers') }}

),

item_mapping as (

    select * from {{ ref('int_items_mapped_to_products') }}

),

contact_mapping as (

    select * from {{ ref('int_contacts_mapped_to_global_customers') }}

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

        contact_mapping.global_customer_id,
        contact_mapping.global_customer_name,
        case
            when contact_mapping.contact_id is null then 'unknown_contact'
            else contact_mapping.global_customer_mapping_status
        end as global_customer_mapping_status,

        -- the contact is the only link to one specific DC (null on every contact
        -- in current data); a global customer has many DCs, so it can't pick one
        contact_mapping.distribution_center_id,
        distribution_centers.distribution_center_name,

        invoice_items.item_remote_id,
        item_mapping.item_id,
        item_mapping.item_name,
        invoices.customer_remote_id,
        contact_mapping.contact_id,
        contact_mapping.contact_name,

        invoice_items.quantity,
        invoice_items.unit_price,
        invoice_items.amount,
        invoices.currency_code,

        invoices.paid_on_date,
        invoices.created_at as invoice_created_at

    from invoice_items
    left join invoices
        on invoice_items.invoice_id = invoices.invoice_id
    left join item_mapping
        on invoices.company_detail_id = item_mapping.company_detail_id
        and invoice_items.item_remote_id = item_mapping.item_remote_id
    left join contact_mapping
        on invoices.company_detail_id = contact_mapping.company_detail_id
        and invoices.customer_remote_id = contact_mapping.contact_remote_id
    left join distribution_centers
        on contact_mapping.distribution_center_id = distribution_centers.distribution_center_id

)

select * from joined
