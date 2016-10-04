/* 
    usage:

    \set ARG1 print-settings.sql \i run-script-on-migrate-and-play-migrate.sql 
    \set ARG1 ddl/foreign-keys.sql \i run-script-on-migrate-and-play-migrate.sql 

*/
\echo 'running psql script ' :ARG1 ' with DST_SCHEMA taking the values of both "migrate" and "play_migrate"'

\set DST_SCHEMA_SAVE :DST_SCHEMA

\set DST_SCHEMA migrate
\ir :ARG1

\set DST_SCHEMA play_migrate
\ir :ARG1
