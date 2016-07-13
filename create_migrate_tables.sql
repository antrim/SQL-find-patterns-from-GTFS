
/* Array difference operators. Thanks to
 * http://www.databasesoup.com/2015/03/fancy-sql-friday-subtracting-arrays.html 
 */

create or replace function array_diff_elements(anyarray, anyarray)
returns anyarray as
$fn$
    select
        array(
            select unnest($1)
             except
            select unnest($2));
$fn$
language sql immutable;

create operator - (
    procedure = array_diff_elements,
    leftarg   = anyarray,
    rightarg  = anyarray
);


create or replace function array_diff_elements_text ( text[], text[] )
returns text[]
language sql
immutable
as $f$
    SELECT array_agg(DISTINCT new_arr.elem)
    FROM
        unnest($1) as new_arr(elem)
        LEFT OUTER JOIN
        unnest($2) as old_arr(elem)
        ON new_arr.elem = old_arr.elem
    WHERE old_arr.elem IS NULL;
$f$;

create operator - (
    procedure = array_diff_elements_text,
    leftarg = text[],
    rightarg = text[]
);

create or replace function array_diff_elements_integer ( integer[], integer[] )
returns integer[]
language sql
immutable
as $f$
    SELECT array_agg(DISTINCT new_arr.elem)
    FROM
        unnest($1) as new_arr(elem)
        LEFT OUTER JOIN
        unnest($2) as old_arr(elem)
        ON new_arr.elem = old_arr.elem
    WHERE old_arr.elem IS NULL;
$f$;

create operator - (
    procedure = array_diff_elements_integer,
    leftarg = integer[],
    rightarg = integer[]
);

create or replace function array_diff_elements_bigint ( bigint[], bigint[] )
returns bigint[]
language sql
immutable
as $f$
    SELECT array_agg(DISTINCT new_arr.elem)
    FROM
        unnest($1) as new_arr(elem)
        LEFT OUTER JOIN
        unnest($2) as old_arr(elem)
        ON new_arr.elem = old_arr.elem
    WHERE old_arr.elem IS NULL;
$f$;

create operator - (
    procedure = array_diff_elements_bigint,
    leftarg = bigint[],
    rightarg = bigint[]
);


/* 
  For Fare rules, a NULL value for a column often means a rule that matches ANY
  or ALL values for that column.  Examples include route_id, origin_id,
  destination_id, contains_id.

  In many cases, coercing NULL values to -411, which we use to mean "ALL",
  allows for simpler joins and searches. 

  NULL_means_ALL(value) is a function to make this pattern more convenient.

  I've defined an implementation for INTEGER or BIGINT columns, if columns of
  type TEXT (or other data types) need to be cooerced from NULL, just create a
  function with the same name but with a different parameter type, for example:

  CREATE FUNCTION public.null_means_all(value TEXT) RETURNS TEXT AS $$
     SELECT COALESCE(value, '**ALL**') $$ LANGUAGE SQL IMMUTABLE;

  Ed 2016-06-27
 */
CREATE OR REPLACE FUNCTION public.null_means_all(value BIGINT)
RETURNS BIGINT AS $$
    SELECT COALESCE(value, -411)
$$ LANGUAGE SQL IMMUTABLE;

ALTER FUNCTION public.null_means_all(value BIGINT) 
      OWNER TO trillium_gtfs_group;

-- geography convenience functions.

