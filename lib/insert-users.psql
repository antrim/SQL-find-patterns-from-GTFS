-- migrate users 
    INSERT INTO :"DST_SCHEMA".users
        (user_id, email, pass, first_name, last_name, active,
        registration_date,
        read_only,
        admin,
        language_id,
        last_modified) 
    SELECT 
        user_id, email, pass, first_name, last_name, active,
        registration_date, 
        (read_only = 1)::boolean,
        (admin = 1)::boolean,
        language_id,
        last_modified
    FROM :"SRC_SCHEMA".users
    ;


