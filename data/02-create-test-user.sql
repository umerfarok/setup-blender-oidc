-- 1. Create the user entity
INSERT INTO guacamole_entity (name, type) 
VALUES ('umerfarooq.dev@gmail.com', 'USER');

-- 2. Create the user (linked to the entity) with an empty password hash
-- Guacamole Google Auth will handle the actual authentication.
INSERT INTO guacamole_user (entity_id, password_hash, password_salt, password_date)
SELECT entity_id, E'\\x00', E'\\x00', CURRENT_TIMESTAMP
FROM guacamole_entity
WHERE name = 'umerfarooq.dev@gmail.com';

-- 3. Grant full Admin permissions to the user so you can configure everything
INSERT INTO guacamole_system_permission (entity_id, permission)
SELECT entity_id, permission::guacamole_system_permission_type
FROM guacamole_entity
CROSS JOIN (
    VALUES ('ADMINISTER'), ('CREATE_CONNECTION'), ('CREATE_CONNECTION_GROUP'), ('CREATE_SHARING_PROFILE'), ('CREATE_USER'), ('CREATE_USER_GROUP')
) AS p(permission)
WHERE name = 'umerfarooq.dev@gmail.com';