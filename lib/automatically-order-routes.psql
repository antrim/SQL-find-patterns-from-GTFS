-- renumber routes to use alphabetical where there is no consistent ordering applied.
--
-- based on view of agencies having routes with unorderd (or partially ordered) routes:
/*
 
    create view migrate.dev_agencies_having_routes_without_full_ordering 
    as select 
        agency_id 
    from migrate.routes 
    group by agency_id 
    having count(distinct route_sort_order) <> count(route_id) 

 */
-- order_unordered_routes_alphabetically_by_route_long_name_query 
    with 

    ordered_routes
    as
    (select 
        *, 
        row_number() 
            over (partition by agency_id order by route_long_name, route_short_name) as route_alpha_order 
    FROM :"DST_SCHEMA".routes 
    inner join 
    :"DST_SCHEMA".dev_agencies_having_routes_without_full_ordering using (agency_id) 
    order by agency_id, route_alpha_order)

    update :"DST_SCHEMA".routes
        set route_sort_order = ordered_routes.route_alpha_order
    FROM ordered_routes
    where routes.route_id = ordered_routes.route_id 
    ;

