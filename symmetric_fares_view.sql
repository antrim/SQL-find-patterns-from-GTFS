/* -- ED: this is not needed any longer, I've updated the symmetric view to
   -- work with route_id and contains_id. 2016-06-24
CREATE VIEW views.play_migrate_fare_rules_no_route_no_contains AS
SELECT *
FROM play_migrate_fare_rules fr
WHERE fr.route_id IS NULL AND fr.contains_id IS NULL;

ALTER VIEW views.play_migrate_fare_rules_no_route_no_contains OWNER TO trillium_gtfs_group;
*/

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

ALTER VIEW views.play_migrate_fare_rules_symmetric OWNER TO trillium_gtfs_group;

CREATE OR REPLACE FUNCTION views.play_migrate_fare_rules_symmetric_trigger ()
RETURNS TRIGGER AS $$
DECLARE
BEGIN
    IF TG_OP = 'DELETE' THEN 
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
              AND (   (origin_id = OLD.zone_id_a AND destination_id = OLD.zone_id_b)
                   OR (origin_id = OLD.zone_id_b AND destination_id = OLD.zone_id_a))
              AND (route_id = OLD.route_id 
                   OR (route_id IS NULL AND OLD.route_id IS NULL))
              AND  (contains_id = OLD.contains_id 
                   OR (contains_id IS NULL AND OLD.contains_id IS NULL)) ; 
    END IF;
    IF TG_OP IN ('INSERT') THEN 
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
              AND (   (origin_id = NEW.zone_id_a AND destination_id = NEW.zone_id_b)
                   OR (origin_id = NEW.zone_id_b AND destination_id = NEW.zone_id_a))
              AND (route_id = NEW.route_id 
                   OR (route_id IS NULL AND NEW.route_id IS NULL))
              AND  (contains_id = NEW.contains_id 
                   OR (contains_id IS NULL AND NEW.contains_id IS NULL)) ; 

        INSERT INTO play_migrate_fare_rules
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

ALTER FUNCTION views.play_migrate_fare_rules_symmetric_trigger() OWNER TO trillium_gtfs_group;


    -- HMM, what should we do if they 'UPDATE'?
    -- If they _only_ updated columns are fare_id, agency_id, zone_id_a, and zone_id_b, then we
    -- can act as though the OLD row was deleted, and the NEW one inserted.
    -- only problem with this is underlying table may possibly lose some metadata.
    -- Well, that's likely a problem even with our INSERT and DELETE operations?
    -- Or maybe its no problem at all.
    -- The lost metadata is fare_id_import etc. There might be another way to manage this.
CREATE TRIGGER play_migrate_fare_rules_symmetric_delete 
INSTEAD OF DELETE OR INSERT ON views.play_migrate_fare_rules_symmetric  
FOR EACH ROW EXECUTE PROCEDURE views.play_migrate_fare_rules_symmetric_trigger();


CREATE OR REPLACE VIEW views.play_migrate_fare_rules_asymmetric AS
SELECT *
FROM play_migrate_fare_rules fr
WHERE    ((fr.fare_id
         , fr.agency_id
         , fr.route_id
         ,    least(fr.origin_id, fr.destination_id) -- zone a
         , greatest(fr.origin_id, fr.destination_id) -- zone b
         , fr.origin_id )
              NOT IN (SELECT fare_id, agency_id, route_id, zone_id_a
                           , zone_id_b, origin_id 
                      FROM views.play_migrate_fare_rules_symmetric));

ALTER VIEW views.play_migrate_fare_rules_asymmetric OWNER TO trillium_gtfs_group;

-- It would be good to verify that: 
--
--     SELECT (2 * count(*)) FROM views.play_migrate_fare_rules_symmetric;
--  +  SELECT      count(*)  FROM views.play_migrate_fare_rules_asymmetric; 
----------------------------------------------------------
--  =  SELECT      count(*)  FROM play_migrate_fare_rules; !! 
-- 
--  But that math isn't possible until we're sure we've removed all duplicates
--  from play_migrate_fare_rules. Ed 2016-06-23.





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
    IF TG_OP = 'DELETE' THEN 
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
    IF TG_OP IN ('INSERT') THEN 
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
CREATE TRIGGER migrate_fare_rules_symmetric_delete 
INSTEAD OF DELETE OR INSERT ON views.migrate_fare_rules_symmetric  
FOR EACH ROW EXECUTE PROCEDURE views.migrate_fare_rules_symmetric_trigger();


CREATE OR REPLACE VIEW views.migrate_fare_rules_asymmetric AS
SELECT *
FROM migrate_fare_rules fr
WHERE    ((fr.fare_id
         , fr.agency_id
         , fr.route_id
         ,    least(fr.origin_id, fr.destination_id) -- zone a
         , greatest(fr.origin_id, fr.destination_id) -- zone b
         , fr.origin_id )
              NOT IN (SELECT fare_id, agency_id, route_id, zone_id_a
                           , zone_id_b, origin_id 
                      FROM views.migrate_fare_rules_symmetric));

ALTER VIEW views.migrate_fare_rules_asymmetric OWNER TO trillium_gtfs_group;

-- It would be good to verify that: 
--
--     SELECT (2 * count(*)) FROM views.migrate_fare_rules_symmetric;
--  +  SELECT      count(*)  FROM views.migrate_fare_rules_asymmetric; 
----------------------------------------------------------
--  =  SELECT      count(*)  FROM migrate_fare_rules; !! 
-- 
--  But that math isn't possible until we're sure we've removed all duplicates
--  from migrate_fare_rules. Ed 2016-06-23.




------ ^^^^^^^^^^^^^^
----- End of migrate_* version of views.

