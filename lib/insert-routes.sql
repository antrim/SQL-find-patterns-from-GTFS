-- routes.sql
    INSERT INTO :"DST_SCHEMA".routes 
        (agency_id, route_id, route_short_name, route_long_name, route_description, route_type
       , route_color 
       , route_text_color
       , route_url, route_bikes_allowed, route_id_import
       , last_modified, route_sort_order, enabled) 
   SELECT 
         agency_id, route_id, route_short_name, route_long_name, route_desc, route_type
       , CASE WHEN route_color ~ '^[0-9a-fA-F]{6}$' 
                   THEN '#'||lower(route_color) 
                   ELSE '#ffffff' END
       , CASE WHEN route_text_color ~ '^[0-9a-fA-F]{6}$' 
                   THEN '#'||lower(route_text_color) 
                   ELSE '#000000' END
       , route_url, route_bikes_allowed, route_id_import
       , last_modified, route_sort_order, CASE WHEN hidden THEN False ELSE True END
    FROM :"SRC_SCHEMA".routes 
    WHERE agency_id IN (select agency_id from :"DST_SCHEMA".agencies);

/* ED 2016-06-27 On further thought, I think it's better not to include the 
 * wildcard entries into the database.
 *
 * (1) They would match entries from multiple agencies, this could potentially 
 *     complicate how we implement a security model, and exporting data.
 *
 * (2) For zones it isn't too bad, but many other tables expect very specific 
 *     data in columns such as routes.bikes_allowed and agencies.phone.
 *     We don't really want to end up with fake values in these columns, it's
 *     probably more work to avoid this problem than to just bear in mind that
 *     -411 is a shorthand for all when writing views and join code.
 */

/*
$all_routes_wildcard_query = "
    INSERT INTO :"DST_SCHEMA".routes
        (agency_id, route_id, route_short_name, route_long_name,
        , route_desc, route_type
         , last_modified, zone_id_import )
    VALUES (-411
          , 'Wildcard: any or all routes for this agency.'
          , -411
          , NOW()
          , '' -- Blank zone_id_import which means 'all' in GTFS. 
      );
    ;
$result = db_query_debug($all_routes_wildcard_query);
 */




