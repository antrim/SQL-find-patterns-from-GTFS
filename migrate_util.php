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

function env_or_default($varname, $default_value) {
    # if varname is an environment variable, use it's value, otherwise return the default_value
    return getenv($varname) ? getenv($varname) : $default_value;
}

# 231 = megabus. https://github.com/trilliumtransit/GTFSManager/issues/327  
# 210 = OLD DEPRECATED PennDOT RT "rabbit transit".
# 40 = OLD DEPRECATED BAT. Has no agency_group aka feed.
#   https://github.com/trilliumtransit/GTFSManager/issues/380#
$skip_agency_id_string =  "210, 40, 231, 523, 567";

# Ed: note that testing has begun as of 2016-08-09.
# Don't set this to migrate unless you're testing after-hours!
# $table_prefix = "migrate";

# $src_schema = "public";
$src_schema = env_or_default('SRC_SCHEMA', "public");

# $table_prefix = "play_migrate";
$dst_schema = env_or_default('DST_SCHEMA', "play_migrate");

$live = false;
set_time_limit(7200);

//  {$src_schema}. 

?>
