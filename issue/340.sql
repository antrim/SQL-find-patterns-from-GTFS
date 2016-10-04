\x on
SELECT 
    b.*, t.*
from public.trips b 
join public.trips t on b.based_on = t.trip_id 
where 
    b.based_on is not null 
    and b.agency_id = 61;


SELECT 
    b.trip_id as b_trip_id, trips.trip_id as trips_trip_id
    , b.agency_id, dev_patterns_trips.timed_pattern_id AS timed_pattern_id
    , service_schedule_group_id AS calendar_id
    , coalesce(b.trip_start_time, trips.trip_start_time)::INTERVAL AS start_time
    -- , snap_first_arrivals_for_trip.first_arrival_time AS start_time 
    , b.trip_start_time as b_trip_start_time
    , trips.trip_start_time as trips_trip_start_time
    , b.block_id
    , monday::boolean, tuesday::boolean, wednesday::boolean
    , thursday::boolean, friday::boolean
    , saturday::boolean, sunday::boolean 
    , trips.in_seat_transfer = 1
FROM :"SRC_SCHEMA".trips b
JOIN :"SRC_SCHEMA".trips 
    ON b.based_on = trips.trip_id
INNER JOIN :"DST_SCHEMA".dev_patterns_trips 
    ON trips.trip_id = dev_patterns_trips.trip_id
INNER JOIN :"SRC_SCHEMA".calendar 
    ON b.service_id = calendar.calendar_id 
WHERE 
    (b.trip_start_time is null
    and trips.trip_start_time is null)
    AND b.service_id IS NOT NULL 
    AND NOT EXISTS (SELECT NULL 
                    FROM :"SRC_SCHEMA".frequencies 
                    WHERE trips.trip_id = frequencies.trip_id) 
    AND b.based_on IS NOT NULL
    AND trips.agency_id IN (SELECT agency_id 
                            FROM :"DST_SCHEMA".agencies);



select * from public.agency where agency_id = 236;

SELECT 
--    t1.agency_id, t1.trip_id, t1.based_on
   -- t1.agency_id, 
    t1.route_id, 
   -- t1.service_id, 
    t1.trip_id, -- t1.trip_short_name,
    t1.headsign_id, t1.block_id, 
   -- t1.shape_id, 
    t1.direction_id, 
    t1.based_on,
--    t1.trip_start_time, 
   -- t1.trip_bikes_allowed, t1.last_modified, t1.hidden,
   -- t1.in_seat_transfer, 
   -- t1.wheelchair_accessible,
    calendar.*
FROM public.trips t1
JOIN public.trips t2 on (t1.based_on = t2.trip_id)
JOIN public.calendar 
    ON t1.service_id = calendar_id
WHERE 
    t1.trip_start_time IS NULL
    AND t2.trip_start_time IS NULL
    AND t1.service_id IS NOT NULL
    AND t2.service_id IS NOT NULL
    AND service_schedule_group_id IS NOT NULL
    AND t1.trip_id NOT IN 
        (SELECT trip_id FROM public.frequencies)
    AND t2.trip_id NOT IN 
        (SELECT trip_id FROM public.frequencies);

