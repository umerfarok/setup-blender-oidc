-- 1. Create the user entity for Admin
INSERT INTO guacamole_entity (name, type) 
VALUES ('umerfarooq.dev@gmail.com', 'USER');

-- 2. Create the user (linked to the entity) with an empty password hash
INSERT INTO guacamole_user (entity_id, password_hash, password_salt, password_date)
SELECT entity_id, E'\\x00', E'\\x00', CURRENT_TIMESTAMP
FROM guacamole_entity
WHERE name = 'umerfarooq.dev@gmail.com';

-- 3. Grant full Admin permissions to the admin user
INSERT INTO guacamole_system_permission (entity_id, permission)
SELECT entity_id, permission::guacamole_system_permission_type
FROM guacamole_entity
CROSS JOIN (
    VALUES ('ADMINISTER'), ('CREATE_CONNECTION'), ('CREATE_CONNECTION_GROUP'), ('CREATE_SHARING_PROFILE'), ('CREATE_USER'), ('CREATE_USER_GROUP')
) AS p(permission)
WHERE name = 'umerfarooq.dev@gmail.com';

-- -------------------------------------------------------------
-- BATCH CREATE CLIENT USERS
-- (We create 5 client users here who will only have basic login access)
-- -------------------------------------------------------------
DO $$
DECLARE
    users TEXT[] := ARRAY[
        'clientuser1@gmail.com',
        'clientuser2@gmail.com',
        'clientuser3@gmail.com',
        'clientuser4@gmail.com',
        'clientuser5@gmail.com'
    ];
    usr TEXT;
BEGIN
    FOREACH usr IN ARRAY users LOOP
        -- Insert entity
        INSERT INTO guacamole_entity (name, type) VALUES (usr, 'USER');
        
        -- Insert dummy auth mapping so SSO takes over
        INSERT INTO guacamole_user (entity_id, password_hash, password_salt, password_date)
        SELECT entity_id, E'\\x00', E'\\x00', CURRENT_TIMESTAMP
        FROM guacamole_entity WHERE name = usr;
    END LOOP;
END $$;