
--
-- PostgreSQL database dump
--

-- Dumped from database version 9.4.1
-- Dumped by pg_dump version 9.6devel

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: play_migrate_fare_attributes; Type: TABLE; Schema: public; Owner: trillium_gtfs_group
--

CREATE TABLE play_migrate_fare_attributes (
    agency_id integer DEFAULT 0,
    fare_id integer NOT NULL,
    price double precision DEFAULT (0)::double precision NOT NULL,
    currency_type character(3) DEFAULT ''::bpchar NOT NULL,
    payment_method integer DEFAULT 0,
    transfers integer DEFAULT 0,
    transfer_duration integer,
    last_modified timestamp without time zone DEFAULT now() NOT NULL,
    fare_id_import character(35) DEFAULT NULL::bpchar
);


ALTER TABLE play_migrate_fare_attributes OWNER TO trillium_gtfs_group;

--
-- Name: play_migrate_fare_attributes_fare_id_seq; Type: SEQUENCE; Schema: public; Owner: trillium_gtfs_group
--

CREATE SEQUENCE play_migrate_fare_attributes_fare_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE play_migrate_fare_attributes_fare_id_seq OWNER TO trillium_gtfs_group;

--
-- Name: play_migrate_fare_attributes_fare_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trillium_gtfs_group
--

ALTER SEQUENCE play_migrate_fare_attributes_fare_id_seq OWNED BY play_migrate_fare_attributes.fare_id;


--
-- Name: play_migrate_fare_rider_categories; Type: TABLE; Schema: public; Owner: trillium_gtfs_group
--

CREATE TABLE play_migrate_fare_rider_categories (
    fare_rider_category_id integer NOT NULL,
    fare_id integer,
    rider_category_custom_id integer,
    price numeric(10,4) DEFAULT NULL::numeric,
    agency_id integer
);


ALTER TABLE play_migrate_fare_rider_categories OWNER TO trillium_gtfs_group;

--
-- Name: play_migrate_fare_rider_categories_fare_rider_category_id_seq; Type: SEQUENCE; Schema: public; Owner: trillium_gtfs_group
--

CREATE SEQUENCE play_migrate_fare_rider_categories_fare_rider_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE play_migrate_fare_rider_categories_fare_rider_category_id_seq OWNER TO trillium_gtfs_group;

--
-- Name: play_migrate_fare_rider_categories_fare_rider_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trillium_gtfs_group
--

ALTER SEQUENCE play_migrate_fare_rider_categories_fare_rider_category_id_seq OWNED BY play_migrate_fare_rider_categories.fare_rider_category_id;


--
-- Name: play_migrate_fare_rules; Type: TABLE; Schema: public; Owner: trillium_gtfs_group
--

CREATE TABLE play_migrate_fare_rules (
    fare_rule_id integer NOT NULL,
    fare_id integer DEFAULT 0,
    route_id integer,
    origin_id integer,
    destination_id integer,
    contains_id integer,
    agency_id integer DEFAULT 0,
    /* is_symmetric Boolean DEFAULT False NOT NULL,  */
    is_combinable Boolean DEFAULT True NOT NULL, 
    last_modified timestamp without time zone DEFAULT now() NOT NULL,
    fare_id_import character(35) DEFAULT NULL::bpchar,
    route_id_import character(35) DEFAULT NULL::bpchar,
    origin_id_import character(35) DEFAULT NULL::bpchar,
    destination_id_import character(35) DEFAULT NULL::bpchar,
    contains_id_import character(35) DEFAULT NULL::bpchar
);


ALTER TABLE play_migrate_fare_rules OWNER TO trillium_gtfs_group;

ALTER TABLE play_migrate_fare_rules ADD PRIMARY key (fare_rule_id);

CREATE UNIQUE INDEX ON play_migrate_fare_rules 
       (agency_id, fare_id, route_id, origin_id, destination_id, contains_id);

--
-- Name: play_migrate_fare_rules_fare_rule_id_seq; Type: SEQUENCE; Schema: public; Owner: trillium_gtfs_group
--

CREATE SEQUENCE play_migrate_fare_rules_fare_rule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE play_migrate_fare_rules_fare_rule_id_seq OWNER TO trillium_gtfs_group;

--
-- Name: play_migrate_fare_rules_fare_rule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trillium_gtfs_group
--

ALTER SEQUENCE play_migrate_fare_rules_fare_rule_id_seq OWNED BY play_migrate_fare_rules.fare_rule_id;


--
-- Name: fare_id; Type: DEFAULT; Schema: public; Owner: trillium_gtfs_group
--

ALTER TABLE ONLY play_migrate_fare_attributes ALTER COLUMN fare_id SET DEFAULT nextval('play_migrate_fare_attributes_fare_id_seq'::regclass);


