<html><head><title>migrate_addendum.php!</title><head>
<body>
<?php

// require_once $_SERVER['DOCUMENT_ROOT'] . '/includes/config.inc.php';
require_once './includes/config.inc.php';

$live = false;
set_time_limit(7200);

# $table_prefix = "migrate";
$table_prefix = "play_migrate";


// Assign names to patterns based on their first stop, last stop, and 
// number of stops. Ed 2016-07-10
// https://github.com/trilliumtransit/migrate-GTFS/issues/12
$pattern_names_method_alpha_query = "
WITH 

pattern_stop_summary AS 
( SELECT 
    pattern_id, 
    count(*) AS number_of_stops, 
    min(stop_order) AS min_stop_order, 
    max(stop_order) AS max_stop_order 
  FROM {$table_prefix}.pattern_stops 
  GROUP BY pattern_id), 

generated_names AS 
( SELECT p.pattern_id
  , s1.name || ' to ' || sN.name || ' x' || number_of_stops AS generated_name
  FROM {$table_prefix}.patterns p
  JOIN pattern_stop_summary ps using(pattern_id) 
  JOIN {$table_prefix}.pattern_stops ps1
       ON (ps1.pattern_id = p.pattern_id AND ps1.stop_order = min_stop_order) 
  JOIN {$table_prefix}.pattern_stops psN
       ON (psN.pattern_id = p.pattern_id AND psN.stop_order = max_stop_order) 
  JOIN stops s1 ON (s1.stop_id = ps1.stop_id)
  JOIN stops sN ON (sN.stop_id = psN.stop_id))

UPDATE ${table_prefix}_patterns SET name = generated_name 
FROM generated_names
WHERE generated_names.pattern_id = {$table_prefix}.patterns.pattern_id;
    ";




// Assign names to patterns based on the difference in which stops they visit 
// compared to the "Primary" (most-often-used) pattern for their route.
// Ed 2016-07-12
// https://github.com/trilliumtransit/migrate-GTFS/issues/11
$pattern_names_method_beta_query = "
WITH

patterns_with_stops_difference AS 
(select
    p.route_id, p.pattern_id, primary_pattern_id  
  , array_length(s_agg.stop_ids, 1) as n_stops
  , coalesce(array_length(s_agg.stop_ids - primary_s_agg.primary_stop_ids, 1), 0) as n_added_stops
  , coalesce(array_length(primary_s_agg.primary_stop_ids - s_agg.stop_ids, 1), 0) as n_removed_stops
  , s_agg.stop_ids - primary_s_agg.primary_stop_ids as added_stop_ids
  , primary_s_agg.primary_stop_ids - s_agg.stop_ids as removed_stop_ids
  , s_agg.stop_ids
from {$table_prefix}.patterns p
join views.{$table_prefix}.route_primary_patterns using (route_id, direction_id)
join
    ( select pattern_id, array_agg(stop_id order by stop_id) stop_ids
      from {$table_prefix}.pattern_stops group by pattern_id) s_agg
    using (pattern_id)
join
    ( select pattern_id, array_agg(stop_id order by stop_id) primary_stop_ids
      from {$table_prefix}.pattern_stops group by pattern_id) primary_s_agg
    on (primary_s_agg.pattern_id = {$table_prefix}.route_primary_patterns.primary_pattern_id)  )

,generated_names AS
(select
    route_id
  , pattern_id
  , primary_pattern_id
  , n_added_stops
  , n_removed_stops
  , case when pattern_id = primary_pattern_id 
        then 'Primary' 
        else case when (n_added_stops > 3 or n_added_stops = 0)
                 then '+ '  || n_added_stops || ' stops'
                 else '+ '  || (SELECT string_agg(name, ' + ')
                                FROM  {$table_prefix}.stops 
                                WHERE stop_id  IN (SELECT unnest(added_stop_ids))) END
          || case when (n_removed_stops > 3 or n_removed_stops = 0)
                 then ' - ' || n_removed_stops || ' stops'
                 else ' - ' || (SELECT string_agg(name, ' - ') 
                                FROM  {$table_prefix}.stops 
                                WHERE stop_id  IN (SELECT unnest(removed_stop_ids))) END
        end
   as generated_name
from patterns_with_stops_difference
order by route_id, pattern_id)

update {$table_prefix}.patterns SET name = generated_name
from generated_names
where generated_names.pattern_id = {$table_prefix}.patterns.pattern_id
    ";

$result = db_query($pattern_names_method_beta_query);


echo "<br / >\n" . "Migration addendum successful.";

?>
</body></html>

