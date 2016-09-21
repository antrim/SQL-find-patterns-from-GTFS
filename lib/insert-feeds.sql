
INSERT INTO :"DST_SCHEMA".feeds
    (feed_id
    , name, contact_email
    , contact_url, license, last_modified)  
SELECT DISTINCT 
        agency_groups.agency_group_id as feed_id
    , group_name AS name, feed_contact_email
    , feed_contact_url, feed_license, agency_groups.last_modified 
FROM :"SRC_SCHEMA".agency_groups 
INNER JOIN :"SRC_SCHEMA".agency_group_assoc 
        ON agency_group_assoc.agency_group_id = agency_groups.agency_group_id 
WHERE agency_group_assoc.agency_id NOT IN (:SKIP_AGENCY_ID_STRING);