--
-- Name: fare_rider_category_id; Type: DEFAULT; Schema: public; Owner: trillium_gtfs_group
--

ALTER TABLE ONLY play_migrate_fare_rider_categories ALTER COLUMN fare_rider_category_id SET DEFAULT nextval('play_migrate_fare_rider_categories_fare_rider_category_id_seq'::regclass);


--
-- Name: fare_rule_id; Type: DEFAULT; Schema: public; Owner: trillium_gtfs_group
--

ALTER TABLE ONLY play_migrate_fare_rules ALTER COLUMN fare_rule_id SET DEFAULT nextval('play_migrate_fare_rules_fare_rule_id_seq'::regclass);


--
-- Name: play_migrate_fare_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: trillium_gtfs_group
--

ALTER TABLE ONLY play_migrate_fare_attributes
    ADD CONSTRAINT play_migrate_fare_attributes_pkey PRIMARY KEY (fare_id);


--
-- Name: play_migrate_fare_rider_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: trillium_gtfs_group
--

ALTER TABLE ONLY play_migrate_fare_rider_categories
    ADD CONSTRAINT play_migrate_fare_rider_categories_pkey PRIMARY KEY (fare_rider_category_id);


--
-- Name: play_migrate_fare_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: trillium_gtfs_group
--

ALTER TABLE ONLY play_migrate_fare_rules
    ADD CONSTRAINT play_migrate_fare_rules_pkey PRIMARY KEY (fare_rule_id);


--
-- Name: play_migrate_fare_attributes; Type: ACL; Schema: public; Owner: trillium_gtfs_group
--

REVOKE ALL ON TABLE play_migrate_fare_attributes FROM PUBLIC;
REVOKE ALL ON TABLE play_migrate_fare_attributes FROM trillium_gtfs_group;
GRANT ALL ON TABLE play_migrate_fare_attributes TO trillium_gtfs_group;
GRANT SELECT ON TABLE play_migrate_fare_attributes TO trillium_gtfs_web_read;


--
-- Name: play_migrate_fare_attributes_fare_id_seq; Type: ACL; Schema: public; Owner: trillium_gtfs_group
--

REVOKE ALL ON SEQUENCE play_migrate_fare_attributes_fare_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE play_migrate_fare_attributes_fare_id_seq FROM trillium_gtfs_group;
GRANT ALL ON SEQUENCE play_migrate_fare_attributes_fare_id_seq TO trillium_gtfs_group;


--
-- Name: play_migrate_fare_rider_categories; Type: ACL; Schema: public; Owner: trillium_gtfs_group
--

REVOKE ALL ON TABLE play_migrate_fare_rider_categories FROM PUBLIC;
REVOKE ALL ON TABLE play_migrate_fare_rider_categories FROM trillium_gtfs_group;
GRANT ALL ON TABLE play_migrate_fare_rider_categories TO trillium_gtfs_group;
GRANT SELECT ON TABLE play_migrate_fare_rider_categories TO trillium_gtfs_web_read;


--
-- Name: play_migrate_fare_rider_categories_fare_rider_category_id_seq; Type: ACL; Schema: public; Owner: trillium_gtfs_group
--

REVOKE ALL ON SEQUENCE play_migrate_fare_rider_categories_fare_rider_category_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE play_migrate_fare_rider_categories_fare_rider_category_id_seq FROM trillium_gtfs_group;
GRANT ALL ON SEQUENCE play_migrate_fare_rider_categories_fare_rider_category_id_seq TO trillium_gtfs_group;


--
-- Name: play_migrate_fare_rules; Type: ACL; Schema: public; Owner: trillium_gtfs_group
--

REVOKE ALL ON TABLE play_migrate_fare_rules FROM PUBLIC;
REVOKE ALL ON TABLE play_migrate_fare_rules FROM trillium_gtfs_group;
GRANT ALL ON TABLE play_migrate_fare_rules TO trillium_gtfs_group;
GRANT SELECT ON TABLE play_migrate_fare_rules TO trillium_gtfs_web_read;


--
-- Name: play_migrate_fare_rules_fare_rule_id_seq; Type: ACL; Schema: public; Owner: trillium_gtfs_group
--

REVOKE ALL ON SEQUENCE play_migrate_fare_rules_fare_rule_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE play_migrate_fare_rules_fare_rule_id_seq FROM trillium_gtfs_group;
GRANT ALL ON SEQUENCE play_migrate_fare_rules_fare_rule_id_seq TO trillium_gtfs_group;


--
-- PostgreSQL database dump complete
--



--
-- PostgreSQL database dump
--

-- Dumped from database version 9.4.1
-- Dumped by pg_dump version 9.6devel

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: migrate_fare_attributes; Type: TABLE; Schema: public; Owner: trillium_gtfs_group
--

