-- blocks
    INSERT into :"DST_SCHEMA".blocks 
        (agency_id, block_id, name)
    SELECT DISTINCT agency_id, block_id, block_label as name
    FROM :"SRC_SCHEMA".blocks
    WHERE 
        agency_id IN (select agency_id from :"DST_SCHEMA".agencies) ; 


