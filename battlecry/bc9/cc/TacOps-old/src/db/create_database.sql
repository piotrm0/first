BEGIN;

-- game-specific "static" tables

CREATE TABLE match_level (
	match_level INT2 PRIMARY KEY,
	abbreviation VARCHAR,
	description VARCHAR
);

CREATE TABLE match_status (
	status_id INT2 PRIMARY KEY,
	description VARCHAR
);

CREATE TABLE color (
	color_id INT2 PRIMARY KEY,
	name VARCHAR,
	rgb_value VARCHAR
);

CREATE TABLE score_attribute (
	score_attribute_id INT PRIMARY KEY,
	name VARCHAR,
	description VARCHAR
);


-- event-specific

CREATE TABLE event_preference (
	preference_key VARCHAR PRIMARY KEY,
	value VARCHAR
);

CREATE TABLE team (
	team_number INT PRIMARY KEY,
	info text,
	short_name VARCHAR,
	nickname VARCHAR,
	robot_name VARCHAR,
	motto VARCHAR,
	location VARCHAR,
	rookie_year int
);


-- matches & scoring

CREATE TABLE game_match (
	match_level INT2 REFERENCES match_level,
	match_number INT2,
	match_index INT2,
	PRIMARY KEY (match_level, match_number, match_index),
	status_id INT2 REFERENCES match_status,
	time_scheduled timestamp,
	winner_color_id INT2 REFERENCES color
);
CREATE OR REPLACE RULE delete_notify AS ON DELETE TO game_match DO ALSO NOTIFY game_match;
CREATE OR REPLACE RULE insert_notify AS ON INSERT TO game_match DO ALSO NOTIFY game_match;
CREATE OR REPLACE RULE update_notify AS ON UPDATE TO game_match DO ALSO NOTIFY game_match;

CREATE TABLE alliance_team (
	match_level INT2,
	match_number INT2,
	match_index INT2,
	FOREIGN KEY (match_level, match_number, match_index) REFERENCES game_match,
	alliance_color_id INT2 REFERENCES color,
	position INT2 DEFAULT 0,
	PRIMARY KEY (match_level, match_number, match_index, color_id, position),
	team_number INT REFERENCES team,
	flags INT DEFAULT 0,
	score INT DEFAULT 0,
	points INT DEFAULT 0
);
CREATE OR REPLACE RULE delete_notify AS ON DELETE TO alliance_team DO ALSO NOTIFY alliance_team;
CREATE OR REPLACE RULE insert_notify AS ON INSERT TO alliance_team DO ALSO NOTIFY alliance_team;
CREATE OR REPLACE RULE update_notify AS ON UPDATE TO alliance_team DO ALSO NOTIFY alliance_team;

CREATE TABLE team_score (
	match_level INT2,
	match_number INT2,
	match_index INT2,
	color_id INT2,
	position INT2,
	FOREIGN KEY (match_level, match_number, match_index, color_id, position) REFERENCES alliance_team,
	score_attribute_id INT REFERENCES score_attribute,
	PRIMARY KEY (match_level, match_number, match_index, color_id, position, score_attribute_id),
	value INT DEFAULT 0
);

-- event results

CREATE TABLE finals_alliance_partner (
	finals_alliance_number INT2,
	recruit_order INT2,
	PRIMARY KEY (finals_alliance_number, recruit_order),
	team_number INT DEFAULT 0
);
CREATE OR REPLACE RULE delete_notify AS ON DELETE TO finals_alliance_partner DO ALSO NOTIFY finals_alliance_partner;
CREATE OR REPLACE RULE insert_notify AS ON INSERT TO finals_alliance_partner DO ALSO NOTIFY finals_alliance_partner;
CREATE OR REPLACE RULE update_notify AS ON UPDATE TO finals_alliance_partner DO ALSO NOTIFY finals_alliance_partner;



-- display "static" tables

CREATE TABLE display_type (
	display_type_label VARCHAR PRIMARY KEY,
	default_quality INT2,
	default_fullscreen BOOLEAN
);

CREATE TABLE game_state (
	state_label VARCHAR PRIMARY KEY,
	description VARCHAR
);

CREATE TABLE display_substate (
	substate_label VARCHAR PRIMARY KEY,
	description VARCHAR
);

CREATE TABLE display_state (
	state_label VARCHAR REFERENCES game_state,
	substate_label VARCHAR REFERENCES display_substate,
	display_type_label VARCHAR REFERENCES display_type,
	PRIMARY KEY (state_label, substate_label, display_type_label)
);

CREATE TABLE display_component_effect (
	effect_label VARCHAR,
	substate_label VARCHAR REFERENCES display_substate,
	component_label VARCHAR,
	keyframe_index int2,
	PRIMARY KEY (effect_label, substate_label, component_label, keyframe_index),
	x_position NUMERIC(6,2),
	y_position NUMERIC(6,2),
	x_scale NUMERIC(5,2),
	y_scale NUMERIC(5,2),
	alpha NUMERIC(5,2),
	rotation NUMERIC(5,2)
);
CREATE OR REPLACE RULE delete_notify AS ON DELETE TO display_component_effect DO ALSO NOTIFY display_component_effect;
CREATE OR REPLACE RULE insert_notify AS ON INSERT TO display_component_effect DO ALSO NOTIFY display_component_effect;
CREATE OR REPLACE RULE update_notify AS ON UPDATE TO display_component_effect DO ALSO NOTIFY display_component_effect;

CREATE TABLE display_effect_option (
	effect_label VARCHAR,
	substate_label VARCHAR,
	component_label VARCHAR,
	keyframe_index int2,
	FOREIGN KEY (effect_label, substate_label, component_label, keyframe_index) REFERENCES display_component_effect,
	key VARCHAR,
	PRIMARY KEY (effect_label, substate_label, component_label, keyframe_index, key),
	value VARCHAR
);

COMMIT;
