<html><head><title>migrate_addendum.php!</title><head>
<body>
<?php

// require_once $_SERVER['DOCUMENT_ROOT'] . '/includes/config.inc.php';
require_once './includes/config.inc.php';

$live = false;
set_time_limit(7200);

# $table_prefix = "migrate";
$table_prefix = "play_migrate";

$migrate_transfers_query = "
    INSERT INTO {$table_prefix}_transfers
      ( transfer_id,
        from_stop_id,
        to_stop_id,
        transfer_type,
        min_transfer_time,
        agency_id,
        last_modified,
        from_stop_id_import,
        to_stop_id_import )

    SELECT 
        transfer_id,
        from_stop_id,
        to_stop_id,
        transfer_type,
        min_transfer_time,
        agency_id,
        last_modified,
        from_stop_id_import,
        to_stop_id_import  
    FROM transfers;
    ";
$result = db_query($migrate_transfers_query);



$get_least_unused_transfer_id = "
    SELECT 1 + MAX(transfer_id)
    FROM {$table_prefix}_transfers";
$result = db_query($get_least_unused_transfer_id);
$least_unused_transfer_id = db_fetch_array($result)[0];
echo "<br />\n least_unused_transfer_id $least_unused_transfer_id";
$restart_transfers_sequence = "
    ALTER SEQUENCE {$table_prefix}_transfers_transfer_id_seq 
    RESTART WITH $least_unused_transfer_id
    ";
$result = db_query($restart_transfers_sequence);