CREATE OR REPLACE FUNCTION ST_Lon ( point GEOGRAPHY ) RETURNS DOUBLE PRECISION as $$ 
  SELECT ST_X( point :: geometry ); 
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION ST_Lat ( point GEOGRAPHY ) RETURNS DOUBLE PRECISION as $$ 
  SELECT ST_Y( point :: geometry ); 
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION ST_MakeLine ( points_or_lines GEOGRAPHY[] ) RETURNS GEOGRAPHY AS $$ 
  SELECT st_makeline(points_or_lines :: GEOMETRY[]) :: GEOGRAPHY
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION ST_GeogFromGeoJSON( geojson text ) RETURNS GEOGRAPHY AS $$ 
  SELECT st_geomFromGeoJSON(geojson) :: GEOGRAPHY
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION ST_NPoints( geog GEOGRAPHY ) RETURNS INTEGER AS $$ 
  SELECT st_npoints(geog :: GEOMETRY)
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION ST_DumpPoints( geog GEOGRAPHY ) RETURNS SETOF geometry_dump AS $$ 
  SELECT ST_DumpPoints(geog :: GEOMETRY);
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION ST_LengthMiles( geog GEOGRAPHY ) RETURNS DOUBLE PRECISION AS $$ 
  SELECT ST_Length(geog) * 0.000621371192237 ;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION is_valid_css_color(color text) RETURNS boolean AS $$
  SELECT lower(color) ~ '^[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]$' 
         or lower(color) ~ '^(aliceblue|antiquewhite|aqua|aquamarine|azure|beige|bisque|black|blanchedalmond|blue|blueviolet|brown|burlywood|cadetblue|chartreuse|chocolate|coral|cornflowerblue|cornsilk|crimson|cyan|darkblue|darkcyan|darkgoldenrod|darkgray|darkgreen|darkgrey|darkkhaki|darkmagenta|darkolivegreen|darkorange|darkorchid|darkred|darksalmon|darkseagreen|darkslateblue|darkslategray|darkslategrey|darkturquoise|darkviolet|deeppink|deepskyblue|dimgray|dimgrey|dodgerblue|firebrick|floralwhite|forestgreen|fuchsia|gainsboro|ghostwhite|gold|goldenrod|gray|green|greenyellow|grey|honeydew|hotpink|indianred|indigo|ivory|khaki|lavender|lavenderblush|lawngreen|lemonchiffon|lightblue|lightcoral|lightcyan|lightgoldenrodyellow|lightgray|lightgreen|lightgrey|lightpink|lightsalmon|lightseagreen|lightskyblue|lightslategray|lightslategrey|lightsteelblue|lightyellow|lime|limegreen|linen|magenta|maroon|mediumaquamarine|mediumblue|mediumorchid|mediumpurple|mediumseagreen|mediumslateblue|mediumspringgreen|mediumturquoise|mediumvioletred|midnightblue|mintcream|mistyrose|moccasin|navajowhite|navy|oldlace|olive|olivedrab|orange|orangered|orchid|palegoldenrod|palegreen|paleturquoise|palevioletred|papayawhip|peachpuff|peru|pink|plum|powderblue|purple|red|rosybrown|royalblue|saddlebrown|salmon|sandybrown|seagreen|seashell|sienna|silver|skyblue|slateblue|slategray|slategrey|snow|springgreen|steelblue|tan|teal|thistle|tomato|turquoise|violet|wheat|white|whitesmoke|yellow|yellowgreen|transparent)$';
        $$ LANGUAGE SQL IMMUTABLE;

CREATE TABLE "public"."migrate_agencies" ( 
	"agency_id" Serial NOT NULL,
	"feed_id" SmallInt,
	"agency_id_import" Character Varying( 100 ) DEFAULT NULL::character varying,
	"agency_url" Character Varying( 255 ) DEFAULT ''::character varying NOT NULL,
	"agency_timezone" Character Varying( 45 ) DEFAULT ''::character varying NOT NULL,
	"agency_lang_id" Integer DEFAULT 1,
	"agency_name" Character Varying( 120 ) NOT NULL,
	"agency_short_name" Character Varying( 10 ) DEFAULT ''::character varying NOT NULL,
	"agency_phone" Character Varying( 70 ) DEFAULT NULL::character varying,
	"agency_fare_url" Character Varying( 255 ),
	"agency_info" Character Varying( 255 ) DEFAULT NULL::character varying,
	"query_tracking" Integer DEFAULT 0,
	"last_modified" Timestamp Without Time Zone DEFAULT now() NOT NULL,
	"maintenance_start" Date,
	"gtfs_plus" Integer DEFAULT 0,
	"no_frequencies" Boolean DEFAULT true NOT NULL,
	PRIMARY KEY ( "agency_id" ) );


