-- transfers
    INSERT INTO :"DST_SCHEMA".transfers
      ( transfer_id,
        from_stop_id,
        to_stop_id,
        transfer_type,
        min_transfer_time,
        agency_id,
        last_modified,
        from_stop_id_import,
        to_stop_id_import )

    SELECT 
        transfer_id,
        from_stop_id,
        to_stop_id,
        transfer_type,
        min_transfer_time,
        agency_id,
        last_modified,
        from_stop_id_import,
        to_stop_id_import  
    FROM :"SRC_SCHEMA".transfers
    WHERE
        agency_id IN (select agency_id from :"DST_SCHEMA".agencies) 
    ;


