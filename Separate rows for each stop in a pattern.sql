SELECT MIN(pattern_id) as pattern_id,MIN(trips.trip_id) as one_trip,string_agg( trips.trip_id::text, ', ' ORDER BY sequences.min_arrival_time ) AS trips_list, sequences.stops_pattern, stop_time_intervals,trips.agency_id,routes.route_id,routes.route_short_name,routes.route_long_name,directions.direction_label,headsigns.headsign
FROM trips
INNER JOIN (

 SELECT  string_agg(stop_times.stop_id::text , ', ' ORDER BY stop_times.stop_sequence ASC) AS stops_pattern, stop_times.trip_id, MIN( stop_times.arrival_time ) AS min_arrival_time
 FROM stop_times
 WHERE stop_times.agency_id IN (1,3,267)
 GROUP BY stop_times.trip_id
 ) AS sequences ON trips.trip_id = sequences.trip_id

INNER JOIN
 (
 SELECT  row_number() over() as pattern_id, min_arrival_time, min_trip_times.trip_id, string_agg(
 case when stop_times.arrival_time IS NOT NULL THEN (stop_times.arrival_time - min_arrival_time)::text
   end
  ,  ','  ORDER BY stop_times.stop_sequence ASC) as stop_time_intervals
 FROM stop_times
 INNER JOIN (
 SELECT MIN( arrival_time ) AS min_arrival_time, trip_id
 FROM stop_times
 WHERE agency_id IN (1,3,267)
 GROUP BY stop_times.trip_id
 ) min_trip_times ON stop_times.trip_id = min_trip_times.trip_id
 WHERE stop_times.agency_id in (1,3,267)
 GROUP BY min_trip_times.trip_id,min_arrival_time
) AS time_intervals_result

ON sequences.trip_id = time_intervals_result.trip_id
LEFT JOIN routes on trips.route_id = routes.route_id
LEFT JOIN directions ON trips.direction_id = directions.direction_id
LEFT JOIN headsigns on trips.headsign_id = headsigns.headsign_id

WHERE trips.agency_id IN (1,3,267)
GROUP BY stops_pattern,stop_time_intervals,trips.agency_id,routes.route_id,routes.route_short_name,routes.route_long_name,directions.direction_label,headsigns.headsign