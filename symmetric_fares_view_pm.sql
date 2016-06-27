
BEGIN TRANSACTION;

/* PLEASE NOTE:
   "PLAY_MIGRATE_" VERSON OF VIEWS HERE. SEE FILE symmetric_fares_view_m.sql
   for "MIGRATE_" version.
  */

/* NOTE: we require that symmetric fare_rules share the same value for
 * is_combinable, and there are places in the code where we assume that to be
 * true. It would be good to add a constraint to that effect.
 * Ed 2016-06-27
 * https://3.basecamp.com/3194913/buckets/257018/todos/149854143#__recording_157033421
 */


/* This DROP makes life easier, clearly it's risky if we ever define another
 * view which depends on play_migrate_fare_rules_symmetric within a different 
 * source file than this one. 
 */
DROP VIEW views.play_migrate_fare_rules_symmetric CASCADE;

CREATE OR REPLACE VIEW views.play_migrate_fare_rules_symmetric AS
SELECT DISTINCT fr1.agency_id
     , fr1.fare_id
     , fr1.origin_id AS zone_id_a
     , fr1.destination_id AS zone_id_b
     , fr1.route_id 
     , fr1.contains_id
     , fr1.is_combinable 
     , GREATEST(fr1.last_modified, fr2.last_modified) AS last_modified
FROM play_migrate_fare_rules fr1
JOIN play_migrate_fare_rules fr2
    ON  fr1.fare_id   = fr2.fare_id
    AND fr1.agency_id = fr2.agency_id
    AND null_means_all(fr1.origin_id) = null_means_all(fr2.destination_id)
    AND null_means_all(fr1.destination_id) = null_means_all(fr2.origin_id)
    AND null_means_all(fr1.route_id)    = null_means_all(fr2.route_id )
    AND null_means_all(fr1.contains_id) = null_means_all(fr2.contains_id )
WHERE     null_means_all(fr1.origin_id) < null_means_all(fr1.destination_id)
      AND null_means_all(fr2.origin_id) > null_means_all(fr2.destination_id);

ALTER VIEW views.play_migrate_fare_rules_symmetric OWNER TO trillium_gtfs_group;


CREATE OR REPLACE FUNCTION views.play_migrate_fare_rules_symmetric_trigger ()
RETURNS TRIGGER AS $$
DECLARE
BEGIN
    IF TG_OP IN ('UPDATE','DELETE') THEN 
        -- Assert that there are no fare rules applying to fare_id which either
        -- go from zone_id_a to zone_id_b or from zone_id_b to zone_id_a.
        -- NOTE that zone_id_a must always be strictly less than zone_id_b
        RAISE NOTICE 'deleted from play_migrate_fare_rules_symmetric:';
        RAISE NOTICE 'fare_id % agency_id % route_id % '
                    , OLD.fare_id
                    , OLD.agency_id
                    , OLD.route_id;
        RAISE NOTICE ' zone_id_a % zone_id_b % contains_id % is_combinable %'
                    , OLD.zone_id_a
                    , OLD.zone_id_b
                    , OLD.contains_id
                    , OLD.is_combinable;

            -- FIXME: add logic to check for & propegate route_id, and
            -- contains_id if they exist.
            
            -- UPDATE for route_id, or contains_id should update the underlying tables.
            -- UPDATE for origin_id or destination_id should delete the old and
            -- create new rows in underlying tables.

        DELETE FROM play_migrate_fare_rules
            WHERE fare_id = OLD.fare_id 
              AND agency_id = OLD.agency_id
              AND (      (null_means_all(origin_id)      = null_means_all(OLD.zone_id_a) 
                      AND null_means_all(destination_id) = null_means_all(OLD.zone_id_b))
                   OR 
                         (null_means_all(origin_id)      = null_means_all(OLD.zone_id_b) 
                      AND null_means_all(destination_id) = null_means_all(OLD.zone_id_a)))
              AND null_means_all(route_id)    = null_means_all(OLD.route_id)
              AND null_means_all(contains_id) = null_means_all(OLD.contains_id);
    END IF;
    IF TG_OP IN ('INSERT','UPDATE') THEN 
        -- Assert that there are a pair of fare rules applying to fare_id
        -- going from zone_id_a to zone_id_b, and from zone_id_b to zone_id_a.
        RAISE NOTICE 'inserted into play_migrate_fare_rules_symmetric:';
        RAISE NOTICE ' fare_id % agency_id % route_id % zone_id_a % zone_id_b % contains_id %'
                    , NEW.fare_id
                    , NEW.agency_id
                    , NEW.route_id
                    , NEW.zone_id_a
                    , NEW.zone_id_b
                    , NEW.contains_id;

        /* DELETE followed by INSERT acts as a poor man's UPSERT.
         * This way we avoid creating duplicate rules.
         * In an ideal world there would be a table constraint preventing duplicates.
         */

        DELETE FROM play_migrate_fare_rules
            WHERE fare_id = NEW.fare_id 
              AND agency_id = NEW.agency_id
              AND (      (null_means_all(origin_id)      = null_means_all(NEW.zone_id_a) 
                      AND null_means_all(destination_id) = null_means_all(NEW.zone_id_b))
                   OR 
                         (null_means_all(origin_id)      = null_means_all(NEW.zone_id_b) 
                      AND null_means_all(destination_id) = null_means_all(NEW.zone_id_a)))
              AND null_means_all(route_id)    = null_means_all(NEW.route_id)
              AND null_means_all(contains_id) = null_means_all(NEW.contains_id);

        /* Note: We don't insert a value for last_modified, instead we let the
         * DEFAULT for last_modified insert the current time as NOW(). 
         * Ed 2016-06-27
         */
        INSERT INTO play_migrate_fare_rules
            (fare_id, agency_id, route_id
           , origin_id, destination_id, contains_id, is_combinable)

        VALUES (NEW.fare_id, NEW.agency_id, NEW.route_id        /* forward */
              , NEW.zone_id_a, NEW.zone_id_b, NEW.contains_id, NEW.is_combinable)

             , (NEW.fare_id, NEW.agency_id, NEW.route_id        /* reverse */
              , NEW.zone_id_b, NEW.zone_id_a, NEW.contains_id, NEW.is_combinable);
    END IF;

    IF TG_OP IN ('INSERT', 'UPDATE') THEN 
      RETURN NEW; -- success
    END IF;
    IF TG_OP = 'DELETE' THEN 
      RETURN OLD; -- success
    END IF;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION views.play_migrate_fare_rules_symmetric_trigger() OWNER TO trillium_gtfs_group;


    /* HMM, what should we do if they 'UPDATE'?
     * If they only updated "key" columns such as the following: fare_id,
     * agency_id, route_id, zone_id_a, zone_id_b, or contains_id; then we can
     * act as though the OLD row was deleted, and the NEW one inserted.
     *
     * If they only update "non-key" columns such as is_combinable or
     * foo_id_import, we should most likely update the underlying fare_rule_id columns.
     * 
     * Only problem with this is underlying table may possibly lose some metadata.
     * Well, that's likely a problem even with our INSERT and DELETE operations?
     * Or maybe its no problem at all.
     *
     * The lost metadata is fare_id_import etc. There might be another way to manage this.
     * 
     * For now we just treat UPDATE as DELETE of OLD followed by insert of NEW!
     * I think that's OK. Ed 2016-06-26.
     */

