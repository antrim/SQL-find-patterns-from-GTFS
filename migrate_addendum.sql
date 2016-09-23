
\ir migrate_util.sql

-- db_query_debug("BEGIN TRANSACTION;");

/*
TRUNCATE
    RESTART IDENTITY"

 */

-- TODO: set all permissions properly, for trillium_gtfs_group and wake_robin_development roles?
-- SEE wiki for the commands which do this.
-- rename this file to 'fix permissions'.sql?
-- Does there exist anything like a puppet module which sets permissions according to a specification?

-- TODO: replace this with inline pl/pgsql  or plv8 to avoid the 'special' exec function?
/*
select public.exec(
    format(
    $fmt$
        select
        pg_catalog.setval(
            '%s', (select 1+max(%I) from %I.%I)); 
    $fmt$
        , sequencename, columnname, schemaname, tablename))
from views.default_column_values
where schemaname = :'DST_SCHEMA';
    ;
    */

/*
    RESEARCH: OK, here it is rewritten in inline pl/pgsql, and inlining the
    query used by views.default_column_values view, which makes this portable
    across any postgresql database. Is the portability worth the
    four-times-longer code?

    Ed 2016-09-20
 */

--CREATE TEMP VIEW psql_vars_temp_view 
--    AS SELECT :'SRC_SCHEMA'::text SRC_SCHEMA, :'DST_SCHEMA'::text DST_SCHEMA;
DO LANGUAGE plpgsql $plpgsql$
DECLARE
    dv record; -- default column values
    dynamic_sql text;
BEGIN
    FOR dv IN 
        SELECT 
            pg_namespace.nspname AS schemaname,
            pg_class.relname AS tablename,
            pg_attribute.attname AS columnname,
            pg_get_expr(pg_attrdef.adbin, pg_attrdef.adrelid) AS defaultvalue,
            regexp_replace(pg_get_expr(pg_attrdef.adbin, pg_attrdef.adrelid), '.*''([^'']*)''.*'::text, '\1'::text) AS sequencename
        FROM pg_attrdef
        CROSS JOIN psql_vars_temp_view AS psql_vars
        JOIN pg_class 
            ON pg_class.oid = pg_attrdef.adrelid
        JOIN pg_namespace 
            ON pg_namespace.oid = pg_class.relnamespace
        JOIN pg_attribute 
            ON  pg_attribute.attnum   = pg_attrdef.adnum 
            AND pg_attribute.attrelid = pg_attrdef.adrelid
        WHERE 
            pg_get_expr(pg_attrdef.adbin, pg_attrdef.adrelid) ~ '^nextval'::text
            AND pg_namespace.nspname = psql_vars.DST_SCHEMA
    LOOP
        dynamic_sql := format(
            $$ SELECT pg_catalog.setval('%s', (SELECT 1+max(%I) FROM %I.%I)) $$
            , dv.sequencename, dv.columnname, dv.schemaname, dv.tablename);
        RAISE INFO 'dynamic_sql: %', dynamic_sql;
        EXECUTE dynamic_sql;
    END LOOP;
END
$plpgsql$;

SELECT * FROM psql_vars_temp_view;


/*
 where schemaname ~ 'migrate';
 */

-- db_query_debug("COMMIT TRANSACTION;");

\echo 'Migration addendum successful.'


