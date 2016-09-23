/*
\h CREATE TRIGGER 
Command:     CREATE TRIGGER
Description: define a new trigger
Syntax:
CREATE [ CONSTRAINT ] TRIGGER name { BEFORE | AFTER | INSTEAD OF } { event [ OR ... ] }
    ON table_name
    [ FROM referenced_table_name ]
    [ NOT DEFERRABLE | [ DEFERRABLE ] [ INITIALLY IMMEDIATE | INITIALLY DEFERRED ] ]
    [ FOR [ EACH ] { ROW | STATEMENT } ]
    [ WHEN ( condition ) ]
    EXECUTE PROCEDURE function_name ( arguments )

where event can be one of:

    INSERT
    UPDATE [ OF column_name [, ... ] ]
    DELETE
    TRUNCATE
*/


/* 
    Note: we'll want to TRUNCATE tz_memoize whenever the contents of
    tz_world_mp_including_territorial_waters changes.  

    Or, delete/update any points which reside in NEW.geog or OLD.geog -- this might be
    slow however.
    
    This could be done using an INSERT, UPDATE, DELETE trigger on
    tz_world_mp_including_territorial_waters.

    Ed 2016-09-21
 */
-- DROP TABLE :"DST_SCHEMA".tz_memoize;

\! echo $PGHOST

-- DROP TABLE :"DST_SCHEMA".tz_memoize ;
CREATE TABLE IF NOT EXISTS :"DST_SCHEMA".tz_memoize (
    point geography(POINT) PRIMARY KEY,
    tzid text NOT NULL);
ALTER TABLE :"DST_SCHEMA".tz_memoize OWNER TO trillium_gtfs_group;
-- PG 9.4 doesn't support IF NOT EXISTS, yet. Ed 2016-09-21.
-- CREATE INDEX IF NOT EXISTS tz_memoize_gist_point ON :"DST_SCHEMA".tz_memoize USING gist (point);
CREATE INDEX tz_memoize_gist_point ON :"DST_SCHEMA".tz_memoize USING gist (point);

/* 
handy pre-populate command:

    insert into play_migrate.tz_memoize (point, tzid) 
    SELECT distinct on (point) point, timezone 
    from play_migrate.stops 
    where timezone is not null and point is not null;

*/


-- DROP FUNCTION :"DST_SCHEMA".point_timezone( geography(POINT)); 
CREATE OR REPLACE FUNCTION :"DST_SCHEMA".point_timezone(arg_point geography(POINT)) RETURNS text AS
$$
DECLARE
    found_tzid text;
BEGIN
    SELECT tzid::text FROM tz_memoize 
        WHERE tz_memoize.point && arg_point LIMIT 1 
        INTO found_tzid;
    -- RAISE INFO 'hello, world';
    IF found_tzid IS NOT NULL
    THEN
        RETURN found_tzid;
    ELSE
        SELECT tzid::text FROM tz_world_mp_including_territorial_waters 
            WHERE ST_Contains(geog, arg_point) LIMIT 1
            INTO found_tzid;
        -- Remember this location for next time.
        IF found_tzid IS NOT NULL
        THEN
            INSERT INTO tz_memoize (point, tzid) 
                VALUES (arg_point, found_tzid);
        END IF;
        RETURN found_tzid;
    END IF;
END
$$ LANGUAGE plpgsql SET search_path = :"DST_SCHEMA", public;

-- DROP FUNCTION :"DST_SCHEMA".point_timezone(geometry(POINT));
CREATE OR REPLACE FUNCTION :"DST_SCHEMA".point_timezone(arg_point geometry(POINT)) RETURNS text AS
$$
    SELECT point_timezone(arg_point :: geography);
$$ LANGUAGE sql SET search_path = :"DST_SCHEMA", public;
ALTER FUNCTION :"DST_SCHEMA".point_timezone(arg_point geography(POINT)) OWNER TO trillium_gtfs_group;
ALTER FUNCTION :"DST_SCHEMA".point_timezone(arg_point geometry(POINT))  OWNER TO trillium_gtfs_group;

-- For quick testing
    SELECT :"DST_SCHEMA".point_timezone(p) 
    FROM ( VALUES 
        (ST_Point(-117,45)::geography), 
        (ST_Point(-90,45)),
        (ST_Point(-80,45 )),
        (ST_Point(-117,45)), 
        (ST_Point(-90,45)), 
        (ST_Point(-80,45 ))
    ) t(p);


CREATE OR REPLACE FUNCTION :"DST_SCHEMA".stops_timezone_trg() RETURNS TRIGGER AS
$$
BEGIN
    NEW.timezone := point_timezone(NEW.point);
    RETURN NEW;
END 
$$ LANGUAGE plpgsql SET search_path = :"DST_SCHEMA", public;
ALTER FUNCTION :"DST_SCHEMA".stops_timezone_trg() OWNER TO trillium_gtfs_group;
CREATE TRIGGER stops_timezone_trg
    BEFORE INSERT OR UPDATE OF point ON :"DST_SCHEMA".stops 
    FOR EACH ROW
        EXECUTE PROCEDURE :"DST_SCHEMA".stops_timezone_trg();
        

\! echo $PGHOST
\echo SRC_SCHEMA :SRC_SCHEMA
\echo DST_SCHEMA :DST_SCHEMA

select * from psql_vars_temp_view;

/* 

\dt  play_migrate.*

*/
