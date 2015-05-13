CREATE VIEW participant_results AS SELECT
	summary.team_number AS team,
	summary.wins,
	summary.losses,
	((summary.num_matches - summary.wins) - summary.losses) AS ties,
	(((((2 * summary.wins) + ((summary.num_matches - summary.wins) - summary.losses)))::numeric(6,3) / (max(1, summary.num_matches))::numeric))::numeric(6,3) AS record,
	(((summary.points_sum)::numeric(6,3) / (max(1, summary.num_matches))::numeric))::numeric(6,3) AS "ave points",
	summary.score_max AS "max score",
	summary.points_sum AS "total points",
	team.short_name AS "team name" 
	FROM ((SELECT alliance_team.team_number,
		sum(CASE WHEN ((game_match.winner_color_id = alliance_team.alliance_color_id) AND
			      ((alliance_team.flags & 1) = 0)) THEN 1 ELSE 0 END) AS wins,
		sum(CASE WHEN ((game_match.winner_color_id <> alliance_team.alliance_color_id) AND
	                      (game_match.winner_color_id <> 0)) THEN 1 ELSE 0 END) AS losses,
		(count(*))::integer AS num_matches,
		max(alliance_team.score) AS score_max,
		sum(alliance_team.points) AS points_sum FROM
			(game_match NATURAL JOIN alliance_team) WHERE
				((((game_match.match_level = 0) AND
				(game_match.match_index = 0)) AND
				(game_match.status_id = 4)) AND
				((alliance_team.flags & 2) = 0))
			GROUP BY alliance_team.team_number) summary NATURAL JOIN team)
			ORDER BY 
				(((((2 * summary.wins) + ((summary.num_matches - summary.wins) - summary.losses)))::numeric(6,3) / (max(1, summary.num_matches))::numeric))::numeric(6,3) DESC,
				(((summary.points_sum)::numeric(6,3) / (max(1, summary.num_matches))::numeric))::numeric(6,3) DESC,
				summary.score_max DESC,
				summary.points_sum DESC;