-- Assign names to patterns based on their first stop, last stop, and 
-- number of stops. Ed 2016-07-10
-- https://github.com/trilliumtransit/migrate-GTFS/issues/12
/*
$pattern_names_method_alpha_query = "
WITH 

pattern_stop_summary AS 
( SELECT 
    pattern_id, 
    count(*) AS number_of_stops, 
    min(stop_order) AS min_stop_order, 
    max(stop_order) AS max_stop_order 
  FROM :"DST_SCHEMA".pattern_stops 
  GROUP BY pattern_id), 

generated_names AS 
( SELECT p.pattern_id
  , s1.name || ' to ' || sN.name || ' x' || number_of_stops AS generated_name
  FROM :"DST_SCHEMA".patterns p
  JOIN pattern_stop_summary ps using(pattern_id) 
  JOIN :"DST_SCHEMA".pattern_stops ps1
       ON (ps1.pattern_id = p.pattern_id AND ps1.stop_order = min_stop_order) 
  JOIN :"DST_SCHEMA".pattern_stops psN
       ON (psN.pattern_id = p.pattern_id AND psN.stop_order = max_stop_order) 
  JOIN :"SRC_SCHEMA".stops s1 ON (s1.stop_id = ps1.stop_id)
  JOIN :"SRC_SCHEMA".stops sN ON (sN.stop_id = psN.stop_id))

UPDATE :"DST_SCHEMA"_patterns SET name = generated_name 
FROM generated_names
WHERE generated_names.pattern_id = :"DST_SCHEMA".patterns.pattern_id;
    ;
    */


-- Assign names to patterns based on the difference in which stops they visit 
-- compared to the "Primary" (most-often-used) pattern for their route.
-- Ed 2016-07-12
-- https://github.com/trilliumtransit/migrate-GTFS/issues/11

WITH
patterns_with_stops_difference AS 
(
    SELECT
        p.route_id, p.pattern_id, primary_pattern_id  
        , array_length(s_agg.stop_ids, 1) as n_stops
        , coalesce(array_length(s_agg.stop_ids - primary_s_agg.primary_stop_ids, 1), 0) as n_added_stops
        , coalesce(array_length(primary_s_agg.primary_stop_ids - s_agg.stop_ids, 1), 0) as n_removed_stops
        , s_agg.stop_ids - primary_s_agg.primary_stop_ids as added_stop_ids
            , primary_s_agg.primary_stop_ids - s_agg.stop_ids as removed_stop_ids
        , s_agg.stop_ids
    FROM :"DST_SCHEMA".patterns p
    JOIN :"DST_SCHEMA".route_primary_patterns AS route_primary_patterns using (route_id, direction_id)
    JOIN
    ( 
        SELECT pattern_id, array_agg(stop_id order by stop_id) stop_ids
        FROM :"DST_SCHEMA".pattern_stops group by pattern_id) s_agg
        USING (pattern_id)
    JOIN
    ( 
        SELECT pattern_id, array_agg(stop_id order by stop_id) primary_stop_ids
        FROM :"DST_SCHEMA".pattern_stops group by pattern_id) primary_s_agg
    ON (primary_s_agg.pattern_id = route_primary_patterns.primary_pattern_id))

, generated_names AS
(
    SELECT
        route_id
        , pattern_id
        , primary_pattern_id
        , n_added_stops
        , n_removed_stops
        , ( CASE when pattern_id = primary_pattern_id 
            THEN 'Primary' 
            ELSE CASE when (n_added_stops > 3 or n_added_stops = 0)
                    THEN '+ '  || n_added_stops || ' stops'
                    ELSE '+ '  || (SELECT string_agg(name, ' + ')
                                    FROM  :"DST_SCHEMA".stops 
                                    WHERE stop_id  IN (SELECT unnest(added_stop_ids))) END
            || CASE when (n_removed_stops > 3 or n_removed_stops = 0)
                    THEN ' - ' || n_removed_stops || ' stops'
                    ELSE ' - ' || (SELECT string_agg(name, ' - ') 
                                    FROM  :"DST_SCHEMA".stops 
                                    WHERE stop_id  IN (SELECT unnest(removed_stop_ids))) END
            END ) AS generated_name
    FROM patterns_with_stops_difference
    ORDER by route_id, pattern_id)

UPDATE :"DST_SCHEMA".patterns SET name = generated_name
FROM generated_names
WHERE generated_names.pattern_id = :"DST_SCHEMA".patterns.pattern_id;


