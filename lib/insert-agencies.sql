
INSERT INTO :"DST_SCHEMA".agencies
    (agency_id, agency_id_import, agency_url, agency_timezone, agency_lang_id
    , agency_name, agency_short_name, agency_phone, agency_fare_url, agency_info
    , query_tracking, last_modified
    , no_frequencies, feed_id) 
SELECT DISTINCT agency.agency_id, agency_id_import, agency_url, agency_timezone, agency_lang_id
    , agency_name, agency_short_name, agency_phone, agency_fare_url, agency_info
    , query_tracking, agency.last_modified
    , no_frequencies, agency_group_id as feed_id 
FROM :"SRC_SCHEMA".agency
INNER JOIN :"SRC_SCHEMA".agency_group_assoc USING (agency_id)
WHERE 
    agency_id not in (:SKIP_AGENCY_ID_STRING);