CREATE TABLE "public"."play_migrate_agencies" ( 
	"agency_id" Serial NOT NULL,
	"feed_id" SmallInt,
	"agency_id_import" Character Varying( 100 ) DEFAULT NULL::character varying,
	"agency_url" Character Varying( 255 ) DEFAULT ''::character varying NOT NULL,
	"agency_timezone" Character Varying( 45 ) DEFAULT ''::character varying NOT NULL,
	"agency_lang_id" Integer DEFAULT 1,
	"agency_name" Character Varying( 120 ) NOT NULL,
	"agency_short_name" Character Varying( 10 ) DEFAULT ''::character varying NOT NULL,
	"agency_phone" Character Varying( 70 ) DEFAULT NULL::character varying,
	"agency_fare_url" Character Varying( 255 ),
	"agency_info" Character Varying( 255 ) DEFAULT NULL::character varying,
	"query_tracking" Integer DEFAULT 0,
	"last_modified" Timestamp Without Time Zone DEFAULT now() NOT NULL,
	"maintenance_start" Date,
	"gtfs_plus" Integer DEFAULT 0,
	"no_frequencies" Boolean DEFAULT true NOT NULL,
	PRIMARY KEY ( "agency_id" ) );

 CREATE TABLE "public"."migrate_blocks" ( 
	"agency_id" Integer NOT NULL,
	"block_id" Serial NOT NULL,
	"name" text NOT NULL,
	"color" text check (is_valid_css_color(color)),
	PRIMARY KEY ( "block_id" ) );

 CREATE TABLE "public"."play_migrate_blocks" ( 
	"agency_id" Integer NOT NULL,
	"block_id" Serial NOT NULL,
	"name" text NOT NULL,
	"color" text check (is_valid_css_color(color)),
	PRIMARY KEY ( "block_id" ) );

CREATE TABLE "public"."migrate_calendars" ( 
	"agency_id" Integer NOT NULL,
	"calendar_id" Serial NOT NULL,
	"name" Character Varying( 2044 ) NOT NULL,
	PRIMARY KEY ( "calendar_id" ) );

CREATE TABLE "public"."play_migrate_calendars" ( 
	"agency_id" Integer NOT NULL,
	"calendar_id" Serial NOT NULL,
	"name" Character Varying( 2044 ) NOT NULL,
	PRIMARY KEY ( "calendar_id" ) );

CREATE TABLE "public"."migrate_calendar_bounds" ( 
	"agency_id" Integer NOT NULL,
	"calendar_bounds_id" Serial NOT NULL,
	"calendar_id" Integer NOT NULL,
	"start_date" Date NOT NULL,
	"end_date" Date NOT NULL,
	PRIMARY KEY ( "calendar_bounds_id" ) );

CREATE TABLE "public"."play_migrate_calendar_bounds" ( 
	"agency_id" Integer NOT NULL,
	"calendar_bounds_id" Serial NOT NULL,
	"calendar_id" Integer NOT NULL,
	"start_date" Date NOT NULL,
	"end_date" Date NOT NULL,
	PRIMARY KEY ( "calendar_bounds_id" ) );

CREATE TABLE "public"."migrate_directions" ( 
	"direction_id" Serial NOT NULL,
	"agency_id" Integer,
	"name" Character Varying( 35 ) NOT NULL,
	"direction_bool" Integer,
	"last_modified" Timestamp Without Time Zone DEFAULT now() NOT NULL,
	PRIMARY KEY ( "direction_id" ) );

CREATE TABLE "public"."play_migrate_directions" ( 
	"direction_id" Serial NOT NULL,
	"agency_id" Integer,
	"name" Character Varying( 35 ) NOT NULL,
	"direction_bool" Integer,
	"last_modified" Timestamp Without Time Zone DEFAULT now() NOT NULL,
	PRIMARY KEY ( "direction_id" ) );

CREATE TABLE "public"."migrate_headsigns" ( 
	"agency_id" Integer,
	"headsign_id" Serial NOT NULL,
	"headsign" Character Varying( 105 ) DEFAULT ''::character varying NOT NULL,
	"last_modified" Timestamp Without Time Zone DEFAULT now() NOT NULL,
	PRIMARY KEY ( "headsign_id" ) );

