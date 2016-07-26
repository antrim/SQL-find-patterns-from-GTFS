create or replace view views.migrate_route_primary_patterns 
as 
select route_id, direction_id, primary_pattern_id from
( 
  select
    route_id, direction_id, pattern_id,
    sum(
        CASE WHEN (headway_secs IS NULL or end_time IS NULL) 
            THEN 1
        ELSE floor(1 + extract(epoch from end_time-start_time) / headway_secs)
        END
        ) AS num_trips,
    first_value(pattern_id) over w as primary_pattern_id
  from migrate_timed_patterns
  join migrate_patterns using (pattern_id)
  join migrate_schedules using (timed_pattern_id)
  group by route_id, direction_id, pattern_id
  window w as (partition by route_id, direction_id
               order by route_id, direction_id, 
                        sum(
                            CASE WHEN (headway_secs IS NULL or end_time IS NULL) 
                                THEN 1
                                ELSE floor(1 + extract(epoch from end_time-start_time) / headway_secs)
                                END
                            )   desc,
                        pattern_id)
  order by route_id, direction_id, num_trips desc, pattern_id 

) most_common
group by route_id, direction_id, primary_pattern_id order by route_id, direction_id;

ALTER view views.play_migrate_route_primary_patterns owner to trillium_gtfs_group;


create or replace view views.migrate_route_primary_patterns 
as 
select route_id, direction_id, primary_pattern_id from
( 
  select
    route_id, direction_id, pattern_id,
    sum(
        CASE WHEN (headway_secs IS NULL or end_time IS NULL) 
            THEN 1
        ELSE floor(1 + extract(epoch from end_time-start_time) / headway_secs)
        END
        ) AS num_trips,
    first_value(pattern_id) over w as primary_pattern_id
  from migrate_timed_patterns
  join migrate_patterns using (pattern_id)
  join migrate_schedules using (timed_pattern_id)
  group by route_id, direction_id, pattern_id
  window w as (partition by route_id, direction_id
               order by route_id, direction_id, 
                        sum(
                            CASE WHEN (headway_secs IS NULL or end_time IS NULL) 
                                THEN 1
                                ELSE floor(1 + extract(epoch from end_time-start_time) / headway_secs)
                                END
                            )   desc,
                        pattern_id)
  order by route_id, direction_id, num_trips desc, pattern_id 

) most_common
group by route_id, direction_id, primary_pattern_id order by route_id, direction_id;

ALTER view views.migrate_route_primary_patterns owner to trillium_gtfs_group;

