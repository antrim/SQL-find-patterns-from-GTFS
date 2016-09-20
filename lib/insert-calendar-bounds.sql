-- calendar bounds
    INSERT into :"DST_SCHEMA".calendar_bounds 
        (agency_id, calendar_id, start_date, end_date)
    SELECT agency_id, service_schedule_group_id as calendar_id, start_date, end_date 
    FROM :"SRC_SCHEMA".service_schedule_bounds
    WHERE 
        agency_id IN (select agency_id from :"DST_SCHEMA".agencies) 
        AND service_schedule_group_id IS NOT NULL;