CREATE TRIGGER play_migrate_fare_rules_symmetric_delete 
INSTEAD OF DELETE OR UPDATE OR INSERT ON views.play_migrate_fare_rules_symmetric  
FOR EACH ROW EXECUTE PROCEDURE views.play_migrate_fare_rules_symmetric_trigger();


/* We're looking for items which don't match fare_rules_symmetric.
   The logic is significantly complicated by the prescense of NULLs which are
   interpreted as wildcards in the case of route_id, origin_id, destination_id,
   and contains_id. Ed 2016-06-26

   What if we were to use "-1" or "-411" as a universal wildcard?
 */

CREATE OR REPLACE VIEW views.play_migrate_fare_rules_asymmetric AS
SELECT fr.*
FROM play_migrate_fare_rules fr
LEFT JOIN views.play_migrate_fare_rules_symmetric s
    ON      fr.fare_id   = s.fare_id
        AND fr.agency_id = s.agency_id
        AND null_means_all(fr.route_id)  = null_means_all(s.route_id)
        AND    least(null_means_all(fr.origin_id)
                   , null_means_all(fr.destination_id)) = null_means_all(s.zone_id_a)
        AND greatest(null_means_all(fr.origin_id)
                   , null_means_all(fr.destination_id)) = null_means_all(s.zone_id_b)
        AND null_means_all(fr.contains_id) = null_means_all(s.contains_id)
WHERE   s.agency_id IS NULL AND s.fare_id IS NULL;

ALTER VIEW views.play_migrate_fare_rules_asymmetric OWNER TO trillium_gtfs_group;

/* 
 It would be good to verify that: 

     SELECT (2 * count(*)) FROM views.play_migrate_fare_rules_symmetric;
  +  SELECT      count(*)  FROM views.play_migrate_fare_rules_asymmetric; 
 --------------------------------------------------------------------------
  =  SELECT      count(*)  FROM play_migrate_fare_rules; !! 
 
  But that math isn't possible until we're sure we've removed all duplicates
  from play_migrate_fare_rules. Ed 2016-06-23.

  The following query should evaluate to sum = 0.

  WITH counts AS 
  ( SELECT -2*count(*) AS c FROM views.play_migrate_fare_rules_symmetric
    UNION ALL
    SELECT -count(*) AS c FROM views.play_migrate_fare_rules_asymmetric
    UNION ALL
    SELECT count(*) AS c FROM play_migrate_fare_rules)
  SELECT sum(c) FROM counts;
  

*/

-- Bingo. This property now holds true with the new definition of
-- views.play_migrate_fare_rules_asymmetric. Ed 2016-06-26.

COMMIT TRANSACTION;


