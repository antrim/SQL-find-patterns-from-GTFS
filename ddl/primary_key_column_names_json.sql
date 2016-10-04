
/*
    https://github.com/trilliumtransit/GTFSManager/issues/392
*/

-- \set DST_SCHEMA migrate
-- \echo :DST_SCHEMA
CREATE or replace FUNCTION 
    :"DST_SCHEMA".primary_key_column_names_json()
    RETURNS text
    AS
    $$
        SELECT 
            pretty_js(array_to_json(array_agg(
                DISTINCT column_name::text ORDER BY column_name::text)))
            AS primary_key_column_names_json
        FROM information_schema.columns
        WHERE 
            column_name ~ '_id$' 
            AND table_schema = current_schema();
    $$ LANGUAGE sql
    SET search_path = :"DST_SCHEMA", public;
ALTER FUNCTION :"DST_SCHEMA".primary_key_column_names_json() 
    owner to trillium_gtfs_group;

