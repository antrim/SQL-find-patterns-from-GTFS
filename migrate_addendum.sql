
\ir migrate_util.psql

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

select public.exec(format($fmt$
    select pg_catalog.setval('%s',
                             (select 1+max(%I) from %I.%I)); $fmt$,
    sequencename, columnname, schemaname, tablename))
from views.default_column_values
where schemaname = :'DST_SCHEMA';
    ;
/*
 where schemaname ~ 'migrate';
 */

-- db_query_debug("COMMIT TRANSACTION;");

\echo 'Migration addendum successful.'


