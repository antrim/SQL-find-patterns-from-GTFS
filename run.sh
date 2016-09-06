#!/bin/bash
export SRC_SCHMEA=public; export DST_SCHEMA=play_migrate; (php migrate.php ; php migrate_addendum.php) | tee tmp/$DST_SCHEMA.log
