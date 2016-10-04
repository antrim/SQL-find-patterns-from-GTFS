/* 
  Create FOREIGN KEYS which seem to be missing from wake robin schemas.

  Easisest way to do this is to use pgadmin to create a foreign key on a development database, then the
  'CREATE Script' menu item to copy/paste its definition.

 */

-- ALTER TABLE :"DST_SCHEMA".calendar_bounds DROP CONSTRAINT calendar_bounds_agency_id_fkey;
ALTER TABLE :"DST_SCHEMA".calendar_bounds
    ADD CONSTRAINT calendar_bounds_agency_id_fkey FOREIGN KEY (agency_id)
    REFERENCES :"DST_SCHEMA".agencies (agency_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT;


/* 
ALTER TABLE :"DST_SCHEMA".calendar_bounds DROP CONSTRAINT calendar_bounds_calendar_id_fkey;
*/
ALTER TABLE :"DST_SCHEMA".calendar_bounds
    ADD CONSTRAINT calendar_bounds_calendar_id_fkey FOREIGN KEY (calendar_id)
    REFERENCES :"DST_SCHEMA".calendars (calendar_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE
    NOT VALID;

-- DELETE FROM :"DST_SCHEMA".calendar_bounds where calendar_id = 246;

ALTER TABLE :"DST_SCHEMA".calendar_bounds  
    VALIDATE CONSTRAINT   calendar_bounds_calendar_id_fkey;

/*
    ALTER TABLE :"DST_SCHEMA".calendar_date_service_exceptions DROP CONSTRAINT calendar_date_service_exceptions_agency_id_fkey;
*/
ALTER TABLE :"DST_SCHEMA".calendar_date_service_exceptions
    ADD CONSTRAINT calendar_date_service_exceptions_agency_id_fkey FOREIGN KEY (agency_id)
    REFERENCES :"DST_SCHEMA".agencies (agency_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT;

ALTER TABLE :"DST_SCHEMA".calendar_dates
    ADD CONSTRAINT calendar_dates_agency_id_fkey FOREIGN KEY (agency_id)
    REFERENCES :"DST_SCHEMA".agencies (agency_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT;


/*
ALTER TABLE :"DST_SCHEMA".calendar_date_service_exceptions DROP CONSTRAINT calendar_date_service_exceptions_calendar_date_id_fkey;
*/
ALTER TABLE :"DST_SCHEMA".calendar_date_service_exceptions
    ADD CONSTRAINT calendar_date_service_exceptions_calendar_date_id_fkey FOREIGN KEY (calendar_date_id)
    REFERENCES :"DST_SCHEMA".calendar_dates (calendar_date_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;


/* 
    ALTER TABLE :"DST_SCHEMA".calendar_date_service_exceptions DROP CONSTRAINT calendar_date_service_exceptions_calendar_id_fkey;
*/
ALTER TABLE :"DST_SCHEMA".calendar_date_service_exceptions
    ADD CONSTRAINT calendar_date_service_exceptions_calendar_id_fkey FOREIGN KEY (calendar_id)
    REFERENCES :"DST_SCHEMA".calendars (calendar_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;


ALTER TABLE :"DST_SCHEMA".calendars
    ADD CONSTRAINT calendars_agency_id_fkey FOREIGN KEY (agency_id)
    REFERENCES :"DST_SCHEMA".agencies (agency_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT;



ALTER TABLE :"DST_SCHEMA".directions
    ADD CONSTRAINT directions_agency_id_fkey FOREIGN KEY (agency_id)
    REFERENCES :"DST_SCHEMA".agencies (agency_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT;


ALTER TABLE :"DST_SCHEMA".fare_attributes
    ADD CONSTRAINT fare_attributes_agency_id_fkey FOREIGN KEY (agency_id)
    REFERENCES :"DST_SCHEMA".agencies (agency_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT;

ALTER TABLE :"DST_SCHEMA".fare_rider_categories
    ADD CONSTRAINT fare_rider_categories_agency_id_fkey FOREIGN KEY (agency_id)
    REFERENCES :"DST_SCHEMA".agencies (agency_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT;

ALTER TABLE :"DST_SCHEMA".fare_rules
    ADD CONSTRAINT fare_rules_agency_id_fkey FOREIGN KEY (agency_id)
    REFERENCES :"DST_SCHEMA".agencies (agency_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT;


-- ALTER TABLE :"DST_SCHEMA".fare_rider_categories DROP CONSTRAINT fare_rider_categories_fare_id_fkey;
ALTER TABLE :"DST_SCHEMA".fare_rider_categories
    ADD CONSTRAINT fare_rider_categories_fare_id_fkey FOREIGN KEY (fare_id)
    REFERENCES :"DST_SCHEMA".fare_attributes (fare_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;

-- ALTER TABLE :"DST_SCHEMA".fare_rules DROP CONSTRAINT fare_rules_fare_id_fkey;
ALTER TABLE :"DST_SCHEMA".fare_rules
    ADD CONSTRAINT fare_rules_fare_id_fkey FOREIGN KEY (fare_id)
    REFERENCES :"DST_SCHEMA".fare_attributes (fare_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;

ALTER TABLE :"DST_SCHEMA".zones add primary key (zone_id);

ALTER TABLE :"DST_SCHEMA".fare_rules
    ADD CONSTRAINT contains_id_fkey FOREIGN KEY (contains_id)
    REFERENCES :"DST_SCHEMA".zones (zone_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;

ALTER TABLE :"DST_SCHEMA".fare_rules
    ADD CONSTRAINT origin_id_fkey FOREIGN KEY (origin_id)
    REFERENCES :"DST_SCHEMA".zones (zone_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;

ALTER TABLE :"DST_SCHEMA".fare_rules
    ADD CONSTRAINT destination_id_fkey FOREIGN KEY (destination_id)
    REFERENCES :"DST_SCHEMA".zones (zone_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;


ALTER TABLE :"DST_SCHEMA".headsigns
    ADD CONSTRAINT headsigns_agency_id_fkey FOREIGN KEY (agency_id)
    REFERENCES :"DST_SCHEMA".agencies (agency_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT;

--- Below foreign keys are still under development.
-- Ed 2016-10-04

ALTER TABLE :"DST_SCHEMA".pattern_stops DROP CONSTRAINT pattern_stops_pattern_id_fkey ;
ALTER TABLE :"DST_SCHEMA".pattern_stops
    ADD CONSTRAINT pattern_stops_pattern_id_fkey FOREIGN KEY (pattern_id)
    REFERENCES :"DST_SCHEMA".patterns (pattern_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;

ALTER TABLE :"DST_SCHEMA".pattern_stops
    ADD CONSTRAINT pattern_stops_stop_id_fkey FOREIGN KEY (stop_id)
    REFERENCES :"DST_SCHEMA".stops (stop_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT
    NOT VALID;


ALTER TABLE  :"DST_SCHEMA".pattern_stops 
    VALIDATE CONSTRAINT pattern_stops_stop_id_fkey;


