
-- SELECT DISTINCT required for the time being since there appear to be some
-- duplicate fare rules. ED 2016-06-23
CREATE OR REPLACE VIEW views.play_migrate_fare_rules_symmetric AS
SELECT DISTINCT fr1.agency_id
     , fr1.fare_id
     , fr1.origin_id AS zone_id_a
     , fr1.destination_id AS zone_id_b
     , fr1.route_id 
     , fr1.contains_id
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
        RAISE NOTICE 'fare_id % agency_id % route_id % zone_id_a % zone_id_b % contains_id %'
                    , OLD.fare_id
                    , OLD.agency_id
                    , OLD.route_id
                    , OLD.zone_id_a
                    , OLD.zone_id_b
                    , OLD.contains_id;

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

        -- DELETE followed by INSERT acts as a poor man's UPSERT.
        -- This way we avoid creating duplicate rules.
        -- In an ideal world there would be a table constraint preventing duplicates.

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

        INSERT INTO play_migrate_fare_rules
            (fare_id, agency_id, route_id
           , origin_id, destination_id, contains_id)

        VALUES (NEW.fare_id, NEW.agency_id, NEW.route_id        /* forward */
              , NEW.zone_id_a, NEW.zone_id_b, NEW.contains_id)

             , (NEW.fare_id, NEW.agency_id, NEW.route_id        /* reverse */
              , NEW.zone_id_b, NEW.zone_id_a, NEW.contains_id);
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


    -- HMM, what should we do if they 'UPDATE'?
    -- If they only updated "key" columns such as the following: fare_id,
    -- agency_id, route_id, zone_id_a, zone_id_b, or contains_id; then we can
    -- act as though the OLD row was deleted, and the NEW one inserted.
    --
    -- If they only update "non-key" columns such as is_combinable or
    -- foo_id_import, we should most likely update the underlying fare_rule_id columns.
    --
    -- Only problem with this is underlying table may possibly lose some metadata.
    -- Well, that's likely a problem even with our INSERT and DELETE operations?
    -- Or maybe its no problem at all.
    --
    -- The lost metadata is fare_id_import etc. There might be another way to manage this.
    -- 

    -- For now we just treat UPDATE as DELETE of OLD followed by insert of NEW!
    -- I think that's OK.

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




---------------------
--- migrate_* version of the views, below.
------ vvvvvvvvvvvvvv


-- SELECT DISTINCT required for the time being since there appear to be some
-- duplicate fare rules. ED 2016-06-23
CREATE OR REPLACE VIEW views.migrate_fare_rules_symmetric AS
SELECT DISTINCT fr1.agency_id
     , fr1.fare_id
     , fr1.origin_id AS zone_id_a
     , fr1.destination_id AS zone_id_b
     , fr1.route_id 
     , fr1.contains_id
FROM migrate_fare_rules fr1
JOIN migrate_fare_rules fr2
    ON fr1.fare_id = fr2.fare_id
    AND fr1.agency_id = fr2.agency_id
    AND fr1.origin_id = fr2.destination_id
    AND fr1.destination_id = fr2.origin_id
    AND (fr1.route_id = fr2.route_id 
         OR (fr1.route_id IS NULL AND fr2.route_id IS NULL))
    AND (fr1.contains_id = fr2.contains_id 
         OR (fr1.contains_id IS NULL AND fr2.contains_id IS NULL))
WHERE fr1.origin_id < fr1.destination_id     
      AND fr2.origin_id > fr2.destination_id;

ALTER VIEW views.migrate_fare_rules_symmetric OWNER TO trillium_gtfs_group;

