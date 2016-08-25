<?php 

function db_query_debug($q) {
    echo "<br />\nrunning query:\n$q \n";
    ob_flush();
    flush();
    $rv = db_query($q);
    echo "<br />\ndatabase return value: $rv \n";
    ob_flush();
    flush();
    return $rv;
}

# 210 = OLD DEPRECATED PennDOT RT "rabbit transit".
$skip_agency_id_string =  "210";

# Ed: note that testing has begun as of 2016-08-09.
# Don't set this to migrate unless you're testing after-hours!
# $table_prefix = "migrate";

# $src_schema = "public";
$src_schema = getenv('SRC_SCHEMA') ? getenv('SRC_SCHEMA') : "public";

# $table_prefix = "play_migrate";
$dst_schema = getenv('DST_SCHEMA') ? getenv('DST_SCHEMA') : "play_migrate";

$live = false;
set_time_limit(7200);

//  {$src_schema}. 

?>
