
\set SRC_SCHEMA `echo ${SRC_SCHEMA:-public}`
\set DST_SCHEMA `echo ${DST_SCHEMA:-play_migrate}`

\set SKIP_AGENCY_ID_STRING '40, 210, 231, 523, 567'
\set SKIP_TRIP_ID_STRING '601686'

/*
    psql_vars_temp_view allows us to use our psql variables from within a DO block.
*/

CREATE OR REPLACE TEMP VIEW psql_vars_temp_view AS (
    SELECT 
        :'SRC_SCHEMA'::text AS src_schema
        , :'DST_SCHEMA'::text AS dst_schema
        , :'SKIP_TRIP_ID_STRING'::text AS skip_trip_id_string
        , :'SKIP_AGENCY_ID_STRING'::text AS skip_agency_id_string
    );
-- vim notes: use @a or @" to refer to yank-variables. 
--  s/$v/\=@a
--  s/$v/\=@"
--        , :'$v'::text AS $v
--        , :'$v'::text AS $v

/*
    drop via

    SELECT exec(format('drop view %I.%I;', table_schema, table_name))
        from information_schema.views 
        where table_schema ~ 'pg_temp' and table_name = 'psql_vars_temp_view';
    

*/

/* Examples:


    DO LANGUAGE plpgsql $plpgsql$
    DECLARE
        psql_vars record;
    BEGIN
        SELECT * FROM psql_vars_temp_view LIMIT 1 INTO psql_vars;
        RAISE INFO 'pslq_vars: %', psql_vars;
        RAISE INFO 'SKIP_AGENCY_ID_STRING: %', psql_vars.skip_agency_id_string;
    END
    $plpgsql$;


    DO LANGUAGE plv8 $plv8$
        var psql_vars = plv8.execute("SELECT * FROM psql_vars_temp_view LIMIT 1")[0];
        plv8.elog(INFO, 'pslq_vars: ', JSON.stringify(psql_vars, true, 2));
        plv8.elog(INFO, 'skip_agency_id_string: ', psql_vars.skip_agency_id_string);
    $plv8$;

*/
