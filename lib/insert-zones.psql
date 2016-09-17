
/* zones */
    INSERT INTO :"DST_SCHEMA".zones
          (zone_id, name, agency_id
         , last_modified, zone_id_import )
    SELECT zone_id, zone_name AS name, agency_id
         , last_modified, zone_id_import 
    FROM :"SRC_SCHEMA".zones;


/* zones wildcard */
    INSERT INTO :"DST_SCHEMA".zones
          (zone_id, name, agency_id
         , last_modified, zone_id_import )
    VALUES (-411
          , 'Wildcard: any or all zones for this agency.'
          , -411
          , NOW()
          , '' /* Blank zone_id_import which means 'all' in GTFS. */
      );


\set DST_SCHEMA_ZONE_CLASS :DST_SCHEMA .zones_zone_id_seq
SELECT pg_catalog.setval(:'DST_SCHEMA_ZONE_CLASS'::regclass, 1 + MAX(zone_id))
FROM :"DST_SCHEMA".zones;
\unset DST_SCHEMA_ZONE_CLASS 


