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

?>
