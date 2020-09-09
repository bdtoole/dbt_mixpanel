with event_table as (

    select * 
    from {{ var('event_table' )}}

),

fields as (

    select
        -- shared default events across platforms - 14
        insert_id,
        time as occurred_at,
        name as event_type,
        distinct_id as people_id,
        properties as event_properties,
        city,
        mp_country_code as country_code,
        region,
        mp_lib as mixpanel_library,
        device_id,
        screen_width,
        screen_height,
        os,
        distinct_id_before_identity as people_id_before_identified

        {%- if var('has_web_events', true) -%}
        ,

        -- web-only default events - 10
        initial_referring_domain,
        referring_domain,
        initial_referrer,
        referrer,
        mp_keyword as referrer_keywords,
        search_engine,
        current_url,
        browser,
        browser_version,
        device as device_name
        {%- endif -%}
        {%- if var('has_android_events', true) or var('has_ios_events', true) -%}
        ,

        -- mobile-only default events - 8
        wifi as has_wifi_connected,
        app_version_string as app_version,
        app_build_number,
        os_version,
        lib_version as mixpanel_library_version,
        manufacturer as device_manufacturer,
        carrier as wireless_carrier,
        model as device_model
        {%- endif -%}
        {%- if var('has_ios_events', true) -%}
        ,

        -- ios-only default events - 1
        radio as network_type
        {%- endif -%}
        {%- if var('has_android_events', true) -%}
        ,

        -- android-only default events - 7
        bluetooth_version,
        has_nfc as has_near_field_communication,
        brand as device_brand,
        has_telephone as has_telephone,
        screen_dpi as screen_pixel_density,
        google_play_services as google_play_service_status,
        bluetooth_enabled as has_bluetooth_enabled
        {%- endif %}

        -- custom properties as specified in your dbt_project.yml
        {%- for column in var('event_custom_columns', []) %}
        ,
        {{ column }}
        {%- endfor %}
        
    from event_table
    where time > {{ "'" ~ var('date_range_start',  '2010-01-01') ~ "'" }}
),

deduped as (

    select * 
    from fields

    {%- set groupby_n = 14 + var('has_web_events', true) * 10 + var('has_ios_events', true) * 1 + 
        var('has_android_events', true) * 7 + (var('has_android_events', true) or var('has_ios_events', true)) * 8 + 
        var('event_custom_columns', [])|length %}

    {{ dbt_utils.group_by(groupby_n) }}
)

select * from deduped
