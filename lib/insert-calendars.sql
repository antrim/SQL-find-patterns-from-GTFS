
-- calendar
    INSERT into :"DST_SCHEMA".calendars
        (agency_id, calendar_id
       , name)
    SELECT agency_id, service_schedule_group_id AS calendar_id
         , service_schedule_group_label AS name
    FROM :"SRC_SCHEMA".service_schedule_groups
    WHERE 
        agency_id IN (select agency_id from :"DST_SCHEMA".agencies) 
        AND service_schedule_group_id IS NOT NULL;


