SELECT match_number as number, winner_color_id as win, position,
a1.team_number as red, a1.flags as flags, a1.score as score, a1.points as points,
a2.team_number as blue, a2.flags as flags, a2.score as score, a2.points as points
FROM game_match INNER JOIN alliance_team a1 USING (match_number, match_level, match_index) 
INNER JOIN alliance_team a2 USING (match_number, match_level, match_index, position)
WHERE a1.alliance_color_id = 1 AND a2.alliance_color_id = 2
ORDER BY match_number, position;