CREATE TABLE "public"."play_migrate_headsigns" ( 
	"agency_id" Integer,
	"headsign_id" Serial NOT NULL,
	"headsign" Character Varying( 105 ) DEFAULT ''::character varying NOT NULL,
	"last_modified" Timestamp Without Time Zone DEFAULT now() NOT NULL,
	PRIMARY KEY ( "headsign_id" ) );

 CREATE TABLE "public"."migrate_patterns" ( 
	"agency_id" SmallInt NOT NULL,
	"pattern_id" Bigint NOT NULL,
	"route_id" Bigint NOT NULL,
	"direction_id" Bigint,
	"headsign_id" Bigint,
    "name" text,
	PRIMARY KEY ( "pattern_id" ) );

 CREATE TABLE "public"."play_migrate_patterns" ( 
	"agency_id" SmallInt NOT NULL,
	"pattern_id" Bigint NOT NULL,
	"route_id" Bigint NOT NULL,
	"direction_id" Bigint,
	"headsign_id" Bigint,
    "name" text,
	PRIMARY KEY ( "pattern_id" ) );

 CREATE TABLE "public"."migrate_pattern_stops" ( 
	"agency_id" SmallInt NOT NULL,
	"pattern_id" Bigint NOT NULL,
	"stop_order" SmallInt NOT NULL,
	"stop_id" Bigint NOT NULL );

 CREATE TABLE "public"."play_migrate_pattern_stops" ( 
	"agency_id" SmallInt NOT NULL,
	"pattern_id" Bigint NOT NULL,
	"stop_order" SmallInt NOT NULL,
	"stop_id" Bigint NOT NULL );


CREATE TABLE "public"."migrate_schedules" ( 
	"timed_pattern_id" Integer NOT NULL,
	"calendar_id" Integer NOT NULL,
	"headway" Integer,
	"block_id" Integer,
	"agency_id" Integer NOT NULL,
	"start_time" Interval NOT NULL,
	"end_time" Interval,
	"schedule_id" Serial NOT NULL,
	"monday" Boolean DEFAULT false NOT NULL,
	"tuesday" Boolean DEFAULT false NOT NULL,
	"wednesday" Boolean DEFAULT false NOT NULL,
	"thursday" Boolean DEFAULT false NOT NULL,
	"friday" Boolean DEFAULT false NOT NULL,
	"saturday" Boolean DEFAULT false NOT NULL,
	"sunday" Boolean DEFAULT false NOT NULL,
	PRIMARY KEY ( "schedule_id" ) );

