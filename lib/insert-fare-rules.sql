-- fare rules
    WITH distinct_fare_rules AS 
        (SELECT agency_id, fare_id, route_id, origin_id, destination_id, contains_id
             , max(fare_rule_id) as golden_fare_rule_id
             , array_agg(fare_rule_id) AS fare_rule_id_agg, count(*)
        FROM :"SRC_SCHEMA".fare_rules
        GROUP BY agency_id, fare_id, route_id, origin_id, destination_id, contains_id)
    INSERT INTO :"DST_SCHEMA".fare_rules 
        (fare_rule_id, fare_id, route_id, origin_id
       , destination_id, contains_id, agency_id
       , last_modified, fare_id_import, route_id_import
       , origin_id_import, destination_id_import, contains_id_import)
    SELECT fare_rule_id, fare_id, route_id, origin_id
         , destination_id, contains_id, agency_id
         , last_modified, fare_id_import, route_id_import
         , origin_id_import, destination_id_import, contains_id_import
    FROM :"SRC_SCHEMA".fare_rules
    /* Require origin_id, destination_id, and contains_id to match a zone.
       https://github.com/trilliumtransit/migrate-GTFS/issues/7#issuecomment-228627448 
     */
    WHERE fare_rule_id IN (SELECT golden_fare_rule_id 
                           FROM distinct_fare_rules)
          AND (origin_id IS NULL 
               OR origin_id IN (SELECT zone_id FROM :"DST_SCHEMA".zones))
          AND (destination_id IS NULL 
               OR destination_id IN (SELECT zone_id FROM :"DST_SCHEMA".zones))
          AND (contains_id IS NULL 
               OR contains_id IN (SELECT zone_id FROM :"DST_SCHEMA".zones))
          AND
              agency_id IN (select agency_id from :"DST_SCHEMA".agencies) 
    ;

-- update is_combinable
    UPDATE :"DST_SCHEMA".fare_rules
        SET is_combinable = False 
    WHERE agency_id IN (42, 175)
          OR (agency_id = (19) 
              AND origin_id IS NOT NULL)
          OR (agency_id = (19) 
              AND destination_id IS NOT NULL)
  ; 


