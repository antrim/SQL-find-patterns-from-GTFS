-- migrate user permissions 
    INSERT INTO :"DST_SCHEMA".user_permissions
        (permission_id, agency_id, user_id, last_modified)
    SELECT 
        up.permission_id, up.agency_id, up.user_id, up.last_modified
    FROM :"SRC_SCHEMA".user_permissions up
    JOIN :"DST_SCHEMA".agencies USING (agency_id)
    JOIN :"DST_SCHEMA".users USING (user_id);