CREATE TABLE "public"."play_migrate_schedules" ( 
	"timed_pattern_id" Integer NOT NULL,
	"calendar_id" Integer NOT NULL,
	"headway" Integer,
	"block_id" Integer,
	"agency_id" Integer NOT NULL,
	"start_time" Interval NOT NULL,
	"end_time" Interval,
	"schedule_id" Serial NOT NULL,
	"monday" Boolean DEFAULT false NOT NULL,
	"tuesday" Boolean DEFAULT false NOT NULL,
	"wednesday" Boolean DEFAULT false NOT NULL,
	"thursday" Boolean DEFAULT false NOT NULL,
	"friday" Boolean DEFAULT false NOT NULL,
	"saturday" Boolean DEFAULT false NOT NULL,
	"sunday" Boolean DEFAULT false NOT NULL,
	PRIMARY KEY ( "schedule_id" ) );

 CREATE TABLE "public"."migrate_stops" ( 
	"agency_id" Integer NOT NULL,
	"stop_id" Serial NOT NULL,
	"stop_code" Character Varying( 2044 ), -- NOT NULL,
	"stop_name" text,
	"location_type" SmallInt NOT NULL,
	"parent_station" Integer,  -- NOT NULL,
	"stop_desc" Character Varying( 2044 ), -- NOT NULL,
	"stop_comments" Character Varying( 2044 ),
	"point" "public".GEOGRAPHY,
	"zone_id" Integer, --  NOT NULL,
	"platform_code" Character Varying( 2044 ), -- NOT NULL,
	"city" Character Varying( 2044 ), --  NOT NULL,
	"direction_id" Integer, -- NOT NULL,
	"url" Character Varying( 2044 ), -- NOT NULL,
	"publish_status" Boolean NOT NULL,
	"timezone" Character Varying( 2044 ), --  NOT NULL,
	PRIMARY KEY ( "stop_id" ) );

 CREATE TABLE "public"."play_migrate_stops" ( 
	"agency_id" Integer NOT NULL,
	"stop_id" Serial NOT NULL,
	"stop_code" Character Varying( 2044 ), -- NOT NULL,
	"stop_name" text,
	"location_type" SmallInt NOT NULL,
	"parent_station" Integer,  -- NOT NULL,
	"stop_desc" Character Varying( 2044 ), -- NOT NULL,
	"stop_comments" Character Varying( 2044 ),
	"point" "public".GEOGRAPHY,
	"zone_id" Integer, --  NOT NULL,
	"platform_code" Character Varying( 2044 ), -- NOT NULL,
	"city" Character Varying( 2044 ), --  NOT NULL,
	"direction_id" Integer, -- NOT NULL,
	"url" Character Varying( 2044 ), -- NOT NULL,
	"publish_status" Boolean NOT NULL,
	"timezone" Character Varying( 2044 ), --  NOT NULL,
	PRIMARY KEY ( "stop_id" ) );

 CREATE TABLE "public"."migrate_timed_patterns" ( 
	"agency_id" SmallInt NOT NULL,
	"timed_pattern_id" Bigint NOT NULL,
    "name" text DEFAULT NULL,
	"pattern_id" Bigint NOT NULL );

 CREATE TABLE "public"."play_migrate_timed_patterns" ( 
	"agency_id" SmallInt NOT NULL,
	"timed_pattern_id" Bigint NOT NULL,
    "name" text DEFAULT NULL,
	"pattern_id" Bigint NOT NULL );

 CREATE TABLE "public"."migrate_timed_pattern_stops" ( 
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

 CREATE TABLE "public"."play_migrate_timed_pattern_stops" ( 
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

 CREATE TABLE "public"."migrate_routes" ( 
	"agency_id" Integer DEFAULT 0,
	"route_id" Serial NOT NULL,
	"route_short_name" Character Varying( 30 ) DEFAULT ''::character varying NOT NULL,
	"route_long_name" Character Varying( 220 ) DEFAULT ''::character varying NOT NULL,
	"route_desc" Text,
	"route_type" Integer DEFAULT 3,
	"route_color" Character Varying( 6 ) DEFAULT NULL::character varying,
	"route_text_color" Character Varying( 6 ) DEFAULT NULL::character varying,
	"route_url" Character Varying( 300 ) DEFAULT NULL::character varying,
	"route_bikes_allowed" Integer DEFAULT 0,
	"route_id_import" Character Varying( 100 ) DEFAULT ''::character varying NOT NULL,
	"last_modified" Timestamp Without Time Zone DEFAULT now() NOT NULL,
	"route_sort_order" Integer DEFAULT 0,
	"hidden" Boolean DEFAULT false NOT NULL,
	PRIMARY KEY ( "route_id" ) );

 CREATE TABLE "public"."play_migrate_routes" ( 
	"agency_id" Integer DEFAULT 0,
	"route_id" Serial NOT NULL,
	"route_short_name" Character Varying( 30 ) DEFAULT ''::character varying NOT NULL,
	"route_long_name" Character Varying( 220 ) DEFAULT ''::character varying NOT NULL,
	"route_desc" Text,
	"route_type" Integer DEFAULT 3,
	"route_color" Character Varying( 6 ) DEFAULT NULL::character varying,
	"route_text_color" Character Varying( 6 ) DEFAULT NULL::character varying,
	"route_url" Character Varying( 300 ) DEFAULT NULL::character varying,
	"route_bikes_allowed" Integer DEFAULT 0,
	"route_id_import" Character Varying( 100 ) DEFAULT ''::character varying NOT NULL,
	"last_modified" Timestamp Without Time Zone DEFAULT now() NOT NULL,
	"route_sort_order" Integer DEFAULT 0,
	"hidden" Boolean DEFAULT false NOT NULL,
	PRIMARY KEY ( "route_id" ) );


 CREATE TABLE "public"."migrate_timed_pattern_stops_nonnormalized" ( 
	"agency_id" SmallInt NOT NULL,
	"agency_name" Character Varying( 2044 ) NOT NULL,
	"route_short_name" Character Varying( 2044 ) NOT NULL,
	"route_long_name" Character Varying( 2044 ) NOT NULL,
	"direction_name" Character Varying( 2044 ) NOT NULL,
	"direction_id" Bigint,
	"trip_headsign_id" SmallInt,
	"trip_headsign" Character Varying( 2044 ),
	"stop_id" Bigint,
	"stop_order" SmallInt NOT NULL,
	"timed_pattern_id" Bigint NOT NULL,
	"pattern_id" Bigint NOT NULL,
	"pickup_type" SmallInt NOT NULL,
	"drop_off_type" SmallInt NOT NULL,
	"one_trip" Bigint,
	"trips_list" text,
	"stops_pattern" text NOT NULL,
	"arrival_time_intervals" text NOT NULL,
	"departure_time_intervals" text NOT NULL,
	"route_id" Bigint,
	"arrival_time" Interval,
	"departure_time" Interval,
	"stop_headsign" Character Varying( 2044 ),
	"stop_headsign_id" Bigint );
	
 CREATE TABLE "public"."play_migrate_timed_pattern_stops_nonnormalized" ( 
	"agency_id" SmallInt NOT NULL,
	"agency_name" Character Varying( 2044 ) NOT NULL,
	"route_short_name" Character Varying( 2044 ) NOT NULL,
	"route_long_name" Character Varying( 2044 ) NOT NULL,
	"direction_name" Character Varying( 2044 ) NOT NULL,
	"direction_id" Bigint,
	"trip_headsign_id" SmallInt,
	"trip_headsign" Character Varying( 2044 ),
	"stop_id" Bigint,
	"stop_order" SmallInt NOT NULL,
	"timed_pattern_id" Bigint NOT NULL,
	"pattern_id" Bigint NOT NULL,
	"pickup_type" SmallInt NOT NULL,
	"drop_off_type" SmallInt NOT NULL,
	"one_trip" Bigint,
	"trips_list" text,
	"stops_pattern" text NOT NULL,
	"arrival_time_intervals" text NOT NULL,
	"departure_time_intervals" text NOT NULL,
	"route_id" Bigint,
	"arrival_time" Interval,
	"departure_time" Interval,
	"stop_headsign" Character Varying( 2044 ),
	"stop_headsign_id" Bigint );

CREATE TABLE "public"."migrate_feeds" (
    name character varying(2044) NOT NULL,
    contact_email character varying(2044) ,
    contact_url character varying(2044),
    license character varying(2044) ,
    id SERIAL NOT NULL,
    last_modified Timestamp Without Time Zone
);

CREATE TABLE "public"."play_migrate_feeds" (
    name character varying(2044) NOT NULL,
    contact_email character varying(2044) ,
    contact_url character varying(2044),
    license character varying(2044) ,
    id SERIAL NOT NULL,
    last_modified Timestamp Without Time Zone
);



CREATE TABLE "public"."migrate_shape_segments" (
    from_stop_id integer NOT NULL,
    to_stop_id   integer NOT NULL,
    linestring GEOGRAPHY, -- line string
    last_modified timestamptz DEFAULT NOW()
);
CREATE UNIQUE INDEX ON "public"."migrate_shape_segments" (from_stop_id, to_stop_id);
CREATE INDEX ON "public"."migrate_shape_segments" (to_stop_id);

CREATE TABLE "public"."play_migrate_shape_segments" (
    from_stop_id integer NOT NULL,
    to_stop_id   integer NOT NULL,
    linestring GEOGRAPHY,  -- line string.
    last_modified timestamptz DEFAULT NOW()
);
CREATE UNIQUE INDEX ON "public"."play_migrate_shape_segments" (from_stop_id, to_stop_id);
CREATE INDEX ON "public"."play_migrate_shape_segments" (to_stop_id);

CREATE TABLE "public"."migrate_pattern_custom_shape_segments" (
    pattern_id INTEGER,
    from_stop_id INTEGER,
    to_stop_id INTEGER,
    linestring GEOGRAPHY
);
CREATE UNIQUE INDEX ON "public"."migrate_pattern_custom_shape_segments" 
       (pattern_id, from_stop_id, to_stop_id);

CREATE TABLE "public"."play_migrate_pattern_custom_shape_segments" (
    pattern_id INTEGER,
    from_stop_id INTEGER,
    to_stop_id INTEGER,
    linestring GEOGRAPHY
);
CREATE UNIQUE INDEX ON "public"."play_migrate_pattern_custom_shape_segments"
       (pattern_id, from_stop_id, to_stop_id);


CREATE TABLE "public"."migrate_calendar_dates" (
    calendar_date_id SERIAL PRIMARY KEY,
    "date" DATE NOT NULL DEFAULT '0001-01-01',
    agency_id INTEGER,
    name TEXT,
    last_modified TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE "public"."play_migrate_calendar_dates" (
    calendar_date_id SERIAL PRIMARY KEY,
    "date" DATE NOT NULL DEFAULT '0001-01-01',
    agency_id INTEGER,
    name TEXT,
    last_modified TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE migrate_calendar_date_service_exceptions (
    calendar_date_exception_id SERIAL PRIMARY KEY,
    calendar_date_id integer NOT NULL,
    exception_type integer,
    calendar_id integer NOT NULL,
	"monday" Boolean DEFAULT false NOT NULL,
	"tuesday" Boolean DEFAULT false NOT NULL,
	"wednesday" Boolean DEFAULT false NOT NULL,
	"thursday" Boolean DEFAULT false NOT NULL,
	"friday" Boolean DEFAULT false NOT NULL,
	"saturday" Boolean DEFAULT false NOT NULL,
	"sunday" Boolean DEFAULT false NOT NULL,
    agency_id integer NOT NULL,
    last_modified timestamp without time zone DEFAULT now() NOT NULL
);

CREATE TABLE play_migrate_calendar_date_service_exceptions (
    calendar_date_exception_id SERIAL PRIMARY KEY,
    calendar_date_id integer NOT NULL,
    exception_type integer,
    calendar_id integer NOT NULL,
	"monday" Boolean DEFAULT false NOT NULL,
	"tuesday" Boolean DEFAULT false NOT NULL,
	"wednesday" Boolean DEFAULT false NOT NULL,
	"thursday" Boolean DEFAULT false NOT NULL,
	"friday" Boolean DEFAULT false NOT NULL,
	"saturday" Boolean DEFAULT false NOT NULL,
	"sunday" Boolean DEFAULT false NOT NULL,
    agency_id integer NOT NULL,
    last_modified timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE "public"."migrate_agencies" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_agencies" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_blocks" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_blocks" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_calendars" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_calendars" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_calendar_bounds" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_calendar_bounds" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_directions" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_directions" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_headsigns" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_headsigns" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_patterns" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_patterns" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_pattern_stops" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_pattern_stops" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_routes" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_routes" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_schedules" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_schedules" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_stops" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_stops" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_timed_patterns" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_timed_patterns" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_timed_pattern_stops" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_timed_pattern_stops" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_timed_pattern_stops_nonnormalized" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_timed_pattern_stops_nonnormalized" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_feeds" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_feeds" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_shape_segments" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_shape_segments" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_pattern_custom_shape_segments" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_pattern_custom_shape_segments" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_calendar_dates" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_calendar_dates" OWNER TO trillium_gtfs_group;

ALTER TABLE "public"."migrate_calendar_date_service_exceptions" OWNER TO trillium_gtfs_group;
ALTER TABLE "public"."play_migrate_calendar_date_service_exceptions" OWNER TO trillium_gtfs_group;
