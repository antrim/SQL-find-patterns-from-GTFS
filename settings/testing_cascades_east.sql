
\set SRC_SCHEMA `echo ${SRC_SCHEMA:-public}`
\set DST_SCHEMA `echo ${DST_SCHEMA:-play_migrate}`

select string_agg(agency_id::text, ', ') AS "SKIP_AGENCY_ID_STRING"
from public.agency where agency_id <> 61 \gset
-- \set SKIP_AGENCY_ID_STRING `echo ${SKIP_AGENCY_ID_STRING:-40, 210, 231, 523, 567}`
\set SKIP_TRIP_ID_STRING `echo ${SKIP_TRIP_ID_STRING:-601686}`


