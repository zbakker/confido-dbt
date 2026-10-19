with

invoices as (

    select * from {{ ref('stg_confido__invoices') }}

),

invoice_items as (

    select * from {{ ref('stg_confido__invoice_items') }}

),

contact_mapping as (

    select * from {{ ref('int_contacts_mapped_to_global_customers') }}

),

distribution_centers as (

    select * from {{ ref('stg_confido__distribution_centers') }}

),

-- negative lines are treated as deductions (same assumption as is_deduction on lines)
invoice_totals as (

    select
        invoice_id,
        count(*) as line_count,
        sum(iff(amount > 0, amount, 0)) as gross_amount,
        sum(iff(amount < 0, amount, 0)) as deduction_amount,
        sum(amount) as net_amount

    from invoice_items
    group by invoice_id

),

joined as (

    select
        invoices.invoice_id,
        invoices.invoice_number,
        invoices.company_detail_id,
        invoices.subsidiary_id,

        invoices.customer_remote_id,
        contact_mapping.contact_id,
        contact_mapping.contact_name,

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

        coalesce(invoice_totals.line_count, 0) as line_count,
        coalesce(invoice_totals.gross_amount, 0) as gross_amount,
        coalesce(invoice_totals.deduction_amount, 0) as deduction_amount,
        coalesce(invoice_totals.net_amount, 0) as net_amount,
        invoices.currency_code,

        invoices.paid_on_date,
        invoices.paid_on_date is not null as is_paid,
        invoices.created_at as invoice_created_at

    from invoices
    left join invoice_totals
        on invoices.invoice_id = invoice_totals.invoice_id
    left join contact_mapping
        on invoices.company_detail_id = contact_mapping.company_detail_id
        and invoices.customer_remote_id = contact_mapping.contact_remote_id
    left join distribution_centers
        on contact_mapping.distribution_center_id = distribution_centers.distribution_center_id

)

select * from joined
