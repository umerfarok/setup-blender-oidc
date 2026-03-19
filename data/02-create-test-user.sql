-- -------------------------------------------------------------
-- BATCH CREATE CLIENT USERS (The Wow Drone Team)
-- -------------------------------------------------------------
DO $$
DECLARE
    users TEXT[] := ARRAY[
        'andrew@thewowdrone.com',
        'al@thewowdrone.com',
        'dags@thewowdrone.com',
        'kristofers@thewowdrone.com',
        'ammillers@thewowdrone.com',
        'umerfarooq.dev@gmail.com'
    ];
    usr TEXT;
BEGIN
    FOREACH usr IN ARRAY users LOOP
        INSERT INTO guacamole_entity (name, type)
        VALUES (usr, 'USER')
        ON CONFLICT (type, name) DO NOTHING;

        INSERT INTO guacamole_user (entity_id, password_hash, password_salt, password_date)
        SELECT entity_id, E'\\x00', E'\\x00', CURRENT_TIMESTAMP
        FROM guacamole_entity
        WHERE name = usr
          AND type = 'USER'
          AND NOT EXISTS (
              SELECT 1
              FROM guacamole_user
              WHERE guacamole_user.entity_id = guacamole_entity.entity_id
          );
    END LOOP;
END $$;

-- Grant full Admin permissions to the admin user
INSERT INTO guacamole_system_permission (entity_id, permission)
SELECT entity_id, permission::guacamole_system_permission_type
FROM guacamole_entity
CROSS JOIN (
    VALUES ('ADMINISTER'),
           ('CREATE_CONNECTION'),
           ('CREATE_CONNECTION_GROUP'),
           ('CREATE_SHARING_PROFILE'),
           ('CREATE_USER'),
           ('CREATE_USER_GROUP')
) AS p(permission)
WHERE name = 'umerfarooq.dev@gmail.com'
  AND type = 'USER'
ON CONFLICT (entity_id, permission) DO NOTHING;
