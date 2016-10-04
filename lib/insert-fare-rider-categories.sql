-- fare rider categories
    INSERT INTO :"DST_SCHEMA".fare_rider_categories
        (fare_rider_category_id, fare_id, rider_category_custom_id 
       , price, agency_id) 
    SELECT fare_rider_category_id, fare_id, rider_category_custom_id 
         , price, agency_id
    FROM :"SRC_SCHEMA".fare_rider_categories
    WHERE
        agency_id IN (select agency_id from :"DST_SCHEMA".agencies) 
        AND fare_id IN (select agency_id from :"DST_SCHEMA".fare_attributes);


