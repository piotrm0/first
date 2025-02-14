DELETE FROM color WHERE color_id >= -1 AND color_id <= 6;
INSERT INTO color (color_id, name, rgb_value) VALUES (-1, 'dark', '0x7F7F7F');
INSERT INTO color (color_id, name, rgb_value) VALUES (0, 'none', '0x000000');
INSERT INTO color (color_id, name, rgb_value) VALUES (1, 'Red', '0xFF7F7F');
INSERT INTO color (color_id, name, rgb_value) VALUES (2, 'Blue', '0x7F7FFF');
INSERT INTO color (color_id, name, rgb_value) VALUES (3, 'Green', '0x7FFF7F');
INSERT INTO color (color_id, name, rgb_value) VALUES (4, 'Purple', '0xFF7FFF');
INSERT INTO color (color_id, name, rgb_value) VALUES (5, 'Orange', '0xFFBF7F');
INSERT INTO color (color_id, name, rgb_value) VALUES (6, 'Yellow', '0xFFFF7F');

DELETE FROM match_level;
INSERT INTO match_level (match_level, abbreviation, description) VALUES (-1, 'P', 'Practice');
INSERT INTO match_level (match_level, abbreviation, description) VALUES (0, 'Q', 'Qualification');
INSERT INTO match_level (match_level, abbreviation, description) VALUES (1, 'EF', 'Eighth-Final');
INSERT INTO match_level (match_level, abbreviation, description) VALUES (2, 'QF', 'Quarter-Final');
INSERT INTO match_level (match_level, abbreviation, description) VALUES (3, 'SF', 'Semi-Final');
INSERT INTO match_level (match_level, abbreviation, description) VALUES (4, 'F', 'Final');

DELETE FROM match_status;
INSERT INTO match_status (status_id, description) VALUES (0, 'Not scheduled');
INSERT INTO match_status (status_id, description) VALUES (1, 'Not Played');
INSERT INTO match_status (status_id, description) VALUES (2, 'Rescheduled');
INSERT INTO match_status (status_id, description) VALUES (3, 'Played');
INSERT INTO match_status (status_id, description) VALUES (4, 'Scored');
INSERT INTO match_status (status_id, description) VALUES (9, 'Never');

BEGIN;
INSERT INTO score_attribute (score_attribute_id, name, description) VALUES (1, 'penalty', '');
INSERT INTO score_attribute (score_attribute_id, name, description) VALUES (11, 'robots', '');
INSERT INTO score_attribute (score_attribute_id, name, description) VALUES (240, 'auton_bonus', '');
INSERT INTO score_attribute (score_attribute_id, name, description) VALUES (241, 'toggle_bonus', '');
INSERT INTO score_attribute (score_attribute_id, name, description) VALUES (249, 'far_goal', '');
INSERT INTO score_attribute (score_attribute_id, name, description) VALUES (250, 'center_goal', '');
INSERT INTO score_attribute (score_attribute_id, name, description) VALUES (251, 'near_goal', '');
END;

CREATE OR REPLACE FUNCTION min(integer, integer) RETURNS integer as $$
	SELECT CASE WHEN $1 < $2 THEN $1 ELSE $2 END
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE FUNCTION max(integer, integer) RETURNS integer as $$
	SELECT CASE WHEN $1 > $2 THEN $1 ELSE $2 END
$$ LANGUAGE SQL STRICT;

-- DROP VIEW participant_results;
CREATE OR REPLACE VIEW participant_results AS
	SELECT	team_number AS team,
		wins,
		losses,
		num_matches - wins - losses AS ties,
		cast(cast((2 * wins + (num_matches - wins - losses)) AS numeric(6,3)) / max(1, num_matches) AS numeric(6,3)) AS record,
		cast(cast(points_sum as numeric(6,3)) / max(1, num_matches) AS numeric(6,3)) AS "ave points",
		score_max AS "max score",
		points_sum AS "total points",
		short_name AS "team name"
	FROM	(
		SELECT	team_number,
			SUM(CASE WHEN winner_color_id = alliance_color_id AND (flags & 1) = 0
				 THEN 1 ELSE 0 END) AS wins,
			SUM(CASE WHEN winner_color_id != alliance_color_id AND winner_color_id != 0
				 THEN 1 ELSE 0 END) AS losses,
			CAST(COUNT(*) AS integer) AS num_matches,
			MAX(score) AS score_max,
			SUM(points) AS points_sum
		FROM game_match NATURAL INNER JOIN alliance_team
		WHERE match_level = 0 AND match_index = 0 AND status_id = 4 AND (flags & 2) = 0
		GROUP BY team_number
		) AS summary NATURAL INNER JOIN team
	ORDER BY record DESC, "ave points" DESC, "max score" DESC, "total points" DESC;
CREATE OR REPLACE RULE delete4participant_results  AS ON DELETE TO game_match DO ALSO NOTIFY participant_results;
CREATE OR REPLACE RULE insert4participant_results  AS ON INSERT TO game_match DO ALSO NOTIFY participant_results;
CREATE OR REPLACE RULE update4participant_results  AS ON UPDATE TO game_match DO ALSO NOTIFY participant_results;
CREATE OR REPLACE RULE delete4participant_results  AS ON DELETE TO alliance_team DO ALSO NOTIFY participant_results;
CREATE OR REPLACE RULE insert4participant_results  AS ON INSERT TO alliance_team DO ALSO NOTIFY participant_results;
CREATE OR REPLACE RULE update4participant_results  AS ON UPDATE TO alliance_team DO ALSO NOTIFY participant_results;

CREATE OR REPLACE VIEW ondeck_match AS
	SELECT * FROM game_match WHERE status_id < 3
	ORDER BY time_scheduled, status_id DESC, match_level, match_number, match_index;
CREATE OR REPLACE RULE delete4ondeck_match AS ON DELETE TO game_match DO ALSO NOTIFY ondeck_match;
CREATE OR REPLACE RULE insert4ondeck_match AS ON INSERT TO game_match DO ALSO NOTIFY ondeck_match;
CREATE OR REPLACE RULE update4ondeck_match AS ON UPDATE TO game_match DO ALSO NOTIFY ondeck_match;
