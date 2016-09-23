
SELECT route_id, trip_id, start_time, end_time , headway_secs
from public.frequencies 
join public.trips using (trip_id) where route_id in (4685)
order by route_id, trip_id;


SELECT route_id, trip_id, start_time, end_time , headway_secs
from migrate.trips 
join migrate.timed_patterns using (timed_pattern_id )
join migrate.patterns using (pattern_id )
where route_id in (4685)
order by route_id, trip_id;

