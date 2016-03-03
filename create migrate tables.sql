CREATE TABLE "public"."migrate_agency" ( 
	"agency_id" Integer DEFAULT nextval('agency_agency_id_seq'::regclass) NOT NULL,
	"agency_id_import" Character Varying( 100 ) COLLATE "pg_catalog"."default" DEFAULT NULL::character varying,
	"agency_url" Character Varying( 255 ) COLLATE "pg_catalog"."default" DEFAULT ''::character varying NOT NULL,
	"agency_timezone" Character Varying( 45 ) COLLATE "pg_catalog"."default" DEFAULT ''::character varying NOT NULL,
	"agency_lang_id" Integer DEFAULT 1,
	"agency_name" Character Varying( 120 ) COLLATE "pg_catalog"."default" NOT NULL,
	"agency_short_name" Character Varying( 10 ) COLLATE "pg_catalog"."default" DEFAULT ''::character varying NOT NULL,
	"agency_phone" Character Varying( 70 ) COLLATE "pg_catalog"."default" DEFAULT NULL::character varying,
	"agency_fare_url" Character Varying( 255 ) COLLATE "pg_catalog"."default" NOT NULL,
	"agency_info" Character Varying( 255 ) COLLATE "pg_catalog"."default" DEFAULT NULL::character varying,
	"query_tracking" Integer DEFAULT 0,
	"last_modified" Timestamp Without Time Zone DEFAULT now() NOT NULL,
	"maintenance_start" Date,
	"gtfs_plus" Integer DEFAULT 0,
	"no_frequencies" Boolean DEFAULT true NOT NULL,
	PRIMARY KEY ( "agency_id" ) );
 
 CREATE TABLE "public"."migrate_directions" ( 
	"direction_id" Integer DEFAULT nextval('directions_direction_id_seq'::regclass) NOT NULL,
	"agency_id" Integer,
	"direction_label" Character Varying( 35 ) COLLATE "pg_catalog"."default" NOT NULL,
	"direction_bool" Integer,
	"last_modified" Timestamp Without Time Zone DEFAULT now() NOT NULL,
	PRIMARY KEY ( "direction_id" ) );
 
 CREATE TABLE "public"."migrate_headsigns" ( 
	"agency_id" Integer,
	"headsign_id" Integer DEFAULT nextval('headsigns_headsign_id_seq'::regclass) NOT NULL,
	"headsign" Character Varying( 105 ) COLLATE "pg_catalog"."default" DEFAULT ''::character varying NOT NULL,
	"last_modified" Timestamp Without Time Zone DEFAULT now() NOT NULL,
	PRIMARY KEY ( "headsign_id" ) );
 
 CREATE TABLE "public"."migrate_pattern_stop" ( 
	"agency_id" SmallInt NOT NULL,
	"pattern_id" Bigint NOT NULL,
	"stop_order" SmallInt NOT NULL,
	"stop_id" Bigint NOT NULL );
 
 CREATE TABLE "public"."migrate_patterns" ( 
	"agency_id" SmallInt NOT NULL,
	"pattern_id" Bigint NOT NULL,
	"route_id" Bigint NOT NULL,
	"direction_id" Bigint,
	"headsign_id" Bigint,
	PRIMARY KEY ( "pattern_id" ) );
 
 CREATE TABLE "public"."migrate_routes" ( 
	"agency_id" Integer DEFAULT 0,
	"route_id" Integer DEFAULT nextval('routes_route_id_seq'::regclass) NOT NULL,
	"route_short_name" Character Varying( 30 ) COLLATE "pg_catalog"."default" DEFAULT ''::character varying NOT NULL,
	"route_long_name" Character Varying( 220 ) COLLATE "pg_catalog"."default" DEFAULT ''::character varying NOT NULL,
	"route_desc" Text COLLATE "pg_catalog"."default",
	"route_type" Integer DEFAULT 3,
	"route_color" Character Varying( 6 ) COLLATE "pg_catalog"."default" DEFAULT NULL::character varying,
	"route_text_color" Character Varying( 6 ) COLLATE "pg_catalog"."default" DEFAULT NULL::character varying,
	"route_url" Character Varying( 300 ) COLLATE "pg_catalog"."default" DEFAULT NULL::character varying,
	"route_bikes_allowed" Integer DEFAULT 0,
	"route_id_import" Character Varying( 100 ) COLLATE "pg_catalog"."default" DEFAULT ''::character varying NOT NULL,
	"last_modified" Timestamp Without Time Zone DEFAULT now() NOT NULL,
	"route_sort_order" Integer DEFAULT 0,
	"hidden" Boolean DEFAULT false NOT NULL,
	PRIMARY KEY ( "route_id" ) );
 
 CREATE TABLE "public"."migrate_timed_pattern" ( 
	"agency_id" SmallInt NOT NULL,
	"timed_pattern_id" Bigint NOT NULL,
	"pattern_id" Bigint NOT NULL );
 
 CREATE TABLE "public"."migrate_timed_pattern_stop" ( 
	"agency_id" SmallInt NOT NULL,
	"stop_id" Bigint,
	"stop_order" SmallInt NOT NULL,
	"timed_pattern_id" Bigint NOT NULL,
	"pickup_type" SmallInt NOT NULL,
	"drop_off_type" SmallInt NOT NULL,
	"route_id" Bigint,
	"arrival_time" Interval,
	"departure_time" Interval,
	"headsign_id" Bigint );
 
 CREATE TABLE "public"."migrate_timed_pattern_stops_nonnormalized" ( 
	"agency_id" SmallInt NOT NULL,
	"agency_name" Character Varying( 2044 ) COLLATE "pg_catalog"."default" NOT NULL,
	"route_short_name" Character Varying( 2044 ) COLLATE "pg_catalog"."default" NOT NULL,
	"route_long_name" Character Varying( 2044 ) COLLATE "pg_catalog"."default" NOT NULL,
	"direction_label" Character Varying( 2044 ) COLLATE "pg_catalog"."default" NOT NULL,
	"direction_id" Bigint,
	"trip_headsign_id" SmallInt,
	"trip_headsign" Character Varying( 2044 ) COLLATE "pg_catalog"."default" NOT NULL,
	"stop_id" Bigint,
	"stop_order" SmallInt NOT NULL,
	"timed_pattern_id" Bigint NOT NULL,
	"pattern_id" Bigint NOT NULL,
	"pickup_type" SmallInt NOT NULL,
	"drop_off_type" SmallInt NOT NULL,
	"one_trip" Bigint,
	"trips_list" Character Varying( 5000 ) COLLATE "pg_catalog"."default",
	"stops_pattern" Character Varying( 5000 ) COLLATE "pg_catalog"."default" NOT NULL,
	"arrival_time_intervals" Character Varying( 5000 ) COLLATE "pg_catalog"."default" NOT NULL,
	"departure_time_intervals" Character Varying( 5000 ) COLLATE "pg_catalog"."default" NOT NULL,
	"route_id" Bigint,
	"arrival_time" Interval,
	"departure_time" Interval,
	"stop_headsign" Character Varying( 2044 ) COLLATE "pg_catalog"."default",
	"stop_headsign_id" Bigint );
 