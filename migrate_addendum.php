<html><head><title>migrate_addendum.php!</title><head>
<body>
<?php

// require_once $_SERVER['DOCUMENT_ROOT'] . '/includes/config.inc.php';
require_once './includes/config.inc.php';

require_once './migrate_util.php';

db_query_debug("BEGIN TRANSACTION;");

/*
db_query_debug("
TRUNCATE
    RESTART IDENTITY"
);
 */




$fmt = '$fmt'; #HACK so I can copy/paste the expression below. Ed 2016-08-15
$update_sequences_query = "
select public.exec(format($fmt$
    select pg_catalog.setval('%s',
                             (select 1+max(%I) from %I.%I)); $fmt$,
    sequencename, columnname, schemaname, tablename))
from views.default_column_values
where schemaname = '{$dst_schema}';
    ";
/*
 where schemaname ~ 'migrate';
 */

db_query_debug($update_sequences_query);


db_query_debug("COMMIT TRANSACTION;");

echo "<br / >\n" . "Migration addendum successful.";

?>
</body></html>

