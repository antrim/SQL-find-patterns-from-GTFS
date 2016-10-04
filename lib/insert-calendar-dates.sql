--
-- calendar dates
INSERT INTO :"DST_SCHEMA".calendar_dates
    (calendar_date_id, "date", agency_id, name, last_modified) 
SELECT 
    calendar_date_id, "date", agency_id, description as name, last_modified
FROM :"SRC_SCHEMA".calendar_dates
WHERE
    agency_id IN (select agency_id from :"DST_SCHEMA".agencies) ;

INSERT INTO :"DST_SCHEMA".calendar_date_service_exceptions
    (calendar_date_id, exception_type, calendar_id
    , monday, tuesday , wednesday
    , thursday, friday, saturday, sunday
    , agency_id
    , last_modified) 
SELECT calendar_date_id, exception_type, service_exception as calendar_id
    , monday::boolean, tuesday::boolean, wednesday::boolean
    , thursday::boolean, friday::boolean, saturday::boolean, sunday::boolean
    , calendar_date_service_exceptions.agency_id
    , calendar_date_service_exceptions.last_modified
FROM :"SRC_SCHEMA".calendar_date_service_exceptions 
INNER JOIN :"SRC_SCHEMA".calendar
    ON calendar_date_service_exceptions.service_exception = calendar.calendar_id
WHERE
    calendar_date_service_exceptions.agency_id IN 
        (SELECT agency_id FROM :"DST_SCHEMA".agencies)
    AND calendar_date_service_exceptions.service_exception IN 
        (SELECT calendar_id FROM :"DST_SCHEMA".calendars)
    AND calendar_date_service_exceptions.calendar_date_id IN 
        (SELECT calendar_id FROM :"DST_SCHEMA".calendar_dates) ;


