CREATE VIEW views.play_migrate_fare_rules_no_route_no_contains AS
SELECT *
FROM play_migrate_fare_rules fr
WHERE fr.route_id IS NULL AND fr.contains_id IS NULL;

ALTER VIEW views.play_migrate_fare_rules_no_route_no_contains OWNER TO trillium_gtfs_group;

CREATE VIEW views.play_migrate_fare_rules_symmetric AS
-- SELECT DISTINCT required for the time being since there appear to be some
-- duplicate fare rules. ED 2016-06-23
SELECT DISTINCT fr1.fare_id, fr1.origin_id AS zone_id_a, fr1.destination_id AS zone_id_b
-- FROM play_migrate_fare_rules fr1
-- JOIN play_migrate_fare_rules fr2
FROM views.play_migrate_fare_rules_no_route_no_contains fr1
JOIN views.play_migrate_fare_rules_no_route_no_contains fr2
    ON fr1.fare_id = fr2.fare_id
    AND fr1.origin_id = fr2.destination_id
    AND fr1.destination_id = fr2.origin_id
WHERE fr1.origin_id < fr1.destination_id     
      AND fr2.origin_id > fr2.destination_id ;
      -- AND fr1.route_id IS NULL 
      -- AND fr2.route_id IS NULL 
      -- AND fr1.contains_id IS NULL 
      -- AND fr1.contains_id IS NULL

ALTER VIEW views.play_migrate_fare_rules_symmetric OWNER TO trillium_gtfs_group;

CREATE OR REPLACE FUNCTION views.play_migrate_fare_rules_symmetric_trigger ()
RETURNS TRIGGER AS $$
DECLARE
BEGIN
    IF TG_OP = 'DELETE' THEN 
        -- Assert that there are no fare rules applying to fare_id which either
        -- go from zone_id_a to zone_id_b or from zone_id_b to zone_id_a.
        -- NOTE that zone_id_a must always be strictly less than zone_id_b
        RAISE NOTICE 'deleted from play_migrate_fare_rules_symmetric fare_id % zone_id_a % zone_id_b %'
            , OLD.fare_id
            , OLD.zone_id_a
            , OLD.zone_id_b;

        DELETE FROM views.play_migrate_fare_rules_no_route_no_contains
            WHERE fare_id = OLD.fare_id 
              AND (   (origin_id = OLD.zone_id_a AND destination_id = OLD.zone_id_b)
                   OR (origin_id = OLD.zone_id_b AND destination_id = OLD.zone_id_a));
        
    END IF;
    IF TG_OP IN ('INSERT') THEN 
        -- Assert that there are a pair of fare rules applying to fare_id
        -- going from zone_id_a to zone_id_b, and from zone_id_b to zone_id_a.
        RAISE NOTICE 'inserted into play_migrate_fare_rules_symmetric fare_id % zone_id_a % zone_id_b %'
            , NEW.fare_id
            , NEW.zone_id_a
            , NEW.zone_id_b;
        -- DELETE followed by INSERT acts as a poor man's UPSERT.
        -- This way we avoid creating duplicate rules.
        -- In an ideal world there would be a table constraint preventing duplicates.
        DELETE FROM views.play_migrate_fare_rules_no_route_no_contains
            WHERE fare_id = NEW.fare_id 
              AND (   (origin_id = NEW.zone_id_a AND destination_id = NEW.zone_id_b)
                   OR (origin_id = NEW.zone_id_b AND destination_id = NEW.zone_id_a));
        INSERT INTO views.play_migrate_fare_rules_no_route_no_contains
            (fare_id, origin_id, destination_id)
        VALUES (NEW.fare_id, NEW.zone_id_a, NEW.zone_id_b)
             , (NEW.fare_id, NEW.zone_id_b, NEW.zone_id_a);
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
    -- If they _only_ columns in table are fare_id, zone_id_a, and zone_id_b, then we
    -- can act as though the OLD row was deleted, and the NEW one inserted.
    -- only problem with this is underlying table may possibly lose some metadata.
    -- Well, that's likely a problem even with our INSERT and DELETE operations?
    -- Or maybe its no problem at all.
CREATE TRIGGER play_migrate_fare_rules_symmetric_delete 
INSTEAD OF DELETE OR INSERT ON views.play_migrate_fare_rules_symmetric  
FOR EACH ROW EXECUTE PROCEDURE views.play_migrate_fare_rules_symmetric_trigger();


    -- FIXME. The terminology and table organization for various categories of
    -- fare_rules could use rationalization and improvement.
    -- 
    -- I've called this view play_migrate_fare_rules_not_symmetric instead of
    -- play_migrate_fare_rules_asymmetric, since it is quite possible that 
    -- fare_rules involving NOT NULL values for route_id and contains_id may be
    -- symmetric by some definition, they simply don't meet our criterea for
    -- "symmetric" routes.
    --
    -- Long term, I suspect we'll want to make other classifications for
    -- fare_rules depending on if route_id and contains_id are NULL, with their
    -- own distinct tables and/or views.
CREATE VIEW views.play_migrate_fare_rules_not_symmetric AS
SELECT *
FROM play_migrate_fare_rules fr
WHERE    (    fr.route_id    IS NULL
          AND fr.contains_id IS NULL
          AND (fr.fare_id, least(fr.origin_id, fr.destination_id), greatest(fr.origin_id, fr.destination_id))
              NOT IN (SELECT fare_id, zone_id_a, zone_id_b from views.play_migrate_fare_rules_symmetric))
      OR fr.route_id    IS NOT NULL 
      OR fr.contains_id IS NOT NULL;

ALTER VIEW views.play_migrate_fare_rules_not_symmetric OWNER TO trillium_gtfs_group;

-- It would be good to verify that: 
--
--     SELECT (2 * count(*)) FROM views.play_migrate_fare_rules_symmetric;
--  +  SELECT      count(*)  FROM views.play_migrate_fare_rules_asymmetric; 
----------------------------------------------------------
--  =  SELECT      count(*)  FROM play_migrate_fare_rules; !! 
-- 
--  But that math isn't possible until we're sure we've removed all duplicates
--  from play_migrate_fare_rules. Ed 2016-06-23.


