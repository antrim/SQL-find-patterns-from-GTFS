-- fare attributes
    INSERT INTO :"DST_SCHEMA".fare_attributes
        (agency_id, fare_id, price, currency_type, payment_method
       , transfers, transfer_duration, last_modified, fare_id_import)
    SELECT agency_id, fare_id, price, currency_type, payment_method
         , transfers, transfer_duration, last_modified, fare_id_import
    FROM :"SRC_SCHEMA".fare_attributes
    WHERE
        agency_id IN (select agency_id from :"DST_SCHEMA".agencies) 
         ;


