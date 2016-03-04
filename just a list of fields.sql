CREATE TABLE "migrate_agency" ( 
agency_id, agency_id_import, agency_url, agency_timezone, agency_lang_id, agency_name, agency_short_name, agency_phone, agency_fare_url, agency_info, query_tracking, last_modified, maintenance_start, gtfs_plus, no_frequencies );
 
 CREATE TABLE "migrate_directions" ( 
direction_id, agency_id, direction_label, direction_bool, last_modified );
 
 CREATE TABLE "migrate_headsigns" ( 
agency_id, headsign_id, headsign, last_modified );
 
 CREATE TABLE "migrate_pattern_stop" ( 
agency_id, pattern_id, stop_order, stop_id,  
 CREATE TABLE "migrate_pattern" ( 
agency_id, pattern_id, route_id, direction_id, headsign_id );
 
 CREATE TABLE "migrate_routes" ( 
agency_id, route_id, route_short_name, route_long_name, route_desc, route_type, route_color, route_text_color, route_url, route_bikes_allowed, route_id_import, last_modified, route_sort_order, hidden );
 
 CREATE TABLE "migrate_timed_pattern" ( 
agency_id, timed_pattern_id, pattern_id,  
 CREATE TABLE "migrate_timed_pattern_stop" ( 
agency_id, stop_id, stop_order, timed_pattern_id, pickup_type, drop_off_type, route_id, arrival_time, departure_time,  
 CREATE TABLE "migrate_timed_pattern_stops_nonnormalized" ( 
agency_id, agency_name, route_short_name, route_long_name, direction_label, direction_id, trip_headsign_id, trip_headsign, stop_id, stop_order, timed_pattern_id, pattern_id, pickup_type, drop_off_type, one_trip, trips_list, stops_pattern, arrival_time_intervals, departure_time_intervals, route_id, arrival_time, departure_time, stop_headsign, stop_headsign_id)