CREATE OR REPLACE FUNCTION views.migrate_fare_rules_symmetric_trigger ()
RETURNS TRIGGER AS $$
DECLARE
BEGIN
    IF TG_OP IN ('UPDATE','DELETE') THEN 
        -- Assert that there are no fare rules applying to fare_id which either
        -- go from zone_id_a to zone_id_b or from zone_id_b to zone_id_a.
        -- NOTE that zone_id_a must always be strictly less than zone_id_b
        RAISE NOTICE 'deleted from migrate_fare_rules_symmetric:';
        RAISE NOTICE 'fare_id % agency_id % route_id % zone_id_a % zone_id_b % contains_id %'
                    , OLD.fare_id
                    , OLD.agency_id
                    , OLD.route_id
                    , OLD.zone_id_a
                    , OLD.zone_id_b
                    , OLD.contains_id;

            -- FIXME: add logic to check for & propegate route_id, and
            -- contains_id if they exist.
            
            -- UPDATE for route_id, or contains_id should update the underlying tables.
            -- UPDATE for origin_id or destination_id should delete the old and
            -- create new rows in underlying tables.

        DELETE FROM migrate_fare_rules
            WHERE fare_id = OLD.fare_id 
              AND agency_id = OLD.agency_id
              AND (   (origin_id = OLD.zone_id_a AND destination_id = OLD.zone_id_b)
                   OR (origin_id = OLD.zone_id_b AND destination_id = OLD.zone_id_a))
              AND (route_id = OLD.route_id 
                   OR (route_id IS NULL AND OLD.route_id IS NULL))
              AND  (contains_id = OLD.contains_id 
                   OR (contains_id IS NULL AND OLD.contains_id IS NULL)) ; 
    END IF;
    IF TG_OP IN ('INSERT','UPDATE') THEN 
        -- Assert that there are a pair of fare rules applying to fare_id
        -- going from zone_id_a to zone_id_b, and from zone_id_b to zone_id_a.
        RAISE NOTICE 'inserted into migrate_fare_rules_symmetric:';
        RAISE NOTICE ' fare_id % agency_id % route_id % zone_id_a % zone_id_b % contains_id %'
                    , NEW.fare_id
                    , NEW.agency_id
                    , NEW.route_id
                    , NEW.zone_id_a
                    , NEW.zone_id_b
                    , NEW.contains_id;

        -- DELETE followed by INSERT acts as a poor man's UPSERT.
        -- This way we avoid creating duplicate rules.
        -- In an ideal world there would be a table constraint preventing duplicates.

        DELETE FROM migrate_fare_rules
            WHERE fare_id = NEW.fare_id 
              AND agency_id = NEW.agency_id
              AND (   (origin_id = NEW.zone_id_a AND destination_id = NEW.zone_id_b)
                   OR (origin_id = NEW.zone_id_b AND destination_id = NEW.zone_id_a))
              AND (route_id = NEW.route_id 
                   OR (route_id IS NULL AND NEW.route_id IS NULL))
              AND  (contains_id = NEW.contains_id 
                   OR (contains_id IS NULL AND NEW.contains_id IS NULL)) ; 

        INSERT INTO migrate_fare_rules
            (fare_id, agency_id, route_id, origin_id, destination_id, contains_id)
        VALUES (NEW.fare_id, NEW.agency_id, NEW.route_id, NEW.zone_id_a, NEW.zone_id_b, NEW.contains_id)
             , (NEW.fare_id, NEW.agency_id, NEW.route_id, NEW.zone_id_b, NEW.zone_id_a, NEW.contains_id);
    END IF;

    IF TG_OP IN ('INSERT', 'UPDATE') THEN 
      RETURN NEW; -- success
    END IF;
    IF TG_OP = 'DELETE' THEN 
      RETURN OLD; -- success
    END IF;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION views.migrate_fare_rules_symmetric_trigger() OWNER TO trillium_gtfs_group;


    -- HMM, what should we do if they 'UPDATE'?
    -- If they _only_ updated columns are fare_id, agency_id, zone_id_a, and zone_id_b, then we
    -- can act as though the OLD row was deleted, and the NEW one inserted.
    -- only problem with this is underlying table may possibly lose some metadata.
    -- Well, that's likely a problem even with our INSERT and DELETE operations?
    -- Or maybe its no problem at all.
    -- The lost metadata is fare_id_import etc. There might be another way to manage this.

    -- For now we just treat UPDATE as DELETE of OLD followed by insert of NEW!
    -- I think that's OK.

CREATE TRIGGER migrate_fare_rules_symmetric_delete 
INSTEAD OF DELETE OR UPDATE OR INSERT ON views.migrate_fare_rules_symmetric  
FOR EACH ROW EXECUTE PROCEDURE views.migrate_fare_rules_symmetric_trigger();


/* We're looking for items which don't match fare_rules_symmetric.
   The logic is significantly complicated by the prescense of NULLs which are
   interpreted as wildcards in the case of route_id, origin_id, destination_id,
   and contains_id. Ed 2016-06-26

   What if we were to use "-1" as a universal wildcard?
   Or perhaps -0xA11 :-)
 */

CREATE OR REPLACE VIEW views.migrate_fare_rules_asymmetric AS
SELECT fr.*
FROM migrate_fare_rules fr
LEFT JOIN views.migrate_fare_rules_symmetric s
    ON      fr.fare_id = s.fare_id
        AND fr.agency_id = s.agency_id
        AND ((fr.route_id  = s.route_id) 
             OR (fr.route_id IS NULL AND s.route_id IS NULL))
        AND    least(fr.origin_id, fr.destination_id) = s.zone_id_a
        AND greatest(fr.origin_id, fr.destination_id) = s.zone_id_b
        AND (fr.contains_id = s.contains_id 
             OR (fr.contains_id IS NULL and s.contains_id IS NULL))
WHERE   s.agency_id IS NULL AND s.fare_id IS NULL;

ALTER VIEW views.migrate_fare_rules_asymmetric OWNER TO trillium_gtfs_group;


------ ^^^^^^^^^^^^^^
----- End of migrate_* version of views.

