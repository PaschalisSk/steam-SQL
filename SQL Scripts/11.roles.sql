CREATE ROLE ceo;
GRANT ALL PRIVILEGES TO ceo;
GRANT ceo TO GR_M0057_ADMIN;

CREATE ROLE store_manager;
GRANT ALL PRIVILEGES ON ps_games TO store_manager;
GRANT store_namager TO GR_M0057_SQL01_S01;

CREATE ROLE developer;
GRANT INSERT ON ps_games TO developer;
GRANT developer TO GR_M0057_SQL01_S02;

CREATE ROLE expansion_manager;
GRANT ALL PRIVILEGES ON ps_countries TO expansion_manager;
GRANT expansion_manager TO GR_M0057_SQL01_S03;

CREATE ROLE store_user;
GRANT SELECT (user_username) ON ps_users TO store_user;
GRANT user TO GR_M0057_SQL01_S04;