CREATE TABLE migrate_fare_attributes (
    agency_id integer DEFAULT 0,
    fare_id integer NOT NULL,
    price double precision DEFAULT (0)::double precision NOT NULL,
    currency_type character(3) DEFAULT ''::bpchar NOT NULL,
    payment_method integer DEFAULT 0,
    transfers integer DEFAULT 0,
    transfer_duration integer,
    last_modified timestamp without time zone DEFAULT now() NOT NULL,
    fare_id_import character(35) DEFAULT NULL::bpchar
);


ALTER TABLE migrate_fare_attributes OWNER TO trillium_gtfs_group;

--
-- Name: migrate_fare_attributes_fare_id_seq; Type: SEQUENCE; Schema: public; Owner: trillium_gtfs_group
--

CREATE SEQUENCE migrate_fare_attributes_fare_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE migrate_fare_attributes_fare_id_seq OWNER TO trillium_gtfs_group;

--
-- Name: migrate_fare_attributes_fare_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trillium_gtfs_group
--

ALTER SEQUENCE migrate_fare_attributes_fare_id_seq OWNED BY migrate_fare_attributes.fare_id;


--
-- Name: migrate_fare_rider_categories; Type: TABLE; Schema: public; Owner: trillium_gtfs_group
--

CREATE TABLE migrate_fare_rider_categories (
    fare_rider_category_id integer NOT NULL,
    fare_id integer,
    rider_category_custom_id integer,
    price numeric(10,4) DEFAULT NULL::numeric,
    agency_id integer
);


ALTER TABLE migrate_fare_rider_categories OWNER TO trillium_gtfs_group;

--
-- Name: migrate_fare_rider_categories_fare_rider_category_id_seq; Type:
-- SEQUENCE; Schema: public; Owner: trillium_gtfs_group
--

CREATE SEQUENCE migrate_fare_rider_categories_fare_rider_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE migrate_fare_rider_categories_fare_rider_category_id_seq OWNER TO trillium_gtfs_group;

--
-- Name: migrate_fare_rider_categories_fare_rider_category_id_seq; Type:
-- SEQUENCE OWNED BY; Schema: public; Owner: trillium_gtfs_group
--

ALTER SEQUENCE migrate_fare_rider_categories_fare_rider_category_id_seq 
      OWNED BY migrate_fare_rider_categories.fare_rider_category_id;


--
-- Name: migrate_fare_rules; Type: TABLE; Schema: public; Owner: trillium_gtfs_group
--

CREATE TABLE migrate_fare_rules (
    fare_rule_id integer NOT NULL,
    fare_id integer DEFAULT 0,
    route_id integer,
    origin_id integer,
    destination_id integer,
    contains_id integer,
    agency_id integer DEFAULT 0,
    /* is_symmetric  Boolean DEFAULT false NOT NULL, */
    is_combinable Boolean DEFAULT true NOT NULL,
    last_modified timestamp without time zone DEFAULT now() NOT NULL,
    fare_id_import character(35) DEFAULT NULL::bpchar,
    route_id_import character(35) DEFAULT NULL::bpchar,
    origin_id_import character(35) DEFAULT NULL::bpchar,
    destination_id_import character(35) DEFAULT NULL::bpchar,
    contains_id_import character(35) DEFAULT NULL::bpchar
);


ALTER TABLE migrate_fare_rules OWNER TO trillium_gtfs_group;

ALTER TABLE migrate_fare_rules ADD PRIMARY key (fare_rule_id);

CREATE UNIQUE INDEX ON migrate_fare_rules 
       (agency_id, fare_id, route_id, origin_id, destination_id, contains_id);



--
-- Name: migrate_fare_rules_fare_rule_id_seq; Type: SEQUENCE; Schema: public; Owner: trillium_gtfs_group
--

CREATE SEQUENCE migrate_fare_rules_fare_rule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE migrate_fare_rules_fare_rule_id_seq OWNER TO trillium_gtfs_group;

--
-- Name: migrate_fare_rules_fare_rule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trillium_gtfs_group
--

ALTER SEQUENCE migrate_fare_rules_fare_rule_id_seq OWNED BY migrate_fare_rules.fare_rule_id;


--
-- Name: fare_id; Type: DEFAULT; Schema: public; Owner: trillium_gtfs_group
--

ALTER TABLE ONLY migrate_fare_attributes ALTER COLUMN fare_id 
      SET DEFAULT nextval('migrate_fare_attributes_fare_id_seq'::regclass);


--
-- Name: fare_rider_category_id; Type: DEFAULT; Schema: public; Owner: trillium_gtfs_group
--

