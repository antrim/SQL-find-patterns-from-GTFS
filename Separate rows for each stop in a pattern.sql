WITH result_set AS(
WITH timed_patterns AS (

WITH timed_patterns_sub AS ( 

SELECT MIN(trips.trip_id) as one_trip,string_agg( trips.trip_id::text, ', ' ORDER BY sequences.min_arrival_time ) AS trips_list, sequences.stops_pattern, arrival_time_intervals,departure_time_intervals,trips.agency_id,routes.route_id,routes.route_short_name,routes.route_long_name,directions.direction_label,headsigns.headsign
FROM trips
INNER JOIN (

	 SELECT  string_agg(stop_times.stop_id::text , ', ' ORDER BY stop_times.stop_sequence ASC) AS stops_pattern, stop_times.trip_id, MIN( stop_times.arrival_time ) AS min_arrival_time

	 FROM stop_times
	 WHERE stop_times.agency_id IN (392)
	 GROUP BY stop_times.trip_id
	 ) AS sequences ON trips.trip_id = sequences.trip_id

INNER JOIN
	 (SELECT
	 min_arrival_time, min_departure_time, min_trip_times.trip_id, string_agg(
	 case when stop_times.arrival_time IS NOT NULL THEN (stop_times.arrival_time - min_arrival_time)::text ELSE ''
	   end
	  ,  ','  ORDER BY stop_times.stop_sequence ASC) as arrival_time_intervals,
	 string_agg(
	 case when stop_times.arrival_time IS NOT NULL THEN (stop_times.departure_time - min_departure_time)::text ELSE ''
	   end
	  ,  ','  ORDER BY stop_times.stop_sequence ASC) as departure_time_intervals 
	 FROM stop_times
		 INNER JOIN (
		 SELECT MIN( arrival_time ) AS min_arrival_time, MIN( departure_time ) AS min_departure_time,  trip_id
		 FROM stop_times
		 WHERE agency_id IN (392)
		 GROUP BY stop_times.trip_id
		 ) min_trip_times ON stop_times.trip_id = min_trip_times.trip_id
	 WHERE stop_times.agency_id in (392)
	 GROUP BY min_trip_times.trip_id,min_arrival_time,min_departure_time
	) AS time_intervals_result

ON sequences.trip_id = time_intervals_result.trip_id

LEFT JOIN routes on trips.route_id = routes.route_id
LEFT JOIN directions ON trips.direction_id = directions.direction_id
LEFT JOIN headsigns on trips.headsign_id = headsigns.headsign_id

WHERE trips.agency_id IN (392)
GROUP BY stops_pattern,arrival_time_intervals,departure_time_intervals,trips.agency_id,routes.route_id,routes.route_short_name,routes.route_long_name,directions.direction_label,headsigns.headsign

) select row_number() over() as timed_pattern_id, * from timed_patterns_sub ),

stop_patterns AS (


WITH unique_patterns AS(
SELECT DISTINCT string_agg(stop_times.stop_id::text , ', ' ORDER BY stop_times.stop_sequence ASC) AS stops_pattern

	 FROM stop_times
	 inner join trips on stop_times.trip_id = trips.trip_id
	 WHERE trips.agency_id IN (392,392) AND trips.based_on IS NULL
	 GROUP BY stop_times.trip_id)
SELECT unique_patterns.stops_pattern,row_number() over() as pattern_id from unique_patterns

)

SELECT timed_patterns.agency_id,stop_times.stop_id, arrival_time_intervals::text || departure_time_intervals::text || ' - ' || stop_patterns.stops_pattern::text AS concat_pattern,
dense_rank() over (partition by timed_pattern_id order by stop_times.stop_sequence) as stop_order,
timed_pattern_id,
stop_patterns.pattern_id,
CASE WHEN stop_times.arrival_time IS NOT NULL THEN (stop_times.arrival_time - min_arrival_time)::text END as arrival_time,
CASE WHEN stop_times.departure_time IS NOT NULL THEN (stop_times.departure_time - min_departure_time)::text END as departure_time,
one_trip,trips_list,stop_patterns.stops_pattern,arrival_time_intervals,departure_time_intervals,route_id,route_short_name,route_long_name,direction_label,headsign FROM timed_patterns
LEFT JOIN stop_times ON timed_patterns.one_trip = stop_times.trip_id
inner JOIN stop_patterns ON timed_patterns.stops_pattern = stop_patterns.stops_pattern
ORDER BY pattern_id,timed_pattern_id ASC, stop_times.stop_sequence ASC
) SELECT COUNT(DISTINCT timed_pattern_id),COUNT(DISTINCT concat_pattern),COUNT(DISTINCT pattern_id),COUNT(DISTINCT stops_pattern) FROM result_set