
-- This query refreshes the first arrivals.
--    begin;
truncate :"DST_SCHEMA".snap_first_arrivals_for_trip;

insert into :"DST_SCHEMA".snap_first_arrivals_for_trip 
select 
    trip_id, arrival_time as first_arrival_time
from (
        select 
            trip_id, arrival_time,
            stop_sequence,
            min(stop_sequence) over (partition by trip_id) as min_stop_sequence 
        from :"SRC_SCHEMA".stop_times
        join :"SRC_SCHEMA".trips using (trip_id)
        where
            stop_times.agency_id in (select agency_id from :"DST_SCHEMA".agencies)
            and trips.trip_id not in (:SKIP_TRIP_ID_STRING)
    ) st
where stop_sequence = min_stop_sequence;

/* scan for duplicate trip_ids here.

select 
    trip_id, array_agg(stop_sequence), array_agg(arrival_time)
from (
        select 
            trip_id, arrival_time,
            stop_sequence,
            min(stop_sequence) over (partition by trip_id) as min_stop_sequence 
        from :"SRC_SCHEMA".stop_times
        join :"SRC_SCHEMA".trips using (trip_id)
        where stop_times.agency_id in (select agency_id from :"DST_SCHEMA".agencies)
    ) st
where stop_sequence = min_stop_sequence
group by trip_id having count(*) > 1;


*/

