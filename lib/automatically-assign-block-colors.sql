
-- FIXME: add a github ticket! Ed 2016-09-16
-- These sample colors need to be copied into any new wake-robin schema

update :"DST_SCHEMA".blocks blocks 
set color = sample_colors.color 
from :"DST_SCHEMA".sample_colors where sample_colors.color_id = blocks.block_id;

