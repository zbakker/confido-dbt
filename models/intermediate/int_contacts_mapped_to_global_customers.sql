with

contacts as (

    select * from {{ ref('stg_confido__contacts') }}

),

global_customers as (

    select * from {{ ref('stg_confido__global_customers') }}

),

resolved as (

    select
        contacts.contact_id,
        contacts.company_detail_id,
        contacts.contact_remote_id,
        contacts.contact_name,
        contacts.parent_contact_remote_id,
        contacts.distribution_center_id,
        coalesce(contacts.global_customer_id, parents.global_customer_id) as global_customer_id,

        case
            when contacts.global_customer_id is not null then 'direct'
            when parents.global_customer_id is not null then 'via_parent'
            else 'unmapped_contact'
        end as global_customer_mapping_status

    from contacts
    left join contacts as parents
        on contacts.company_detail_id = parents.company_detail_id
        and contacts.parent_contact_remote_id = parents.contact_remote_id

),

final as (

    select
        resolved.*,
        global_customers.global_customer_name

    from resolved
    left join global_customers
        on resolved.global_customer_id = global_customers.global_customer_id

)

select * from final
