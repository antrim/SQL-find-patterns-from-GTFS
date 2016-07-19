create view views.play_migrate_route_primary_patterns 
as 
select route_id, direction_id, primary_pattern_id from
( select
    route_id, direction_id, pattern_id,
    count(*), first_value(pattern_id) over w as primary_pattern_id
  from play_migrate_timed_patterns
  join play_migrate_patterns using (pattern_id)
  group by route_id, direction_id, pattern_id
  window w as (partition by route_id, direction_id
               order by route_id, direction_id, count(*) desc, pattern_id)
  order by route_id, direction_id, count(*) desc, pattern_id) most_common
group by route_id, direction_id, primary_pattern_id order by route_id, direction_id;


ALTER view views.play_migrate_route_primary_patterns owner to trillium_gtfs_group;

create view views.migrate_route_primary_patterns 
as 
select route_id, primary_pattern_id from
( select route_id, pattern_id, count(*), first_value(pattern_id) over w as primary_pattern_id
  from migrate_timed_patterns
  join migrate_patterns using (pattern_id)
  group by route_id, pattern_id
  window w as (partition by route_id order by route_id, count(*) desc, pattern_id)
  order by route_id, count(*) desc, pattern_id) most_common
group by route_id, primary_pattern_id order by route_id;

ALTER view views.migrate_route_primary_patterns owner to trillium_gtfs_group;