ALTER TABLE ONLY migrate_fare_rider_categories ALTER COLUMN fare_rider_category_id 
      SET DEFAULT nextval('migrate_fare_rider_categories_fare_rider_category_id_seq'::regclass);


--
-- Name: fare_rule_id; Type: DEFAULT; Schema: public; Owner: trillium_gtfs_group
--

ALTER TABLE ONLY migrate_fare_rules ALTER COLUMN fare_rule_id 
      SET DEFAULT nextval('migrate_fare_rules_fare_rule_id_seq'::regclass);


--
-- Name: migrate_fare_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner:
-- trillium_gtfs_group
--

ALTER TABLE ONLY migrate_fare_attributes
    ADD CONSTRAINT migrate_fare_attributes_pkey PRIMARY KEY (fare_id);


--
-- Name: migrate_fare_rider_categories_pkey; Type: CONSTRAINT; Schema: public;
-- Owner: trillium_gtfs_group
--

ALTER TABLE ONLY migrate_fare_rider_categories
    ADD CONSTRAINT migrate_fare_rider_categories_pkey PRIMARY KEY (fare_rider_category_id);


--
-- Name: migrate_fare_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: trillium_gtfs_group
--

ALTER TABLE ONLY migrate_fare_rules
    ADD CONSTRAINT migrate_fare_rules_pkey PRIMARY KEY (fare_rule_id);


--
-- Name: migrate_fare_attributes; Type: ACL; Schema: public; Owner: trillium_gtfs_group
--

REVOKE ALL ON TABLE migrate_fare_attributes FROM PUBLIC;
REVOKE ALL ON TABLE migrate_fare_attributes FROM trillium_gtfs_group;
GRANT ALL ON TABLE migrate_fare_attributes TO trillium_gtfs_group;
GRANT SELECT ON TABLE migrate_fare_attributes TO trillium_gtfs_web_read;


--
-- Name: migrate_fare_attributes_fare_id_seq; Type: ACL; Schema: public; Owner: trillium_gtfs_group
--

REVOKE ALL ON SEQUENCE migrate_fare_attributes_fare_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE migrate_fare_attributes_fare_id_seq FROM trillium_gtfs_group;
GRANT ALL ON SEQUENCE migrate_fare_attributes_fare_id_seq TO trillium_gtfs_group;


--
-- Name: migrate_fare_rider_categories; Type: ACL; Schema: public; Owner: trillium_gtfs_group
--

REVOKE ALL ON TABLE migrate_fare_rider_categories FROM PUBLIC;
REVOKE ALL ON TABLE migrate_fare_rider_categories FROM trillium_gtfs_group;
GRANT ALL ON TABLE migrate_fare_rider_categories TO trillium_gtfs_group;
GRANT SELECT ON TABLE migrate_fare_rider_categories TO trillium_gtfs_web_read;


--
-- Name: migrate_fare_rider_categories_fare_rider_category_id_seq; Type: ACL;
-- Schema: public; Owner: trillium_gtfs_group
--

REVOKE ALL ON SEQUENCE migrate_fare_rider_categories_fare_rider_category_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE migrate_fare_rider_categories_fare_rider_category_id_seq FROM trillium_gtfs_group;
GRANT ALL ON SEQUENCE migrate_fare_rider_categories_fare_rider_category_id_seq TO trillium_gtfs_group;


--
-- Name: migrate_fare_rules; Type: ACL; Schema: public; Owner: trillium_gtfs_group
--

REVOKE ALL ON TABLE migrate_fare_rules FROM PUBLIC;
REVOKE ALL ON TABLE migrate_fare_rules FROM trillium_gtfs_group;
GRANT ALL ON TABLE migrate_fare_rules TO trillium_gtfs_group;
GRANT SELECT ON TABLE migrate_fare_rules TO trillium_gtfs_web_read;


--
-- Name: migrate_fare_rules_fare_rule_id_seq; Type: ACL; Schema: public; Owner: trillium_gtfs_group
--

REVOKE ALL ON SEQUENCE migrate_fare_rules_fare_rule_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE migrate_fare_rules_fare_rule_id_seq FROM trillium_gtfs_group;
GRANT ALL ON SEQUENCE migrate_fare_rules_fare_rule_id_seq TO trillium_gtfs_group;

--
-- PostgreSQL database dump complete
--


create table play_migrate_zones (
    zone_id SERIAL,
    zone_name text,
    agency_id integer,
    last_modified timestamp DEFAULT now(),
    zone_id_import text
);

ALTER TABLE play_migrate_zones OWNER TO trillium_gtfs_group;


create table migrate_zones (
    zone_id SERIAL,
    zone_name text,
    agency_id integer,
    last_modified timestamp DEFAULT now(),
    zone_id_import text
);

ALTER TABLE migrate_zones OWNER TO trillium_gtfs_group;
    

