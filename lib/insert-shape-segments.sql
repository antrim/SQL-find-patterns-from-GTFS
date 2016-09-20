-- shape_segments
-- Only copy the most recent segment (that with the largest shape_segment_id) 
-- for every group of segments with the same (to_stop_id, from_stop_id) pair!
-- "Older" segments are not used by GTFSManager anyhow.
INSERT into :"DST_SCHEMA".shape_segments 
    (from_stop_id, to_stop_id
    , last_modified
    , linestring )

WITH most_recent AS (
        SELECT shape_segments.start_coordinate_id,
        shape_segments.end_coordinate_id,
        max(shape_segments.shape_segment_id) AS shape_segment_id
        FROM :"SRC_SCHEMA".shape_segments
        GROUP BY shape_segments.start_coordinate_id, shape_segments.end_coordinate_id )

SELECT ss.start_coordinate_id, ss.end_coordinate_id
        , ss.last_modified
        , st_makeline(array_agg(shape_points.geom::geography ORDER BY shape_points.shape_pt_sequence))
FROM :"SRC_SCHEMA".shape_segments ss
INNER JOIN most_recent USING (shape_segment_id)
INNER JOIN :"SRC_SCHEMA".shape_points USING (shape_segment_id)
WHERE ss.start_coordinate_id IS NOT NULL 
        AND ss.end_coordinate_id IS NOT NULL
        AND ss.start_coordinate_id IN (SELECT stop_id FROM :"DST_SCHEMA".stops) 
        AND ss.end_coordinate_id   IN (SELECT stop_id FROM :"DST_SCHEMA".stops)
GROUP BY ss.start_coordinate_id, ss.end_coordinate_id, ss.last_modified
;

/*
ED: this has been merged above.

DELETE FROM :"DST_SCHEMA".shape_segments 
WHERE from_stop_id NOT IN (SELECT stop_id FROM :"DST_SCHEMA".stops) 
        OR to_stop_id NOT IN (SELECT stop_id FROM :"DST_SCHEMA".stops);
*/


