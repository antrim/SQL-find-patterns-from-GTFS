<html><head><title>migrate_addendum.php!</title><head>
<body>
<?php

// require_once $_SERVER['DOCUMENT_ROOT'] . '/includes/config.inc.php';
require_once './includes/config.inc.php';

require_once './migrate_util.php';


db_query_debug("
TRUNCATE
      {$dst_schema}.users
    , {$dst_schema}.user_permissions
    RESTART IDENTITY"
);


$migrate_user_query  = "
    INSERT INTO {$dst_schema}.users
        (user_id, email, pass, first_name, last_name, active,
        registration_date,
        read_only,
        admin,
        language_id,
        last_modified) 
    SELECT 
        user_id, email, pass, first_name, last_name, active,
        registration_date, 
        (read_only = 1)::boolean,
        (admin = 1)::boolean,
        language_id,
        last_modified
    FROM {$src_schema}.users
    ";

db_query_debug($migrate_user_query);

$migrate_user_permissions_query  = "
    INSERT INTO {$dst_schema}.user_permissions
        (permission_id, agency_id, user_id, last_modified)
    SELECT 
        up.permission_id, up.agency_id, up.user_id, up.last_modified
    FROM {$src_schema}.user_permissions up
    JOIN {$dst_schema}.agencies USING (agency_id)
    ";

db_query_debug($migrate_user_permissions_query);



## FIXME: this won't work if dst_schema is other than migrate or play_migrate.
## Something to look at when we support "importing" agencies via this migrate script.
$fmt = '$fmt'; #HACK so I can copy/paste the expression below. Ed 2016-08-15
$update_sequences_query = "
select public.exec(format($fmt$
    select pg_catalog.setval('%s',
                             (select 1+max(%I) from %I.%I)); $fmt$,
    sequencename, columnname, schemaname, tablename))
from views.default_column_values
where schemaname = '{$dst_schema}';
    ";

db_query_debug($update_sequences_query);

echo "<br / >\n" . "Migration addendum successful.";

?>
</body></html>

