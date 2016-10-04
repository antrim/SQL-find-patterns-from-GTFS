--
-- calendar bounds
/*  

select 1+1;

delete from :"DST_SCHEMA".calendar_bounds;

*/

INSERT into :"DST_SCHEMA".calendar_bounds 
    (agency_id, calendar_id, start_date, end_date)
SELECT agency_id, service_schedule_group_id as calendar_id, start_date, end_date 
FROM :"SRC_SCHEMA".service_schedule_bounds
WHERE 
    agency_id IN (SELECT agency_id FROM :"DST_SCHEMA".agencies) 
    AND service_schedule_group_id IN (SELECT calendar_id FROM :"DST_SCHEMA".calendars) 
    AND service_schedule_group_id IS NOT NULL;


