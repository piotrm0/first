--
-- PostgreSQL database dump
--

SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: alliance_team; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE alliance_team (
    match_level smallint NOT NULL,
    match_number smallint NOT NULL,
    match_index smallint NOT NULL,
    alliance_color_id smallint NOT NULL,
    "position" smallint DEFAULT 0 NOT NULL,
    team_number integer,
    flags integer DEFAULT 0,
    score integer DEFAULT 0,
    points integer DEFAULT 0
);


ALTER TABLE public.alliance_team OWNER TO postgres;

--
-- Name: color; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE color (
    color_id smallint NOT NULL,
    name character varying,
    rgb_value character varying
);


ALTER TABLE public.color OWNER TO postgres;

--
-- Name: display_component_effect; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE display_component_effect (
    effect_label character varying NOT NULL,
    substate_label character varying NOT NULL,
    component_label character varying NOT NULL,
    keyframe_index smallint NOT NULL,
    x_position numeric(6,2),
    y_position numeric(6,2),
    x_scale numeric(5,2),
    y_scale numeric(5,2),
    alpha numeric(5,2),
    rotation numeric(5,2)
);


ALTER TABLE public.display_component_effect OWNER TO postgres;

--
-- Name: display_effect_option; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE display_effect_option (
    effect_label character varying NOT NULL,
    substate_label character varying NOT NULL,
    component_label character varying NOT NULL,
    keyframe_index smallint NOT NULL,
    key character varying NOT NULL,
    value character varying
);


ALTER TABLE public.display_effect_option OWNER TO postgres;

--
-- Name: display_state; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE display_state (
    state_label character varying NOT NULL,
    substate_label character varying NOT NULL,
    display_type_label character varying NOT NULL
);


ALTER TABLE public.display_state OWNER TO postgres;

--
-- Name: display_substate; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE display_substate (
    substate_label character varying NOT NULL,
    description character varying
);


ALTER TABLE public.display_substate OWNER TO postgres;

--
-- Name: display_type; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE display_type (
    display_type_label character varying NOT NULL,
    default_quality smallint,
    default_fullscreen boolean,
    description character varying
);


ALTER TABLE public.display_type OWNER TO postgres;

--
-- Name: event_preference; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE event_preference (
    preference_key character varying NOT NULL,
    value character varying
);


ALTER TABLE public.event_preference OWNER TO postgres;

--
-- Name: finals_alliance_partner; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE finals_alliance_partner (
    finals_alliance_number smallint NOT NULL,
    recruit_order smallint NOT NULL,
    team_number integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.finals_alliance_partner OWNER TO postgres;

--
-- Name: game_match; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE game_match (
    match_level smallint NOT NULL,
    match_number smallint NOT NULL,
    match_index smallint NOT NULL,
    status_id smallint,
    time_scheduled timestamp without time zone,
    winner_color_id smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.game_match OWNER TO postgres;

--
-- Name: game_state; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE game_state (
    state_label character varying NOT NULL,
    description character varying,
    menu_order smallint,
    menu_label character varying
);


ALTER TABLE public.game_state OWNER TO postgres;

--
-- Name: match_level; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE match_level (
    match_level smallint NOT NULL,
    abbreviation character varying,
    description character varying
);


ALTER TABLE public.match_level OWNER TO postgres;

--
-- Name: match_status; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE match_status (
    status_id smallint NOT NULL,
    description character varying
);


ALTER TABLE public.match_status OWNER TO postgres;

--
-- Name: ondeck_match; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW ondeck_match AS
    SELECT game_match.match_level, game_match.match_number, game_match.match_index, game_match.status_id, game_match.time_scheduled, game_match.winner_color_id FROM game_match WHERE (game_match.status_id < 3) ORDER BY game_match.time_scheduled, game_match.status_id DESC, game_match.match_level, game_match.match_number, game_match.match_index;


ALTER TABLE public.ondeck_match OWNER TO postgres;

--
-- Name: max(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION max(integer, integer) RETURNS integer
    AS $_$
	SELECT CASE WHEN $1 > $2 THEN $1 ELSE $2 END
$_$
    LANGUAGE sql STRICT;


ALTER FUNCTION public.max(integer, integer) OWNER TO postgres;

--
-- Name: team; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE team (
    team_number integer NOT NULL,
    info text,
    short_name character varying,
    nickname character varying,
    robot_name character varying,
    location character varying,
    rookie_year integer
);


ALTER TABLE public.team OWNER TO postgres;

--
-- Name: participant_results; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW participant_results AS
    SELECT summary.team_number AS team, summary.wins, summary.losses, ((summary.num_matches - summary.wins) - summary.losses) AS ties, (((((2 * summary.wins) + ((summary.num_matches - summary.wins) - summary.losses)))::numeric(6,3) / (max(1, summary.num_matches))::numeric))::numeric(6,3) AS record, (((summary.points_sum)::numeric(6,3) / (max(1, summary.num_matches))::numeric))::numeric(6,3) AS "ave points", summary.score_max AS "max score", summary.points_sum AS "total points", team.short_name AS "team name" FROM ((SELECT alliance_team.team_number, sum(CASE WHEN ((game_match.winner_color_id = alliance_team.alliance_color_id) AND ((alliance_team.flags & 1) = 0)) THEN 1 ELSE 0 END) AS wins, sum(CASE WHEN ((game_match.winner_color_id <> alliance_team.alliance_color_id) AND (game_match.winner_color_id <> 0)) THEN 1 ELSE 0 END) AS losses, (count(*))::integer AS num_matches, max(alliance_team.score) AS score_max, sum(alliance_team.points) AS points_sum FROM (game_match NATURAL JOIN alliance_team) WHERE ((((game_match.match_level = 0) AND (game_match.match_index = 0)) AND (game_match.status_id = 4)) AND ((alliance_team.flags & 2) = 0)) GROUP BY alliance_team.team_number) summary NATURAL JOIN team) ORDER BY (((((2 * summary.wins) + ((summary.num_matches - summary.wins) - summary.losses)))::numeric(6,3) / (max(1, summary.num_matches))::numeric))::numeric(6,3) DESC, (((summary.points_sum)::numeric(6,3) / (max(1, summary.num_matches))::numeric))::numeric(6,3) DESC, summary.score_max DESC, summary.points_sum DESC;


ALTER TABLE public.participant_results OWNER TO postgres;

--
-- Name: score_attribute; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE score_attribute (
    score_attribute_id integer NOT NULL,
    name character varying,
    description character varying
);


ALTER TABLE public.score_attribute OWNER TO postgres;

--
-- Name: team_score; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE team_score (
    match_level smallint NOT NULL,
    match_number smallint NOT NULL,
    match_index smallint NOT NULL,
    alliance_color_id smallint NOT NULL,
    "position" smallint NOT NULL,
    score_attribute_id integer NOT NULL,
    value integer DEFAULT 0
);


ALTER TABLE public.team_score OWNER TO postgres;

--
-- Name: test; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE test (
    id integer NOT NULL,
    name character varying
);


ALTER TABLE public.test OWNER TO postgres;

--
-- Name: min(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION min(integer, integer) RETURNS integer
    AS $_$
	SELECT CASE WHEN $1 < $2 THEN $1 ELSE $2 END
$_$
    LANGUAGE sql STRICT;


ALTER FUNCTION public.min(integer, integer) OWNER TO postgres;

--
-- Data for Name: alliance_team; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY alliance_team (match_level, match_number, match_index, alliance_color_id, "position", team_number, flags, score, points) FROM stdin;
0	27	0	1	1	173	0	82	82
0	27	0	1	2	61	0	82	82
0	27	0	1	3	176	0	82	82
0	27	0	2	1	1027	0	80	80
0	27	0	2	2	839	0	80	80
0	27	0	2	3	228	0	80	80
0	39	0	1	1	1735	0	52	52
0	39	0	1	2	173	0	52	52
0	39	0	1	3	1153	0	52	52
0	39	0	2	1	2079	0	44	44
0	39	0	2	2	467	0	44	44
0	39	0	2	3	571	0	44	44
0	14	0	1	1	1991	0	66	66
0	14	0	1	2	1027	0	66	66
0	14	0	1	3	1289	0	66	66
0	14	0	2	1	350	0	22	22
0	14	0	2	2	1735	0	22	22
0	14	0	2	3	1685	0	22	22
0	21	0	1	1	1100	0	58	58
0	21	0	1	2	61	0	58	58
0	21	0	1	3	839	0	58	58
0	21	0	2	1	571	0	48	48
0	21	0	2	2	350	0	48	48
0	21	0	2	3	562	0	48	48
0	42	0	1	1	263	0	28	28
0	42	0	1	2	61	0	28	28
0	42	0	1	3	228	0	28	28
0	42	0	2	1	181	0	70	70
0	42	0	2	2	125	0	70	70
0	42	0	2	3	166	0	70	70
0	49	0	1	1	350	0	78	78
0	49	0	1	2	228	0	78	78
0	49	0	1	3	1058	0	78	78
0	49	0	2	1	190	0	36	36
0	49	0	2	2	125	0	36	36
0	49	0	2	3	263	0	36	36
0	24	0	1	1	1761	0	40	40
0	24	0	1	2	1991	0	40	40
0	24	0	1	3	2079	0	40	40
0	24	0	2	1	1468	0	30	30
0	24	0	2	2	2067	0	30	30
0	24	0	2	3	811	0	30	30
0	36	0	1	1	263	0	66	66
0	36	0	1	2	1100	0	66	66
0	36	0	1	3	181	0	66	66
0	36	0	2	1	97	0	40	40
0	40	0	1	1	1289	0	70	70
3	1	2	1	1	121	0	102	102
3	1	2	1	2	40	0	102	102
3	1	2	1	3	1474	0	102	102
3	1	3	1	2	121	0	0	0
3	1	3	1	3	1474	0	0	0
3	1	3	1	1	40	0	0	0
3	1	1	1	3	1474	0	114	114
3	1	1	1	1	40	0	114	114
3	1	1	1	2	121	0	114	114
4	2	0	2	3	126	0	98	98
0	40	0	1	2	1519	0	70	70
0	40	0	1	3	1761	0	70	70
0	17	0	1	1	88	0	36	36
0	17	0	1	2	1733	0	36	36
0	17	0	1	3	97	0	36	36
0	17	0	2	1	809	0	28	28
0	17	0	2	2	176	0	28	28
0	17	0	2	3	20	0	28	28
0	55	0	2	2	40	0	134	134
0	55	0	2	3	271	0	134	134
0	30	0	1	1	271	0	46	46
0	30	0	1	2	467	0	46	46
0	30	0	1	3	263	0	46	46
0	30	0	2	1	1761	0	48	48
0	30	0	2	2	1100	0	48	48
0	30	0	2	3	811	0	48	48
0	1	0	1	1	467	0	42	42
0	1	0	1	2	238	0	42	42
0	1	0	1	3	1058	0	42	42
0	1	0	2	1	20	0	106	106
0	1	0	2	2	121	0	106	106
0	1	0	2	3	61	0	106	106
0	45	0	1	3	2067	0	62	62
0	45	0	2	1	121	0	44	44
0	45	0	2	2	1153	0	44	44
0	45	0	2	3	1027	0	44	44
0	45	0	1	1	1733	0	62	62
0	45	0	1	2	1100	0	62	62
0	52	0	2	3	121	0	102	102
0	52	0	1	1	529	0	36	36
0	52	0	1	2	319	0	36	36
0	12	0	1	1	2342	0	40	40
0	12	0	1	2	2067	0	40	40
0	12	0	1	3	230	0	40	40
0	12	0	2	1	173	0	38	38
0	12	0	2	2	562	0	38	38
0	12	0	2	3	319	0	38	38
0	40	0	2	1	88	0	32	32
0	40	0	2	2	809	0	32	32
0	40	0	2	3	1991	0	32	32
0	6	0	1	1	1153	0	18	18
0	6	0	1	2	562	0	18	18
0	6	0	1	3	2342	0	18	18
0	6	0	2	1	555	0	44	44
0	6	0	2	2	1991	0	44	44
0	6	0	2	3	228	0	44	44
0	9	0	2	2	529	0	56	56
0	9	0	2	3	40	0	56	56
0	9	0	1	1	20	0	98	98
0	9	0	1	2	126	0	98	98
0	9	0	1	3	97	0	98	98
0	9	0	2	1	61	0	56	56
0	16	0	1	1	166	0	40	40
0	16	0	1	2	1761	0	40	40
0	16	0	1	3	1058	0	40	40
0	16	0	2	1	1519	0	60	60
0	16	0	2	2	1153	0	60	60
0	16	0	2	3	811	0	60	60
0	3	0	1	1	190	0	22	22
0	3	0	1	2	97	0	22	22
0	3	0	1	3	2067	0	22	22
0	3	0	2	1	271	0	98	98
0	3	0	2	2	126	0	98	98
0	3	0	2	3	88	0	98	98
0	47	0	1	1	97	0	46	46
0	47	0	1	2	571	0	46	46
0	47	0	1	3	1474	0	46	46
0	47	0	2	1	1519	0	78	78
0	47	0	2	2	467	0	78	78
0	47	0	2	3	1991	0	78	78
0	54	0	1	1	175	0	48	48
0	54	0	1	2	1733	0	48	48
0	54	0	1	3	562	0	48	48
0	54	0	2	1	1761	0	52	52
0	54	0	2	2	97	0	52	52
0	54	0	2	3	173	0	52	52
0	29	0	1	1	562	0	72	72
0	29	0	1	2	555	0	72	72
0	29	0	1	3	1519	0	72	72
0	29	0	2	1	172	0	36	36
0	29	0	2	2	190	0	36	36
0	29	0	2	3	238	0	36	36
0	23	0	1	1	271	0	94	94
0	23	0	1	2	555	0	94	94
0	23	0	1	3	1685	0	94	94
0	23	0	2	1	263	0	72	72
0	23	0	2	2	1519	0	72	72
0	23	0	2	3	1058	0	72	72
0	44	0	1	2	1468	0	72	72
0	44	0	1	3	238	0	72	72
0	44	0	2	1	529	0	62	62
0	44	0	2	2	176	0	62	62
0	44	0	2	3	2342	0	62	62
0	44	0	1	1	1685	0	72	72
0	51	0	1	1	1153	0	77	77
0	51	0	1	2	131	0	77	77
2	2	2	2	2	230	0	80	80
2	2	2	2	3	195	0	80	80
2	2	2	1	3	88	0	68	68
2	2	2	2	1	809	0	80	80
4	2	0	1	1	121	0	98	98
4	2	0	1	2	40	0	98	98
4	2	0	1	3	1474	0	98	98
4	2	0	2	1	1027	0	98	98
4	2	0	2	2	1519	0	98	98
3	1	2	2	1	195	0	44	44
3	1	2	2	2	809	0	44	44
3	1	2	2	3	230	0	44	44
3	1	3	2	1	230	0	0	0
3	1	3	2	2	809	0	0	0
3	1	3	2	3	195	0	0	0
3	1	1	2	1	195	0	80	80
3	1	1	2	2	809	0	80	80
3	1	1	2	3	230	0	80	80
2	1	2	2	1	173	0	20	20
2	1	2	2	2	319	0	20	20
2	1	2	2	3	1468	0	20	20
2	2	2	1	1	20	0	68	68
2	2	2	1	2	1733	0	68	68
0	46	0	1	3	1289	0	52	52
0	46	0	2	1	40	0	74	74
0	46	0	2	2	555	0	74	74
0	46	0	2	3	173	0	74	74
0	53	0	1	1	1027	0	52	52
0	53	0	1	2	1474	0	52	52
0	53	0	1	3	467	0	52	52
0	53	0	2	1	571	0	30	30
0	53	0	2	2	88	0	30	30
0	53	0	2	3	555	0	30	30
0	28	0	1	1	809	0	36	36
0	28	0	1	2	2342	0	36	36
0	28	0	1	3	131	0	36	36
0	28	0	2	1	166	0	50	50
0	28	0	2	2	1474	0	50	50
0	28	0	2	3	350	0	50	50
0	56	0	1	1	230	0	106	106
0	56	0	1	2	1519	0	106	106
0	56	0	1	3	2079	0	106	106
0	56	0	2	1	1100	0	86	86
0	56	0	2	2	126	0	86	86
0	56	0	2	3	1991	0	86	86
0	15	0	1	1	263	0	46	46
0	15	0	1	2	1474	0	46	46
0	15	0	1	3	555	0	46	46
0	15	0	2	1	839	0	50	50
0	15	0	2	2	1468	0	50	50
0	15	0	2	3	2079	0	50	50
0	22	0	1	1	166	0	36	36
0	22	0	1	2	1153	0	36	36
0	22	0	1	3	190	0	36	36
0	22	0	2	1	1735	0	30	30
0	22	0	2	2	529	0	30	30
0	22	0	2	3	1474	0	30	30
0	43	0	1	1	195	0	70	70
0	43	0	1	2	271	0	70	70
0	43	0	1	3	172	0	70	70
0	43	0	2	1	230	0	102	102
0	43	0	2	2	1058	0	102	102
0	43	0	2	3	839	0	102	102
0	50	0	1	1	1685	0	56	56
0	50	0	1	2	195	0	56	56
0	50	0	1	3	166	0	56	56
0	50	0	2	1	172	0	92	92
0	50	0	2	2	1468	0	92	92
0	50	0	2	3	20	0	92	92
0	25	0	2	2	20	0	84	84
0	25	0	2	3	230	0	84	84
0	25	0	1	1	175	0	90	90
3	2	2	1	1	271	0	64	64
3	2	2	1	2	263	0	64	64
3	2	2	1	3	839	0	64	64
2	3	2	1	1	839	0	36	36
2	3	2	1	2	263	0	36	36
2	3	2	1	3	271	0	36	36
3	2	3	1	1	839	0	0	0
3	2	3	1	2	263	0	0	0
3	2	3	1	3	271	0	0	0
3	2	1	1	1	271	0	72	72
3	2	1	1	2	263	0	72	72
3	2	1	1	3	839	0	72	72
0	38	0	1	3	1733	0	40	40
0	38	0	2	1	1685	0	66	66
0	38	0	2	2	1474	0	66	66
0	38	0	2	3	2067	0	66	66
0	38	0	1	1	238	0	40	40
0	13	0	1	1	228	0	56	56
0	13	0	1	2	571	0	56	56
0	13	0	1	3	1100	0	56	56
0	13	0	2	1	175	0	72	72
0	13	0	2	2	195	0	72	72
0	13	0	2	3	238	0	72	72
0	20	0	1	1	195	0	46	46
0	20	0	1	2	1027	0	46	46
0	20	0	1	3	125	0	46	46
0	20	0	2	1	238	0	46	46
0	20	0	2	2	1289	0	46	46
0	20	0	2	3	2342	0	46	46
0	11	0	2	2	467	0	26	26
0	11	0	2	3	190	0	26	26
0	18	0	1	1	172	0	38	38
0	18	0	1	2	173	0	38	38
0	18	0	1	3	181	0	38	38
0	18	0	2	1	121	0	88	88
0	18	0	2	2	319	0	88	88
0	18	0	2	3	126	0	88	88
0	5	0	1	1	230	0	70	70
0	5	0	1	2	319	0	70	70
0	5	0	1	3	571	0	70	70
0	5	0	2	1	809	0	14	14
0	5	0	2	2	263	0	14	14
0	5	0	2	3	1733	0	14	14
0	33	0	1	1	40	0	118	118
0	33	0	1	2	20	0	118	118
0	33	0	1	3	839	0	118	118
0	33	0	2	1	125	0	42	42
0	33	0	2	2	319	0	42	42
0	33	0	2	3	228	0	42	42
0	8	0	1	1	1027	0	22	22
0	8	0	1	2	1685	0	22	22
0	8	0	1	3	1761	0	22	22
0	8	0	2	1	1289	0	56	56
0	8	0	2	2	166	0	56	56
0	8	0	2	3	839	0	56	56
0	31	0	1	1	1468	0	106	106
1	8	1	1	1	126	0	56	56
1	8	1	1	2	1519	0	56	56
1	8	1	1	3	1027	0	56	56
1	1	1	1	1	121	0	126	126
1	1	1	1	2	40	0	126	126
1	1	1	1	3	1474	0	126	126
1	1	1	2	1	1735	0	42	42
1	1	1	2	2	228	0	42	42
1	1	1	2	3	1761	0	42	42
1	6	1	1	1	1991	0	22	22
1	6	1	1	2	131	0	22	22
1	6	1	1	3	125	0	22	22
1	6	1	2	1	555	0	24	24
1	6	1	2	2	172	0	24	24
1	6	1	2	3	1153	0	24	24
0	31	0	1	2	1991	0	106	106
0	31	0	1	3	1735	0	106	106
0	31	0	2	1	529	0	66	66
0	31	0	2	2	1733	0	66	66
0	31	0	2	3	1058	0	66	66
0	2	0	1	1	172	0	50	50
0	2	0	1	2	40	0	50	50
0	2	0	1	3	350	0	50	50
0	2	0	2	1	181	0	28	28
0	2	0	2	2	2079	0	28	28
0	2	0	2	3	529	0	28	28
0	46	0	1	1	811	0	52	52
0	46	0	1	2	88	0	52	52
0	48	0	2	1	1735	0	50	50
0	48	0	2	2	2079	0	50	50
0	36	0	2	2	2342	0	40	40
0	36	0	2	3	172	0	40	40
0	11	0	1	1	176	0	70	70
0	11	0	1	2	1733	0	70	70
0	11	0	1	3	181	0	70	70
0	11	0	2	1	809	0	26	26
0	48	0	2	3	126	0	50	50
0	7	0	1	1	175	0	38	38
0	7	0	1	2	811	0	38	38
0	7	0	1	3	1735	0	38	38
1	5	1	2	1	350	0	36	36
1	5	1	2	2	97	0	36	36
1	5	1	2	3	190	0	36	36
1	8	1	2	1	181	0	46	46
1	8	1	2	2	571	0	46	46
1	8	1	2	3	2342	0	46	46
3	2	2	2	1	1519	0	94	94
3	2	2	2	2	126	0	94	94
3	2	2	2	3	1027	0	94	94
4	3	0	1	1	1474	0	130	130
4	3	0	1	2	40	0	130	130
4	3	0	1	3	121	0	130	130
4	3	0	2	1	1519	0	82	82
4	3	0	2	2	126	0	82	82
4	3	0	2	3	1027	0	82	82
2	3	2	2	1	125	0	42	42
2	3	2	2	2	1991	0	42	42
2	3	2	2	3	131	0	42	42
2	4	2	2	1	1519	0	86	86
2	4	2	2	2	126	0	86	86
2	4	2	2	3	1027	0	86	86
2	4	2	1	1	238	0	80	80
2	4	2	1	2	175	0	80	80
2	4	2	1	3	176	0	80	80
2	2	3	1	1	1733	0	0	0
2	2	3	1	2	20	0	0	0
2	2	3	1	3	88	0	0	0
0	52	0	1	3	1289	0	36	36
0	52	0	2	1	176	0	102	102
0	52	0	2	2	811	0	102	102
2	2	3	2	1	809	0	0	0
2	2	3	2	2	230	0	0	0
2	2	3	2	3	195	0	0	0
2	1	1	1	1	40	0	90	90
2	1	1	1	2	121	0	90	90
2	1	1	1	3	1474	0	90	90
2	1	1	2	1	1468	0	26	26
2	1	1	2	2	173	0	26	26
2	1	1	2	3	319	0	26	26
0	19	0	2	1	230	0	108	108
0	19	0	2	2	175	0	108	108
0	19	0	2	3	131	0	108	108
0	34	0	1	1	126	0	68	68
0	34	0	1	2	230	0	68	68
0	34	0	1	3	166	0	68	68
0	34	0	2	1	176	0	78	78
0	34	0	2	2	350	0	78	78
0	34	0	2	3	175	0	78	78
1	7	2	1	1	175	0	104	104
1	7	2	1	2	176	0	104	104
1	7	2	1	3	238	0	104	104
1	7	2	2	1	2079	0	90	90
1	7	2	2	2	61	0	90	90
1	7	2	2	3	562	0	90	90
1	8	2	1	1	126	0	100	100
1	8	2	1	2	1519	0	100	100
1	8	2	1	3	1027	0	100	100
1	8	2	2	1	181	0	56	56
1	8	2	2	2	571	0	56	56
1	8	2	2	3	2342	0	56	56
1	6	2	1	1	1991	0	40	40
1	6	2	1	2	131	0	40	40
1	6	2	1	3	125	0	40	40
1	6	2	2	1	555	0	16	16
1	6	2	2	2	172	0	16	16
1	6	2	2	3	1153	0	16	16
1	3	2	1	1	20	0	104	104
1	3	2	1	2	88	0	104	104
1	3	2	1	3	1733	0	104	104
1	3	2	2	1	166	0	40	40
1	3	2	2	2	1058	0	40	40
1	3	2	2	3	2067	0	40	40
1	2	1	1	1	173	0	84	84
1	2	1	1	2	1468	0	84	84
1	2	1	1	3	319	0	84	84
1	2	1	2	1	1289	0	48	48
1	2	1	2	2	1100	0	48	48
1	2	1	2	3	467	0	48	48
1	2	2	1	1	173	0	68	68
1	2	2	1	2	1468	0	68	68
1	2	2	1	3	319	0	68	68
1	2	2	2	1	1289	0	40	40
2	2	1	2	2	230	0	94	94
2	2	1	2	3	809	0	94	94
2	2	1	1	3	88	0	64	64
2	2	1	1	1	1733	0	64	64
2	2	1	1	2	20	0	64	64
2	2	1	2	1	195	0	94	94
2	1	3	1	1	121	0	0	0
2	1	3	1	2	40	0	0	0
2	1	3	1	3	1474	0	0	0
2	1	3	2	1	319	0	0	0
2	1	3	2	2	1468	0	0	0
2	1	3	2	3	173	0	0	0
1	2	2	2	2	1100	0	40	40
1	2	2	2	3	467	0	40	40
1	4	2	1	1	230	0	82	82
1	4	2	1	2	195	0	82	82
1	4	2	1	3	809	0	82	82
1	4	2	2	1	1685	0	26	26
1	4	1	1	1	230	0	90	90
1	4	1	1	2	195	0	90	90
1	4	1	1	3	809	0	90	90
1	4	1	2	1	1685	0	18	18
1	4	1	2	2	811	0	18	18
1	4	1	2	3	529	0	18	18
3	2	3	2	3	126	0	0	0
3	2	1	2	1	1027	0	82	82
3	2	1	2	2	126	0	82	82
3	2	1	2	3	1519	0	82	82
4	1	0	1	1	121	0	146	146
4	1	0	1	2	1474	0	146	146
4	1	0	1	3	40	0	146	146
4	1	0	2	1	1519	0	82	82
4	1	0	2	2	126	0	82	82
4	1	0	2	3	1027	0	82	82
0	25	0	1	2	121	0	90	90
0	25	0	1	3	181	0	90	90
0	25	0	2	1	88	0	84	84
0	37	0	1	1	1027	0	60	60
0	37	0	1	2	1468	0	60	60
0	37	0	1	3	529	0	60	60
0	37	0	2	1	1058	0	68	68
0	37	0	2	2	562	0	68	68
0	37	0	2	3	271	0	68	68
0	19	0	1	1	40	0	62	62
0	19	0	1	2	228	0	62	62
0	19	0	1	3	467	0	62	62
2	4	1	1	1	176	0	104	104
2	4	1	1	2	238	0	104	104
2	4	1	1	3	175	0	104	104
2	4	1	2	1	1519	0	70	70
2	4	1	2	2	126	0	70	70
2	4	1	2	3	1027	0	70	70
2	4	3	1	1	238	0	80	80
1	5	2	1	1	839	0	76	76
1	5	2	1	2	271	0	76	76
1	5	2	1	3	263	0	76	76
1	5	2	2	1	350	0	20	20
1	5	2	2	2	97	0	20	20
1	5	2	2	3	190	0	20	20
1	4	2	2	2	811	0	26	26
1	4	2	2	3	529	0	26	26
1	3	1	1	1	20	0	82	82
1	3	1	1	2	88	0	82	82
1	3	1	1	3	1733	0	82	82
1	3	1	2	1	166	0	64	64
1	3	1	2	2	1058	0	64	64
1	3	1	2	3	2067	0	64	64
0	51	0	2	2	181	0	34	34
0	51	0	2	3	2067	0	34	34
0	4	0	1	1	125	0	4	4
0	4	0	1	2	1100	0	4	4
0	4	0	1	3	176	0	4	4
0	4	0	2	1	1474	0	40	40
0	4	0	2	2	131	0	40	40
0	4	0	2	3	173	0	40	40
0	38	0	1	2	811	0	40	40
0	41	0	1	1	175	0	86	86
0	41	0	1	2	319	0	86	86
0	41	0	1	3	20	0	86	86
0	41	0	2	1	131	0	30	30
0	41	0	2	2	350	0	30	30
0	41	0	2	3	190	0	30	30
0	48	0	1	1	1761	0	36	36
0	48	0	1	2	809	0	36	36
0	48	0	1	3	562	0	36	36
0	7	0	2	1	1519	0	26	26
0	7	0	2	2	195	0	26	26
0	7	0	2	3	1468	0	26	26
0	35	0	1	1	195	0	102	102
0	35	0	1	2	131	0	102	102
0	35	0	1	3	121	0	102	102
0	35	0	2	1	555	0	48	48
0	35	0	2	2	61	0	48	48
0	35	0	2	3	190	0	48	48
0	10	0	1	2	88	0	100	100
0	10	0	1	3	172	0	100	100
1	1	2	1	2	40	0	130	130
1	1	2	1	3	1474	0	130	130
1	1	2	2	1	1735	0	38	38
1	1	2	2	2	228	0	38	38
1	1	2	2	3	1761	0	38	38
1	1	2	1	1	121	0	130	130
1	7	1	1	1	175	0	86	86
1	7	1	1	2	176	0	86	86
1	7	1	1	3	238	0	86	86
1	7	1	2	1	2079	0	42	42
1	7	1	2	2	61	0	42	42
1	7	1	2	3	562	0	42	42
1	5	1	1	1	839	0	56	56
1	5	1	1	2	271	0	56	56
1	5	1	1	3	263	0	56	56
3	2	3	2	1	1027	0	0	0
3	2	3	2	2	1519	0	0	0
2	4	3	1	2	176	0	80	80
2	4	3	1	3	175	0	80	80
2	4	3	2	3	126	0	92	92
2	4	3	2	1	1027	0	92	92
2	4	3	2	2	1519	0	92	92
2	3	3	1	1	271	0	64	64
2	3	3	1	2	839	0	64	64
2	3	3	1	3	263	0	64	64
2	3	3	2	1	125	0	54	54
2	3	3	2	2	131	0	54	54
2	3	3	2	3	1991	0	54	54
2	3	1	1	1	263	0	90	90
0	26	0	2	1	319	0	50	50
0	26	0	2	2	195	0	50	50
0	26	0	2	3	97	0	50	50
0	26	0	1	1	126	0	58	58
0	26	0	1	2	40	0	58	58
0	26	0	1	3	125	0	58	58
0	51	0	1	3	839	0	77	77
0	51	0	2	1	238	0	34	34
0	10	0	2	1	131	0	92	92
0	10	0	2	2	271	0	92	92
0	10	0	2	3	125	0	92	92
0	10	0	1	1	121	0	100	100
0	32	0	1	1	2067	0	42	42
0	32	0	1	2	1153	0	42	42
0	32	0	1	3	2079	0	42	42
0	32	0	2	1	1685	0	54	54
0	32	0	2	2	571	0	54	54
0	32	0	2	3	1289	0	54	54
0	55	0	1	1	61	0	46	46
0	55	0	1	2	1735	0	46	46
0	55	0	1	3	809	0	46	46
0	55	0	2	1	2342	0	134	134
2	3	1	1	2	839	0	90	90
2	3	1	1	3	271	0	90	90
2	3	1	2	1	1991	0	62	62
2	3	1	2	2	131	0	62	62
2	3	1	2	3	125	0	62	62
2	1	2	1	1	40	0	120	120
2	1	2	1	2	1474	0	120	120
2	1	2	1	3	121	0	120	120
\.


--
-- Data for Name: color; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY color (color_id, name, rgb_value) FROM stdin;
-1	dark	0x7F7F7F
0	none	0x000000
1	Red	0xFF7F7F
2	Blue	0x7F7FFF
3	Green	0x7FFF7F
4	Purple	0xFF7FFF
5	Orange	0xFFBF7F
6	Yellow	0xFFFF7F
\.


--
-- Data for Name: display_component_effect; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY display_component_effect (effect_label, substate_label, component_label, keyframe_index, x_position, y_position, x_scale, y_scale, alpha, rotation) FROM stdin;
appear	test	rankings	0	320.00	203.00	100.00	100.00	100.00	0.00
slide	test	rankings	1	320.00	203.00	100.00	100.00	100.00	0.00
slide	test	rankings	2	320.00	203.00	100.00	100.00	100.00	0.00
appear	match	clock	0	320.00	-60.00	85.00	85.00	100.00	0.00
slide	match	clock	1	320.00	40.00	85.00	85.00	100.00	0.00
slide	match	clock	2	320.00	-60.00	85.00	85.00	100.00	0.00
appear	match	match	0	320.00	520.00	50.00	50.00	100.00	0.00
slide	match	match	1	320.00	455.00	50.00	50.00	100.00	0.00
slide	match	match	2	320.00	520.00	50.00	50.00	100.00	0.00
appear	match	team_red	0	-100.00	40.00	35.00	35.00	100.00	0.00
slide	match	team_red	1	160.00	40.00	35.00	35.00	100.00	0.00
slide	match	team_red	2	-100.00	40.00	35.00	35.00	100.00	0.00
appear	match	team_blue	0	740.00	40.00	35.00	35.00	100.00	0.00
slide	match	team_blue	1	480.00	40.00	35.00	35.00	100.00	0.00
slide	match	team_blue	2	740.00	40.00	35.00	35.00	100.00	0.00
appear	results	match	0	320.00	540.00	70.00	70.00	100.00	0.00
slide	results	match	1	320.00	445.00	70.00	70.00	100.00	0.00
slide	results	match	2	320.00	540.00	70.00	70.00	100.00	0.00
appear	results	team_red	0	200.00	560.00	55.00	55.00	100.00	0.00
slide	results	team_red	1	200.00	360.00	55.00	55.00	100.00	0.00
slide	results	team_red	2	200.00	560.00	55.00	55.00	100.00	0.00
appear	results	team_blue	0	440.00	560.00	55.00	55.00	100.00	0.00
slide	results	team_blue	1	440.00	360.00	55.00	55.00	100.00	0.00
slide	results	team_blue	2	440.00	560.00	55.00	55.00	100.00	0.00
appear	rankings_ondeck	ondeck	0	195.00	700.00	80.00	80.00	100.00	0.00
slide	rankings_ondeck	ondeck	1	195.00	423.00	90.00	90.00	100.00	0.00
slide	rankings_ondeck	ondeck	2	195.00	700.00	80.00	80.00	100.00	0.00
appear	rankings_ondeck	rankings	0	320.00	203.00	100.00	100.00	100.00	0.00
slide	rankings_ondeck	rankings	1	320.00	203.00	100.00	100.00	100.00	0.00
slide	rankings_ondeck	rankings	2	320.00	203.00	100.00	100.00	100.00	0.00
appear	ladder_ondeck	ondeck	0	195.00	700.00	80.00	80.00	100.00	0.00
slide	ladder_ondeck	ondeck	1	195.00	423.00	90.00	90.00	100.00	0.00
slide	ladder_ondeck	ondeck	2	195.00	700.00	80.00	80.00	100.00	0.00
appear	ladder_ondeck	ladder	0	320.00	203.00	100.00	100.00	100.00	0.00
slide	ladder_ondeck	ladder	1	320.00	203.00	100.00	100.00	100.00	0.00
slide	ladder_ondeck	ladder	2	320.00	203.00	100.00	100.00	100.00	0.00
appear	rankings_results	rankings	0	320.00	240.00	100.00	100.00	100.00	0.00
slide	rankings_results	rankings	1	320.00	165.00	100.00	85.00	100.00	0.00
slide	rankings_results	rankings	2	320.00	240.00	100.00	100.00	100.00	0.00
appear	rankings_results	match	0	320.00	540.00	70.00	70.00	100.00	0.00
slide	rankings_results	match	1	320.00	445.00	70.00	70.00	100.00	0.00
slide	rankings_results	match	2	320.00	540.00	70.00	70.00	100.00	0.00
appear	rankings_results	team_red	0	200.00	560.00	55.00	55.00	100.00	0.00
slide	rankings_results	team_red	1	200.00	360.00	55.00	55.00	100.00	0.00
slide	rankings_results	team_red	2	200.00	560.00	55.00	55.00	100.00	0.00
appear	rankings_results	team_blue	0	440.00	560.00	55.00	55.00	100.00	0.00
slide	rankings_results	team_blue	1	440.00	360.00	55.00	55.00	100.00	0.00
slide	rankings_results	team_blue	2	440.00	560.00	55.00	55.00	100.00	0.00
appear	ladder_results	ladder	0	320.00	240.00	100.00	100.00	100.00	0.00
slide	ladder_results	ladder	1	320.00	165.00	100.00	85.00	100.00	0.00
slide	ladder_results	ladder	2	320.00	240.00	100.00	100.00	100.00	0.00
appear	ladder_results	match	0	320.00	540.00	70.00	70.00	100.00	0.00
slide	ladder_results	match	1	320.00	445.00	70.00	70.00	100.00	0.00
slide	ladder_results	match	2	320.00	540.00	70.00	70.00	100.00	0.00
appear	ladder_results	team_red	0	200.00	560.00	55.00	55.00	100.00	0.00
slide	ladder_results	team_red	1	200.00	360.00	55.00	55.00	100.00	0.00
slide	ladder_results	team_red	2	200.00	560.00	55.00	55.00	100.00	0.00
appear	ladder_results	team_blue	0	440.00	560.00	55.00	55.00	100.00	0.00
slide	ladder_results	team_blue	1	440.00	360.00	55.00	55.00	100.00	0.00
slide	ladder_results	team_blue	2	440.00	560.00	55.00	55.00	100.00	0.00
appear	rankings	rankings	0	1240.00	240.00	100.00	100.00	100.00	0.00
slide	rankings	rankings	1	320.00	240.00	100.00	100.00	100.00	0.00
slide	rankings	rankings	2	1240.00	240.00	100.00	100.00	100.00	0.00
appear	ladder	ladder	0	1240.00	240.00	100.00	100.00	100.00	0.00
slide	ladder	ladder	1	320.00	240.00	100.00	100.00	100.00	0.00
slide	ladder	ladder	2	1240.00	240.00	100.00	100.00	100.00	0.00
appear	pairings	pairings	0	1000.00	220.00	100.00	100.00	100.00	0.00
slide	pairings	pairings	1	320.00	220.00	100.00	100.00	100.00	0.00
slide	pairings	pairings	2	1000.00	220.00	100.00	100.00	100.00	0.00
\.


--
-- Data for Name: display_effect_option; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY display_effect_option (effect_label, substate_label, component_label, keyframe_index, key, value) FROM stdin;
\.


--
-- Data for Name: display_state; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY display_state (state_label, substate_label, display_type_label) FROM stdin;
empty	empty	main
empty	empty	pit
empty	test	test
env	env	main
env	env	pit
env	test	test
q_match	match	main
q_match	rankings_ondeck	pit
q_match	test	test
q_results	results	main
q_results	rankings_results	pit
q_results	test	test
e_match	match	main
e_match	ladder_ondeck	pit
e_match	test	test
e_results	results	main
e_results	ladder_results	pit
e_results	test	test
rankings	rankings	main
rankings	rankings	pit
rankings	test	test
pairings	pairings	main
pairings	pairings	pit
pairings	test	test
ladder	ladder	main
ladder	ladder	pit
ladder	test	test
\.


--
-- Data for Name: display_substate; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY display_substate (substate_label, description) FROM stdin;
empty	Shows nothing.
env	Shows whatever ENV dictates.
match	Shows the match.
results	Shows the results.
rankings	Shows the rankings.
pairings	Shows the pairings.
ladder	Shows the ladder.
rankings_ondeck	Shows rankings and the ondeck panel.
rankings_results	Shows rankings and the results.
ladder_ondeck	Shows ladder and the ondeck panel.
ladder_results	Shows ladder and the results.
test	Shows whatever is being tested.
\.


--
-- Data for Name: display_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY display_type (display_type_label, default_quality, default_fullscreen, description) FROM stdin;
main	0	t	This is the main display shown usually over the field.
pit	0	t	This is the pit display shown usually in the pit.
test	0	f	This is for testing only.
\.


--
-- Data for Name: event_preference; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY event_preference (preference_key, value) FROM stdin;
\.


--
-- Data for Name: finals_alliance_partner; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY finals_alliance_partner (finals_alliance_number, recruit_order, team_number) FROM stdin;
4	2	88
5	2	195
6	2	1519
7	1	1991
8	1	173
9	1	1289
7	2	131
8	2	1468
1	1	121
2	1	839
3	1	175
4	1	20
5	1	230
10	1	555
11	1	181
12	1	1685
9	2	1100
13	1	166
10	2	172
11	2	571
12	2	811
14	1	2079
15	1	350
16	1	1735
13	2	1058
14	2	61
15	2	97
1	2	40
6	1	126
16	2	228
16	3	1761
15	3	190
14	3	562
13	3	2067
12	3	529
11	3	2342
10	3	1153
9	3	467
8	3	319
7	3	125
6	3	1027
5	3	809
2	2	271
4	3	1733
3	2	176
3	3	238
2	3	263
1	3	1474
\.


--
-- Data for Name: game_match; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY game_match (match_level, match_number, match_index, status_id, time_scheduled, winner_color_id) FROM stdin;
0	27	0	4	2008-05-11 09:21:00	1
0	3	0	4	2008-05-10 17:49:00	2
0	5	0	4	2008-05-10 18:03:00	1
0	21	0	4	2008-05-10 20:49:00	1
0	34	0	4	2008-05-11 10:02:00	2
0	42	0	4	2008-05-11 10:47:00	2
0	49	0	4	2008-05-11 11:26:00	1
0	9	0	4	2008-05-10 18:31:00	1
0	36	0	4	2008-05-11 10:14:00	1
0	24	0	4	2008-05-11 09:00:00	1
0	18	0	4	2008-05-10 20:27:00	2
0	16	0	4	2008-05-10 20:13:00	2
0	39	0	4	2008-05-11 10:30:00	1
0	33	0	4	2008-05-11 09:56:00	1
0	4	0	4	2008-05-10 17:57:00	2
0	31	0	4	2008-05-11 09:44:00	1
0	2	0	4	2008-05-10 17:42:00	1
0	8	0	4	2008-05-10 18:24:00	2
0	46	0	4	2008-05-11 11:10:00	2
0	53	0	4	2008-05-11 11:47:00	1
0	28	0	4	2008-05-11 09:27:00	2
0	56	0	4	2008-05-11 12:04:00	1
0	15	0	4	2008-05-10 20:06:00	2
0	22	0	4	2008-05-10 20:56:00	1
0	43	0	4	2008-05-11 10:53:00	2
0	50	0	4	2008-05-11 11:31:00	2
0	25	0	4	2008-05-11 09:09:00	1
0	37	0	4	2008-05-11 10:20:00	2
0	12	0	4	2008-05-10 19:46:00	1
3	2	2	4	2008-05-12 17:27:00	2
3	1	2	4	2008-05-12 17:21:00	1
4	3	0	4	2008-05-12 18:06:00	1
2	3	2	4	2008-05-12 16:15:00	2
2	4	2	4	2008-05-12 16:21:00	2
1	7	2	4	2008-05-12 15:12:00	1
1	8	2	4	2008-05-12 15:19:00	1
1	4	1	4	2008-05-11 14:07:00	1
1	6	2	4	2008-05-12 15:07:00	1
0	19	0	4	2008-05-10 20:34:00	2
0	40	0	4	2008-05-11 10:36:00	1
0	6	0	4	2008-05-10 18:10:00	2
0	11	0	4	2008-05-10 19:40:00	1
0	47	0	4	2008-05-11 11:15:00	2
0	54	0	4	2008-05-11 11:53:00	2
0	29	0	4	2008-05-11 09:33:00	1
0	14	0	4	2008-05-10 19:59:00	1
0	23	0	4	2008-05-10 21:03:00	1
0	44	0	4	2008-05-11 10:58:00	1
0	51	0	4	2008-05-11 11:37:00	1
0	26	0	4	2008-05-11 09:15:00	1
0	38	0	4	2008-05-11 10:25:00	2
1	5	1	4	2008-05-11 14:13:00	1
1	2	1	4	2008-05-11 13:55:00	1
1	2	2	4	2008-05-12 14:43:00	1
1	5	2	4	2008-05-12 15:00:00	1
1	3	1	4	2008-05-11 14:01:00	1
1	1	2	4	2008-05-12 14:37:00	1
1	7	1	4	2008-05-12 14:24:00	1
2	2	3	9	2008-05-12 18:17:00	0
2	1	1	4	2008-05-12 15:31:00	1
2	1	3	9	2008-05-12 18:17:00	0
3	1	3	9	2008-05-12 18:17:00	0
3	2	3	9	2008-05-12 18:17:00	0
3	1	1	4	2008-05-12 17:05:00	1
3	2	1	4	2008-05-12 17:12:00	2
0	13	0	4	2008-05-10 19:53:00	2
0	20	0	4	2008-05-10 20:42:00	0
0	7	0	4	2008-05-10 18:18:00	1
0	41	0	4	2008-05-11 10:42:00	1
0	48	0	4	2008-05-11 11:21:00	2
0	35	0	4	2008-05-11 10:08:00	1
0	10	0	4	2008-05-10 19:33:00	1
0	17	0	4	2008-05-10 20:19:00	1
0	32	0	4	2008-05-11 09:50:00	2
0	55	0	4	2008-05-11 11:59:00	2
0	30	0	4	2008-05-11 09:39:00	2
0	1	0	4	2008-05-10 17:35:00	2
0	45	0	4	2008-05-11 11:04:00	1
0	52	0	4	2008-05-11 11:42:00	2
4	1	0	4	2008-05-12 17:41:00	1
2	2	1	4	2008-05-12 15:37:00	2
1	4	2	4	2008-05-12 14:55:00	1
1	8	1	4	2008-05-12 14:31:00	1
1	1	1	4	2008-05-11 13:49:00	1
1	6	1	4	2008-05-11 14:19:00	2
1	3	2	4	2008-05-12 14:49:00	1
2	4	1	4	2008-05-12 15:56:00	1
2	4	3	4	2008-05-12 16:52:00	2
2	3	3	4	2008-05-12 16:31:00	1
2	3	1	4	2008-05-12 15:44:00	1
2	1	2	4	2008-05-12 16:03:00	1
2	2	2	4	2008-05-12 16:09:00	2
4	2	0	4	2008-05-12 17:52:00	0
\.


--
-- Data for Name: game_state; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY game_state (state_label, description, menu_order, menu_label) FROM stdin;
env	Displays selected per display type.	0	Select by Display Type
empty	All displays show nothing.	1	Empty
q_match	Main display shows match while pit shows rankings and ondeck.	2	Match for Qualifications
q_results	Main display shows results while pit shows rankings and results.	3	Results for Qualifications
e_match	Main display shows match while pit shows ladder and ondeck.	4	Match for Elimination
e_results	Main display shows results while pit shows ladder and results.	5	Results for Elimination
pairings	All displays show just pairings.	6	Pairings
rankings	All displays show just rankings.	7	Rankings
ladder	All displays show just ladder.	8	Ladder
\.


--
-- Data for Name: match_level; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY match_level (match_level, abbreviation, description) FROM stdin;
-1	P	Practice
0	Q	Qualification
1	EF	Eighth-Final
2	QF	Quarter-Final
3	SF	Semi-Final
4	F	Final
\.


--
-- Data for Name: match_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY match_status (status_id, description) FROM stdin;
0	Not scheduled
1	Not Played
2	Rescheduled
3	Played
4	Scored
9	Never
\.


--
-- Data for Name: score_attribute; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY score_attribute (score_attribute_id, name, description) FROM stdin;
1	penalty	
11	robots	
240	auton_bonus	
241	toggle_bonus	
249	far_goal	
250	center_goal	
251	near_goal	
\.


--
-- Data for Name: team; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY team (team_number, info, short_name, nickname, robot_name, location, rookie_year) FROM stdin;
1	The Chrysler Foundation & Oakland Schools Technical Campus Northeast High School	ChryslerOSTCNE	The Juggernauts	Juggy	Pontiac, MI, USA	1997
4	Milken Family Foundation/Raytheon/Roberts Tool Co./The Carcannon Corp & HighTechHigh-LA	HTH-LA Robotics	Team ELEMENT	Fawkes	Lake Balboa, CA, USA	1997
5	Ford FIRST Robotics & Melvindale High School	MHS / Ford Robocards	Robocards	The Guillotine	Melvindale, MI, USA	1998
7	Lockheed Martin/AAI Corporation/BD/Towsontowne Rotary/Tessco & Parkville High School and Center for Mathematics, Science, and Computer Science	Team007	Team007	 	Baltimore, MD, USA	1997
8	General Hydroponics / TIBCO & Palo Alto High School	Paly Robotics	The Vikings	Odin	Palo Alto, CA, USA	1996
9	Roosevelt High School	DANA Corp. & RHS	Roosevelt RoboRiders	 	Chicago, IL, USA	1998
11	Givaudan/John and Margaret Post Foundation/Siemen's & Mt. Olive Robotics Team	Siemens, MORT	MORT	MORT	Flanders, NJ, USA	1997
16	Baxter Healthcare Corp/The Science and Technology Group & Mountain Home High School	Baxter & Mtn Home HS 	Bomb Squad	Two Minute Warning	Mountain Home, AR, USA	1996
20	HostRocket.com/General Electric Volunteers/Rensselaer Polytechnic Institute/Advanced Manufacturing Techniques Inc./Viatalk/Lockheed Martin-KAPL/Bank of America/Trustco Bank & Shenendehowa High School	Hostrocket RPI & Shen	The Rocketeers	The Claw	Clifton Park, NY, USA	1992
21	ASRC/Boeing & Astronaut  & Titusville High School	ComBBAT Team 21	ComBBAT	clueless	Titusville, FL, USA	1998
25	Bristol-Myers Squibb/Infrared Remote Solutions/NASA & North Brunswick Twp. High School	BMS, IRS,NASA & NBTHS	Raider Robotix	Evil Machine 5- Jughandle	North Brunswick, NJ, USA	1997
27	The Chrysler Foundation/Schenck Rotec/Applied Manufacturing Technologies/Guardian Industries/The Clarkston Foundation/Mclaren Health Care/Bosch/Recticel North America Inc. & Clarkston Schools & OSMTech Academy at Clarkston High School	Clarkston OSMTech	Team RUSH	Gold RUSH 	Clarkston, MI, USA	1997
28	PIERSON HIGH SCHOOL	Pierson HS	Mission Impossible	Mission Impossible	Sag Harbor, NY, USA	1996
31	AEP/University of Tulsa & Jenks High School	U of Tulsa & Jenks HS	Prime Movers	 	Jenks, OK, USA	1997
33	The Chrysler Foundation & Notre Dame Preparatory	Chrysler& NDP	Killer Bees	Buzz 13	Auburn Hills, MI, USA	1996
34	Continental Corporation & Limestone County Career Technical Center High School	Rockets	Rockets	Apollo	Athens, AL, USA	1997
39	General Motors Desert Proving Grounds / ITT Technical Institue / Microchip Technology, Inc. / Steve Sanghi Family Foundation / FRC team 991 / O.N. Design / SIMREX Corporation & Highland High School	Hawks	The 39th Aero Squadron	Kenny	Gilbert, AZ, USA	1998
40	intelitek & Trinity High School	Trinity   	Checkmate	Checkmate 4	Manchester, NH, USA	1998
41	ANADIGICS & Watchung Hills Regional High School	Watchung	Warriors	 	Warren, NJ, USA	1997
42	Daniel Webster College/HydroCam Corporation & Alvirne H.S.	AHS/DWC/SAVANT	P.A.R.T.S. (Precision Alvirne Robotics Team Systems)	 	Hudson, NH, USA	1995
45	Delphi/Duke Energy/AndyMark, Inc./Indiana Department of Workforce Development/Ivy Tech Community College & Kokomo Center School Corporation	Delphi & Kokomo HS	TechnoKats Robotics Team	Ham Tray	Kokomo, IN, USA	1992
47	Delphi Corporation / The Chrysler Foundation & Pontiac Central High School	Delphi&Pontiac Centra	Chief Delphi	Chief	Pontiac, MI, USA	1996
48	Delphi Corporation & Warren G. Harding High School	Delphi & Harding HS	Delphi E.L.I.T.E.	Xtremachen 11	Warren, OH, USA	1998
49	Dow Chemical Company/Delphi Automotive Systems/Sign Depot/ALRO Steel & Buena Vista High School	Dow & Buena Vista HS	Robotic Knights	Excalabur	Saginaw, MI, USA	1998
53	Eleanor Roosevelt High School	Robo Raiders	Area 53	 	Greenbelt, MD, USA	1998
56	Ethicon & Bound Brook High School	Ethicon & Bound Brook	Robbe Xtreme	 	Bound Brook, NJ, USA	1997
57	ExxonMobil/Halliburton/Hydraquip/Powell Electric/Walter P. Moore & Booker T. Washington & High School for Engineering Professions	ExxonMobil&HSEP	Leopards	 	Houston, TX, USA	1998
58	Fairchild Semiconductor & South Portland High School	Fairchild & S. Port.	Riot Crew	Red Riot	South Portland, ME, USA	1996
59	Miami Coral Park Sr. High School & MCPHS Engineering Magnet Program	RAMTECH59	Ramtech	NANO	Miami, FL, USA	1997
60	Laron Incorporated / Bearing, Belt, Chain / Brackett Aircraft / Praxair / Chrysler Proving Grounds & KUSD #20 & Kingman Arizona	Ford and Kingman High	Bionic Bulldogs	lappy	Kingman, AZ, USA	1997
61	EMC/Foster-Miller, Inc./LONZA/Pegasus, Inc./Anver Corporation/Lee Company/Allegro Microsystem Inc./Douglas Festival Committee/Blackstone Valley Vocational Regional School District & Blackstone Valley Regional Vocational Technical High School	EMC/Foster-Mill & BVT	Shifters	BVT1	Upton, MA, USA	1995
63	GE Volunteers & McDowell High School & Fairview High School	The Red Barons	The Red Barons	Red Baron	Erie, PA, USA	1997
65	GM Powertrain & Pontiac Northern High School	GMPT&PontiacNorthern	The Huskie Brigade	PowerDawg	Pontiac, MI, USA	1997
66	General Motors Powertrain Corp & Willow Run High School	GM & Willow Run HS	The Flyers	Bandit	Ypsilanti, MI, USA	1998
67	General Motors Milford Proving Ground & Huron Valley Schools	GM&HuronValleySchools	The HOT Team	HOTBOT	Milford, MI, USA	1997
68	General Motors Engineering Structural Development Laboratories/3 Dimensional Services/Easter Seal Society of Michigan & Oakland County Area Schools	Truck Town Thunder	T3	T3	Pontiac, MI, USA	1998
69	P&G & Quincy Public Schools	Gillette & Quincy PS	Team HYPER (Helping Youth Pursue Engineering and Robotics)	HYPER Drive	Quincy, MA, USA	1998
70	General Motors/Chrysler Foundation/Kettering University & Goodrich High School	More Martians	More Martians	My Other Favorite Robot	Goodrich, MI, USA	1998
71	Beatty International/City of Hammond/PEPSI Americas & School City of Hammond	Team Hammond	Team Hammond	The Beast	Hammond, IN, USA	1996
73	Bausch & Lomb Incorporated/Ortho-Clinical Diagnostics, Inc. & Edison School of Engineering & Manufacturing High School	B&L/ O-CD & ET HS	The Visioneers	 	Rochester, NY, USA	1995
74	Haworth Inc. / Tiara Yachts & Holland High School	Haworth/Tiara/HHS	Team C.H.A.O.S.	 	Holland, MI, USA	1995
75	J&J Consumer and Personal Products Worldwide - & Hillsborough High School	J&J & Hillsborough HS	RoboRaiders	RoboRaider	Hillsborough, NJ, USA	1996
79	Honeywell Inc & East Lake High School	Honeywell & ELHS	Team Krunch	Captain Krunch 9	Clearwater, FL, USA	1998
81	Honeywells MICRO SWITCH Division - 11 West Spring Street A2-140 & Freeport High School-Lena Winslo-Aquin High School	 The MetalHeads	MetalHeads	 	Freeport, IL, USA	1994
84	DuPont/NE PA Tech Prep Consortium & Athens Area School District & Northeast Bradford School District & Towanda Area School District & Troy Area School District	DuPont & Towanda	Chuck 84	Chuck	Towanda, PA, USA	1998
85	Herman Miller Foundation / Trans-matic / ODL, INC. / Town & Country Group / ITW  Drawform / Gentex / Midway Machine Techlologies / Plascore / TNT-Holland Motor Freight / Mead Johnson Nutritionals & Zeeland West High School & Zeeland East High School	BOB	B.O.B. (Built on Brains)	BOB	Zeeland, MI, USA	1996
86	JEA/Johnson & Johnson VISTAKON & Stanton College Preparatory School	Team Resistance	Team Resistance	 	Jacksonville, FL, USA	1998
87	Lockheed Martin & Rancocas Valley Regional High School	RVR & Lockheed Martin	Red Devils	Diablo	Mount Holly, NJ, USA	1997
88	DePuy, Codman, DePuy Spine-Johnson & Johnson Companies & Bridgewater Raynam Regional High School	DePuy / BRRHS	TJ(Squared)	 	Bridgewater, MA, USA	1996
93	Plexus Corporation & Appleton Area School District	Plexus & Appleton HS	N.E.W. Apple Corps Robotics	Tobor 11	Appleton, WI, USA	1997
94	Lear Corporation/Minnick Web Services & Southfield High School	Southfield High	The  Technojays	TJ V.10	Southfield, MI, USA	1998
95	Thayer School of Engineering at Dartmouth College / NH Charitable Foundation / Chroma Technology / Cedarwood Technical Service / Hypertherm / Chicago Soft, Ltd / Warrem Loomis / Geokon, Inc. & Lebanon High School	Upper Valley Robotiic	The Grasshoppers	 	Lebanon, NH, USA	1997
97	MIT & Cambridge Rindge and Latin High School & Rindge School of Technical Arts & Chelsea High School	MIT/CRLS/RSTA/CHS	RoboRuminants	 	Cambridge, MA, USA	1996
100	PDI Dreamworks / Woodside High School Foundation / SRI International & Woodside High School & Carlmont High School	Woodside/Carlmont	The WildHats	Ballfrog	Woodside, CA, USA	1998
101	Saint Patrick High School	Saint Patrick	Striker	 	Chicago, IL, USA	1997
102	Ortho Clinical Diagnostics/Verizon Wireless & Somerville High School	Somerville HS	The Gearheads	Firestorm (2007)	Somerville, NJ, USA	1998
103	Amplifier-Research / BAE Systems / Lutron Electronics, Inc / Pathology Group of Doylestown / Glen Magnetics / Harro Hoflinger / Day Tool / Custom Finishers / Hot Chalk / PHTool & Palisades High School	AR/Lutron/CF/BAE	Cybersonics	 	Kintnersville, PA, USA	1997
104	MEI & WCASD High Schools	MEI & WCASD	Team Universal	 	West Chester, PA, USA	1998
107	Metal Flow Corp. & Holland Christian High School	MFC & HCHS	Team R.O.B.O.T.I.C.S.	Flo	Holland, MI, USA	1997
108	Motorola, Inc & Dillard High School & Taravella High School	Motorola&Dllrd&Tarvla	SigmaC@T	Sigmacat	Ft. Lauderdale, FL, USA	1995
111	Motorola & Rolling Meadows High School & Wheeling High School	Motorola & RMHS/WHS	WildStang	WildStang	Schaumburg, IL, USA	1996
114	OppoDigital/Intuitive Surgical/Best Buy/Woz/Los Altos Rotary & Los Altos High School	Los Altos Robotics	Eagle Strike	 	Los Altos, CA, USA	1997
115	Google / BAE SYSTEMS / Monster Cable / Front Office Team & Monta Vista High School	Monta Vista Robotics	MVRT	El Toro	Cupertino, CA, USA	1998
116	NASA Headquarters/CSI & Herndon High School	NASA Hq & Herndon HS	Epsilon Delta	ED v8.0	Herndon, VA, USA	1996
117	Paul Lumber & Supply Company/Vivisimo/Emco/Bug-o & Taylor Alderdice High School	Steel Dragons	The Steel Dragons	 	Pittsburgh, PA, USA	1998
118	NASA-JSC & Clear Creek ISD	NASA-JSC & CCISD	Robonauts	Ballacuda	League City, TX, USA	1997
120	Rockwell Automation/Alcoa Foundation/GrafTech Corporation/SMART Consortium/Jennings Foundation/NASA Glenn Research Center/Greater Cleveland Partnership/Kiwanis Club of Cleveland/Cuyahoga Community College & East Technical High School	Scarabian Knights	Scarabian Knights	 	Cleveland, OH, USA	1995
121	NAVSEA Undersea Warfare Center / EFD Inc.--Nordson / Raytheon / RI Economic Development Corporation / University of Rhode Island & Middletown High School & Portsmouth High School & Tiverton High School & Mount Hope High School & North Kingstown High Schoo	Rhode Warriors/NUWC	Rhode Warriors	Rhode Warrior	Newport County, RI, USA	1996
122	ASME/Canon Virginia Inc./Jefferson Labs/NASA Langley Research Center/Old Point National Bank/Thomas Nelson Community College & New Horizons Regional Education Center 	Nasa/NewHorizons	NASA Knights	Excalibur	Hampton, VA, USA	1997
123	General Motors / Ford Motor / JJ's Design & Engineering / R & B Welding / Coffey Machining Services / Augies / ITT Tech & Hamtramck High School	Hamtramck High	Team - Cosmos	CosmoBot	Hamtramck, MI, USA	1997
125	Northeastern University/Textron Systems & Brookline High School & Catholic Memorial High School	NU-TRONS	NU-TRONS	Roger-Roger	Boston, MA, USA	1998
126	Nypro Inc. & Clinton High School	NYPRO & Clinton HS	Gael Force	Gael Force	Clinton, MA, USA	1992
128	American Electric Power / Grandview Heights Marble Cliff Education Foundation & Grandview Heights High School	AEP/GHMCEF&GHHS	The Botcats	James 'Bot	Grandview Heights, OH, USA	1997
131	Active Shock / BAE SYSTEMS / Rockwell Automation / University of New Hampshire & Central High School	ActiveShockBAECentral	C.H.A.O.S.	CHAOS Returns	Manchester, NH, USA	1995
133	Eagle Industries Inc. & Bonny Eagle High School	Eagle Ind & B.E.H.S.	B.E.R.T	BERT"08"	Standish, ME, USA	1997
134	New Hampshire Technical Institute/AG New England/BAE Systems & Pembroke Academy	Team Discovery	Team Discovery	Pluto	Pembroke, NH, USA	1997
135	Power Lift/Patrick Metals/General Motors/BOSCH/AM General/PHM Community & Penn Robotics	PHM/Power Lift	Penn Robotics	Black Knight	Mishawaka, IN, USA	1998
136	Port Authority of New York and New Jersey / National Starch & Chemical Company & Plainfield High	J&J,Nat'lStrch&PlfdHS	Killer Kardinals	 	Plainfield, NJ, USA	1997
138	Monarch Instrument / BAE Systems / Texas Instruments Incorporated & Souhegan High School	Souhegan/Monarch/BAE/	Entropy	Hummer	Amherst, NH, USA	1996
141	JR Automation Technologies, Inc./Engineered Automation Systems, Inc./Plascore/Horizon Outlet Center & West Ottawa High School	JR Automation & WOHS	WO-BOT	WOBOT	Holland, MI, USA	1995
145	P&GP/TBDI, Inc./Norwich Glass & Norwich HS & Unidilla Valley HS & DCMO BOCES & Sherburne-Earlville HS	P&G & Norwich HS	T-Rx	 	Norwich, NY, USA	1997
148	RackSolutions.com/L-3 Communications Integrated Systems & Greenville High School	RackSolutions/L-3/GHS	Robowranglers	Tumbleweed	Greenville, TX, USA	1992
151	BAE Systems & Nashua High School	BAE SYSTEMS&Nashua HS	Tough Techs	E-wing	Nashua, NH, USA	1995
155	Altuglas International  Arkema Group & Berlin High School & C.M. McGee Middle School	Berlin FIRST	The Technonuts	Nutty IX	Berlin, CT, USA	1994
157	EMC/Intel/Raytheon & Assabet Valley Regional Technical HS	AZTECHS Team 157	AZTECHS 157	 	Marlborough, MA, USA	1995
159	LSI Logic/Agilent Technologies, Inc./AMD & Poudre High School	Alpine Robotics	Alpine Robotics	Hooptie	Fort Collins, CO, USA	1998
166	BAE Systems & Merrimack High School	BAE & Merrimack HS	Chop Shop	Gemini	Merrimack, NH, USA	1995
167	Rockwell Collins  & City High School & West High School	RoboHawks	Children of the Corn	E100	Iowa City, IA, USA	1998
168	North Miami Beach Senior High	M.I.B.	Mechanical Investigation Bureau	Giggidy giggidy	North Miami Beach, FL, USA	1998
171	UW-Platteville & Area Schools	UWP & Area Schools	Extreme Engineering	 	Platteville, WI, USA	1995
172	IDEXX Laboratories/Lanco Assembly Systems & Falmouth High School & Gorham High School	Northern Force #172	Northern Force	FalGor	Gorham/Falmouth, ME, USA	1996
173	CNC Software/JP Fabrication & Repair/Nerac, Inc./United Technologies Research Center & East Hartford High School & Rockville High School & Tolland High School	UTRC,EHHS,RHS,MHS&THS	R.A.G.E. (Robotics & Gadget Engineering)	 	East Hartford, CT, USA	1995
174	UTC Carrier & Liverpool High School	UTC Carrier L-pool HS	Arctic Warriors	Snobot	Liverpool, NY, USA	1998
175	UTC Hamilton Sundstrand Space, Land & Sea & Enrico Fermi High School	UTC/HamSund & FermiHS	Buzz Robotics	 	Enfield, CT, USA	1996
176	UTC Hamilton Sundstrand & Suffield High School & Windsor Locks High School	UTC/HamSund WL & Suff	Aces High	Blackjack	Windsor Locks, CT, USA	1996
177	UTC Power & South Windsor High School	UTC Power & SWHS	Bobcat Robotics	The Ring Wrangler	South Windsor, CT, USA	1995
178	UTC Otis Elevator/ebm-papst Inc./UTC Sikorsky & Farmington High School	Otis/ebmpapst/FHS	2nd Law Enforcers	The Scarab	Farmington, CT, USA	1997
179	United Technologies/EDF/Pratt & Whitney & Inlet Grove High School & Suncoast High School	UTC/PW,EDF & IGHS	The Children of the Swamp	SWAMPTHING	Riviera Beach, FL, USA	1998
180	Krieger Machine / Diagnostic Imaging Services / Toyota of Stuart / Pratt Whitney Rocketdyne & Jensen Beach High School & Martin County High School & South Fork High School & Clark Advanced Learning Center (High School)	Team SPAM	S.P.A.M.	Running With Scissors	Stuart, FL, USA	1998
181	Pratt & Whitney/United Technologies & Hartford Public Schools	UTC-PrtWht&Hartford	Birds Of Prey	BOP	Hartford, CT, USA	1998
184	Ford Motor Company / Fordson High School Alumni Association & Fordson High School & Dearborn Public Schools Education Foundation	Ford & Fordson HS	F.R.E.D.	FRED	Dearborn, MI, USA	1998
188	Scotiabank/Bell Canada/Toronto District School Board & Woburn Collegiate Institute	Woburn Robotics	Blizzard	Blizzard IX	Toronto, ON, Canada	1998
190	WPI & Massachusetts Academy of Math and Science	WPI & Mass Academy	Gompei and the H.E.R.D.	 	Worcester, MA, USA	1992
191	Xerox Corporation & J. C. Wilson Commencement Academy	Xerox Wilson X-CATS	X-CATS	X-Tender	Rochester, NY, USA	1992
192	Roku & Gunn High School	Gunn Robotics Team	GRT	G-Force	Palo Alto, CA, USA	1997
195	Smiths Medical/Tiger Enterprises & Southington High School	Smiths/Southington HS	Cyber Knights	Knightmare 2K7	Southington, CT, USA	1998
201	General Motors Research and Development & Rochester High School	GM R&D & RHS	The FEDS	 	Rochester Hills, MI, USA	1998
203	Campbell's Soup & Camden County Technical High School	Campbell Soup & CCTS	One TUFF Team (Team United for FIRST)	Rocky	Sicklerville, NJ, USA	1998
204	Eastern Regional High School Board of Education /Eastern Educational Foundation/Exxon Mobil & Eastern Camden County Regional High Schools	E.R.V.	Eastern Robotic Vikings	Loki	Voorhees, NJ, USA	1998
207	Walt Disney Imagineering & Centinela Valley Union High School District	METALCRAFTERS	METALCRAFTERS	DuraBot	Hawthorne, CA, USA	1999
211	Eastman Kodak Company & John Marshall High School	Marshall & Kodak	MAK	 	Rochester, NY, USA	1999
213	Keene High First Robotics Club	KHS Dirty Birds	The Dirty Birds	 	Keene, NH, USA	1999
217	Ford Motor Company/FANUC Robotics America/B&K Corporation & Utica Community Schools	Ford/FANUC/B&K & UCS	ThunderChickens	Odin	Sterling Heights, MI, USA	1999
219	Warren Hills Regional High School	Warren Hills Reg HS	Team Impact	 	Washington, NJ, USA	1999
222	Northeast Pennsylvania Tech Prep Consortium / Guyette Communication / Procter and Gamble & Tunkhannock Area High School	P&G/Gyet/NTPC&Tnkhnck	Tigertrons	The Claw	Tunkhannock, PA, USA	1999
223	Johnson & Johnson/State Electric & LakeLand Regional High School & Piscataway Vo-Tech	j&jselectconsmcvt	Xtreme Heat	xtreme heat	Piscataway, NJ, USA	1999
224	MCL Machine - Tools & Piscataway - High School	PHS	The Tribe	The Chief	Piscataway, NJ, USA	1999
226	GM CCRW & Troy High Schools	GM-CCRW &Troy Schools	Hammerheads	Hammerhead 9	Troy, MI, USA	1999
228	Bristol-Myers Squibb & Maloney High School & Platt High School & Wilcox Technical High School	BMS&GUS	Team "Gus"	Gus 9	Meriden, CT, USA	1999
229	Division by Zero - Clarkson SPEED Program & Massena Central High School & Salmon River High School	Clrksn/Mssna/SlmRvr	Division By Zero	Afterthought	Potsdam, NY, USA	1999
230	UTC Sikorsky/Pitney Bowes/OEM Controls/Unilever & Shelton High School	UTC/PB/OEM/UNLVR/SHS	Gaelhawks	 	Shelton, CT, USA	1999
231	Lyondell Chemical / Oceaneering Space Systems / United Space Alliance & Pasadena ISD	 Lyondell/Oceaneering	High Voltage	Roboticus	Pasadena, TX, USA	1998
233	NASA @Kennedy Space Center/Bradley Investments, LLC/GovConnection, Inc & Rockledge High School & Cocoa Beach High School & Viera High School & School Board of Brevard County	The Pink Team	The Pink Team	Roccobot	Rockledge/Cocoa Beach/Viera, FL, USA	1999
234	Allison Transmission / Rolls-Royce / Our Proud Grandmas & Perry Meridian High School	Team Cyber Blue	Cyber Blue	Ritchie X	Indianapolis, IN, USA	1999
236	Dominion Millstone Power Station & Lyme-Old Lyme High School	Millstone/LOLHS	Techno-Ticks	Tick 10	Old Lyme, CT, USA	1999
237	Siemon Company/TUV Rheinland/Trumpf & Watertown High School	Sie-H2O-Bots Siehobot	T.R.I.B.E.	Pal V2008	Watertown, CT, USA	1999
238	Texas Instruments / BAE Systems & Manchester Memorial High School	MMHS	Cruisin Crusaders	BAE-TI	Manchester, NH, USA	1999
240	DTE ENERGY / Jefferson Adult Boosters / ITT Tech / Ford Motor Co / Education Plus Credit Union / UWUA Local 223 / UAW Local 14 / Mr Leski / Monroe Aluminum & Jefferson High School Robotics	Jefferson High School	Tempest	 	Monroe, MI, USA	1999
241	BAE Systems / Tire Warehouse & Pinkerton Academy	Astros	Astros	Astro	Derry, NH, USA	1999
245	GM Finance Staff / Continental & Rochester Adams High School	GM/Continental/AdamsH	Adambots	 	Rochester Hills, MI, USA	1999
246	Boston University & Boston University Academy	Boston University	Overclocked	RoboRhett	Boston, MA, USA	1999
247	Terminal Supply / Azure Dynamics / Production Tool Supply / Ford Motor Company & Berkley High School	TS/Ford/PTS/BHS	Da Bears	 	Berkley, MI, USA	1999
250	Capital Region Robotics Team / GE Volunteers / GlobalSpec / RPI & Colonie Central High School	GE Globalspec Colonie	Dynamos	 	Colonie, NY, USA	1999
253	Autodesk, Inc. / Xilinx / BAE Systems & Mills High School	Mills Robotics Team	MRT	 	Millbrae, CA, USA	1999
254	NASA Ames Research Center / Pacific Coast Metal, INC. & Bellarmine College Prep High School	NASA Ames Robotics	Cheesy Poofs	Raptor	San Jose, CA, USA	1999
256	BAE SYSTEMS / Willow Glen Foundation / Google Inc. / Lockheed Martin / B3 Advanced Communication Systems / ALTA Design and Manufacturing Inc / Peak Plastics / Hijinx Comics & Willow Glen High School	Willow Glen High	Rams	Rambo IX	San Jose, CA, USA	1999
263	Retlif Testing Laboratories / CHECK-MATE INDUSTRIES, INC. / Sachem Robotics Team 263 Booster Club & Sachem Central School District	Sachem Aftershock	Sachem Aftershock	Phoenix	Farmingville, NY, USA	1999
269	Pentair / ITT / GE Volunteers & Oconomowoc High School	GE/ITT/&Oconomowoc Hi	CooneyTech	Bandit	Oconomowoc, WI, USA	1999
270	Deer Park High School & Deer Park School District	DPHS Falcon-X	Falcons	 	Deer Park, NY, USA	1999
271	AUDIBLE.COM/BAE Systems/Verizon/Bad Boys From Bay Shore Ltd. & Bay Shore High School	Mechanical Marauders	Mechanical Marauders	 	Bay Shore, NY, USA	1999
272	Visteon Automotive Systems/TPS Golf -- AimPoint Technologies/Delaware Valley Industrial Resource Center/Montgomery County Community College & Lansdale Catholic High School	Visteon/TPS/MCCC&LCHS	Cyber-Crusaders	Horsepower	Lansdale, PA, USA	1998
276	Youngstown State University/Star Supply & Chaney Robotics Team	YCS - Chaney 	Mad Cow Engineers	 	Youngstown, OH, USA	1999
279	Dana Corporation & Rogers High School & Toledo Technology Academy High School	Dana, TTA, Rogers HS	Tech Fusion	 	Ottawa Lake, MI, USA	1999
280	Ford Motor Company / ITT Technical Institute / Wade Trim & Associates & Taylor Career Center & Kennedy H.S. & Truman H.S. & Gabriel Richard H.S.	Ford &Taylor Schools	TNT	"Predator"	Taylor, MI, USA	1999
281	Michelin/Greenville Tech & 4-H & GTCHS & Christ Church Episcipal & JL Mann & Southside	Michelin/4H/GTC	Team E.T.	E.T.4	Greenville, SC, USA	1999
284	Elk Lake HS & SCCTC	Elk Lake/SCCTC	The Crew	 	Dimock, PA, USA	1999
287	Brookhaven National Lab & William Floyd HS	BNL/Battelle/Wm.Floyd	Floyd	 	Mastic Beach, NY, USA	1999
288	H.S. Die & Engineering / Roman Manufacturing / D&M Metals & Grandville High School	The RoboDawgs	The RoboDawgs	RD10	Grandville, MI, USA	1999
291	GE Volunteers & Erie School District & Villa Maria Academy	GE/Erie Schools/Villa	CIA - Creativity In Action	Lake Effect X	Erie, PA, USA	1999
292	The Chrysler Foundation / Indiana Department of Workforce Development / The Delphi Foundation & Western High School	ChryslerWesternDelphi	PantherTech	Sgt. Joe	Russiaville, IN, USA	1999
293	Bristol-Myers Squibb/MEI & Hopewell Valley Central High School	BMS/Hopewell Valley	Team S.P.I.K.E.	SPIKE	Pennington, NJ, USA	1999
294	Northrop Grumman & Mira Costa High School & Redondo Union High School	Beach Cities Robotics	BCR	Rip City Ape	Redondo Beach, CA, USA	1999
295	NEC / Sierra College / Intel / Pasco Scientific / Harris & Bruno International & Granite Bay High School & Whitney High School & Oakmont High School	South Placer Robotics	Renevatio	Run-Away-Runway	Granite Bay, CA, USA	1999
296	Arial Foundation / Bombardier Aerospace / Ernst &Young / Dorel / Tactico / Proden / Mad Science & Loyola High School	Arial & Loyola High	Northern Knights	Northern Knight	Montreal, QC, Canada	1999
302	The Chrysler Foundation & Lake Orion High School	Team 302	The Dragons	 	Lake Orion, MI, USA	1999
303	Pressure Tube Manufacturing & Bridgewater Raritan Regional High School	PTM Panther Robotics	Panther Robotics	 	Bridgewater, NJ, USA	1999
304	Wellspring & George Washington High School & School District of Philadelphia	Robo Griffins	GWHS Robo Griffins	RoboGriff	Philadelphia, PA, USA	1999
306	Corry Industrial Roundtable / Foamex / Johnson Books & Stuff / Corry Contract Inc / Bova's Hardware / Corry Lumber Co. / D&E Machining Inc.  / State Farm Insurance / Tonnard Mfg. Corp. / Viking Plastics Inc. & Corry Area High School	Corry Robotics Team	CRT	 	Corry, PA, USA	1999
308	Tecla Company, Inc./TRW & Walled Lake Schools	TRW&Walled Lake	The Monsters	Audrey 9	Farmington Hills, MI, USA	1999
312	Baxter Healthcare of Tampa Bay & Lakewood High School	Baxter/Lkwd HS	HeatWave	Fire Starter 9	St. Petersburg, FL, USA	1999
313	Ford Motor Company/ITT Technical Institute & Wayne-Westland Schools	WayneWestland Robotic	The Bionic Union	Sarbez 8	Wayne, MI, USA	1999
314	A Frame Awards, Inc./Carman-Ainsworth Education Foundation/Delphi/GM Manufacturing/Mid-Michigan Robotics Alliance/New Technologies, Inc./PENTECH/Rowe Engineering/UAW & Carman-Ainsworth High School	GM/CAHS	The Megatron Oracles	Big MO	Flint, MI, USA	1999
316	BE&K/DuPont CCRE/Dupont Chambers Works/DuPont Engineering/PSEG/Salem County Community College/South Jersey Robotics, Inc & Salem County High Schools	South Jersey Robotics	LuNaTeCs	Super Sam	Carneys Point, NJ, USA	1999
319	BAE Systems/Liberty Machine/Winnipesauke Driving School & Prospect Mountain High School	BOB	Big Bad Bob	Big Bad Bob	Alton, NH, USA	1999
321	Drexel University & SDP-Central High School	Central High&Drexel U	RoboLancers	Hogmanay	Philadelphia, PA, USA	1999
322	General Motors Powertrain/University of Michigan - Flint/Landaal Packaging & Flint Community Schools	GMPT/ UofM/ Flint HS	Team F.I.R.E. 	Fire Hazard	Flint, MI, USA	1999
326	GM Powertrain & Romulus Community Schools	GM & Romulus HS	Xtreme Eagles	 	Romulus, MI, USA	1999
329	Motorola & Patchogue-Medford High School	Pat-Med Robotics	Raiders	Voj-a-nator	Medford, NY, USA	1999
330	J&F Machine / NASA-JPL / NGC / Raytheon & Hope Chapel Academy High School	Beach Bots	Beach Bots	Beach Bot	Hermosa Beach, CA, USA	1999
333	Credit Suisse/MTA/DHACNY/Cool Jewels/East Coast Appraisal & Canarsie HS & John Dewey H S	CAN-DEW	 CAN-DEW	Robo Chief	Brooklyn, NY, USA	1999
334	Royal King, Inc / MTA-NYC Transit Authority / Argent Assoc., INC. / Brooklyn Tech.Alumni Foundation, Inc. / ConEd & Brooklyn Tech. H.S.	Tech.	Techengineers	Charlie	Brooklyn, NY, USA	1999
335	Con Edison/Ackman Family Foundation/Goldman Sachs/VER Tech Elevator/MTA-NYC Transit Authority/City Tech/Polytech/Dubno Brothers & Science Skills Center HS	Skillz Tech	Skillz Tech Royalty	The GnatoBot	Brooklyn, NY, USA	1999
337	American Electric Power/National Armiture/Ralph R Willis Career-Technical Center/WV Department of Adult-Technical Programs/Mayo Manufacturing & Logan County Schools	AEP/Coal/RWC&TC/LCS	Hard Working Hard Hats	STAR-bot 	Logan, WV, USA	2000
339	New World Associates/Battelle Memorial Institute/Stafford County Economic Development Authority & Commonwealth Governor's School	CGS-NWA-Stafford EDA	Kilroy	Kilroy	Stafford, VA, USA	2000
340	Bausch & Lomb Incorporated & Churchville-Chili High School	Bausch & Lomb & CCHS	G.R.R. (Greater Rochester Robotics)	Roxanne	Churchville, NY, USA	2000
341	Rohm & Haas Company / BAE Systems / Johnson & Johnson PRD / Siemens Corporation / DeVry University / PJM Interconnection & Wissahickon High School	RH/BAE/JJ/SEA/DU/WHS	Miss Daisy	Miss Daisy	Ambler, PA, USA	2000
342	Dorchester County Council/Robert Bosch Corporation/Trident Technical College/Fab Tech/Bosch Rexroth & Summerville High School & Fort Dorchester High School & Woodland High School  & Dorchester County Career School & Northside Christian School High School	SHS/FDHS/WHS/TTC	Burning Magnetos	Burnie 9	North Charleston, SC, USA	2000
343	School District of Oconee County / Square D Company / Duke Energy / Itron, Inc. & F.P Hamilton Career Center & Seneca High School & Walhalla High School & West-Oak High School & Tamassee-Salem High School	Metal-In-Motion	Metal-In-Motion	 	Seneca, SC, USA	2000
346	Alstom Power / Dupont / Computer Resource Team, Inc / Peer Consortium at JTCC & Lloyd C. Bird Pre-Engineering Progam	LC Bird High School	RoboHawks	 	Chesterfield, VA, USA	2000
348	Mass Bay Engineering/PIAB & Norwell High School	PIAB,MBE & Norwell HS	Norwell Robotics	 	Norwell, MA, USA	2000
350	Analog Devices/Ward Fabrication/Raytheon & Timberlane Regional High School	Timberlane 	Timberlane Robotics	Technotus	Plaistow, NH, USA	2000
352	Carle Place High School	Carle Place H.S.	The Green Machine	 	Carle Place, NY, USA	2000
353	Trio Hardware & Plainview-Old Bethpage Central School District	POBCSD/TRIO POBOTS	POBOTS	 	Plainview, NY, USA	2000
354	Bloomberg/New York City College of Technology/Verizon Corporation & George Westinghouse High School	Bloom/NYCCT/Ver/West	G-House Pirates	FIRST Mate	Brooklyn, NY, USA	2000
357	Sapsis Rigging Inc. & Upper Darby High School	Upper Darby HS	Royal Assault	Jester	Drexel Hill, PA, USA	2000
358	Festo / Fonar & Hauppauge High School	Festo/Fonar-Hauppauge	Robotic Eagles	Fang	Hauppauge, NY, USA	2000
359	University of Hawaii Physics / NAVSEA Detachment Pacific / The Urata Corporation / NASA Ames Research Center / Video Dreams Inc. / McInerny Foundation / Hawaii Web Design, Inc. / R.M. Towill Corp. / Castle & Cooke, Inc. Dole Plantation / Waialua Federal C	Na Keiki O Ka Wa Hope	Hawaiian Kids	Poi Pounder VIII	Waialua, HI, USA	2000
360	Fikret Yuksel Foundation/Parents of Bellarmine Robotics & Bellarmine Prep	BPSEP	The Revolution	Rainmaker 9	Tacoma, WA, USA	2000
362	American Elements/Northrop Grumman/Raytheon/Gensler & The Archer School for Girls	Raytheon/Archer	The Muses	 	Los Angeles, CA, USA	2000
364	NASA/SAIC/Seemann Composites/DuPont Delisle/Knesal Engineering Services, INC. & Gulfport High School Technology Center	Team Fusion	Team Fusion	Gabelstapler	Gulfport, MS, USA	2000
365	DuPont Engineering/DuPont CCRE/First State Robotics & MOE Robotics Group	DuPont Engr MOE	Miracle Workerz	MOE	Wilmington, DE, USA	2000
368	HECO / BAE SYSTEMS & McKinley High School	HECO / BAE / McKinley	TKM.368 (Team Kika Mana)	Hawaiian Electric	Honolulu, HI, USA	2000
369	BEZOS Family Foundation & William E. Grady High School	Grady Tech	RoboBob 2.0	 	Brooklyn, NY, USA	2000
371	Richmond County Savings Foundation/Port Authority of New York and New Jersey/Bloomberg/Con Edison/Plumbers Local Union #1 & Curtis High School	RCSF & CHS	Cyber Warriors	alexia	Staten Island, NY, USA	2000
372	Electroimpact / SAIC / Rane Corporation / Olympic Hospitalist Physicians, PS & Kamiak High School	Kamiak	I.Q.	Artificial Insanity	Mukilteo, WA, USA	2000
375	Staten Island Foundation/Port Authority of New York and New Jersey/Richmond County  Foundation/Verizon/Con Edison & Staten Island Technical High School	SI Tech	Robotic Plague	AMY	Staten Island, NY, USA	2000
378	Delphi Thermal/UAW 686 & Newfane High School	Delphi/UAW/Newfane HS	The Circuit Stompers	High Five	Newfane, NY, USA	2000
379	Girard High School	Girard High School	Robocats	STEM CAT 	Girard, OH, USA	2000
380	Consolidated Edison/Pershing Square. & Samuel Gompers High School	Gompers	G-FORCE	 	Bronx, NY, USA	2000
381	Bristol Myers Squibb & Trenton Central High School	Trenton/BMS	Tornadoes	 	Trenton, NJ, USA	2000
383	Altus / Banco do Brasil / Dorvo Maquinas / Metalaser & Província de São Pedro High School	Brazilian Machine	Brazilian Machine	Brazilian Buddy IX	Porto Alegre, RS, Brazil	2000
384	GE Volunteers/Qimonda of Richmond/Flexicell/ShowBest Fixture Corp./Specialty's Our Name/ChemTreat/Sams Club/CAPER/ITT Technical Institute & Henrico Co. Education Foundation & Tucker High School	GE/Qim/SBFC/SON/JRT	Sparky 384	Sparky 8	Richmond, VA, USA	2000
386	Harris Corp / Rockwell Collins / EDAK / ACE / Jackson and Tull / Compass Solutions / Ascent Media / FIT & School Board of Brevard County & Melbourne HS & Satellite HS & West Shore Jr & Sr High School & Home Schooled	Team Voltage	Team Voltage	Ty-Rap VIII	Melbourne, FL, USA	2000
388	NASA / Terra Tech Engineering & Grundy High School & Buchanan County Career & Technology Center High School	Grundy HS	Maximum Oz	Maximum Oz 4.0	Grundy, VA, USA	2000
393	Indiana Department of Workforce Development/Rolls-Royce Corp./Keihin IPT Mfg., Inc./Triumph Fabrications & Morristown High School	Full Metal Jackets 	FMJ 393	Shark, The Single Man	Morristown, IN, USA	2000
395	The McGraw-Hill Companies/Columbia University & Morris High School Campus  & Professional Children's School & Fieldston	McGraw/&Morris Campus	2 TrainRobotics	 	Bronx, NY, USA	2000
397	Delphi /Unigraphics & Flint Southwestern Academy & Bendle High School	Delphi/UG/FSWA/Bendle	Knight Riders	 	Flint, MI, USA	2000
399	HR Textron/Northrop Grumman/Lockheed Martin/ITEA/NASA Dryden Flight Research & Antelope Valley Union High School District & Lancaster High School	Eagle Robotics	Eagle Robotics	The Phantom	Lancaster, CA, USA	2000
401	Virginia Tech School of Education & Montgomery County Public Schools	VT/MCPS	Hokie Guard	NSBI	Christiansburg, VA, USA	2000
405	Qimonda & Richmond Community High School	 RCHS	The Chameleons	 	Richmond, VA, USA	2000
406	Chrysler Foundation -Mack Ave Engine plant & Mumford High School 	Mumford/DCX Mack Ave.	Mumford Chargers	 	Detroit, MI, USA	2000
408	Blanche Ely High School & DeVry University	BlancheElyHS	The RoboTicks	 	Pompano Beach, FL, USA	2000
414	Capital Area Partners for Educational Reform/Farmer Machine Company/Henrico Education Foundation/ITT Technical Institute/The Jackson Foundation & Hermitage Technical Center	Hermitage Tech Center	Smokie and the Bandits	Smokie	Richmond, VA, USA	2000
417	Hewlett Packard / Brookhaven National Laboratory & Mount Sinai High School	Mt. Sinai	Stangbot	 	Mt. Sinai, NY, USA	2000
418	National Instruments / BAE SYSTEMS INC. / LASA Robotics Association & Liberal Arts & Science Academy High School	LASA	Purple Haze	ZePHyr	Austin, TX, USA	2000
421	Electrical Union/Argosy Foundation/Automated Data Processing/Iron Workers/Plumbers Union & Alfred E. Smith H.S.	Smith Warriors	The Warriors	 	Bronx, NY, USA	2000
422	New Market Corporation/Dupont Advanced Fiber Systems & Maggie L. Walker Governor's School	MLWGS / NewMarket	Mech Tech Dragons	 	Richmond, VA, USA	2000
423	Cheltenham High School & Eastern Center for Arts & Technology High School & Springfield High School	Mechanical Mayhem	SEC	 	Willow Grove, PA, USA	2000
424	Bausch & Lomb Incorporated & Churchville-Chili High School	Bausch & Lomb & CCHS	GRR (Greater Rochester Robotics)	dawn	Churchville, NY, USA	2000
425	DRS Technologies / Taek Force, Inc. / HMB Steel Corp. / LLC GovConnection, Inc & Eau Gallie High School & Brevard Public Schools & West Shore Jr Sr High School	Team Spartans	Spartans	Sparticus	Melbourne, FL, USA	2000
433	Mount St. Joseph Academy & Aggrey Memorial AME Zion High School (GHANA)	MSJA Firebirds	Firebirds	Fire, DUCK! 	Flourtown, PA, USA	2000
434	KaDa Medical Instruments / Houston Robotics / ITT Tech / CenterPoint Energy / Fluor & Hightower High School & Fort Bend ISD	HHS / Fort Bend ISD	Kracken	Kracken	Missouri City, TX, USA	2000
435	EMC Corporation / Hunter Industries, Inc. / NCSU College of Engineering & Southeast Raleigh Magnet High School	SRMHS Robodogs	Robodogs	RoboDog	Raleigh, NC, USA	2000
437	Houston Robotics & Richardson High School	RHS Robotics	The Eagles	 	Richardson, TX, USA	2000
440	DTE ENERGY / ASAP Property Management Inc. / Jublee Housing Initiave & Community Devel, Corp / ITT Technical Institute / NASA / Ford Motor Company / R.L.Schmitt Co. Inc & Detroit Public Schools & Cody HS High School	Cody HS	The Suspects	comet	Detroit, MI, USA	2000
441	ITT Technical Institue / ASME / Houston Robotics & Reagan High School	DEVIL DOGS	DEVIL DOGS	Thor IV	Houston, TX, USA	2000
442	AUVSI / ASMDCA & Lee High School & New Century Technology High School	AA NCLC	Redstone Robotics	Da Bomb	Huntsville, AL, USA	2000
443	University of Denver & Standing Ovations for All & Ricks Center Middle School	DU Freelance	Freelance Robotics	LanceABot	Denver, CO, USA	2000
444	Lockheed Martin IS&S/Hess Corporation/School District of Philadelphia & MASTBAUM A.V.T.S. PANTHERS	MASTBAUM A.V.T.S.	Philly's Extreme Team	 	Philadelphia, PA, USA	2000
447	DRN Machine & Madison County High Schools	MadCo Partnership	Team Roboto	 	Anderson, IN, USA	2000
448	Cranbrook Kingswood School	Cranbrook	Crandroids	 	Bloomfield Hills, MI, USA	2000
449	BAE Systems & Montgomery Blair High School Robot Project	Blair Robot Project	Wrenchman	The Wrenchman	Silver Spring, MD, USA	2000
451	Dana Corporation & Sylvania City Schools	DANA/The Cat Attack	The Cat Attack	 	Sylvania, OH, USA	2000
453	Paragon Technologies & F.V. Pankow Center & L'Anse Creuse Public Schools	Paragon Tech & Pankow	G.E.A.R.S.	 	Clinton Township, MI, USA	2000
456	ERDC & Vicksburg-Warren Schools	Warren Central	Vikings	Viking IX	Vicksburg, MS, USA	2000
457	Rackspace Managed Hosting / General Dynamics Information Technology / Lockheed Martin Kelly Aviation Center / Valero Energy Corporation / Toyota Motor Manufacturing, Texas, Inc. / EG&G Logistics / Carter Burgess Engineers / Pape Dawson Engineers / Fernand	RACKSPACE GDIT & SSHS	Grease Monkeys	Chango	San Antonio, TX, USA	2000
461	Purdue FIRST Programs/Caterpillar & West Lafayette Jr-Sr High School	Boiler Invasion	Westside Boiler Invasion	Rowdy Pete 	West Lafayette, IN, USA	2000
462	NASA/Delphi Automotive & Provine High School Robotic Team	Delphi & Provine HS	The Rambunctious Rams	 	Jackson, MS, USA	2000
467	Intel & Shrewsbury High School	Intel & Shrewsbury	Duct Tape Bandits	 	Shrewsbury, MA, USA	2000
468	Android Industries / MAIN Mfg. / ITT Tech / Baker College & Flushing High School	Baker Explorers	Baker's Secret	Aftershock	Flint, MI, USA	2000
469	AVL / AI / Kostal / NACHI Robotics / Norgren / Eco-Bat / Quexco / Maher Construction / EnCel / Costco Wholesale / AIN Plastics / Ka-Wood Gear / Sonic EDM / Gorman's Gallery / Specialty Fabrication / Lawrence Technological University & International Academ	AVL, Ai & IA	Las Guerrillas	Cornelius VIII	Bloomfield Hills, MI, USA	2000
470	Hyundai-Kia America Technical Center, Inc. / Ypsilanti Public Schools Foundation / ITT Technical Institute & Ypsilanti High School	Ypsi High Robotics	Alpha Omega Robotics	Full Throttle	Ypsilanti, MI, USA	2000
473	NASA/Montana Space Grant Consortium & Corvallis High School	MSGC & Corvallis MT	Montana State Robotics Team	Wylerd	Corvallis, MT, USA	2000
476	Precision Tool & Die/ConocoPhillips/Cookshack/Mid-America Door/Oklahoma State University College of Engineering (CEAT) & Ponca City High School	Conoco/PoncaCity HS	Wildcats	Manny	Ponca City, OK, USA	2000
484	Lockheed-Martin/GE Volunteers & Haverford High School	Lockheed/GE/Haverford	The Pit Crew	Stealth Racer	Havertown, PA, USA	2000
486	Kimberly-Clark Corp. / 3M Dyneon / McNeil Consumer and Specialty Pharmaceuticals & Strath Haven HS	Strath Haven HS	Positronic Panthers	 	Wallingford, PA, USA	2000
488	Bezos Family Foundation/Microsoft/Boeing/Ameriprise Financial & Franklin High School	Team XBot	Team XBot	X8: The Ocho	Seattle, WA, USA	2000
492	The International School PTSA / Rottler Manufacturing	Titan Robotics	Titan Robotics Club	Mnemosyne	Bellevue, WA, USA	2001
494	Chrysler Foundation/General Motors & Goodrich High School	Martians	Martians	My Favorite Robot	Goodrich, MI, USA	2001
496	Port Jefferson Robotics Club	Port Jefferson HS	Powerhouse	 	Port Jefferson, NY, USA	2001
498	Honeywell International/Vitron Manufacturing/C & H Refrigeration/Kathy's Music & Cactus High School	Cobra Commanders	Cobra Commanders	 	Glendale, AZ, USA	2001
499	ITT Tech/Kelly Aviation Lockheed Martin/ASME - International Petroleum Technology Institute/MTC Technologies/Home  Depot & Edgewood ISD	Toltechs	Toltechs	 	San Antonio, TX, USA	2001
500	U.S. Coast Guard Academy, USCG Foundation, USCG Alumni Association & Local Supporters & Grosso Regional Vocational Technical High School & New London Magnet High School & Westerly, RI  High School & Local Home School Community	CGA Team USA	Team 500/Team USA	Objie 10	New London, CT, USA	2001
501	FCI Burndy Products/Dynamic Network Services/HomeSeer Technologies & Manchester High School WEST	FCI/DynSyn/HomeS/West	The PowerKnights	The Power Knight	Manchester, NH, USA	2001
503	Intier Automotive & Novi High School	Intier/Novi	Frog Force	Pulverizing Patel	Novi, MI, USA	2001
509	Electrocraft/Insight Technology, Inc. & Bedford High School	Bedford High School	Red Storm	 	Bedford, NH, USA	2001
514	G & L Precision Corp/Miller Place PTO/MP Robotics Boosters & Miller Place Schools	Miller Place Robotics	Entropy	Willy the Aluminum Mammoth	Miller Place, NY, USA	2001
515	GM CCRW & Osborn High School	Osborn/GM CRW	TechnoKnights	Oz	Detroit, MI, USA	2001
518	GRAPCEP Davenport/GUMBO/Steelcase/Ferris State University/IST & Ottawa Hills High School	Steelcase-FSU-IST	Blue Steel	 	Grand Rapids, MI, USA	2001
519	General Motors Foundation GM CCRW / Harvey Industries / ITT Technical Institute & Golightly Career and Technical Center & Pershing High School	GM/ITT& Golightly	Robo Masters	 	Detroit, MI, USA	2001
522	New York Container Terminal / Richmond County Savings Foundation / The Port Authority of NY & NJ / SI Bank & Trust Foundation / Con Edison / Verizon Foundation / Northfield Savings Bank & Mckee Vocational High School	McKee Voc. H.S.	ROBO WIZARDS	Miss Ella	Staten Island, NY, USA	2001
525	DISTek Integration, Inc / Rockwell Collins / John Deere Waterloo Operations / NCK Software / UNI College of Natural Sciences and Iowa Space Grant Consortium / Eason Grant & Cedar Falls High School	Cedar Falls HS	Swart-Dogs	 	Cedar Falls, IA, USA	2001
527	Plainedge High School Red Dragons	Plainedge Red Dragons	Dragons	 	No. Massapequa, NY, USA	2001
529	Mansfield High School	Mansfield Robotics	The Mansfield Hornets	 	Mansfield, MA, USA	2001
533	ITT Industries / L3 Communications Narda Microwave & Lindenhurst Senior High School	PSICOTICS	PSICOTICS	the Drifter	Lindenhurst, NY, USA	2001
537	Rockwell Automation/GE Volunteers & Hamilton High School 	GE, Rockwell, & HHS	Charger Robotics	 	Sussex, WI, USA	2001
538	Arab High School	Arab HS	Dragon Slayers	 	Arab, AL, USA	2001
539	UNITE with Virgil Brackins & Trinity Episcopal School	Titans	Titans	 	Richmond, VA, USA	2001
540	The Randolph & Susan Reynolds Foundation / ShowBest Fixture Inc. / Henrico Education Foundation, Inc. / Piedmont Metal Fabricators Inc. / CAPER of Richmond, VA. / TKL / ITT Technical Institute & Mills Godwin High School	Godwin H. S. Robotics	TALON 540	TALON	Richmond, VA, USA	2001
545	Island Trees High School	ITHS	ROBO-DAWGS	 	Levittown, NY, USA	2001
547	AUVSI / F.E.A.R Foundation & Lincoln Co. High School Falcon Engineering And Robotics	F.E.A.R & LCHS	F.E.A.R.	Toro	Fayetteville, TN, USA	2001
548	General Motors Corporation / Shiloh Industries & Northville High School	Northville H.S.	Robostangs	 	Northville, MI, USA	2001
549	Mar-Lee Companies / Raytheon / Steel Fab inc / Solidus Technical Solutions & Leominster High School	Bose/Leominster	DevilDawgs	LEW	Leominster, MA, USA	2001
550	Warren County Technical School	NanKnights	NanKnights	 	Washington, NJ, USA	2001
554	Procter & Gamble & Highlands High School	P&G/Highlands	Highlanders	William Wallace	Ft. Thomas, KY, USA	2001
555	Judy and Josh Weston & Montclair Board of Education	Montclair Robotics	Montclair Robotics	The Partially Robotic Bulldog of Death, Destruction, & Gracious 	Montclair, NJ, USA	2001
558	Yale University/United Illuminating & H.R. Career H.S.	Career High School	RoboSquad	Phoenix	New Haven, CT, USA	2001
562	Montachusett Regional Vocational Technical School	Monty Tech	SPARK - Students Pursuing Applied Robotics Knowledge	 	Fitchburg, MA, USA	2001
563	BOK Tech High School & Sunrise Foundation	Bok Thrashers	Thrashers	Steelrelacus	Phila, PA, USA	2001
564	Longwood High School	LONGWOODCSD	Digital Impact	 	Middle Island, NY, USA	2001
568	AREA/BP & Dimond High	Dimond Alaska	Nerds of the North	Absolute Zero Mark VII	Anchorage, AK, USA	2001
569	B&G Deli  Caterers / Sunrise of East Meadow / Stock Drive Products-Sterling Instrument / East Meadow Kiwanis / East Meadow Chamber of Commerce / Heads Up Construction & W.T. Clarke H.S.	Rams	Flounders	 	Westbury, NY, USA	2001
570	Glen Cove High School	GC HS Team Phoenix	Team Phoenix	 	Glen Cove, NY, USA	2001
571	UTC Otis Elevator/Dymotek, Inc./Coherent/Design Innovation, Inc./JAZ Industries, Inc./The Loomis Chaffee School & Windsor High School & Metropolitan Learning Center	UTC Team Paragon	Team Paragon	Renegade	Windsor, CT, USA	2001
573	The Chrysler Foundation & Brother Rice High School & Marian High School	BRMarianMechWarriors	Mech Warriors	The Raptor	Bloomfield Hills, MI, USA	2001
578	Gleason Works & Fairport High School	Blue Lightning	Blue Lightning	Marvin	Fairport, NY, USA	2001
580	IMS & Campbell Hall School	IMS & Campbell Hall	RoboticVikes	S.T.U.	North Hollywood, CA, USA	2001
581	BAE Systems & San Jose High Academy	SJHA	Bulldog Robotics	Bulldog 8	San Jose, CA, USA	2001
585	NASA/Northrop-Grumman/Arcata Associates, Inc. & Tehachapi High School	THS/NASA/Northrop	Cyber Penguins	Robo Tux 2.0	Tehachapi, CA, USA	2001
587	Duke University/J W Faircloth and Son/Microsoft & Orange High School & Cedar Ridge High School	OHS/CRHS//Faircloth	Hedgehogs	OCCAM VIII:Yottabot	Hillsborough, NC, USA	2001
589	NASA JPL & Crescenta Valley High School	CVHS Robotics	FalKON	 	La Crescenta, CA, USA	2001
590	NASA/Stennis Space Center & Choctaw Central High School	Chahta Warriors	Chahta Warriors	Tushka VIII	Choctaw, MS, USA	2001
597	USC-MESA / Zoe & Steven Green / Dr. Eileen Goodes / Iridescent / El Camino College / Southern Christian Leadership Council / Avis Rent  a Car / Los Angeles Trade Tech / Kissick Family Foundation / Raytheon / L. A. City Councilman Bernard C. Parks / Teledy	Foshay/USC-MESA/NASA	Wolverines	Wolvie Neptune	Los Angeles, CA, USA	2001
599	California State University, Northridge & Granada Hills Charter High School	GHCHS  Robodox	Robodox	Physician	Granada Hills, CA, USA	2001
600	Central Virginia Community College/AREVA/Region 2000 Technology Council & Lynchburg City Schools	Region 2000 Schools	RamRod Robotics	RamRod 08	Lynchburg, VA, USA	2001
604	BAE SYSTEMS/Bunny Dawson/Google/IBM/Siemens/Sierra Radio Systems & Leland High School	Leland Quixilver	Quixilver	 	San Jose, CA, USA	2001
606	King Drew High School	Raytheon/KingDrew LA	CyberEagles	 	Los Angeles, CA, USA	2001
610	Bangor Metals/Cachelan/Gamut Threads & Crescent School	Crescent Robotics	The Coyotes	Coyobot IX	Toronto, ON, Canada	2001
611	Explus Inc. & Langley High School	Langley Saxons	Saxons	Otto IV	McLean, VA, USA	2001
612	Noblis/Northrop Grumman/SAIC/IAI/AOL & Chantilly Academy	Chantilly	Chantilly Robotics	 	Chantilly, VA, USA	2001
613	Rotor Clip Company, Inc. & Franklin High School	FHS RoboWarriors	RoboWarriors	Confusion	Somerset, NJ, USA	2001
614	U.S. Army Night Vision Lab/ALION/EOIR Technologies/Fibertek/Northrop Grumman/SAIC & Hayfield Secondary School Robotics Club	Hayfield Secondary	NightHawks	NightHawk VIII	Alexandria, VA, USA	2001
615	NASA & Ballou Senior High School	The Mighty Knights	Knights	 	Washington, DC, USA	2001
617	Highland Springs High School	HSHS SPRINGERS	Nerd Herd	 	Highland Springs, VA, USA	2001
619	University of Virginia/GE Volunteers/MoneyWise Payroll Solutions/Parker Intellectual Property Law Firm, PLC/MoneyWise Bookkeeping Services/Cableform, Inc. & Charlottesville Albemarle High Schools	UVA & area schools	Cavalier Robotics	Hoolander 	Charlottesville, VA, USA	2001
620	Sprint Nextel / VMD System Integrators, Inc. / JMHS PSTA / Optimist Club of Vienna & James Madison High School	Warbots	Warbots	 	Vienna, VA, USA	2001
623	IEEE/Lockheed Martin/Phadia/BAE SYSTEMS/Princeton Information/Telford Technologies/NIH & Oakton High School & Oakton High School Academic Boosters	LockheedMartin/Oakton	Ohmens	 	Vienna, VA, USA	2001
624	BP America/Oceaneering & Cinco Ranch High School	BP/OII&Cinco Ranch HS	CRyptonite	 	Katy, TX, USA	2001
637	Marotta Controls, Inc. & Montville Twp. High School	MontvilleRoboticsTeam	MR. T	Mr. T	Montville Township, NJ, USA	2001
639	AccuFab Inc / BAE Systems / BorgWarner Morse TEC / Innovative Dynamics, Inc / Innovative Metal Works / IPEI / Kionix / Triad Foundation / VFW Post 961 & Ithaca High School	Kionix/Morse TEC/IHS	Code Red Robotics	Red Dragon	Ithaca, NY, USA	2001
640	Con Edison/Port Authority of New York and New Jersey & Thomas A. Edison High School	Robo Elite	Team Viro	3 Plus!	Jamaica, NY, USA	2001
647	Operational Test Command U.S. Army / Houston Robotics / GaN Corporation / Gen. (R) Robert M. Shoemaker & Killeen Independent School District & Robert M. Shoemaker High School	Shoemaker & OTC	Cyber Wolf Corps	 	Killeen, TX, USA	2001
648	eServ / Ken-Tronics / John Deere / SME & Sherrard High School & Davenport West High School & Moline High School	ES/JD/KT/SME ELITE	Q. C. ELITE	QC FLAMES	Quad Cities, IL, USA	2001
649	Saratoga High School	Saratoga Robotics	Saratoga Robotics	"The Challenged"	Saratoga, CA, USA	2001
653	Bezos Foundation/Houston Robotics & Edison High School	BezosHoustonEdison	NOSIDE	 	San Antonio, TX, USA	2001
660	BAE SYSTEMS/Houston Robotics & Round Rock High School	Robo Dragons	Dragons	Marvin	Round Rock, TX, USA	2001
662	Academy School District 20	Rocky Mtn. Robotics	Rocky Mountain Robotics	 	Colorado Springs, CO, USA	2001
663	Motorola Inc./WRT Corporation & Whitinsville Christian School	WCS Robonauts	Robonauts	 	Whitinsville, MA, USA	2001
665	DeVry University / Lockheed Martin / Walt Disney World / Miller Bearings and Motion Systems / Fluid Power Society / Goldstar Machine & Tool & Oak Ridge H.S. & Edgewater H.S. & Cypress Creek High School	M.A.Y.H.E.M.	M.A.Y.H.E.M.	Vierling (pronounced "FEAR-ling")	Orlando, FL, USA	2001
668	BAE Systems / Outback Manufacturing / House Family Foundation / McHale Creative & Pioneer High School ASB	The Apes of Wrath	The Apes of Wrath	Kijo	San Jose, CA, USA	2001
670	iWoz / Symantec / BAE Systems / EMC Corporation / Ronald C. Crane / Intuitive Surgical, Inc. & Homestead High School	HRT	Homestead Robotics	 	Cupertino, CA, USA	2001
675	Rohnert Park Rotary / MV Transportation / Abbott Diabetes Care / LRG Capital / Brooks Automation / Nicole Smith Orthodontics / Friedman's Home Improvement & Technology High School	Tech High Robotics	Phantom Robitics	Glory Angel	Rohnert Park, CA, USA	2001
677	Ohio State University / American Electric Power / Roush Honda & Columbus School for Girls	CSG/OSU/AEP Robotics	Murphy's Outlaws	 	Columbus, OH, USA	2001
686	NASA Goddard Space Flight Center/New London Precision Instruments, Inc./Rinker Materials/Samuel/The Barrie Family/The Kinna Family & Linganore High School	LINGANORE HS	Bovine Intervention	 	Frederick, MD, USA	2001
687	Northrop-Grumman / CAMS PTSO / Raytheon / Boeing / Rhodia & California Academy of Mathematics and Science	camsRobotics Team 687	The Nerd Herd	B.L.T. (Limit Tester)	Carson, CA, USA	2001
691	JPL/HR Textron/ITT/Honda/Raytheon & Hart School District	Hart Burn	Hart Burn	 	Steenson Ranch, CA, USA	2001
692	Society of Women Engineers, Sacramento Valley Section / The Stewart Family / Pasco Scientific / CyboSoft / Dos Coyotes & St Francis High School	St. Francis HS	THE FEMBOTS	Grrraham	Sacramento, CA, USA	2001
694	Credit Suisse / D. E. Shaw & Co. / Verizon / Con Edison / Time, Inc. / The Wallace Foundation / Yvette & Larry Gralla / Cox & Company, Inc & Stuyvesant High School Alumni Association & Parents Association & Stuyvesant High School	StuyPulse	StuyPulse	DESBOT	New York, NY, USA	2001
695	Parker / Envision Radio Corporation / The Metal Store / Lyndhurst Lumber & Beachwood High School	Beachwood HS	The Bison	 	Beachwood, OH, USA	2001
696	NASA/JPL/Glendale Community College/TruCut/The Kauffman Family/Canoga Perkins/Hardcore Racing/Arrow Metal Stamping/Gordon Woods Welding Supply/HEC & Clark Magnet High School	Clark Magnet HS	Circuit Breakers	The Burd	La Crescenta, CA, USA	2001
698	Microchip Technology Inc./Port Plastics/Industrial Metal Supply & Hamilton High School	HHS Robotics	HHS Microbots	Mikey's Phoenix	Chandler, AZ, USA	2001
701	Valero Refining Companies / COGCO, Wireline Inc / Brown Family / PGP Corporation / Solano County Office of Education / Tesoro Refining Companies / Fairfield-Suisun Rotary / Travis USD & Vanden High School	Vanden Robotics	RoboVikes	Thor	Fairfield, CA, USA	2001
702	Raytheon / Fold-A-Goal / Shinano Kenshi Corporation / Tech Empower / M&K Metal Co. / Pom Wonderful / Safoyan Family / Mary C. Davis & Culver CIty High School	Bagel Bytes	Bagel Bytes	HR 702-S	Culver City, CA, USA	2001
703	Delphi & Saginaw Career Complex	Delphi/Saginaw Career	Phoenix	The Phoenix	Saginaw, MI, USA	2001
704	Lockheed Martin Missiles and Fire Control / General Motors-Arlington Assembly & South Grand Prairie High School	Warriors	Warriors	Chief 6	Grand Prairie, TX, USA	2001
706	Price Engineering & Arrowhead High School	AHS/PRICE ENG	CYBERHAWKS	 	Hartland, WI, USA	2001
708	Motorola / AMI Semiconductor / Centocor, Inc. / Immunicon & Hatboro-Horsham High School & Upper Moreland High School	Motorola/HHHS/UMHS	Hardwired Fusion	 	Horsham, PA, USA	2001
709	The Agnes Irwin School	Femme Tech Fatale	Femme Tech Fatale	 	Rosemont, PA, USA	2001
714	New Jersey Institute of Technology/Port Authority of New York New Jersey & Technology High School	NPS/ADP/-Tech HS	panthera	 	Newark, NJ, USA	2001
716	BD/C. A. Lindell/Salisbury Bank and Trust/21st Century Fund & Housatonic Valley Regional High School	Housatonic HS	Who'sCTEKS	Random ?uestion	Falls Village, CT, USA	2001
743	Bloomberg & Evander Childs  Campus & High School of Computers and Technology	Technobots	Technobots	The Gripper	Bronx, NY, USA	2002
744	Apex Machine Co. & Westminster Academy	AWACS	Shark Attack	Shark Attack	Ft. Lauderdale, FL, USA	2002
752	NJIT/The Port Authority of New York & New Jersey & Newark Public Schools & Science High School	Science High School	The League	 	Newark, NJ, USA	2002
753	Bend Research & Mountain View High School	OR High Desert Droids	High Desert Droids	AC=RO	Bend, OR, USA	2002
754	NWTC/MMC/M&M Foundation & Marinette HS & Menominee HS & Peshtigo HS	FROSTBYTE	FROSTBYTE	 	Marinette, WI, USA	2002
758	ArvinMeritor / Meritor Suspension Systems / Ridge Landfill Community Trust / Chathm-Kent Community Foundation & The High Schools of South Kent	SKY Robotics	South-Kent Youth Robotics	 	Blenheim, ON, Canada	2002
759	ARM/Cambridge Angels/metapurple Ltd./Microsoft & Hills Road Sixth Form College	Systemetric	Systemetric	mothzilla	Cambridge, UK, Great Britain	2002
766	Menlo-Atherton High School	MAHS	M-A Bears	Ma Bear	Atherton, CA, USA	2002
768	NASA Goddard Space Flight Center/Fred Needel, Inc. & Brauckmann Family & Clash Family & Woodlawn High School	TechnoWarriors	TechnoWarriors	 	Baltimore, MD, USA	2002
771	St. Mildred's Lightbourn Parent Association/DANA-Long Manufacturing/MD Robotics & St. Mildred's-Lightbourn High School	S.W.A.T.	SWAT	Mildread	Oakville, ON, Canada	2002
772	General Motors of Canada/Capaldi Corporation/Amherst Quarries/Centerline & Sandwich Secondary School	Sabre Bytes Robotics	Sabre Bytes	Mantis	LaSalle, ON, Canada	2002
781	Bruce Power/Power Workers' Union & Kincardine District Secondary School	Kincardine/BrucePower	Kinetic Knights	 	Kincardine, ON, Canada	2002
801	Lockheed Martin / United Space Alliance / Wyle Laboratories / Bradley Investments, LLC / United Launch Alliance / GovConnection / Perrone Properties / Brevard Public Schools & Merritt Island High School & Edgewood Jr Sr High School & Jefferson Middle Scho	Horsepower	Horsepower	Mustang Sally	Merritt Island, FL, USA	2002
804	Duke Energy/Williams and Fudge & Applied Technology Center & Rock Hill District 3 High Schools	DUKE/WMS&FUDGE/RHD3	MetalMorphosis	Mothra	Rock Hill, SC, USA	2002
806	Xaverian High School & Bishop Kearney High School & Fontbonne Hall Academy High School	Brooklyn Blacksmiths	Blacksmiths	The Anvil	Brooklyn, NY, USA	2002
809	Cheney Tech PTO/Pratt & Whitney/Stanley Works & Cheney Tech	Cheney Tech	The TechnoWizards	Merlin	Manchester, CT, USA	2002
810	Smithtown Schools	Mechanical Bulls	The Mechanical Bulls	Minotaur	Smithtown, NY, USA	2002
811	BAE Systems / Rice's Pharmacy / WBC Extrusion / Festo Corporation & Bishop Guertin High School	Bishop Guertin HS	Cardinals	Ella-Vader	Nashua, NH, USA	2002
812	The University of California at San Diego/Calit2/Fish & Richardson/General Motors/The UCSD Machine Perception Laboratory/Qualcomm/The Annenberg Foundation/San Diego Gas and Electric/Space and Naval Warfare Systems Center, San Diego/Northrop Grumman/GeoCon	UCSD & PREUSS	The Midnight Mechanics	Plan Z	San Diego, CA, USA	2002
815	e-Merging Market Technologies LLC/Ford Motor Company/Dan's Robotic Team/HJ Manufacturing/ITT Technical Institute/Copper and Brass Sales/Victory Industries, Inc/Extra Space Storage Southgate & Allen Park High School & St Frances Cabrini High School	Ford & AP & SFC HS	Advanced Power	 	Allen Park, MI, USA	2002
816	BCIT Foundation & BCIT	BCIT/Westampton	Panthers	Anomaly	Westampton, NJ, USA	2002
818	General Motors General Assembly Engineering & Warren Consolidated Schools	Team 818 GM-GAE & WCS	Steel Armadillos	 	Warren, MI, USA	2002
829	ProportionAir Corporation/Rolls-Royce Corporation/Indiana Department of Workforce Development & Walker Career Center	Warren Robotics Team	Digital Goats	Lynn	Indianapolis, IN, USA	2002
830	Toyota Technical Center / AVL North America, Inc. / University of Michigan / Vitullo and Associates / UMentorFIRST & Ann Arbor Huron High School	AVL/Toyota/UM/Huron	Rat Pack	 	Ann Arbor, MI, USA	2002
832	Applied Systems Intelligence / Women in Technology / GE Volunteers / ITT Technical  Institute / COACH Robotics, Ltd. & Roswell High School	Roswell High School	Chimera	Oscar	Roswell, GA, USA	2002
834	Lutron Electronics, Inc/Quakertown National Bank/Olympus America Inc. & Southern Lehigh School District	Southern Lehigh	SparTechs	Kronos	Center Valley, PA, USA	2002
835	DENSO  & Detroit Country Day School	DENSO & DCDS	The Sting	 	Beverly Hills, MI, USA	2002
836	The RoboBees & BAE Systems/The Patuxent Partnership & Dr. James A. Forrest Career & Technology Center High School	RoboBees	RoboBees	 	Leonardtown, MD, USA	2002
839	G & L Tool / Hamilton Sundstrand / Hartford Steam Boiler Inspection & Insurance Company / Rosie Boosters Inc. / Berkshire Power & Agawam High School	Agawam High School	Rosie Robotics	Rosie 7.0	Agawam, MA, USA	2002
840	Alloy Cutting / CIM 3 Engineering / Genentech, Inc. / Jim Minkey Remax Today / SRI International & San Mateo Union High School District & Aragon High School	Aragon Robotics Team	ART	HAL4	San Mateo, CA, USA	2002
841	Google/Chevron & Richmond High Student Center	Richmond High 	The BioMechs	 	Richmond, CA, USA	2002
842	Honeywell / Arthur M. Blank Foundation / Science Foundation Arizona / Intel / Vegas Fuel / Wells-Fargo & Carl Hayden High School	Carl Hayden Falcons	Falcon Robotics	Virginia's DREAM	Phoenix, AZ, USA	2002
843	Dofasco/Hertz /KTS Tooling/NTN Bearings & Halton District School Board & White Oaks Secondary School	WOW	Wildcats	 	Oakville, ON, Canada	2002
845	Accu Tech & Pendleton High School	Cutting Edge	Cutting Edge	 	Pendleton, SC, USA	2002
846	NASA / Google / LAM Research / Cardiomind, Inc / DP Products / SJSU & Lynbrook High School	Lynbrook HS Robotics	The Funky Monkeys	 	San Jose, CA, USA	2002
847	Hewlett Packard / IBEW Local 280 / Gene Tools / Wet Labs & Philomath High School	PHRED	PHRED	PHRED VII	Philomath, OR, USA	2002
848	The Cloer family / Mike Mena / California Pro Sports / Red Car Restaurant & Rolling Hills Preparatory School	Rolling Hills Prep	Bambots	Tikibot	San Pedro, CA, USA	2002
852	Lawrence Livermore National Laboratory/Outback Manufacturing/Trossen Robotics/Northrop Grumman/Macy's West/General Atomics & The Athenian School	Athenian Robotics	The Athenian Robotics Collective	Chet VI	Danville, CA, USA	2002
854	TDSB & Martingrove C. I. 	Martingrove Robotics	The Iron Bears	 	Toronto, ON, Canada	2002
857	The Chrysler Foundation/General Motors/Michigan Technological University & Houghton High School	DCX/GM/MTU/HHS	Superior Roboworks	Francios	Houghton, MI, USA	2002
858	Delphi Corp. & Wyoming Public Schools	Delphi Demons	Delphi Demons	DD	Wyoming, MI, USA	2002
862	Robert Bosch LLC / ITT Technical Institute & Plymouth-Canton Educational Park	P-CEP,BOSCH	Lightning Robotics	THOR	Canton, MI, USA	2002
865	Toronto District School Board & Western Technical-Commercial School	WARP7 Robotics	Warp7	 	Toronto, ON, Canada	2002
867	Los Angeles County ROP & Arcadia Unified School District	AHS A.V.	Absolute Value	Trinity VII	Arcadia, CA, USA	2002
868	Rolls Royce/Delphi & Carmel High School	Carmel TechHOUNDS	TechHOUNDS	 	Carmel, IN, USA	2002
869	ANSUN, Protective Metals Inc / Cordis Corporation (J&J) & Middlesex High School	Cordis/Middlesex HS	Power Cord 869	MAC	Middlesex, NJ, USA	2002
870	Miller Environmental / Sea Tow International / Southold PTA / Precison Pneumatics / Westhampton Glass and Metal / Sunrise Busses, Inc / Lewis Marine Supply of Greenport / Westhampton True Value Hardware / Southold Rotary / Hart's True Value Hardware / Spe	Southold & Miller Env	TEAM  R. I. C. E.  	 	Southold, NY, USA	2002
871	West Islip Robotics Booster Club, Inc. & West Islip High School	West Islip Robotechs 	Robotechs	Critical Mass	West Islip, NY, USA	2002
872	columbus state community college & marion franklin boosters	MFHS/SEC/AEP/CSCC/GP	Techno-Devils	 	Columbus, OH, USA	2002
876	ND Space Grant Consortium / Thunder Boosters / Lloyd Farms / Northwood Coop Oil / Sheyenne Valley Financial / Farmers Union Insurance / Naastad Construction / Hatton Mens Club / Aneta Whitetail Ashley Lions / Dr. Mary Aaland / Citizen's State Bank of Finl	Hatton/NorthwoodNDSGC	Thunder Robotics	Wicked Witch of the West	Hatton, ND, USA	2002
877	UND Space Grant Consortium & Cando Public High School	Cando Cub Robotics	Cubs	Kryptobot VII	Cando, ND, USA	2002
878	UND North Dakota Space Grant Consortium / Rugby Welding & Machine / Rugby Truck Bodies & Equipment / Dakota Prairie Supply & Rugby High School	RHS/UND/RugbyMfg&Weld	Metal Gear	Atlas	Rugby, ND, USA	2002
884	Malverne High School	Malverne Robotics	Quarks	 	Malverne, NY, USA	2002
885	Vermont Technical College/Norwich University David Crawford School of Engineering & Randolph Union High School	Vermont Robotics	GREEN TEAM	 	Randolph, VT, USA	2002
888	Howard County Public Schools/NASA Goddard & Glenelg	Glenelg	Robotiators	 	Glenelg, MD, USA	2002
894	UAW Region 1 C / Cummings Inc. / General Motors Foundaton / Phillips   Welding & Flint Powers Catholic High School	Powers Chargers	Chargers	awesomo 4000	Flint, MI, USA	2002
896	N.J.I.T. & Central High School and Newark Public Schools	CHS/NPS	Blue Steel	Blue Steel I	Newark, NJ, USA	2002
900	North Carolina High School of Science and Mathematics	NCSSM	Team Infinity	Stanley the U-Bot	Durham, NC, USA	2002
903	General Motors/Ford Motor Company & Charles Chadsey High School & Detroit Public Schools	GM/Ford/Chadsey High 	RoboTroopers	General  Ford	Detroit, MI, USA	2002
904	Dematic/Gill Industries/GM - Grand Rapids Metal Center/HS Technolgies & Creston High School	GM/Gill/Creston HS	D cubed	 	Grand Rapids, MI, USA	2002
905	Platt Tech Parent Faculty Organization & Platt Technical High School	Platt Tech	Platt Tech Panthers	FRED	Milford, CT, USA	2002
907	Toronto District School Board & East York Collegiate Institute	East York Cybernetics	East York Cybernetics	 	Toronto, ON, Canada	2002
909	Ewing Marion Kauffman Foundation & Lawrence High School	LawrenceHighRobotics	Junkyard Crew	OzBot 	Lawrence, KS, USA	2002
910	Borg Warner / The Chrysler Foundation / Magna International & Bishop Foley	The Foley Freeze	The Foley Freeze	Foley Freeze	Madison Heights, MI, USA	2002
919	TDSB & Harbord CI	Harbord C.I.	Tiger Techs	 	Toronto, ON, Canada	2002
922	AEP / Powell-Watson Toyota of Laredo / Laredo Women's City Club & United Engineering & Technology Magnet 	ULTIMATE	ULTIMATE:  United Longhorn Team Inspiring Mental Attitude Toward	Bezerker	Laredo, TX, USA	2002
928	Motorola Foundation & Benjamin Banneker Academic HS	Banneker High School	Hounds of Steel	 	Washington, DC, USA	2002
930	GE Volunteers & Mukwonago High School	Mukwonago BEARS	Mukwonago Building Extremely Awesome RobotS	 	Mukwonago, WI, USA	2002
931	Emerson / Anheuser-Busch / Ranken Technical College / WaterJet Tech / CopperBend Pharmacy / Belleville Kiwanis & St. Louis Public Schools & Gateway Institute of Technology	Emerson/Ranken/SLPS	Perpetual Chaos	G7	St. Louis, MO, USA	2002
932	The Nordam Group / AEP-PSO / Bezalel Foundation / Allied Fence Company / HE&M Saw / APSCO, Inc. / Petro-Chem Development Co., Inc. / Bank of Oklahoma / Memorial Robotics Booster Club & Tulsa Engineering Academy at Memorial	Nordam/AEP/MemorialHS	Circuit Chargers	 	Tulsa, OK, USA	2002
935	EWING MARION KAUFFMAN FOUNDATION / WallaceTozier / Higgs Tech Consulting & Newton High School	NHS/Ewing/Higg/SME/AB	RaileRobotics	Lachesis	Newton, KS, USA	2002
937	Ewing Marion Kauffman Foundation/GE Volunteers & Shawnee Mission North HS	SMN	North Stars	 	Overland Park, KS, USA	2002
938	Ewing Marion Kauffman Foundation & Central Heights High School	VXR	Viking Xtreme Robotics	 	Richmond, KS, USA	2002
939	Sisseton High School	Sisseton HS	Hiphopanonymous	 	Sisseton, SD, USA	2002
945	Walt Disney World & Colonial High School	Colonial HS	Element 945	 	Orlando, FL, USA	2002
948	Birdwell Machine/The Bezos Family Foundation & Newport High School	Newport HS	NRG (Newport Robotics Group)	 	Bellevue, WA, USA	2002
949	Intellectual Ventures & Bellevue High School	Atom Smashers & I.V.	Atom Smashers	DIV	Bellevue, WA, USA	2002
955	Hewlett Packard / Videx / ATS Systems Oregon / Discovery Management Group & Crescent Valley High School	HP/Videx/ATS/CVHS	CV Robotics	RaiderBOT VII	Corvallis, OR, USA	2002
956	Hewlett-Packard/Videx & Santiam Christian Schools	Eagles	Eagle Cybertechnology 	CMW	Corvallis, OR, USA	2002
957	Oregon State University / viper northwest / hewlett packard & west albany high school	HP/Viper/West Albany	Pokebot Masters	Pokebot	Albany, OR, USA	2002
963	AEP / Battelle / Columbus State Community College & Columbus East High School & South East Career Center	EAST/AEP/CSCC/SECC	Tiger Techs	 	Columbus, OH, USA	2002
964	Ford, NASA GRC, and Fluke & Bedford HIgh School	Robocats	Bearcats	Elite Technobot	Bedford, OH, USA	2002
967	ASME/Bentley Manufacturing/Carpenters Local #308/EHA/Host Rocket/IEEE/Innovative Signs/Iowa Fluid Power/Linn-Mar Booster Club/Linn-Mar Foundation/Rockwell Collins & Linn-Mar High School	Linn-Mar Robotics	Mean Machine	Mean Machine	Marion, IA, USA	2002
968	BAE Systems & West Covina High School	RAWC (West Covina HS)	RAWC (Robotics Alliance Of West Covina)	 	West Covina, CA, USA	2002
971	Google, Inc. / Berger Manufacturing, Inc / Intuitive Surgical, Inc. / P F Development Inc. / Los Altos Robotics & Mountain View High School	Spartan Robotics	"RoboSpartans"	 	Mountain View, CA, USA	2002
972	BAE Systems / EMC Corporation & Los Gatos High School	Los Gatos HS BAE/EMC	Iron Paw	 	Los Gatos, CA, USA	2002
973	Cal Poly San Luis Obispo/Pacific Gas & Electric/LARON Incorporated & Atascadero High School Greyhound Revolutionary Robotics	GRR	Greybots	 	Atascadero, CA, USA	2002
975	JetBlue Airways / Dominion / Computer Resource Team / PEER Tech Prep Consortium / John Tyler Community College & James River High School	James River	Synergy Robotics	A robot named Blue	Midlothian, VA, USA	2002
980	Alliance Spacesystems / Evolution Robotics / Solutions for Automation / Crystal View Corp. / Tweed Financial Services / Neighbors Empowering Youth / Mustangs on the Move & Delphi Academy	ThunderBots	ThunderBots	Lightning	No. Los Angeles Area, CA, USA	2002
981	Instr. Soc. of America / HR TEXTRON / Chevron USA Inc / Tejon Ranch & Frazier Mountain High	FMHS	Snobotics	 	Lebec, CA, USA	2002
987	Bearing Belt Chain / Cirque du Soleil / Albertsons & Cimarron-Memorial High School	HIGHROLLERS	HIGHROLLERS	Pit Boss II	Las Vegas, NV, USA	2002
988	Clark High School	Robotics Anonymous 	Robotics Anonymous 	 	Las Vegas, NV, USA	2002
989	JMA Elevated Architecture/Summerlin Children's Forum & Palo Verde High School Science &Technology Club	Palo Verde	Rounders	 	Las Vegas, NV, USA	2002
991	Tommy Gate Company / Kitchell / Microchip Technology, Inc. / Ryan Companies US, Inc. & Brophy College Preparatory	Brophy Robotics	The Dukes	 	Phoenix, AZ, USA	2002
995	Mark Keppel High School	MKHS-DGRSRS	DEGREASERS	 	Alhambra, CA, USA	2002
996	Casa Grande High School	CGUHS Cougars	Mecha-Knights	 	Casa Grande, AZ, USA	2002
997	Videx Corporation / Outback Manufacturing & Corvallis High School	Spartan Robotics	Spartans	Spartacus	Corvallis, OR, USA	2002
999	Sikorsky Aircraft/Amphenol & Cheshire High School	Sikorsky/Cheshire HS/	C.R.A.S.H.        (Cheshire Robotics and Sikorsky Helicopters)	Crash	Cheshire, CT, USA	2002
1000	Urschel Laboratories Incorporated & Wheeler High School	Urschel&Wheeler HS	Cybearcats	 	Valparaiso, IN, USA	2003
1001	Rockwell Automation/Martha Holden Jennings and George Gund Foundations & Charles F. Brush High School	Brush High School	Hacksaw	Hacksaw VI	Lyndhurst, OH, USA	2003
1002	Georgia Institute of Technology RoboJackets / GE Volunteers / Women In Technology / Cobb EMC & Wheeler High School	GE/WIT Wheeler HS	The CircuitRunners	 	Marietta, GA, USA	2003
1006	General Motors of Canada (Engng & Product Planning) & Port Perry H.S.	PPHS & GM Canada	Port Perry Robotics	Fast Eddie VI	Port Perry, ON, Canada	2003
1008	Honda of America / American Electric Power / Chipotle / Battelle / Beechwold Hardware / Columbus State Community College & Southeast Career Center High School & Columbus City Schools & Whetstone High School	WHS/ AEP/ Honda	Team Lugnut	Chief Lugnut	Columbus, OH, USA	2003
1011	Science Foundation AZ / Hanlon Engineering / IBM / ITT-Tech & Sonoran Science Academy	Sonoran Science	CRUSH	Rombert	Tucson, AZ, USA	2003
1013	Science Foundation of Arizona / Arizona State University East Polytechnic / Russ' True Value / Intel / Magma Engineering Co / Alliance Lumber / TRW Automotive / General Motors Desert Proving Grounds / Kiwanis Club of Queen Creek / DeRito Development Inc /	QCHS Robotics	The Phoenix	Velcro III	Queen Creek, AZ, USA	2003
1014	Dublin Robotics Boosters / OSU FIRST & Dublin City Schools	Dublin Robotics	Bad Robots	Bad Robot 5.0	Dublin, OH, USA	2003
1015	Yazaki North America & Pioneer High School	Yazaki NA/Pioneer	Pi Hi Samurai	 	Ann Arbor, MI, USA	2003
1018	Beckman Coulter / Rolls Royce / Waterjet Cutting of Indiana / Diversified Systems, Inc / Indiana Department of Workforce Development / ITT Technical Institute & Pike Academy of Science and Engineering, Pike High School	Pike Acad of Sci/Eng	RoboDevils	Devil's Child	Indianapolis, IN, USA	2003
1023	Midwest Fluid Power / La-Z-Boy Inc. / RD Tool / BP Toledo Refinery / Macsteel / Dynics / Steel Dimensions / Promedica Health System / MTS Seating / Hydro Technology / M & N Controls / VDS & Bedford High School	Bedford Express	Bedford Express	The Baconator	Temperance, MI, USA	2003
1024	Aircom Manufacturing/Beckman Coulter/Rolls-Royce Corporation & Bernard K. McKenzie Career Center	Kil-A-Bytes	Kil-A-Bytes	 	Indianapolis, IN, USA	2003
1025	Schaeffler Group / Tshwane University of Technology / Trophy Robotics / OUR Credit Union / Leoni Corporation / Klapwijk Engineering / F'SATIE / Ferndale Education Foundation / IMPIS ROBOTICS CORPORATION & Ferndale Schools & Royal Oak Schools	IMPIS ROBOTICS TEAM	IMPIS	Audrey3	Ferndale, MI, USA	2003
1026	IMT York & Bank of York & Floyd D. Johnson Technology Center & York Comprehensive High School	Bank of York/FDJTC	Cougars	 	York, SC, USA	2003
1027	ITT Power Solutions/ConEdison Energy Co., Inc. & West Springfield High School	ITT &  WSHS	Mechatronic Maniacs	Maniac Max	West Springfield, MA, USA	2003
1029	Motorola & Belen Jesuit & Lourdes Academy	Wolvcats	Wolvcats	 	Miami, FL, USA	2003
1033	Alstom Power, Inc./Wyeth Engineering/Dupont Spruance & Benedictine High School & Saint Gertrude High School	Holy Rollers	Holy Rollers	Rubber Sole	Richmond, VA, USA	2003
1038	P&G/Pella Entry Systems/CI Automation/Miami University & Lakota East  & Butler Technology and Career Development Schools	P&G - Lakota Robotics	Thunderhawks	Firehawk	Liberty Township, OH, USA	2003
1047	Raytheon Space and Airborne Systems & Woodbridge High School	Woodbridge NerdLinger	Nerd Lingers	 	Irvine, CA, USA	2003
1048	National Starch and Chemical Co., Inc/AdvanTech International/Wilkes University & Manville High School	NSC/WU/MHS	Mustang Robotics	Stash IV	Manville, NJ, USA	2003
1051	Marion County Technical Education Center	Marion Co. Robotics	Technical Terminators	T2	Marion, SC, USA	2003
1053	Centre for Communication and Information Technology / Lookheed Martin  Canada / Algonquin College / Chipworks / University of Ottawa / General Bearing Service Inc. / Loucon Metal Limited / McCarthy Tetrault & Glebe Collegiate High School	Glebe	Glebe Gryphons	 	Ottawa, ON, Canada	2003
1057	Thiele Kaolin/Sandersville Railroad/Sandersville Technical College & Brentwood School	BRENTWOOD	The Blue Knights	 	Sandersville, GA, USA	2003
1058	BAE/Parker Pneutronics/Fleet Ready Corp. & Londonderry High School	LHS PVC Pirates	PVC Pirates	Confusion	Londonderry, NH, USA	2003
1065	Walt Disney World Ride and Show Engineering/BalloonBRITES.com/DeVry University/South Orange Ace Hardware & Technical Education Center Osceola & Professional And Technical High School & Osceola High School	Tatsu	Tatsu	S.I.D.	Kissimmee, FL, USA	2003
1070	Dreamworks Animation skg/California State University, Northridge/Raytheon & Louisville High School	Royal Robotrons	Royal Robotrons	The Spark	Woodland Hills, CA, USA	2003
1071	UTC & Wolcott High School	UTC & Wolcott High	Team Max	MAX	Wolcott, CT, USA	2003
1072	Harker Foundation/Intuitive Surgical & The Harker School	Harker Robotics	Harker Robotics	Mu-238	San Jose, CA, USA	2003
1073	BAE SYSTEMS / Technology Garden & Hollis-Brookline High School	The Force Team	The Force Team	Leviathan	Hollis, NH, USA	2003
1075	Andor Robotics / Ontario Power Generation / NSK Bearing & Sinclair Student Parliament	Sinclair Sprockets	Sprockets	Sprockets 5	Whitby, ON, Canada	2003
1086	Eck Supply Inc / McKesson Corp. / Henrico Education Foundation / Flexicell / Qimonda NA / Showbest Fixture Corp. & Deep Run High School	Deep Run	Blue Cheese	Blue Cheddar	Glen Allen, VA, USA	2003
1087	Hanard Machine Inc/West Salem High Education Foundation/Schneider Charitable Foundation/Today's Hair/West Salem Rotary/Meyer Memorial Trust & West Salem High School	West Salem Titronics	Titronics Digerati	 	Salem, OR, USA	2003
1089	Bristol-Myers Squibb/Machine Medic/SPECO Tile & Marble, Inc. & Hightstown High School	Hightstown Robotics	Team Mercury	Silver Lightning	Hightstown, NJ, USA	2003
1091	GE Volunteers / Mantz Automation & Hartford Union High School	HUHS@MantzAutomation	Oriole Assault	Bird of Prey	Hartford, WI, USA	2003
1094	Bill Davis Inc./ITT Technical Institute/Cuivre River Electric/Diversified Check Solutions LLC/Pfizer/Emerson Engineers Club & River City Robots	RCR Channel Cats	Channel Cats	 	O'fallon, MO, USA	2003
1095	Virgina Tobacco Commission / Community Foundation of Danville Pittsylvania County / Sartomer Corporation / Mecklenberg Electric Co-operative / Intertape Polymer Group / Danville Pittsylvania County Chamber of Commerce / Chatham Rotary Club & Pittsylvania 	Chatham Robotics	RoboCavs	The Beast	Chatham, VA, USA	2003
1098	Pfizer /Rockwood School District & Eureka High School & Lafayette High School & Marquette High School & Rockwood Summit High School	Rockwood Robotics	Rockwood Robotics	 	Wildwood, MO, USA	2003
1099	General Electric & Brookfield High School	GE & BHS	LIONS	LEO	Brookfield, CT, USA	2003
1100	Rohm and Haas & Algonquin Regional High School	Rohm and Haas & ARHS	The T-Hawks	 	Northboro, MA, USA	2003
1102	Energy Solutions/Washington Safety Management/Bridgestone Firestone/Senator Greg and Betty Ryberg/Parsons & Aiken County Public Schools	M'Aiken Magic	Aiken County Robotics Team M'Aiken Magic	Ragnarok	Aiken, SC, USA	2003
1103	Pentair Water / MPC / Kikkoman Foods / CMCI & Delavan Darien High School	Delavan Darien HS	Cometron	We are in the process of naming our Robot	Delavan, WI, USA	2003
1108	AARP / Ewing Marion Kauffman Foundation / The Baehr Foundation / Schoolhouse Foundation / TeamBank N.A. / Briley Sonics / Walmart 242 / Women in Engineering and Science Programs, K-State & Paola High School	Paola High School	Panther Robotics	 	Paola, KS, USA	2003
1111	BAE / McCarter Welding / NASA Goddard Space Flight Center / ARINC Technical Excellence Society / Master Graphic Printing Company / Global Science & Technology Inc. / Lockheed Martin IS&S / Screen Designs, Inc. / Marty's Bag Works & South River High School	Seahawks	"The Power Hawks"	Hawk Bot	Edgewater, MD, USA	2003
1114	General Motors - St. Catharines Powertrain & Governor Simcoe Secondary School	GM Simbotics	Simbotics	Simbot SS	St. Catharines, ON, Canada	2003
1123	Autodidactic Intelligent Minors	AIM Robotics	AIM Robotics	Nautilus	Burke, VA, USA	2003
1124	UTC Fire and Security & Avon High School	UTCF&S & Avon HS	ÜberBots	Lightning	Avon, CT, USA	2003
1126	Xerox Corporation & Webster High Schools	Xerox & Webster HS	SPARX	 	Webster, NY, USA	2003
1127	Women In Technology/Manheim DRIVE/Siemens PLM Software/ITT Tech/MB & R Engineering Inc. & Milton High School	WitDriveLotusRobotics	Lotus Robotics	That's Off The Chain	Milton, GA, USA	2003
1130	South Albany High School	SAHS/OSU/NASA/HP	Rebel Robotics	 	Albany, OR, USA	2003
1135	Brenner-Fiedler & Associates & Whitney High School	WHS Robotics	Schmoebotics	Lil Schmoe	Cerritos, CA, USA	2003
1137	Mathews High School	MATHEWS HS	Rocket Sauce	Qoobix	Mathews, VA, USA	2003
1138	Tyco Electronics / DTS Digital / Nexan / Annenberg Foundation / MBDA Missile Systems / Frazier Aviation / Medtronic / Jostens / Xerox Corporation / Wells Fargo Bank West Hills & Chaminade College Preparatory	Eagle Engineering	Eagle Engineering	ART	West Hills, CA, USA	2003
1141	G.E. Volunteers & Thomas A. Stewart High School	TAS 	TAS Megawatts	 	Peterborough, ON, Canada	2003
1143	Lockheed Martin/One Point Inc. & Abington Heights High School	Abington Heights	Cruzin' Comets	 	Clarks Summit, PA, USA	2003
1144	Ethicon LLC & María Cruz Buitrago High School & Miguel Melendez Muñoz & Cooperativa de Integridad Social & Thomas Alva Edison School & Bayamon Military Academy & José Campeche High School & Notre Dame High School & Ana J. Candelas High School & Cristo de 	Coquitron	Coquitron	Coquitrón Transformed	San Lorenzo, PR, USA	2003
1147	Optimist Club / thermogenesis & Elk Grove High School	Herd Robotics	The Herdinators	Atlas	Elk Grove, CA, USA	2003
1153	Walpole High School	WHS	Robo-Rebels	The MinuteMan	Walpole, MA, USA	2003
1155	The Hennessy Family Foundation / The Alumni Association of The Bronx High School of Science / ConEdison / Kepco Inc. / Parent Association of The Bronx High School of Science / Providge Consulting / The Ackman Family Foundation / Snapple & The Bronx High S	The Bronx SciBorgs	SciBorgs	Colbertimus Prime	Bronx, NY, USA	2003
1156	Marista Pio XII High School	Pio XII	Under Control	 	Novo Hamburgo, RS, Brazil	2003
1157	Impact On Education/Ball Aerospace & Boulder High School	Boulder	Hippie-bots	 	Boulder, CO, USA	2003
1158	Bacon Foundation / Collbran Job Corps / Daniels Foundation / Department of Labor / Ametek Dixon / Laramie Energy / Western Colorado Community Foundation / Bureau of Reclamation / EnCana Oil & Gas / Williams Energy / National Instruments / Wal*Mart / Hillt	Eagle Corps	The Corps	Gove 6	Collbran, CO, USA	2003
1159	Albertsons/NASA & Ramona Convent Secondary School	Ramona Rampage	Ramona Rampage	 	Alhambra, CA, USA	2003
1160	JPL / Chinese Club of San Marino & San Marino High School	SMHS Robotics Team	Firebird Robotics	Firebird	San Marino, CA, USA	2003
1164	NASA & Mayfield HS	Project NEO	Project NEO	 	Las Cruces, NM, USA	2003
1165	Paradise Valley High School	Team Paradise	Team Paradise	 	Phoenix, AZ, USA	2003
1168	CTDI & Malvern Preparatory School & Villa Maria Academy	Malvern Robotics	Malvern Robotics	FriarBot	Malvern, PA, USA	2003
1172	SMC Corporation & Richmond Technical Center	Rich Tech	We Tek Too	 	Richmond, VA, USA	2003
1178	Boeing  & DeSmet Jesuit High School & John F. Kennedy Catholic High School	D.R.T.	D.R.T.	 	St. Louis, MO, USA	2003
1182	AFFECT / Heat Transfer Systems / Rotary International / Pfizer Inc. / Festo Corporation / EPIC Systems Inc. / Dobbs Tire and Auto Centers / Compear Design / Electronic Support Systems / Labview / GRAYBAR & Parkway South High School	Patriots	Patriots	Wompus	Manchester, MO, USA	2003
1189	General Motors & Grosse Pointe Public Schools	Grosse Pte Gearheads	The Gearheads	Atlas	Grosse Pointe, MI, USA	2003
1195	Navy/Patriots Technology Training Center/Prince Georges County, MD & Tall Oaks Vocational High School	Patriots-TTC	Eagles Dare!	 	Seat Pleasant, MD, USA	2003
1197	Northrup-Grumman / Raytheon Co / Moog Aircraft / Toyota Motor / ACE Clearwater Enterprises / Sign-A-Rama El Segundo & South High School & North High School & West High School & Torrance High School	TorBots	TorBots	Tormentor	Torrance, CA, USA	2003
1203	Farmingdale University & West Babylon School District	WB PANDEMONIUM	PANDEMONIUM	 	West Babylon, NY, USA	2003
1208	O'Fallon High School	OTHS Robotics	Metool Brigade	 	O'fallon, IL, USA	2003
1209	AEP/University of Tulsa/Booker T. Washington Foundation for Academic Excellence & Booker T. Washington High School	AEP, TU & BTW	Agents Orange	Booker VI - "Atlas"	Tulsa, OK, USA	2003
1211	BEZOS Foundation / Verizon Foundation / Rajswasser-Flaherty Family & Friends of Automotive High School	Automotive H.S.	Robotnics	Piston One	Brooklyn, NY, USA	2003
1212	Modern Industries & Seton Catholic	Seton Robotics	Sentinels	Dr. Octabot	Chandler, AZ, USA	2003
1216	KUKA & Oak Park High School	Kuka OPHS Knights	Knights	Knightmare	Oak Park, MI, USA	2003
1218	Vulcan Spring / Vectrix Corporation & Chestnut Hill Academy & Springside School	Vulcan Robotics	Vulcan Robotics	Vulcan	Philadelphia, PA, USA	2003
1219	Apotex Inc. / Humber River Regional Hospital Foundation & Emery Collegiate Institute	TDSB/Emery CI	Iron Eagles	 	Toronto, ON, Canada	2003
1221	Honeywell Aerospace Canada & St. Martin's Secondary School	Nerdbotics	Nerdbotics	 	Mississauga, ON, Canada	2003
1222	AMF Bakery System & Huguenot High School	Huguenot High School	Falcons	Mighty Falconbot	Richmond, VA, USA	2003
1225	Shining Rock LLC & Henderson County Public Schools Robotics Team	AMPERAGE	AMPERAGE	LOUISE	Hendersonville, NC, USA	2003
1228	Infineum/A&M Industrial Supply/Merck & Rahway High School	Rahway	a-MERCK- IN- INDIANS	 	Rahway, NJ, USA	2003
1230	Verizon/Credit Suisse/Pershing Square/ADP & Herbert H. Lehman High School	Lionics	The Lehman Lionics	Leo V	Bronx, NY, USA	2003
1236	Galileo Magnet High School	VerizonCorning	Phoenix Rising	 	Danville, VA, USA	2003
1237	Verizon/Credit Suisse/Goldman Sachs/NYC Transit & University Neighborhood High School	L.E.S. Cyborgs	Lower East Side Cyborgs	 	New York, NY, USA	2003
1241	General Motors of Canada & Rick Hansen Secondary School	GMCL & Rick Hansen SS	Theory6_Team Hansen Experience of Robotic Youth	Speedo-Demon	Mississauga, ON, Canada	2004
1242	David Posnack Hebrew Day School	DPHDS	Team S.M.I.L.E.Y	 	Plantation, FL, USA	2004
1243	General Motors Flint Truck Assembly / EFC Systems Inc / PRP Inc. / Butterworth Industries / ITT Technical Institute & Swartz Creek High School	GM Truck & SCHS	Dragons	Dragon-1	Swartz Creek, MI, USA	2004
1244	Volvo Motor Graders/SIFTO & GDCI	VMG/GDCI/SCI/TG	Viking Robotics	 	Goderich, ON, Canada	2004
1245	Ball Aerospace/Impact on Education/American Astronautical Society/lijit.com/Lockheed Martin/EvilRobotics.net & Monarch High School	Shazbots	MoHi Shazbots	REC	Louisville, CO, USA	2004
1246	Rotary Club of Agincourt / TDSB / RM Systems Integrators & Agincourt CI	Klocworxs	Agincourt Klocworxs	Klockworxs	Scarborough, ON, Canada	2004
1247	Labsphere, Inc. & Kearsarge Regional High School	KRHS/Labsphere	Robotics of Kearsarge (ROK)	 	North Sutton, NH, USA	2004
1248	Ford Motor Company/SMART Consortium & Midpark High School	Midpark HS Meteors	MHS Robotics	 	Middleburg Heights, OH, USA	2004
1249	American Electric Power/Mingo Career and Technical Center/Southern West Virginia Coal Resources/West Virginia Department of Career and Technical  Education & Mingo County Schools	Mingo Career Center	Robo Rats	RoboRat	Delbarton, WV, USA	2004
1250	Ford Motor Company/The Henry Ford & Henry Ford Academy	Gator-Bots	Gator-Bots	The Gator-B.O.T.T.	Dearborn, MI, USA	2004
1251	Sonny's Enterprises, The Car Wash Factory & Atlantic Technical Magnet High School	ATC Magnet HS	TechTigers	El Tigre Loco	Coconut Creek, FL, USA	2004
1254	Hinckley Research & Van Buren ISD	Entropy	Entropy	Havoc	Lawrence, MI, USA	2004
1255	ExxonMobil Chemical Company & Goose Creek CISD	Blarglefish	Blarglefish	Blarglebot	Baytown, TX, USA	2004
1258	Ryerson & Seattle Lutheran High School	SeaLu	SeaLu Robotics	Island Scorpion	Seattle, WA, USA	2004
1259	GE Volunteers & Pewaukee High School	Paradigm Shift	Paradigm Shift	The Barnaby Rover	Pewaukee, WI, USA	2004
1261	Motorola Inc. & Peachtree Ridge High School	PRHS RoboLions	RoboLions	Long Shot	Suwanee, GA, USA	2004
1262	Patrick Henry Community College/American Electric Power/Bassett Furniture, Inc./Hooker Furniture Corporation/CP Films, Inc & Piedmont Governor's School for Mathematics, Science and Technology	pgsmst	STAGS	STAGS	Martinsville, VA, USA	2004
1266	Linda Lee / Justin Lee / Rob Healey / Issa Family Foundation / Aaron Rollison Memorial Fund / Elite Realty Inc / Qualcomm / San Diego College, Career & Technical Education & Madison High School Devil Duckies	Madison Devil Duckies	The Devil Duckies	Quacker	San Diego, CA, USA	2004
1268	GE Volunteers/Rockwell Automation/Milwaukee Area Technical College/United Water & Washington High School	GEHC/Purgold Robotics	GEHC/Washington	Bicycle Kick	Milwaukee, WI, USA	2004
1270	Youth Technology Academy of Cuyahoga Community College/NASA Glenn Research Center/Cuyahoga County Workforce Development Dept/National Science Foundation/Cleveland TechWorks/George Gund Foundation & Cleveland Metropolitan School District	Dragons	Red Dragons	Slayer	Cleveland, OH, USA	2004
1274	Ford Motor Company/SMART Consortium & Berea High School	Berea HS Braves	ß!-!$ ®0ß071¢$ 	Sheila	Berea, OH, USA	2004
1276	Midcoast School of Technology	Kaizen Blitz	Kaizen Blitz	Joe	Rockland, ME, USA	2004
1277	BAE SYSTEMS/Siemens Enterprise Networks/Nokia Siemens Networks/Symphony Service Corporation & Groton-Dunstable Regional High School	GDRHS Musketeers	The 1277 Musketeers	 	Groton, MA, USA	2004
1279	National Starch & Chemical Co. & Immaculata High School	NSC & IHS	Cold Fusion	 	Somerville, NJ, USA	2004
1280	EMC Corporation/Intuitive Surgical & San Ramon Valley High School	Ragin' C-Biscuits	Ragin' C- Biscuits of San Ramon Valley High	C-Biscuit	Danville, CA, USA	2004
1281	Alexander Mackenzie High School & York Region District School Board	AlexMac	Mustang Robotics	 	Richmond Hill, ON, Canada	2004
1284	Metal Research & Guntersville High School	D.A.R.T.	Design Applications for Robotics Technology	 	Guntersville, AL, USA	2004
1287	Academy of Arts, Science & Technology	AAST	Aluminum Assault	 	Myrtle Beach, SC, USA	2004
1288	Boeing Employees Community Fund & Francis Howell School District	1288	RAVEN Robotics	 	Saint Charles, MO, USA	2004
1289	Lawrence High School	Gearheadz-LHS	Gearheadz	Artoo2	Lawrence, MA, USA	2004
1290	Si Se Puede & Chandler High School	CHS-Robotics	Si Se Puede	 	Chandler, AZ, USA	2004
1293	D5Robotics : School District Five of Lexington and Richland Counties & Irmo & Dutch Fork & Chapin	D5 Robotics	D5 Robotics	Chomp	Columbia, SC, USA	2004
1294	HomeMeeting.com / Aerojet / Citrix / SAE NW Section & Eastlake High School Robotics & Lake Washington Foundation	EHS Robotics	Top Gun	 	Sammamish, WA, USA	2004
1296	Special Products and Manufacturing / The PTR Group / L-3 Communications, ComCept Division & Rockwall High School	UFT/DOS/SPM/RHS	Full Metal Jackets	Atlas	Rockwall, TX, USA	2004
1302	Point Blank Solutions / Hudson Farm Foundation / BAE Systems / Thor Labs & Pope John XXIII Regional High School	Pope John XXIII H.S.	Revolution Robotics	 	Sparta, NJ, USA	2004
1303	CC/Automation Electronics & NCSD	WYOHAZARD	WYOHAZARD	 	Casper, WY, USA	2004
1304	NASA/Interlocks/Tulane University/University of New Orleans & New Orleans Charter Science and Mathematics High School	N.O. Sci/Math High	N.O. Botics	 	New Orleans, LA, USA	2004
1305	Near North Student Robotics Initiative	NNSRI	Ice Cubed	TOM	North Bay, ON, Canada	2004
1306	GE Volunteers/Isthmus Engineering & Manufacturing & Madison Metropolitan School District	BadgerBOTS	BadgerBOTS	 	Madison, WI, USA	2004
1307	St. Thomas Aquinas High School	St. Thomas Aquinas	Robosaints	 	Dover, NH, USA	2004
1308	Balance Product Development / EMI Plastics Equipment & St. Ignatius High School	St. Ignatius Wildcats	Wildcats	 	Cleveland, OH, USA	2004
1310	Thales Group / Ken Shaw Lexus Toyota / Hatch Mott MacDonald / TDSB & Runnymede CI	KSLT&QCT&HMM&TDSB&RCI	RUNNYMEDE ROBOTICS	Red Raven	Toronto, ON, Canada	2004
1311	GE Volunteers/Women In Technology/Cobb EMC/Arylessence/AIAA (American Institute of Aeronautics and Astronautics/Thunder Tower Harley Davidson/Anderson Power Products/georgia tech research institute/General Cable/Gougeon Brothers/Johnnys Pizza/Peterson Alu	Kell / GE / WIT	Longhorns	 	Marietta, GA, USA	2004
1312	Power Workers' Union / Bruce Power, & Sacred Heart High School	Syntax Error	Syntax Error	Robotitron III	Walkerton, ON, Canada	2004
1317	AEP/The Ohio State University/Honda of America Manufacturing/Honda R & D/Siemens Airfield Solutions/American SHOWA & Educational Robotics of Central Ohio	Digital Fusion	Digital Fusion	 	Westerville, OH, USA	2004
1318	Issaquah High School	IRS	Issaquah Robotics Society	The Auditor	Issaquah, WA, USA	2004
1319	ITT Technical Institute / Merovan Office Center / Hendricks Fabrication / AssetPoint / Eubanks Electrical & Mauldin High School & Greenville County Schools	Mauldin HS	Flash	 	Mauldin, SC, USA	2004
1322	GM/Weber Electric & G.R.A.Y.T. Leviathons	Leviathan's	Genesee Robotics Area Youth Team (GRAYT)	BOB	Fenton, MI, USA	2004
1323	Berry Construction/FMC Food Tech & Madera High School	FMC/Berry Const./ MHS	MadTown Robotics	ETR5	Madera, CA, USA	2004
1324	NASA / AZ Science Foundation / Verde Valley Robotics, Inc. / Combusion Dynamics / Northern Arizona University & Sedona Red Rock High School & American Heritage Academy	Verde Valley Robotics	Sporks	 	Sedona, AZ, USA	2004
1325	Cisco Systems/Promation Engineering Ltd. & Gordon Graydon Memorial SS	Graydon Robotics	Inverse Paradox	 	Mississauga, ON, Canada	2004
1326	FMC Technologies/Houston Robotics/Stress Engineering Services & Cypress Ridge High School	SES/HR/CRHS	Cy-Ridge Robotics	 	Houston, TX, USA	2004
1327	CTS Corp/South Bend Mayor's After School Program/Indiana Department of Workforce Development/Mack Tool Engineering/Notre Dame & South Bend School Corporation	South Bend Robotics	SBOTZ	 	South Bend, IN, USA	2004
1329	St. Louis Priory High School & Visitation Academy High School	VIPRs	VIPRs	 	St. Louis, MO, USA	2004
1332	PXP ~ Plains Exploration and Production Company / Capco & Plateau Valley High School	PVHS	S.W.I.F.T.	 	Collbran, CO, USA	2004
1334	Hatch / The Woodbridge Family Foundation / Halton District School Board & Oakville Trafalgar High School Red Devils	O.T.	OTHS Red Devils	 	Oakville, ON, Canada	2004
1339	CH2M Hill & Denver Public Schools	East High School	AngelBotics	The BeatBot	Denver, CO, USA	2004
1340	Iannelli Construction Co. Inc / Ackman Family Foundation / Bloomber LLC / Adams Robotics -john adams HS-Con Edison & John Adams High School	Adams Robotics	Adams Robotics	Adrian	Queens, NY, USA	2004
1341	Sun Hydraulics Corporation & Cardinal Mooney High School	Knights Who Say "Nee"	The Knights Who Say "Nee"	 	Sarasota, FL, USA	2004
1345	DeVry University & Stranahan High School	DeVry, D&D & SHS	Platinum Dragons	 	Ft Lauderdale, FL, USA	2004
1346	General Motors Canada & David Thompson Secondary School	GMC/DTSS Vancouver	Trobotics	 	Vancouver, BC, Canada	2004
1348	Denver Public Schools & J F. Kennedy High School	J.F.K. Robotics	Commanders	 	Denver, CO, USA	2004
1350	Raytheon / IGUS / Brown University & LaSalle Academy	RaytheonBrownULaSalle	The Rambots	Rambot	Providence, RI, USA	2004
1351	Meadows Manufacturing & Archbishop Mitty High School	Mitty Robotics	TKO	 	San Jose, CA, USA	2004
1357	DeVry University / Agilent Technologies, Inc. / GE Volunteers / Kimble Precision, Inc. / Spatial Corp. & Thompson Valley High School	TV Robotics	High Voltage	------	Loveland, CO, USA	2004
1358	The Macarthur Generals	MacArthur High Scool 	The Gerneral	 	Levittown, NY, USA	2004
1359	Hewlett-Packard / Videx / Concept Systems, Inc. / IBEW Local 280 / Albany Rotary Clubs & BSA Venture Crew 308 & Linn County Schools	Crew 308	Scalawags	The Kracken	Albany, OR, USA	2004
1361	American  Astronautical Society / Hewlett Packard Corporation / Booz, Allen and Hamilton / Lockheed Martin & Sierra High School	Sierra High School	Nightmares/aliens	aledod	Colorado Springs, CO, USA	2004
1366	West Side High School	Roughriders	wild wild west	 	Newark, NJ, USA	2004
1367	Barringer High School	Barringer & Tech	Blue Bear	 	Newark, NJ, USA	2004
1369	DeVry University/University of South Florida & Middleton Magnet High School	Middleton HS	Minotaur	 	Tampa, FL, USA	2004
1370	DuPont Engineering / The Town of Middletown / Metal Sales & Service, Inc. / Valero / ILC Dover, Inc. & Middletown High School	Middletown Robotics	The Blue Charge	 	Middletown, DE, USA	2004
1371	Arthur Blank Foundation/Women in Technology- Atlanta GA/National Action Council for Minorities in Engineering (NACME) & Frederick Douglass High School Center for Engineering and Applied Technology	FDHS Astros	Cosmic Gold	Freddy D	Atlanta, GA, USA	2004
1373	E.O.Smith	Panthers	Spontaneous Combustion	 	Storrs, CT, USA	2004
1375	Raytheon Company / Aurora Public Schools Education Foundation & Aurora Central High School	AC Robotics	Trobots	Awsimo	Aurora, CO, USA	2004
1377	DeVry Univeristy / Apple Skin Media / Ball Aerospace & Technologies Corp / LSI Logic / Oerlikon & Bollman Center	BTEC	BTEC Machines	Devry Dominators	Thornton, CO, USA	2004
1378	Gemini Observatory / Hawaii Space Grant Consortium / HELCO & Hilo High School & Hilo High School	Hilo High Vikings	Eureka	Eureka	Hilo, HI, USA	2004
1379	Nordson Corporation / EMS Technologies / LXE / PMI Atlanta / Women in Technology / ITT Technical  Institute & Norcross High School & Gwinnett County Public Schools	Gear Devils	Gear Devils	Blue Streak	Norcross, GA, USA	2004
1382	Johnson & Johnson & ETEP - Prof. E. Passos Technical High School	J&J BR & ETEP	ETEP Team	CRTEC-5	Sao Jose dos Campos, SP, Brazil	2004
1386	The Timken Company & Timken Senior High School	CCS Robotics	The Trobots	 	Canton, OH, USA	2004
1388	Melfred Borzall/California Polytechnic State University-San Luis Obispo/Pacific Gas & Electric & Arroyo Grande High School Eagle Robotics	Eagle Robotics	Eagle Robotics	HammerTime	Arroyo Grande, CA, USA	2004
1389	Georgetown Day High School & Walt Whitman High School	Team 1389 Robotics	Team 1389 Robotics	Green Stig	Washington, DC, USA	2004
1390	Disney World & Saint Cloud High School & Harmony High School	Disney/HarmonyHS/SCHS	WELETHEDAWGSOUT	 	St. Cloud & Harmony, FL, USA	2004
1391	Westtown Friends High School	Westtown Friends Scho	the metal moose	Moose V	Westtown, PA, USA	2004
1396	Richmond County Savings Foundation/Port Authority of New York and New Jersey & Tottenville High School	Tottenville Pyrobots	Pyrobots	Squeeze Box	Staten Island, NY, USA	2004
1398	USC College of Engineering / The Challenger Learning Center of Richland County School District One / Square D - Schneider Electric / South Carolina Department of Education / Shakespeare Company / ITT Technical Institute / American Association of Blacks in	Keenan 1398	Robo-Raiders	 	Columbia, SC, USA	2004
1403	Convatec - Bristol-Myers Squibb  & Montgomery High School	Montgomery HS / BMS	Cougar Robotics	 	Skillman, NJ, USA	2004
1404	Bresser Construction Management Inc./TDSB & Dr Norman Bethune CI	Bethune	SHOCKs	 	Toronto, ON, Canada	2004
1405	Hoselton / Starbucks Corporation / Roberts Wesleyan College & The Charles Finney High School	Falcons Robotics	Falcons Robotics	Charlie V	Penfield, NY, USA	2004
1408	Jefferson High School	JHS	The Saints	 	Edgewater, CO, USA	2004
1410	George Washington High School & Rocky Mountain School of Expeditionary Learning	GW	Patribot	 	Denver, CO, USA	2004
1413	Mecklenburg Electric Cooperative & Mecklenburg County Public Schools	Bluestone - MEC&MCPS	Skrappy's Crew	Skrappy	Skipwith, VA, USA	2004
1414	The Howle Foundation / Siemens / Clyde Bergemann & Atlanta International School	iHOT	iHOT	 	Atlanta, GA, USA	2004
1415	Pratt & Whitney / Columbus Technical College / Bytewise & Northside High School	P&W-Bytewise-NHS	The Flying Pumpkins	Cheez	Columbus, GA, USA	2004
1418	Digital Design & Imaging Service, Inc. / Falls Church City Television / Aurora Flight Sciences & George Mason High School	Vae Victus	Vae Victus	 	Falls Church, VA, USA	2004
1421	NASA & Picayune High School & Pearl River Central High School	Pearl River Robotics	Team Chaos	 	Picayune, MS, USA	2004
1425	Xerox / West Linn Wilsonville School District / City of Wilsonville, Oregon & Wilsonville High School	Wilsonville Robotics	Error Code Xero	Whomper	Wilsonville, OR, USA	2004
1429	GE Volunteers/Houston Robotics/VICO Mfg/Woven Metal Products & Galena Park High School	GPHS ROBOTICS	TEAM KAOS	Whiplash	Galena Park, TX, USA	2004
1432	M.J .Murdock Charitable Trust & Franklin High School	Franklin Robot Team	Franklin Robotics	 	Portland, OR, USA	2004
1436	Duke Energy & Fort Mill High School	Jackets	Yellow Jackets	 	Fort Mill, SC, USA	2004
1438	MAES/Raytheon & Anaheim High School	MAES/Raytheon/Anaheim	The A Team	Aztech Warrior 5	Anaheim, CA, USA	2004
1439	Arthur M. Blank Foundation / WIT / NASA & Benjamin E. Mays High School	B.E. Mays Robotics	The Innovators	 	Atlanta, GA, USA	2004
1444	Rolla Alumni of Beta Sigma Psi / Engineered Sales / White-Rodgers / Arco Construction Co. / Trinity Products / Applied Ind. Tech. / Grasso Plaza / Neff Press / DaimlerChrysler St Louis Assembly Plant / Inventory Sales Co / Benson Electric / Structures Inc	The Lightning Lancers	The Lightning Lancers	 	St. Louis, MO, USA	2004
1448	Taylor Products/Ewing Marion Kauffman Foundation/Ducommun Aerostructures/ACE Hardware/Ruskins/Dayton Superior & Parsons High School	Parsons Vikings	Parsons Vikings	Rocket Boy R4 "The Atlas"	Parsons, KS, USA	2004
1450	Xerox Corp & Ben Franklin Educational Campus	XQ Robotix	XQ RobotiX	Q-Dawg	Rochester, NY, USA	2004
1456	Intel & Basha High School	Intel & Basha High	GrizzlyBots	 	Chandler, AZ, USA	2004
1457	Sierra Nevada Corporation & Coral Academy of Science	Coral Robotics	RoboKnights	Battle Axe	Reno, NV, USA	2004
1458	ROP Contra Costa Co., CA & Monte Vista High School & San Ramon Valley Education Foundation	NASA/MV Danvillans	Monte Vista Danvillans	 	Danville, CA, USA	2004
1466	Webb School of Knoxville	Webb Robotics	Webb Robotics	 	Knoxville, TN, USA	2004
1468	BAE SYSTEMS & Hicksville High School	HICKSVILLE HS	Hicksville J-Birds	A-SOLT BOT	Hicksville, NY, USA	2004
1474	Tewksbury Memorial High School	Tewksbury Titans	Titans	Prometheus	Tewksbury, MA, USA	2004
1477	Anadarko / Halliburton / P.A.S.T. / SBM Offshore / ETSZone / TBKM / Biofuels Power & Conroe ISD	CISD/APC/Halliburton	Northside Roboteers	ChewBotta	The Woodlands, TX, USA	2004
1480	Bezos Foundation/Houston Robotics/MAES & Jefferson Davis High School	Davis Robotics	Robatos Locos	Pancho	Houston, TX, USA	2004
1482	General Motors of Canada & Bishop Grandin High School	GMC & BGHS	Ghosts	 	Calgary, AB, Canada	2004
1484	Houston Robotics / C-Stem & Prepared 4 Life & Hogg Middle School	Hogg Robotics	Hoggzilla	Hoggzilla	Houston, TX, USA	2004
1492	Microchip & AZ Community Robotics	Microchip/AZCommunity	Team CAUTION	Grapefruit	Tempe, AZ, USA	2004
1493	National Grid/RPI & Albany High School	RPI & AHS	The Falcons	 	Albany, NY, USA	2004
1495	Avon Grove High School	AGHS Robotics	AGR	 	West Grove, PA, USA	2004
1501	PHD Inc. / Indiana Department of Workforce Development / 4H Robotics / American Society for Quality / UT Electronic Controls / Wabash Technologies & Huntington North High School	Huntington4H Robotics	Team THRUST	Phoenix	Huntington, IN, USA	2005
1502	The Chrysler Foundation / Chelsea Tool / Chelsea Comfort Inn and Conference Center / Mike's Home Repair / ACTI / Absopure / Kennedy Associates / Putterz / Meijer: Ann Arbor / ATW: Advanced Technology and Testing / Robert's Paint & Body & Chelsea High Scho	Chrysler & Chelsea HS	Technical Difficulties	Jack	Chelsea, MI, USA	2005
1503	General Motors - St. Catharines Powertrain & OPG & Westlane Secondary School	GM Spartonics	GM Spartonics	Spartavator	Niagara Falls, ON, Canada	2005
1504	Rockwell Automation/Dart Foundation/TechSmith/General Motors/Michigan State University Students & Okemos High School & Lansing Christian High School	OHS/LCHS 	Desperate Penguins	 	Okemos, MI, USA	2005
1506	General Motors WFG / Kettering University / Toyota Boshoku America / Medallion / Woodbridge Group / Android Industries / Acord Holdings LLC / FANUC Robotics America / Irvin Automotive / Fitzpatrick Mfg. Co. & North Oakland, Macomb & Genesee County High Sc	m^2	Metal Muscle	 	North Oakland County, MI, USA	2005
1507	Delphi & Lockport High School	Delphi/Lockport	Warlocks	 	Lockport, NY, USA	2005
1510	Beaverton Education Foundation / Intel / Portland Community College & Beaverton Public Schools Robotics Team	Westview Robotics	Wildcats	 	Beaverton, OR, USA	2005
1511	Harris Corporation & Penfield High School	Harris RF & Penfield	Rolling Thunder	BDU	Penfield, NY, USA	2005
1512	Criterium-Turner Engineers/Refurbished Equipment Marketplace & St. Paul's School High School	St. Paul's School	The Metal Vidsters	Blazing Thunder	Concord, NH, USA	2005
1513	Houston Robotics/ITT Technical Institute & Wunsche Academy	Wunsche Academy	Cyclones	Cyclone	Spring, TX, USA	2005
1514	TDSB & West Humber CI	WHCI Robotics	The Vikes	 	Toronto, ON, Canada	2005
1515	Walt Disney Imagineering / Mercedes-Benz of Beverly Hills & Beverly Hills High School & R.O.P.	BH Robotics	MorTorq	Orange Fever	Beverly Hills, CA, USA	2005
1516	W & K Automotive / EMC Corporation / Wells Fargo / Chabot Space & Science Center / ROP Contra Costa Co, CA / San Ramon Valley Education Foundation & California High School	CHS Robotics	Grizzlies	Peetee Ze Pokur	San Ramon, CA, USA	2005
1517	BAE Systems/Bittware, Inc & Bishop Brady High School	We Robot	P4	M'nad Knocker	Concord, NH, USA	2005
1518	JRLON & Palmyra-Macedon High School	JRLON Pal-Mac	Raiders	 	Palmyra, NY, USA	2005
1519	BAE Systems / Rockwell Automation & Milford Area Youth Homeschoolers Enriching Minds	BAE & Rockwell MAYHEM	Mechanical Mayhem	Fezzik & Speed Racer Mach 6	Milford, NH, USA	2005
1520	Access International / Credit Suisse / CCNY / Zazzle & HSMSE	Omega - 13	Omega - 13	 	New York, NY, USA	2005
1522	Sonic Tools / HHS Robotics Booster Club / Hanover Education Foundation / CH2M Hill / Palari Publishing / Richmond East Moose Lodge / Qimonda Richmond & Hanover High School & Hanover County Board of Education	DOTM1522	DOTM - Defenders of the Multiverse	Christopher Walken	Mechanicsville, VA, USA	2005
1523	GE Volunteers/Sikorsky & Jupiter High School	M.A.R.S.	Mega Awesome Robotic Systems	www.marsbot.org	Jupiter, FL, USA	2005
1525	NASA/Colborne Engineering/Underwriter's Laboratory & Deerfield HS Warbots	Warbots	Deerfield High School Warriors	ULe	Deerfield, IL, USA	2005
1527	biogen idec Foundation/East county ROP/Ranesco/Gen-Probe/Qualcomm & Granite Hills High School	Granitehills&ECROP	Bionic Battalion	Tobor MK4	El Cajon, CA, USA	2005
1528	FANUC Robotics America / Global Engine Manufacturing Alliance (GEMA) / Ron George Design & Consulting / ITT Technical Institute / NSK Corporation & St. Mary Catholic Central High School & Monroe High School	Monroe County Robotic	iPirates	 	Monroe, MI, USA	2005
1529	Indiana Dept. of Workforce Development/Rolls-Royce/Fab2Order & Southport High School	CyberCards	CyberCards	Homer	Indianapolis, IN, USA	2005
1532	Cuyahoga Community College (YTA) / NASA Glenn Research Center / Cleveland TechWorks / TFOME Sierra Lobo Inc. / Cleveland State University & SuccessTech Academy	NASA/CA/Sierra/STA	Royals	Chief Long Arm	Cleveland, OH, USA	2005
1533	ABCO Automation / Piedmont Triad Partnership / The Dell Foundation / Tyco Electronics / North Carolina A&T State University / RF Micro Devices & The Early College at Guilford High School	ABCO/PTP/Dell/Tyco/RF	Triple Strange	 	Greensboro, NC, USA	2005
1535	Algoma District School Board	The Knights of Alloy	KOA	Sir Jimmy	Sault Ste Marie, ON, Canada	2005
1537	Lockeed Martin & Uniondale High School	Knights	Robotic Knights	 	Uniondale, NY, USA	2005
1538	Qualcomm / BlueChip Machine & Fabrication / San Diego County Sheriff's Department / Industrial Metal Supply & High Tech High School	HTH-SD Robotics	The Holy Cows	Daisy II	San Diego, CA, USA	2005
1539	Duke Energy/Midrex/Process Inovation and Design & Clover School District	R.J.L.A.	Robotic Justice League of America	 	Clover, SC, USA	2005
1540	Catlin Gabel School	Catlin Gabel	Flaming Chickens	Nemo	Portland, OR, USA	2005
1541	Peer Consortium at JTCC / American Electrical Inc. / Filtrona Fibertec / Pocket Money Recycling Co. / Southern Electronics / Ervin Coppridge Machine Co / Hunton & Williams & Midlothian High School	MidloCANics	MidloCANics	SARTANYAC: Delta project	Midlothian, VA, USA	2005
1543	DisneyWorld / DeVry University & Poinciana High School & Poinciana High School SAC 	PHS and Disney	The Riddler Revolution	The Riddler 2.0	Kissimmee, FL, USA	2005
1544	British Petroleum / Personal Page & Bartlett High School	Ice Bears	One Byte Short	Io	Anchorage, AK, USA	2005
1546	Baldwin Foundation for Education & Baldwin Senior High School	Baldwin Robotics	Chaos, Inc.	 	Baldwin, NY, USA	2005
1547	General Motors of Canada & Trafalgar Castle School	GM & Trafalgar Castle	Where's Waldo?	Waldo	Whitby, ON, Canada	2005
1548	Alaska Robotics Education Assoc./BP & Highland Tech High	Highlanders	Highlanders	 	Anchorage, AK, USA	2005
1549	Washtenaw Community College & Washtenaw Technical Middle College	F1r3tr4xX	Fire TraXX	Phoenix	Ann Arbor, MI, USA	2005
1550	NASA & O. Perry Walker Senior High School	Botics Squad	The Botics Squad	 	New Orleans, LA, USA	2005
1551	Bausch & Lomb Corp/Lake Country Woodworkers/Mitchell-Joseph Insurance/Mount Hope Medical/Keenan Group, Inc. Realtors & Naples Central School	B&L and Naples HS	The Grapes of Wrath	Shiela MacGuyver	Naples, NY, USA	2005
1552	Seagate Corp./Xlinx Corp./Front Range Engineering/Applied Design/Lockheed Martin Coherent Technologies Inc./Micro Analysis /Niwot Florist & Niwot High School	Niwot High School	CougarBots	 	Niwot, CO, USA	2005
1553	DuPont Engineering/Applied Technology Education Campus & Lugoff-Elgin High School	Lugoff-Elgin Robotics	Demons	L.E. (life-like entity)	Lugoff, SC, USA	2005
1554	Oceanside Union Free School District 	Sailors	Oceanside Sailors	Skippy	Oceanside, NY, USA	2005
1555	Caterpillar/Indiana Department of Workforce Development/Leis Machine Shop/Liberty Township/Vanguard Industry & North White High School	PULSE	Promoting Understanding of Life, Science, and Engineering	 	Monon, IN, USA	2005
1557	Mt Dora Community Trust / Walt Disney Co. / Devry University & Lake County Public High Schools & Mount Dora Bible School	12 Volt Bolt	Lake County Alliance	Royal Flush	Mount Dora, FL, USA	2005
1558	TDSB & Albert Campbell CI	Albert Campbell	ACCIdent	 	Toronto, ON, Canada	2005
1559	Corning Tropel & Victor High School	Victor High School	Devil-Tech	 	Victor, NY, USA	2005
1560	Palo Alto Investors & Pinewood School	Pinewood School	RoboPanthers	 	Los Altos Hills, CA, USA	2005
1561	Chesapeake Energy Corporation / Edmond Summit Rotary Club / Oklahoma Educators Credit Union & Francis Tuttle Pre-Engineering Academy	Francis Tuttle Tech	Robo Ducks	 	Oklahoma City, OK, USA	2005
1563	The Port Authority of NY & NJ & Arts High School	Arts High	ROBOT-CATS	ROBOT-Cats	Newark, NJ, USA	2005
1564	TDSB & A.Y. Jackson SS	A.Y. Jackson S.S.	J.A.G.S.	 	Toronto, ON, Canada	2005
1565	ComDev & Jacob Hespeler Secondary School	Com Dev & JHSS	Think Tank Technologies (T3)	 	Cambridge, ON, Canada	2005
1566	Idaho National Laboratory/Battelle Energy Alliance & Hillcrest High School & Bonneville HIgh School	AK	AMMOKNIGHTS	Marco	Idaho Falls, ID, USA	2005
1569	Idaho National Laboratory / AMI Semiconductor, Inc. / National Science Foundation / Simplot / Idaho State University GK12 / Bechtel / Advanced Industrial Supply / Warden Fluid Dynamics & Idaho School District #25	Haywire Robotics	Haywire	Mach 5	Pocatello, ID, USA	2005
1570	General Motors of Canada & Kitsilano Secondary	Demon Robotics	Demons	 	Vancouver, BC, Canada	2005
1571	Platt Electric / ITT Technical School / MicroChip & The Center for Advanced Learning	CAL	Braught Wurst	ISTE IV	Gresham, OR, USA	2005
1572	Raytheon/Exchange Resources/Qualcomm/The Neurosciences Institute & Construction Tech Academy at Kearny Educational Complex	Hammer Heads	Hammer Heads	ViseGrip	San Diego, CA, USA	2005
1573	Elbit Systems & Kfar Galim 	KG & Elbit	Kfar Galim	 	Kfar Galim, NORTHERN, Israel	2005
1574	Iscar & Misgav 	MisCar	MisCar	MisCar	Misgav, NORTHERN, Israel	2005
1576	Tel Aviv Municipality/Bank Hapoalim & Eroni Chet	Eroni Chet	Eroni Chet	 	Tel Aviv, TEL AVIV, Israel	2005
1577	SAP LAB & Aviv	Aviv - SAP	steampunk	 	Raanana, CENTRAL, Israel	2005
1579	Tel Aviv Municipality & Shevach Mofet	Tel Aviv & SM	Shevach-Mofet	 	Tel Aviv, TEL AVIV, Israel	2005
1580	IDF 108 & Ort Ronson	 Ronson	Ronson	Roni	Ashkelon, SOUTHERN, Israel	2005
1583	Rite of Passage & Ridge View Academy	Rambotics	Ridge View Academy Rambotics	 	Watkins, CO, USA	2005
1584	4Frontiers/Impact on Education/Fahren Corporation/Mentor Graphics/Ball Aerospace Systems/Indian Peaks ACE Hardware & Nederland  High School	Ned High Pirates	Pirates	The Paul Emerling	Nederland, CO, USA	2005
1585	Discount Tent Renter & Red Jacket High School	Holzy's Army	H.A. 1585	 	Shortsville, NY, USA	2005
1590	Nordson Corporation & Lorain Admiral King High School	Admiral King Rambots	Rambots	 	Lorain, OH, USA	2005
1591	ITT Industries Space System Division & Greece Central High Schools	Greece Athena	Greece Gladiators	 	Rochester, NY, USA	2005
1592	Analex Corporation/Gov Connection/NASA Launch Services Program & Brevard Public Schools & Cocoa High School	Bionic Tiger Robotics	Bionic Tigers	 	Cocoa, FL, USA	2005
1594	Brearley High School & Chapin High School	BrearleyChapin	Double X	Valkyrie	New York, NY, USA	2005
1595	Pearson Packaging Systems & Saint Georges School	Pearson/SGS	Dragons	Ascalon	Spokane, WA, USA	2005
1596	Sault Area Career Center	Sault Instigators	Instigators	 	Sault Ste Marie, MI, USA	2005
1598	Kiwanis Club of Danville / Danville Public Schools Gifted Resources / The Tobacco Commission / EIT / Jarrett Welding / Gamewood Data Systems & George Washington High School	GWHS	Team Talon	Talon's Evolution	Danville, VA, USA	2005
1599	Qimonda Richmond & Atlee High School	Techromancers	Techromancers	Gurren-Lagann	Mechanicsville, VA, USA	2005
1600	Con Edison  Bloomberg Media & Thomas Jefferson High School Campus & High School For Civil Rights & FDNY High School For Fire & Life Safety	JeffTech	JeffTech	 	Brooklyn, NY, USA	2005
1601	Airborn Flightware/Stony Brook/The Safa Center, New Wave Holistic Health Center/Winergy LLC & Aviation High School	Quantum Samurai	QS1601	 	L.I.C., NY, USA	2005
1602	Ford Motor Company & Consortium College Preparatory High School	Ford/CCPHS/Roeper HS	CougarBots	Pinchy 	Detroit, MI, USA	2005
1605	TDSB & George Harvey CI	George Harvey CI	Project Da Vinci	 	Toronto, ON, Canada	2005
1606	Division Ave. High School	Division Avenue HS	Division Dragons	 	Levittown, NY, USA	2005
1607	Northrop Grumman Corporation & Roosevelt High School High School	RRR	Rough Riders	 	Roosevelt, NY, USA	2005
1610	BAE Systems / Hercules, Inc. / International Paper / Vic's Signs and Engraving / R & T Digital / Burgess & Co. / FNS Network & Franklin High School	BAE/BCO/IP/VicSgn/Hrc	B.O.T. (Builders of Tomorrow)	 	Franklin, VA, USA	2005
1612	State Farm Insurance & Nature Coast Technical High School	NCTSHARKS	Robo-Sharks	Bruce Mach III	Brooksville, FL, USA	2005
1616	New Jersey-New York Port Authority & Weequahic High School	indians	weequahic indians	Tisquantum	Newark, NJ, USA	2005
1617	Newark Public Schools/The Port Authority of NY & NJ/New Jersey Institute of Technology & Malcolm X Shabazz High School	Team 1617	The Almighty Bulldogs	The Trackmaster	Newark, NJ, USA	2005
1618	Colonial Supplemental Insurance / Richland County School District #1 / Wood True Value Hardware / Intel & Columbia High School	Columbia HS	Capital Robotics III	 	Columbia, SC, USA	2005
1619	BluePrint Robotics / Up-A-Creek Robotics / Seagate Technology / Lockheed Martin & CDC High School & Silver Creek High School	Up-A-Creek Robotics	UAC Robotics	 	Longmont, CO, USA	2005
1620	OPG - Pickering/Linear Contours & Dunbarton High School	DHS/OPG/LinearContour	Robolution	 	Pickering, ON, Canada	2005
1622	Northrop Grumman / HP / The Schneider Family Foundation / The Todd and Mari Gutschow Family Foundation / BAE SYSTEMS / Qualcomm / City of Poway & Poway High School	Poway High School	Team Spyder	For Sale	Poway, CA, USA	2005
1623	Banner Engineering Corp. & Shattuck St. Mary's School	SSM Banner Bots	Banner Bots	 	Faribault, MN, USA	2005
1625	Exelon Nuclear-Byron Generating Station / Haldex Hydraulics / Tru-Cut & Winnebago High School	 WHS and Exelon	Winnovation	 	Winnebago, IL, USA	2005
1626	St. Joseph's High School	Falcon Robotics	Falcon Robotics	 	Metuchen, NJ, USA	2005
1629	Beitzel Corporation/Garrett Container Systems & Garrett County Public Schools	Beitzel/GCS/GCBOE	Garrett Coalition (GaCo)	Meshach 4.0	McHenry, MD, USA	2005
1631	UNLV & Coronado High School	Cybernetic Cougars	Cougars	CNTRL Z	Henderson, NV, USA	2005
1633	ITT Technical Institute & Tempe High School	RoboBuffs	RoboBuffs	Atlas	Tempe, AZ, USA	2005
1634	The Weatherly Institute for Robotics and Engineering/KG Projections, Inc. & Weatherly School District	WIREKGProjWHS&CynSoft	Wreckers	 	Weatherly, PA, USA	2005
1635	Bloomberg, LP / Port Authority of New York and New Jersey / New York Community Bank & Newtown High School	Technotics	"IMPACT"	"IMPACT"	Elmhurst, NY, USA	2005
1640	Arkema Inc. / Kaloke Technologies Inc. / Analytical Graphics Inc. / Bentley Systems Incorporated / Kensey-Nash Inc. / The Burns Group & Downingtown Area School District	sab-BOT-age	sab-BOT-age	DEWBOT 4	Downingtown/Exton, PA, USA	2005
1641	Scaled Composites & Mojave High School	Mojave Robotics	Where's Waldo?	Waldo	Mojave, CA, USA	2005
1642	Bell Helicopter & Dunbar High School	Dunbar HS Robotics	BluGraphite	KingBeetleTronGanzoillaSupremeRuleroftheunderworld2	Ft. Worth, TX, USA	2005
1643	Tallmadge Foundation/Vulcan Machinery Company/Summit Racing & Tallmadge High School	BB in B II	Bob's Builders in Black	 	Tallmadge, OH, USA	2005
1644	California State University,Los Angeles-MEP/Hispanic Egineers National Achievement Awards Corporation/Mexican American Engineers and Scientists/Raytheon/Society of Hispanic Engineers and Science Students (SHESS)/Society of Hispanic Professional Engineers/	MAX Q Robotics	Manual Arts Extreme Quadrivium	 	Los Angeles, CA, USA	2005
1646	Caterpillar/Purdue FIRST Programs & Jefferson High School	Precision Guessworks	Boiler Precision Guessworks	Scorponok	Lafayette, IN, USA	2005
1647	Lockheed Martin & Lenape Regional Robotics Team	Iron Devils	LRR	 	Tabernacle, NJ, USA	2005
1648	Arthur M. Blank Family Foundation/Turner Broadcasting, Inc. & Henry W. Grady High School	Turner/Grady HS	Grady Gearbox Gangstaz	 	Atlanta, GA, USA	2005
1649	Lockheed Martin simulation, Training and Support & Windermere Preparatory High School & Orange County 4H clubs	 EMS	Team EMS	 	Windemere, FL, USA	2005
1652	NASA & LakeView Technology Academy	LakeView Tech	LakeView Legends	 	Pleasant Prairie, WI, USA	2005
1655	NASA/Smyth County School Board & Smyth Career and Technology Center	SCTC	Blue Ridge Screaming Eagles	 	Marion, VA, USA	2005
1656	University of Pennsylvania Engineering School & The Haverford School	Fords	Fords of Fury	The Scorpion	Haverford, PA, USA	2005
1657	Boeing & Mevoot Eron	Mevoot E'Ron	Mevoot E'ron	 	Kibutz E'in Shemer, NORTHERN, Israel	2005
1658	South Tech High School	South Tech	Geeks With Calculators	 	St. Louis, MO, USA	2005
1660	ConEdison/Credit Suisse & The Frederick Douglass Academy & Rice High School	Harlem Knights	Harlem Knights	 	New York, NY, USA	2005
1661	First Class Foods & The Buckley School High School	Buckley Griffitrons	Griffitons	 	Sherman Oaks, CA, USA	2005
1662	Jim Elliot Christian High School	Elliot	Raptor Force Engineering	Buhrbot	Lodi, CA, USA	2005
1665	Kaz Inc & Hudson High School	Hudson High School	Weapons of Mass Construction	 	Hudson, NY, USA	2005
1666	Ewing Marion Kauffman Foundation/NASA/Southwest Kansas Technical School & Liberal High School Redskin Nerd Herd	Nerd Herd	Liberal High Nerd Herd	Masada	Liberal, KS, USA	2005
1669	DeVry Univeristy/Pioneer Electronics & Juan Rodriguez Cabrillo High School	Cabrillo Jaganators	Pioneer Electronics Long Beach Unified Schools Cabrillo High Jag	mel	Long Beach, CA, USA	2005
1671	Pelco / Educational Employees Credit Union / Lifestyle Furniture / California Imaging Institute / CV Robotics & Buchanan High School	Buchanan Robotics	"DOC"	DOC IV: The Blizzard	Clovis, CA, USA	2005
1672	Stryker Orthopedics & Mahwah High School Robotics Club	Tbirds	Thunderbirds	 	50 Ridge Rd. Mahwah, NJ, USA	2005
1674	Onekama Lions Club / West Shore Medical Center / Manistee National Golf & Resort / Back Forty Express, Inc. & Onekama High School	Lake Effect 1674	Lake Effect 	ORT 4	Onekama, MI, USA	2005
1675	Rockwell Automation/GE Volunteers/George Mosher/Milwaukee Rotary/Milwaukee School of Engineering & Lynde and Harry Bradley Technology & Trade School & Rufus King High School	GE/RA/King/B. Tech	The Ultimate Protection Squad	Super Uper	Milwaukee, WI, USA	2005
1676	KPMG / Dassault Falcon Jet / Honeywell / The Port Authority of NY & NJ & Pascack Valley Regional High School District	The PI-oneers 	The Pascack PI-oneers	Land Shark	Montvale, NJ, USA	2005
1677	General Motors / Western Michigan University / Techcare, President & Owner & Kalamazoo Public Schools	Kalamzoo Area Schools	Quantum Ninjas 	Cedrick	Kalamazoo, MI, USA	2005
1678	Schilling Robotics & Davis Senior High School	Davis Robotics	EnGen	 	Davis, CA, USA	2005
1680	DMI Canada/EDS Canada & Fort Erie Secondary School & District School Board of Niagara	FESStronics	Fort Erie Secondary School	 	Fort Erie, ON, Canada	2005
1682	NASA/Boeing ECF & La Sierra HS	La Sierra	Wired Workers	 	Riverside, CA, USA	2005
1683	Nordson Corp./Siemens Energy and Automation & Northview HS	TechnoTitans	Titans of Steel	Titan Spirit	Duluth, GA, USA	2005
1684	Cypress Computer Systems Inc. & Lapeer East High School	East Alchemists	East Alchemists	 	Lapeer, MI, USA	2005
1685	EMC & Worcester Vocational High School	Tech-Know Commandos	Tech-Know Commandos	 	Worcester, MA, USA	2005
1687	Doherty Memorial High School	Doherty	Dorks	 	Worcester, MA, USA	2005
1688	Port Authority of NY & NJ/Bloomberg LP/Richmond County Savings Foundation & Port Richmond High School	Team Stick Shift	Team Stick Shift	 	Staten Island, NY, USA	2005
1689	Port Authority of New York and New Jersey & Bloomfield High School	Blazing Bengals	Blaze	 	Bloomfield, NJ, USA	2005
1690	Marvell / Sun Microsystems & Ort Shomron High School	Binyamina	The Answer	A-I	Binyamina, NORTHERN, Israel	2005
1691	Friends of Sidney High School Science & Sidney High School	Sidney Salvo	Omega Platoon	Gunrunner	Sidney, MT, USA	2005
1692	Los Angeles Air Force Base / Raytheon Black Employees Network (RAYBEN) / UCLA-MESA / Los Angeles Chapter Professional Black Engineers / Los Angeles Urban League / Los Angeles Unified School District & Crenshaw High School	Crenshaw HS	CougarBots	Ryuuk	Los Angeles, CA, USA	2005
1696	NASA & Sun River Valley Science Club	Simms HS	Mech Tiger	 	Simms, MT, USA	2005
1698	City College of New York (CUNY)/L. Ackman & A. Phillip Randolph HS	Metal Cougars	Metal Cougars (MC^2)	 	New York, NY, USA	2005
1699	Dominion Nuclear Connecticut Inc. & Bacon Academy	Robocats	Robocat	 	Colchester, CT, USA	2005
1700	Evolve Machines/IDEO & Castilleja School	Gatorbotics	Gatorbotics	 	Palo Alto, CA, USA	2005
1701	University of Detroit Mercy / SlipNOT Metal Safety Flooring & University of Detroit Jesuit High School and Academy	RoboCubs	RoboCubs	 	Detroit, MI, USA	2005
1702	Cal Poly Pomona University/Raytheon & CITY HONORS HIGH SCHOOL	Los Platanos Fritos	Los Platanos Fritos	Bananasaurus	Ingelwood, CA, USA	2005
1703	Rancho Aviation Academy & Robotics Club	Rancho Rambots	Rambots	 	Las Vegas, NV, USA	2005
1704	Steelers:     Fontana High School & San Bernardino Valley College	Steelers	Steelers	Steelers	Fontana, CA, USA	2005
1706	General Motors Wentzville Assembly Plant & Timberland & Holt	Wentzville	Mango Fandango	IOWNYA	Wentzville, MO, USA	2005
1708	Robotics Engineering Excellence/The Future is Mine/The Heinz Endowments & McKeesport Area Technology Center	Natural Selection	Natural Selection	 	McKeesport, PA, USA	2005
1710	Ewing Marion Kauffman Foundation / Black & Veatch / Archer Technologies & Olathe Northwest High School	Kauffman & Olathe NW	The Ravonics Revolution	Yosefa	Olathe, KS, USA	2006
1711	TranTek Automation Corporation / Traverse Bay Sunrise Rotary Foundation / Team Elmer's / Artec Interiors / Grand Traverse Resort / Norris-Kennell Family / Great Lakes Eye Consultants  Peter D. Fedor, M.D. / Fifth Third Bank / Traverse City Products, Inc. 	SCI-MA-TECH	SCI-MA-TECH Raptors	 	Traverse City, MI, USA	2006
1712	Feldman & Friends, LLC / Narberth Curves / Vexrobotics.com / The Williamson Free School / Lambda Chi Alpha / Living Logos / Lower Merion School District & Lower Merion High School	LMSD/LMHS 	Dawgma	Galactus	Ardmore, PA, USA	2006
1713	New York Air Brake & Thousand Islands High School	Thousand Islands CSD	Gears	Apex	Cape Vincent / Clayton, NY, USA	2006
1714	Quad Tech / Rockwell Automation / Siemens / NASA / Marquette University / Milwaukee SPE / Pentair Water / MSOE / Rexnord / WalMart / American Acrylics USA LLC & Thomas More High School	More Robotics	More Robotics	Philbert	Milwaukee, WI, USA	2006
1716	ITT-Technical Institute/Barry-WehmillerPCMC & De Pere High School	ITTtech/RedbirdRobotX	R-Squared	3-bird	De Pere, WI, USA	2006
1717	Valley Precision Products / National Security Technologies LLC / Raytheon / Las Cumbres Observatory Global Telescope / FLIR Systems / ATK Space / Santa Barbara County ROP & Dos Pueblos High School Engineering Academy	DP Engineering	D'Penguineers	PenguinBot	Goleta, CA, USA	2006
1718	Ford Motor Company / The Chrysler Foundation / NuStep Inc / The Esenco Corporation / Outback Embroidery / Armada Lions / Strikers Entertainment Center / Emhart Teknologies / Earl Contracting Company / Plymouth Dental Associates, P.C. / Barton Malow / Arma	Ford/Chrysler/MA2S	The Fighting Pi	 	Armada, MI, USA	2006
1719	Park School Parents Association / BD Diagnostics / Lion Brothers Corporation / Advanced Design Products, Inc. & The Park School of Baltimore	 Umbrella Corporation	The Umbrella Corporation	 	Brooklandville, MD, USA	2006
1720	Indiana Department of Workforce Development / Meridian Services / Ball State University & Muncie-Delaware County Schools	MuncieDelawareRobotic	PhyXTGears	Sparky	Muncie, IN, USA	2006
1721	Toyota of Nashua / BAE Systems & Concord Robotics	Concord Robotics	Tidal Force	Tidal Force	Concord, NH, USA	2006
1723	Ewing Marion Kauffman Foundation & Independence School District	Independence S D	The F.B.I. - FIRST Bots of Independence	I Like Pickles	Independence, MO, USA	2006
1724	Weber High School	Weber Fever	Weber Fever	 	Pleasant View, UT, USA	2006
1726	Science Foundation Arizona / US Army IEWTD & Buena High School	N.E.R.D.S.	Nifty Engineering Robotics Design Squad	 	Sierra Vista, AZ, USA	2006
1727	NASA Goddard Space Flight Center (GSFC)/AAI/Raytheon & Dulaney High School	Dulaney Robotics	Rex	Rex	Timonium, MD, USA	2006
1728	Bausch & Lomb/Rochester Institute of Technology & School Without Walls High School, Rochester City School Distri	School Without Walls	B.L.I.N.G.  (Bausch & Lomb Inspires & Nurtures Growth)	The Big Bling Machine	Rochester, NY, USA	2006
1730	Ewing Marion Kauffman Foundation / R&D Tool and Engineering / Black & Veatch / Browns Needlework / Superior Electric Construction Inc. / Aquila / Cerner / Control Service / Kastle Grinding / P1 group / Shelton and Son Lawn and Tree / Electrcal Corporation	Team Driven	Team Driven	 	Lees Summit, MO, USA	2006
1731	Raytheon / DRH Design Group & Fresta Valley Christian High School	Fresta Valley Robotic	Fresta Valley Robotics Club	Riveteer	Marshall, VA, USA	2006
1732	Quad Tech Inc. / Briggs & Stratton / Rockwell Automation / John McDermott Family / Titan Inc. / Marquette University & Marquette University High School	Hilltopper Robotics	Hilltoppers	 	Milwaukee, WI, USA	2006
1733	EMC/Quinsigamond Community College & Worcester North High School	North High School	PolarBots	 	Worcester, MA, USA	2006
1735	WPI & Burncoat High School	WPI / Burncoat H.S.	Green Reapers	D-Fence v3.0	Worcester, MA, USA	2006
1736	Caterpillar Inc & Peoria Heights High School & Richwoods High School & IVC High School	Robot Casserole	Robot Casserole	 	Peoria, IL, USA	2006
1737	Ewing Marion Kauffman Foundation & Excelsior Springs School Distict	Project eXcelsior	Project X	Chip	Excelsior Springs, MO, USA	2006
1739	After School Matters and Motorola / Francis W Parker School / Corn Products International / Google / Brose Technik fur Automobile / Flodyne-Hydradyne / I.D.E.A. / Digital Media Center @ IIT & Agape Werks	Chicago Knights	Chicago Knights	Trogdor	Chicago, IL, USA	2006
1740	Dominion Millstone Power Station & Ledyard High School	LHS	 Cyber Colonels	 	Ledyard, CT, USA	2006
1741	Indiana Department of Workforce Development / Rolls-Royce / National Starch and Chemical Co., Inc / Endress+Hauser / ITT & Center Grove School Corporation	Red Alert	Red Alert	 	Greenwood, IN, USA	2006
1742	OU College of Engineering/Johnson Controls-York/Mickey Clagg & Moore Norman Technology Center	MNTC Robotics	Shockwave	Trigonosaurus	Norman, OK, USA	2006
1743	Singularity Clark LP / Caterpillar Inc & City Charter High School	Short Circuits	Short Circuits	 	Pittsburgh, PA, USA	2006
1744	Seacrest School	Seacrest	Deep Tinkers	Mr. Roboto	Naples, FL, USA	2006
1745	ITT Technical Institute / BAE Syatems / Houston Robotics / Richardson ISD / Pizza Hut, Inc / Siemens PLM Software & J.J Pearce High School	Pearce Robotics	P-51 Mustangs	Air Raid 3	Richardson, TX, USA	2006
1746	Automation Direct & Forsyth Alliance Robotics Team	Forsyth Alliance	Forsyth Alliance	Otto	Cumming, GA, USA	2006
1747	Purdue FIRST Programs/Caterpillar & William Henry Harrison High School	HBR	HBR	 	West Lafayette, IN, USA	2006
1748	Army Research Laboratory/Northrop Grumman Electronic Systems/NASA's Maryland Space Grant Consortium/Morgan State University & Dunbar High School and Patterson High School	LabRats Team 1748	Dunbar/Patterson Lab Rats	Big Cheeze	Baltimore, MD, USA	2006
1750	Charles Machine Works (Ditch Witch) / Larry's Machine Shop / Dr. Charles & Jeanne  Bacon / Stillwater Designs (Kicker) / Bob Howard / Grimsley's Janitorial Supply / Mickey Clagg / KOPCO / Dean Karl & Verna Lou Reid / MyLaptopGPS / Dr. Richard & Ann Lowery	ThunderStorm Robotics	ThunderStorm Robotics	L-Rod (lightning Rod)	Stillwater, OK, USA	2006
1751	North Atlantic Industries & Comsewogue High School	Comsewogue Robotics	The Warriors	 	Port Jefferson Station, NY, USA	2006
1752	Ewing Marion Kauffman Foundation / Wattmaster Controls Inc / Clayco Electric / WHS Booster Club & Winnetonka HIgh School	Tonka Robotics	Tonka	The Crab or The Claw	Kansas City, MO, USA	2006
1755	After School Matters and Motorola & Percy L. Julian High School	Electro Matrix	Jaguarbotics	Relative Notion	Chicago, IL, USA	2006
1756	Caterpillar Inc & Manual High School & Farmington High School & Limestone High School & Richwoods High School & Metamora High School & Peoria High School & Brimfield High School & Peoria Area Home Schools	Argos	Argos	 	Peoria, IL, USA	2006
1757	Westwood High School	Westwood (MA) High	Wolverines	 	Westwood, MA, USA	2006
1758	Roche Carolina / GE Volunteers / Progress Energy / Florence Darlington Technical College & Florence School District One	FSD1 Technomancers	Technomancers	F.E.A.R (Florence Engineering and Robotics	Florence, SC, USA	2006
1759	El Segundo High School	El Segundo Robotics	Eagles	 	El Segundo, CA, USA	2006
1760	Freescale Semiconductor/Indiana Department of Workforce Development/Delphi/Dr Richard Lasbury DDS/Duke Energy & Taylor Community Schools	Taylor Robotics	Robo-Titans	 	Kokomo, IN, USA	2006
1761	GE Volunteers & Lynn Vocational Technical Institute	Lynn Tech / GE	TekClaz	Siriuz Biznes	Lynn, MA, USA	2006
1763	Ewing Marion Kauffman Foundation / Midwest Research Institute / Kansas City Area Life Sciences Institute / Chris Hauber / Global Re-Source Funding & Paseo Academy of Fine and Performing Arts	Paseliens	Zeus	Flora	Kansas City, MO, USA	2006
1764	EWING MARION KAUFFMAN FOUNDATION / Pride Manufacturing / Aquila, Inc. / ProAct Marketing Group & Liberty High School	Liberty Robotics	Dirty Gears	Ham Sandwich	Liberty, MO, USA	2006
1765	General Motors, ERIE 1 BOCES	Great Minds	Great Minds	Goliath	Cheektowaga, NY, USA	2006
1766	Columbus Area Career Connection High School	 Temper Metal	TM	 	Columbus, IN, USA	2006
1768	Cisco Systems & Nashoba Regional HS	Nashoba	Nashoba	 	Bolton, MA, USA	2006
1769	Ewing Marion Kauffman Foundation / Inland Tool / ATS Kansas City, Kansas / The University of Kansas / Cable-Dahmer Chevrolet Car Dealership of Kansas City / General Motors Fairfax Assembly & J. C. Harmon High School	JC Harmon & Kauffman	Hawks	Hawkinator	Kansas City, KS, USA	2006
1771	Women in Technology / Meggitt Training Systems US / CAB Incorporated / SWIFT ATLANTA / Georgia Precision & North Gwinnett High School	WIT CAB NorthGwinnett	404 The Unknown Error	Steel Phoenix	Suwanee, GA, USA	2006
1772	Prefeitura de Gravatai / SMED Gravatai / Pirelli / General Motors / FreeSurf / Armazem dos Parafusos / Brascril & AIDTEC & Houston Robotics & Heitor Villa Lobos Estate High School	AIDTEC	AIDTEC Trail Blazers	Gravatai R-03	Gravatai, RS, Brazil	2006
1775	Ewing Marion Kauffman Foundation / Hallmark / Cerner & Lincoln College Preparatory Academy	Lincobotics	Tigerbytes	 	Kansas City, MO, USA	2006
1776	Ewing Marion Kauffman Foundation & DeLaSalle Education Center	DeLaSalle	Declaration	 	Kansas City, MO, USA	2006
1777	Ewing Marion Kauffman Foundation/RTE Technologies, Inc. & Shawnee Mission West High School	Viking Robotics	Viking Robotics	Brunhilda	Overland Park, KS, USA	2006
1778	Bezos Family Foundation / Edmonds Community College / CH2MHill / Dan Terry Inc. / Society of Professional Engineering Employees in Aerospace / Intermec Corporation & Mountlake Terrace High School	Mountlake Terrace HS	Hawks	Chilly 2.0	Mountlake Terrace, WA, USA	2006
1779	Excel High School & Monument High School	Excel-Monument	G. St. Techies	 	South Boston, MA, USA	2006
1780	NASA/Broadbent & Associates/Graystone Inc./Hydro Arch/Republic Services & Basic High School	Basic/Broadbent	Wolves Robotics	 	Henderson, NV, USA	2006
1781	After School Matters and Motorola & Lindblom Math and Science Academy	Electric Eagles	Eagle-Bots	Achilles	Chicago, IL, USA	2006
1782	Ewing Marion Kauffman Foundation/Aquila, Inc./Ford Assembly Plant & Raytown High School	RAYTOWN BLUEJAYS	BLUEJAYS	 	RAYTOWN, MO, USA	2006
1783	NE Mich Industrial Assoc. / Sandvik, Inc. / West Branch Regional Medical Center / McDonalds of West Branch / Kiwanis Club of West Branch / Optimist Club of West Branch / Lay Industries / Hart Pontiac GMC Buick / North Central Michigan Community Foundation	Ogemaw Heights	Falcon Firebots	 	West Branch, MI, USA	2006
1784	Seherr-Thoss Foundation/Litchfield Education Foundation/SSyD & Litchfield High School	LHS Robotics	Litchbots	Sonny	Litchfield, CT, USA	2006
1785	Ewing Marion Kauffman Foundation/Aquila/GE Volunteers & Blue Springs South High School	KauffmnAquilaGEBSSHS	JagWired Robotics	Jaginator	Blue Springs, MO, USA	2006
1787	NASA Glen Research Center / Medical Device Solutions & Orange High School	OHS	Rusted Oranges	Rusty	Pepper Pike, OH, USA	2006
1788	ITT Technical Institute / GE Volunteers / Georgia Institute of Technology RoboJackets / Arthur Blank Foundation / Delta Air Lines, Inc. & Southside Comprehensive High School	Robolazers	Robolazers	Game Over II	Atlanta, GA, USA	2006
1789	Henderson Mill & West Grand High School Robotics	Thingamabots	Thingamabots	 	Kremmling, CO, USA	2006
1791	First Robotics-anonymous sponsor/Godwin Pumps/National Auto Sales & Clayton HS	Clayton HS	T.O.P. Hatters	B.O.B.	Clayton, NJ, USA	2006
1793	Leadership Center for Science & Engineering / GE Volunteers of GE Energy / BAE Systems -Norfolk Ship Repair / Old Dominion University / ECPI College of Technology / Tabet Manufacturing & Norview High School	Norview High School	The Pilots	ACE	Norfolk, VA, USA	2006
1795	Coca Cola/Arthur Blank Foundation & School of Technology at Carver	SOT Technobots	SOT3 Triple Threat Technobots	 	Atlanta, GA, USA	2006
1796	NASA & Queens Vocational and Technical HS	SCEETERS	ROBOTIGERS	 	LongIsland City, NY, USA	2006
1798	NASA & Flowing Wells High School	NasaCaballeros	NasaRoboKnights	 	Tucson, AZ, USA	2006
1799	South Jeffco Robotics @Dakota Ridge	Nighthawks	predators	 	Littleton, CO, USA	2006
1800	Ewing Marion Kauffman Foundation & Bonner Springs High School	BSHS Bravebotics	Bravebotics	ALF	Bonner Springs, KS, USA	2006
1801	Entergy/Houston Robotics/Lamar University Electrical Engineering & Kountze High School	Kountze HS	The Dapper Dans	Steely Dan	Kountze, TX, USA	2006
1802	Ewing Marion Kauffman Foundation / Black & Veatch & Piper High School Physics Club	Piper	Stealth	Stealth 3.0	Kansas City, KS, USA	2006
1803	Port Washington Educational Foundation/Strober Building Materials & Paul D. Schreiber High School	Port Vikings	Vikings	Woodworks	Port Washington, NY, USA	2006
1804	Harley-Davidson Kansas City Plant / Ewing Marion Kauffman Foundation & Oak Park High School	Northman Robotics	Northmen	 	Kansas City, MO, USA	2006
1805	Ewing Marion Kauffman Foundation / Burns and McDonnell Engineering / Under Tech, Inc. / DeVry University / Mid-America Merchandising, Inc. / Martin Sprocket and Gear, Inc / SBE / DuBois Consultants, Inc. / JustRite Machinery / G & H Consulting / Barry Dis	KC HOT BOTS	HOT BOTS	 	Kansas City, MO, USA	2006
1806	Ewing Marion Kauffman Foundation/Harley-Davidson/Aquila/LABCONCO & Smithville High Tech Group	SHS WARRIORS	S.W.A.T.	SCET	SMITHVILLE, MO, USA	2006
1807	Bristol-Myers Squibb / TAH Enterprises / GAUM Inc & Allentown High School	Allentown Robotics	Redbird Robotics	 	Allentown, NJ, USA	2006
1808	Freeport High School	Red Devils	Red Devils	 	Freeport, NY, USA	2006
1810	Honeywell International / Lawler Gear Corp. / Country Club Bank / DST Systems, Inc. / Baker Bookkeeping and Taxes / ABLE, Inc. / Ewing Marion Kauffman Foundation & Mill Valley High School	Psychotechnica	Jaguars	 	Shawnee, KS, USA	2006
1811	The Port Authority of New York & New Jersey / New Jersey Institute of Technology & East Side High School	East Side High School	FRESH	Canti	Newark, NJ, USA	2006
1814	TDSB & Northview Heights SS	Northview Heights SS	Phoenix In Fight	Phoenix 	Toronto, ON, Canada	2006
1815	TDSB & Sir John A Macdonald CI	Macdonald CI	Team Sigma	 	Toronto, ON, Canada	2006
1816	Medtronic / Ecolab / Honeywell / Wanner Engineering / FWR Communication Networks & Edina High School	Edina Robotics	"The Green Machine"	"Zerkit"	Edina, MN, USA	2006
1817	Texas Tech University / Bezos Foundation & Lubbock HS & Estacado HS & Monterey High School	LISD & Bezos/NASA/TTU	Llano Estacado RoboRaiders	 	Lubbock, TX, USA	2006
1818	NASA/AEP SWEPCO/General Motors Shreveport Assembly Plant/Service Electric & LSUS & Southwood High School	Southwood High School	Cowboys	 	Shreveport, LA, USA	2006
1820	Planet Technologies/BAE/Intelligent Automation, Inc./Materials Handling Systems, Inc. & Colonel Zadok Magruder High School	Havoc	Havoc	 	Rockville, MD, USA	2006
1823	Lincoln High School	ping 	the fighting pings	ping	portland, OR, USA	2006
1824	Region 14 ATC & ConVal High School	Apollos	1824	 	Peterborough, NH, USA	2006
1825	Ewing Marion Kauffman Foundation/Metro Academy & Johnson County Homeschool	JC Homeschool	JC Homeschool	 	Blue Springs, MO, USA	2006
1827	EWING MARION KAUFFMAN FOUNDATION & Center High School	CHS Robo-Tech	Robo-Tech	The STING	Kansas City, MO, USA	2006
1828	NASA/UA Science and Technology Park & Vail High School	Vail High School	BoxerBots	DEFAULT 7	Vail, AZ, USA	2006
1829	NASA / BAE Systems / ODU & Arcadia High School	Firebots	'Da Bots	 	Oak Hall, VA, USA	2006
1831	BAE/New Hampshire Ball Bearing/Gilford Rotary Club & Gilford High School	GIlford High School	Screaming Eagles	Nebuchadnezzar	GIlford, NH, USA	2006
1834	BAE SYSTEMS/Google/San Jose Job Corps/MetroED & SIATech	Evolution	Evolution	EVO	San Jose, CA, USA	2006
1835	TDSB & RH King Academy	RH King Academy	RH King Academy	Metal King	Toronto, ON, Canada	2006
1836	Leslie Zola Science Scholarship & Mitchell Academy of Science and Technology & Milken Community High School	MilkenKnights	MilkenKnights	The Killer Rabbit	Los Angeles, CA, USA	2006
1841	Bank of America, Ace Underwriting Group, Devry University,  Lucas Orthodontics, Prospect Plastics, EPTS,  Identity Eye Wear,  Identity Resort Wear & South Plantation High School	Crazy Bred	Crazy Bred......Yeeeeaah!!	Sneeble I	plantation, FL, USA	2006
1845	National Soc. Black Engineers / Teradata Corporation / ITT Technical Institute / Arthur Blank Family Foundation & D. M. Therrell High School	CyberPanthers	Cyber Panthers	Panthera Robotica	Atlanta, GA, USA	2006
1846	Research In Motion / Mellon / Ontario Power Generation & Conseil scolaire des écoles catholiques du Sud-Ouest & Saint-Francois-Xavier High School	SFX	X-MEN	Elite	Sarnia, ON, Canada	2006
1847	Ewing Marion Kauffman Foundation & Wyandotte High School	Wyandotte	Bullbots	 	Kansas City, KS, USA	2006
1848	Women In Technology / Qcept Technologies / Georgia Tech Robojackets / Applied Systems Intelligence / ITT Tech(Kennesaw) / Denford & East Cobb Middle School & Georgia Robotics Alliance	Georgia Alliance	SOUP	 	Marietta, GA, USA	2006
1850	NASA & ACE Technical High School	ACE Tech Mechanicats	Mechanicats	 	Chicago, IL, USA	2006
1852	NASA & SUSD & Desert Mountain High School	Team Amore	Team Amore	Roadkill	Scottsdale, AZ, USA	2006
1855	The Annenberg Foundation / FIRST & Magnolia Science Academy High School	MSA MagnoBots	MagnoBots	Magnomus Prime	Reseda, CA, USA	2006
1858	NASA/Lockheed Martin Michoud Space Systems & Salmen High School	Mighty Spartans	Spartans	 	Slidell, LA, USA	2006
1859	NASA/Bogalusa Daily News/Gaylord Chemical/Lockheed Martin/Temple Inland -Bogalusa & Bogalusa High School	NASA Temple-Inland GC	RoboJacks	panzer	Bogalusa, LA, USA	2006
1860	Johnson & Johnson  & CEPHAS - H.A.Souza Professional Training Center	J&J & CEPHAS	CEPHAS	 	Sao Jose dos Campos, SP, Brazil	2006
1862	21st Century/Port Authority of New York New Jersey & Cliffside Park High School	Red Raiders 	Red Raiders 	PX4	Cliffside Park, NJ, USA	2006
1864	NASA/Briggs & Stratton Corporation/Marquette University/CG Schmidt Construction/Milwaukee School of Engineering/Bentley World Packaging & Messmer High School	Messmer	Bishops	 	Milwaukee, WI, USA	2006
1865	NASA / Lawrence Petru / Dent Free America / Attractions Unlimited / H.C. Pickett / Joseph Woodcox / Jared Jameson / M&L / Texas Direct Auto / Texas Direct Auto / Shell International Technology, Inc / Shell International Technology,Inc / FIRST / ITT Techni	Y.E.S.	Young Engineers Succeeding	 	Missouri City, TX, USA	2006
1867	C-STEM Teacher & Student Support Services, Inc./Shell & Phillis Wheatley High School	Wildcats	The Prowlers	 	Houston, TX, USA	2006
1868	NASA Ames Research Center / BAE Systems / Microsoft / Stellar Solutions / Federal Aviation Adm. & Girl Scouts	NASA / Girl Scouts 	Space Cookies	 	Moffett Field, CA, USA	2006
1870	Premier Integrated Technologies & Hunting Hills High School	Team Lightning	The Lightning Arx	Arc II.OH!	Red Deer, AB, Canada	2006
1872	NASA/Johnson & Johnson & Colegio San Ignacio de Loyola	Colegio San Ignacio	Yellow Fever	El Jibarito Ver. 3	San Juan, PR, USA	2006
1875	Brevard Public Schools & Space Coast High School	Autonomato Autonomato	Autonomatons	 	Cocoa, FL, USA	2006
1876	The Dement Family Fund / Community Foundation of the Lowcountry & Hilton Head High School & Beaufort County School District	Beachbotics	Beachbotics	Sandroid	Hilton Head Island, SC, USA	2006
1877	WIT Foundation & Lumpkin County High School	Lumpkin County Miners	Gold Diggers	 	Dahlonega, GA, USA	2006
1880	Bloomberg / East Harlem Tutorial Program / NASA & Central Park East High School	East Harlem Warriors	W.O.E.H	Jackie 3	New York, NY, USA	2006
1881	State Farm / Novartis / BMW of NA & Garrett Morgan Academy High School	The Generals	The Generals	Nebus	Paterson, NJ, USA	2006
1883	NASA/UNLV & Del Sol High School	Del Sol 	Dragons	The Resolute	Las Vegas, NV, USA	2006
1884	Inmarsat / Orange & The American School in London & Quintin Kynaston High School	ASL-QK	Griffins	Chachi 2: Electric Boogaloo	London, UK, Great Britain	2006
1885	TKC Communications / Micron Technology / SI International / SAIC / Aurora Flight Sciences / George Mason University / ASCO / Thermopylae Sciences & Technology / Lockheed Martin / Data Tactics / BAE Systems / Virginia National Guard & Battlefield High Scho	Battlefield Robocats	Robocats	Paws Of Steel	Haymarket, VA, USA	2006
1886	BAE Syatems & Urbana High School	UHS	Hawks	 	Ijamsville, MD, USA	2006
1887	Idaho National Laboratory / Idaho State University & Shelley High School	Shelley Robotics Club	Russet Robotix	 	Shelley, ID, USA	2006
1891	Idaho National Laboratory / Micron Technology / Hewlett-Packard & Mountain View High School	Bullbots	Bullbots	Robo Bull	Meridian, ID, USA	2006
1893	Sylvan  Laureate Foundation, Inc. / Netzer Metal Craft / Maryland Space Grant Consortium / Morgan State University & Baltimore Polytechnical Institute	Baltimore Poly Tech	High Tech Parrots	Poly	Baltimore, MD, USA	2006
1894	Datta Consultants, Inc./Maryland Space  Grant Consortium/Morgan State University/NASA/Sylvan Laureate Foundation & WEB DuBois High School	  Elite	The Elite	Counterstrike	Baltimore, MD, USA	2006
1895	Lockheed Martin / The Williams Companies Foundation,Inc / Micron Technology, Inc. / Scitor Corporation / Aurora Flight Sciences Corporation / Hayward Family / City of Manassas Public Schools Education Foundation, INC / SignGraphx & Osbourn High School	Lambda Corp	Lambda Corp	Avenger	Manassas, VA, USA	2006
1896	Traverse Bay Area Intermediate School District & Manufacturing Technology Academy of Northwest Michigan High School	MTA	Concussive Engineers	Xena	Traverse City, MI, USA	2006
1897	Intel/Society of Mexican American Engineers and Scientists (MAES) & South Valley Academy High School	SVA	Red Hot Chile Dragons	 	Albuquerque, NM, USA	2006
1898	ASME/C-STEM/NASA/SHELL & Westside High School	Westside Wolves	Wolves	 	Houston, TX, USA	2006
1899	Case Engineering / Magellan Architects / Bezos Family Foundation & Interlake High School	Saints Robotics	Saints	 	Bellevue, WA, USA	2006
1900	Booz Allen Hamilton / Rotary Club of Washington, DC / BAE Systems & T. Roosevelt Senior High School	Roosevelt	Rough Riders	 	Washington, DC, USA	2006
1902	D6 Industries, Inc./Lockheed Martin/Disney-DeVry University & 4-H of Orange Co. Fla & Lake Highland Preparatory School	4-H Exploding Bacon	Exploding Bacon	 	Winter Park, FL, USA	2006
1904	Maryland Space Grant Consortium / Morgan State University & Walbrook High School Campus	Walbrook	Warbots	 	Baltimore, MD, USA	2006
1907	Prince Edward High School	Prince Edward HS	Birds of Prey	Phoenix 1.0	Farmville, VA, USA	2006
1908	Northampton High School	NHS	Yellow Jackets	 	Eastville, VA, USA	2006
1912	Shell Exploration & Production Company / Woodside USA / NASA / Lockheed Martin / Taylor Energy Company LLC / Planning Systems Inc & St. Tammany Parish School Board & Northshore High School	Team Combustion	Team Combustion	Hoss	Slidell, LA, USA	2006
1915	NASA & McKinley Technology High School	MTHS Robotics 	MTHS Robotics	 	Washington, DC, USA	2006
1916	Akamai Foundation & Madison Park Tech Voc High School	Madison Park Robotics	MADISON PARK Robotics	The MP MACHINE	Roxbury, MA, USA	2006
1918	Kaydon Bearings/Illinois Tool Works/The Fremont Area Community Foundation/The Gerber Foundation/The people of Newaygo County & Newaygo County Regional Educational Services Association (NC RESA) and Fremont, Newaygo, Grant, and Providence	NC GEARS	Cognitive Diligence	 	Fremont, MI, USA	2006
1920	NASA/BLAST Foundation/Intralox/LEAP Program  University Of New Orleans/Lockheed Martin & McMain Secondary High School	Hurricanes	McMain Hurricanes	Pink Panther	New Orleans, LA, USA	2006
1922	BAE Systems/Osram-Sylvania/www.TheDataLoggerStore.com & Hopkinton High School & John Stark High School	OZ-Ram	OZ-Ram	Tin Man III	Contoocook/Weare, NH, USA	2006
1923	Friends of 1923 & West Windsor-Plainsboro High School North	MidKnight Inventors	MKI Robotics	The Knight Rider	Plainsboro, NJ, USA	2006
1926	NASA / Embry Riddle University / Wilson Electric / NAU / Troops To Teachers / Intel / Microchip Technology & NATIVE and EVIT High School	TEAM 8-Bit	Team 8-Bit	Outsource	Mesa, AZ, USA	2006
1927	Northrop Grumman / Stennis Space Center / NASA / Mississippi Power Company / PFG Optics / Lifetime Portable Buildings, LLC / Metal Tech & St. Patrick Catholic High School	Team Tempest	Tempest	Noah 	Biloxi, MS, USA	2006
1929	Credit Suisse & Montclair Board of Education	MHS Girl's Team 1929	FoxyBots	 	Montclair, NJ, USA	2006
1930	Lee Garelick / Read's Ice Cream / Gripa / Rochester Software Associates / Cleaning with Care / Mr. and Mrs. Murray / Mark's Remodeling / Klein Steel / T & T Materials & Rush Henrietta	Comets	Comets	Jolly Roger	Henrietta, NY, USA	2006
1933	Doncaster Aimhigher & Ridgewood high school	The Crew	Sailors	 	Doncaster, UK, Great Britain	2006
1937	Boeing Israel & Maccabim Reut High school	Maccabim Reut	Elysium	 	Reut, Central, Israel	2006
1939	Ewing Marion Kauffman Foundation & The Barstow School	Barstow Knights	Kuh-nig-its	Sir Robin	Kansas City, MO, USA	2006
1940	Benton Harbor High School	BHHSWhirl-Hut	The Tech Tigers	Moble Suit Tiger	Benton Harbor, MI, USA	2006
1941	The Chrysler Foundation / ITT Technical Institute / D.R.M. Stakor and Associates & Frederick Douglass College Preparatory Academy	Fred D. Hurricanes	The Hurricanes	The Hurricane	Detroit, MI, USA	2006
1942	IAF-ASSOCIATION/IAF-DEPOT 22 & ORT TEL NOF H.S high school	ORT Tel-Nof	Tel-Nof	SINDERELLA	Tel-Nof, Central, Israel	2006
1943	Begin High School	Begin High School	Neat Team	 	Rosh Hayin, Central, Israel	2006
1944	Israel Air force & Technical Airforce H.S.	Airforce High School	Airforce High School	Ramnik	Haifa, Haifa, Israel	2006
1946	OPGAL OPTRONIC INDUSTRIES & Abu Roomi	Abu Romi	Abu Romi	 	Tamara, Northern, Israel	2006
1947	Alliance Industries/GM UMI Israel & Sciences & Arts Amal1 H.S.	Sciences & Arts H.S.	BlacKnight Robotics	Iron Man	Hadera, Central, Israel	2006
1949	Clal Industries & Shapira, Natanya H.S.	Shapira	shapira	 	Natanya, Central, Israel	2006
1951	Tel Aviv Municipality & Ort Singolovsky	Ort Singolovsky	Ort Singolovsky	 	Tel Aviv, Tel Aviv, Israel	2006
1952	Arming force H.S.	Arming High School	Arming High School	 	tzrifin, Central, Israel	2006
1955	Beit Yerah	Beit Yerah	Beit Yerah	 	Emek Hayarden, Northern, Israel	2006
1957	Altshuler Shaham/Assatec/Intel & Nofey Golan	Ort Nofey Golan	LighTeam	Laika	Katzrin, Northern, Israel	2006
1959	FN Manufacturing/Siemens VDO/Southern Expediting Inc. & Blythewood High School	Aye, Robot	Aye, Robot	One Armed Sam	Blythewood, SC, USA	2006
1965	EMC Corporation & Mount Saint Joseph Academy	EMC & MSJA	The Eagles	 	Brighton, MA, USA	2006
1967	BAE SYSTEMS/Google & Notre Dame High School	Google Notre Dame	The Janksters	 	San Jose, CA, USA	2006
1972	Qualcomm & Imperial Valley MESA Program & Central Union High School	CUHS and IV MESA	Searing Engineering	Spartan 16	El Centro, CA, USA	2006
1973	Smith Family Foundation of Boston & Brighton High School	BRIGHT BURNING TIGERS	BBT'S	 	Boston, MA, USA	2006
1977	Colorado Technical University/Northrup Grumman Denver, CO & Loveland High School	Loveland High School	Virtual Commandos	 	Loveland, CO, USA	2006
1980	Army Research Laboratory / Black & Decker / Interactive Communications Research & Aberdeen High School	SMA-Aberdeen	The Brigade	 	Aberdeen, MD, USA	2006
1981	Ewing Marion Kauffman Foundation & Van Horn High School	Van Horn Robot Team	The Gearheads	King Twitchy	Independence, MO, USA	2007
1982	Ewing Marion Kauffman Foundation & Shawnee Mission Northwest High School	Northwest HIgh School	Cougar Robotics	Cougar Robotics	Shawnee, KS, USA	2007
1983	Galvin Flying Service / Society of Professional Engineering Employees in Aerospace / AHS PTSA / OMAX & Aviation High School	Aviation High School	Skunkworks	Das Uber Stinktier	Des Moines, WA, USA	2007
1984	Ewing Marion Kauffman Foundaton/NASA/Shawnee Mission Education Foundation & Shawnee Mission South High School	Raider Robotics	Raider Revolution Robotics	GEORGE	Overland Park, KS, USA	2007
1985	Emerson/NASA/DRS & Hazelwood Central High School	Robohawks	Robohawks	 	Florissant, MO, USA	2007
1986	Ewing Marion Kauffman Foundation & Lee's Summit West High School	Team Titanium	Team Titanium	 	Lee's Summit, MO, USA	2007
1987	Ewing Marion Kauffman Foundation / Douglas and Shari Edwards / Aquila / R&D Tool and Engineering / Cerner Corporation / Honeywell / Kastle Grinding / High Tech Laser & Engraving / Associated Women's Care / JCI Industries / Securitas Systems / Shafer Compu	Lees Summit North HS	Broncobots	Mammoth	Lees Summit, MO, USA	2007
1988	Rockwell Automation / Generac Power Systems, Inc. / Johnson Controls Inc / Mathison Metalfab, Inc & School District of Kettle Moraine	KM Girls Robotics	The Sweetie Pies	The BEAST	Wales, WI, USA	2007
1989	Vernon Township High School	Vernon	Viking Robotics	Thor	Vernon Township, NJ, USA	2007
1990	NASA & Cloverleaf Local Schools	Rammathorn	Galloping Cop	Ramrod	Lodi, OH, USA	2007
1991	GE Volunteers / Integralis / Hartford Public Schools / University of Hartford / NASA & University High School of Science and Engineering & American School for the Deaf	UHSEE	Dragons	Wiki	Hartford, CT, USA	2007
1992	DST Sytems, Inc./Ewing Marion Kauffman Foundation & Raytown South High School	Robocards	Raytown South Robocards	 	Raytown, MO, USA	2007
1994	Ewing Marion Kauffman Foundation and F.L. Schlagle High School	F.L. Schlagle HS	The mighty stallions	 	Kansas City, KS, USA	2007
1995	University of Maine & United Technologies Center  Region #4	UMaine & UTC	Fatal Error	 	Bangor, ME, USA	2007
1996	Ewing Marion Kauffman Foundation / Fike Corporation / Aquila / Honeywell / Siemens & Blue Springs High School	Wildcat Robotics	Wildcat Robotics	 	Blue Springs, MO, USA	2007
1997	Ewing Marion Kauffman Foundation & Bishop Miege High School	Stagbots	Stag Robotics	 	Roeland Park, KS, USA	2007
1998	NASA / Rayconnect / Livernois Vehicle Development & Robichaud High School	Robodogz	Robodogz	ROBODOG	Dearborn Heights, MI, USA	2007
1999	Jacobs Engineering / S.A.M.E. / First City Bank / NDIA & Fort Walton Beach High School & OWC Collegiate High School	Okaloosa United	O.U.T.E.R Limits	 	Fort Walton Beach, FL, USA	2007
2001	Ewing Marion Kauffman Foundation & Hickman Mills High School Robotics Team	Hickman Cougars	Wild Cats	Elmo	Kansas City, MO, USA	2007
2002	NASA & Tualatin High School	TuHS Robotics	TETRA (Tualatin Engineering, Technology, and Robotics Associatio	 	Tualatin, OR, USA	2007
2004	Neosource Aerospace Repair and Manufacturing / World Manufacturing & Tulsa Technology Center	TTC Robotics	ThunderDucks	 	Tulsa, OK, USA	2007
2007	Spinner Atlanta/ITT Technical Institute & Duluth High School & Gwinnett County Public Schools	DHS-Spinner-ITT-Tech	Robots of the Round Table	Sir Gearsalot	Duluth, GA, USA	2007
2008	Ewing Marion Kauffman Foundation & Northeast High School	VIKING VOYAGER ROBOT	VI VOT	VIKING VOYAGER ROBOT	Kansas City, MO, USA	2007
2009	Smith Family Foundation and New Mission High School	Forbidden Planet	Forbidden Planet	Robby the Robot	Roxbury, MA, USA	2007
2010	Delphi Corporation / NASA & Champion High School	Delphi & Champion HS	Lightning Bots	The Flash	Warren, OH, USA	2007
2011	Ewing Marion Kauffman Foundation & St. Mary's High School Bundschu Memorial	SMH Renegade Robotics	SMH Robotics	010100110100110101001000	Independence, MO, USA	2007
2012	North Kansas City Iron & Metal / Tech Gurus / Cummins Tools / Ewing Marion Kauffman Foundation & North Kansas City High School	Zenith Robotics 	@ Zenith	 	North Kansas City, MO, USA	2007
2013	ARO Technologies & Stayner Collegiate Institute High School	Cyber Gnomes	Cyber Gnomes	 	Stayner, ON, Canada	2007
2014	General Motors Foundation / NASA & Hazelwood East High School	Spartan Robotics	Spartans	 	St. Louis, MO, USA	2007
2015	Aalderink Electric Co. / NASA / Ronald McDonald House Charities of Outstate Michigan- / Parkway Electric & Wavecrest Career Academy	Wavecrest	The Wave	 	Holland, MI, USA	2007
2016	Johnson & Johnson Consumer Products Worldwide / NASA / Janssen Pahrmaceutica & Ewing High School	EHS Robotics	Mighty Monkey Wrenches	 	Ewing, NJ, USA	2007
2021	NASA/New World Associates & Fredericksburg Academy	FA Robotics	FAR	 	Fredericksburg, VA, USA	2007
2022	Caterpillar Inc & Illinois Mathematics and Science Academy	IMSA FIRST Robot Club	Vulcans	 	Aurora, IL, USA	2007
2023	Government Connections / The ABLE Trust / Papa John's Pizza Co. / Harris Corporation / Florida Space Grant Consortium & Brevard County Schools & Palm Bay High School PiraTech Robotics	PiraTech Robotics	PiraTech	The Flying Dutchman	Melbourne, FL, USA	2007
2024	Hawaii Space Grant Consortium/Caltech submillimeter Telescope & Waiakea High School	Kekoa O Haaheo	Warrior Pride	Stich IV	Hilo, HI, USA	2007
2027	Westbury High School	Westbury Rayout	Rayout	 	Old Westbury, NY, USA	2007
2028	Lockheed Martin/Northrup Grumman Newport News/Georgia Tech Research Institute/NASA/Craft Engineering & Phoebus High School & Hampton City Schools	HCS/PHS	Phantom Robotics	 	Hampton, VA, USA	2007
2029	Qualcomm / NASA / Stoody Industrial and Welding Supplies Inc. & Sun Valley Charter High School	Neo-Tech Robotics	Neo-Tech Robotics	P.O.S	Ramona, CA, USA	2007
2030	Ewing Marion Kauffman Foundation & Westport High School	Westport 'Botics	RoboTigers	 	Kansas City, MO, USA	2007
2031	NASA/American Electric Power/Battelle/The Ohio State University/Columbus State Community College/Columbus Public Schools & Southeast Career Center High School & Walnut Ridge High School	Scotts	Brainy-Actz	Unknown Quantity	Columbus, OH, USA	2007
2032	NASA / Miramar College / San Diego High Foundation / San Diego Downtown Rotary Club / Qualcomm / Industrial Metal Supply / Hawthorne Machinery / Quicksilver clothing & SAN DIEGO HIGH EDUCATION COMPLEX <HIGH SCHOOL>FUNKY MONKEYS	San Diego High	Funky Monkeys	THOR	San Diego, CA, USA	2007
2034	NASA/University Nevada, Las Vegas & Legacy High School	Legacy High School	IncrediBULLS	¥ "The Robot Formerly Known as Ferdinand"	North Las Vegas, NV, USA	2007
2035	NASA/Monterey Bay Internet & Carmel High School	Robo "Rockin" Bot	"Rockin" Bots	 	Carmel, CA, USA	2007
2036	NASA / McGuckin Hardware Store / Ball Aerospace & Technologies Corp / Monarch High School / IBM / Impact On Education / Laboratory for Atmospheric and Space Physics & Fairview High School	The Black Knights	The Knights	Johnny 5	Boulder, CO, USA	2007
2037	NASA / Electrical Dynamics / American Spouses Club / Bryan Blankenship & AFNORTH American DODEA High School	Unique Custom  Robots	UCR	ZemZam	Brunssum, The Netherlands, Other, Other	2007
2038	Caterpillar Inc / NASA & Spalding High School	Cat/NASA/Spalding HS	Sky Bandits	 	Griffin, GA, USA	2007
2039	NASA/Woodward Governor/Hamilton Sundstrand & Rockford Public High Schools (Dist. 205)	Rockford Robotics	Rockford Robotics	Robo-Talon	Rockford, IL, USA	2007
2040	NASA/eServ, a Perot Systems Company & Dunlap High School	D.E.R.T.	D.E.R.T.	 	Dunlap, IL, USA	2007
2041	After School Matters and Motorola & Roberto Clemente High School Robotics	Clemente Robotics	The Roboticats	 	Chicago, IL, USA	2007
2042	NASA/Canyon Engineering/Electrorack Enclosure Products/Numatics Engineering & Academy of the Canyons Middle College High School	AOC-ROBO-TREES	Robo-trees	Hal	Santa Clarita, CA, USA	2007
2043	The Smith Family Foundation/Wentworth Institute of Technology & J D. O'Bryant School of Math and Science High School	OB Tigers	Frequency 2043	 	Roxbury, MA, USA	2007
2044	BAE Systems / Applied Information Management (AIM) Institute / Nebraska Advanced Manufacturing Coalition / Booz Allen Hamilton & Papillion LaVista High Schools	Big Red Robotics	Big Red Robotics	 	Papillion, NE, USA	2007
2045	Mickey and Debbie Clagg / EnerQuest Oil & Gas, L.L.C. & Metro Technology Centers	Metro Technology 	Robo-Techs	Timmy II	Oklahoma City, OK, USA	2007
2046	NASA / Andrews Space Incorporated & Tahoma Senior High School	Tahoma Robotics Club	Tahoma Robotics Club	 	Maple Valley, WA, USA	2007
2048	DTE Energy/Ford Motor Co. & Detroit Academy for Young Women High School & Detroit Public Schools	Pink Panthers	Panthers	Pink Teminator	Detroit, MI, USA	2007
2050	The Chrysler Foundation & Southeastern High School of Technology	SE_Blazers	SEB	The Blazer	Detroit, MI, USA	2007
2051	A.W. Beattie Career Center High School	Beattie Career Center	Beattie	Bulldog	Allison Park, PA, USA	2007
2052	Medtronic & Irondale High School	Irondale Robotics	KnightKrawler	Sweetfeet	New Brighton, MN, USA	2007
2053	BAE Systems & Union-Endicott High School	TigerTronics	TigerTronics	Apollo	Endicott, NY, USA	2007
2054	Delphi/Williams Tooling/Electrocal Inc./Byron Bank & Hopkins High School	Viking Robotics	BIG BLUE Crew	BIG BLUE II	Hopkins, MI, USA	2007
2056	CNC Woodcraft / RMT Robotics & Orchard Park Secondary School	Patriotics	Patriotics	Tilt-A-Hurl	Stoney Creek, ON, Canada	2007
2057	NASA/University of Nevada, Las Vegas & Arbor View High School	Arbor View Robotics	AV CyberBulls	McFrizzle	Las Vegas, NV, USA	2007
2061	NASA & Canyon Springs High School	"The Canyon"	Pioneers	Twisted Steel	N Las Vegas, NV, USA	2007
2062	GE Volunteers / Rockwell Automation / NASA / Milwaukee School Of Engineering / Marquette University / HK Systems Inc. / Waukesha Electric & School District of Waukesha	Waukesha School Dist.	C.O.R.E  2062	Helios	Waukesha, WI, USA	2007
2063	Beall Trailers of California, Inc. / Billington Manufacturing Inc / Anything Vinyl / Fastenal & Pitman High School	Pride Robotics	Green Machine	Green Machine	Turlock, CA, USA	2007
2064	Friends of Region 15 FIRST ORganizations LLC & Pomperaug Regional High School	The Panther Project 	The Panther Project	 	Southbury, CT, CT, USA	2007
2065	NASA / Mississippi Space Grant consortium & H W. Byers High School	Team Dynasty	The Lions	 "The Tank"	Holly Springs, MS, USA	2007
2066	NASA/QUALCOMM  Incorporated/Imperial Valley MESA & Southwest High School	Southwest High	PFTB of Doom	 	El Centro, CA, USA	2007
2067	NASA/Bishop's Orchards & Guilford High School	Apple Pi	Apple Pi	APPLE Pi	Guilford, CT, USA	2007
2068	NASA / National Guard / Lockheed Martin / Micron Technology / BAE Systems & Osbourn Park High School	OPHS Metal Jackets	Metal Jackets	Stinger	Manassas, VA, USA	2007
2069	Eldorado High School	Black Widow	Black Widow	Black Widow	Las Vegas, NV, USA	2007
2070	NASA / The Port Authority of NY & NJ / General Devices / S.T.O.P. of New Jersey & Ridgefield Board of Education & Ridgefield PTA & Ridgefield Memorial High School	Ridgefield Robotics	The Royals - P=I<sup>2</sup>.R ates	Rambo	Ridgefield, NJ, USA	2007
2071	Idaho National Laboratory / Idaho State University-GK-12 / Glock INc & Marsh Valley High School	Marsh Valley Robotics	Autonomous Eagles	 	Arimo, ID, USA	2007
2072	NASA & G.W. Carver H.S. for Engineering	Carver Cybernetics	The Cybernauts	 	Houston, TX, USA	2007
2073	NASA & Pleasant Grove High School	PGHS	Eagles	 	Elk Grove, CA, USA	2007
2074	I.C. Norcom High School	NNSY ICN  Robohoundz	Robohoundz	Atomic Dog	Portsmouth, VA, USA	2007
2075	GE Volunteers / NASA / BP & R Engineering / Richard W. Panek DDS & West Catholic High School	West Catholic	Enigma	 	Grand Rapids, MI, USA	2007
2076	Thistletown Collegiate Institute / Canadian Standards Association & Toronto District School Board	TCI Robotics	 Scots	Hasty Hastings	Toronto, ON, Canada	2007
2077	Rockwell Automation / GE Volunteers / Generac Power Systems, Inc. / Mathison Metalfab, Inc & School District of Kettle Moraine	KM Robotics	Laser Robotics	EL JEFE	Wales, WI, USA	2007
2078	L D Inc. / NASA / Vessel Statistics / Chevron Oil / Petersen & Associates / Cembell & St. Paul's High School	SPS	Robotic Ooze	Wolfbot II	Covington, LA, USA	2007
2079	ALARM Millis High School	ALARM	ALARM	JAWS	Millis, MA, USA	2007
2080	NASA / Wal-Mart / Shell Exploration & Production Company / DynMcDermott / Southeastern Louisiana University / Lockheed Martin & Hammond High School	Torbotics	Torbotics	Vortex H-02	Hammond, LA, USA	2007
2081	NASA/Advanced Technology Services & Peoria Notre Dame High School	PND Robotics	Icarus	 	Peoria, IL, USA	2007
2083	NASA / BLITZ Soluitions / Sanders Sound Systems / Lockheed Martin & Team BLITZ  Home School & Conifer High School	Team BLITZ	Team BLITZ	 	Conifer, CO, USA	2007
2084	Manchester Essex Regional High School	Robotsbythe-C	Robotsbythe-C	C Monster	Manchester, MA, USA	2007
2085	Banks Integration Group Inc./IBEW local #180/NASA/Horace & Laura Whitman/Valero Oil Refinery & Solano County Office of Education ROP & VUSD GATE & Vacaville High School	The Bulldogs	Bulldogs	 	Vacaville, CA, USA	2007
2090	NASA/Sam O. Hirota Engineers & Surveyors & Punahou High School	Punahou Robotics	BuffnBlue	 	Honolulu, HI, USA	2007
2091	NASA/Lockheed Martin & Sarah T. Reed Senior High School	Reed Robotics	Olympians	Chariot of Fire	New Orleans, LA, USA	2007
2092	Parker Hanifin / NASA / Pender Brothers / Port Royal Landing Marina & Arts Communication and Technology High School & Beaufort High School & Beaufort County School District	NASA/RACO/P.B/PRM/BHS	Beaufort Robotics / Mad Scientist 	Eaglebot 2	Beaufort, SC, USA	2007
2100	Tropicana Products Inc. / Citibank, N.A. / C&L Technologies / Ross Mixing, Inc. / Ed's Painting and Paperhanging & St. Lucie West Centennial High School	Masters of M.E.T.A.L.	M Squared	G.I.R. (Gears In Retrospect)	Port St. Lucie, FL, USA	2007
2102	Nordson-Asymtek / ViaSat / Bottlerocket Entertainment / Qualcomm / San Dieguito Academy Foundation / Rockstar San Diego / Answers, Plus / Coastal Christian Center & San Dieguito Academy High School	Paradox	Team Paradox	Beasley	Encinitas, CA, USA	2007
2103	Comcast Cable/Gloucester Education Foundation (GEF) & Gloucester High School	Fighting Fisherman	Fisherman	Chaos	Gloucester, MA, USA	2007
2104	Worcester South High School	The Colonels	The Colonels	Six Shooter	Worcester, MA, USA	2007
2106	Luck Stone Corporation/TKL Products Corp & Goochland High School	Goochland High School	The Junkyard Dogs	 	Goochland,, VA, USA	2007
2107	GE Volunteers & Lake Taylor High School	LT Titans	Titans	Olympian	Norfolk, VA, USA	2007
2108	NASA / Qimonda / ASME / Eclectech, Inc / GE / GSK & Green Hope High School	Green Hope HS	Team Awkward Turtle	Zippy T 2	Cary, NC, USA	2007
2110	Smith Family Foundation/Karl Marks, Individual Contributor/ThingMagic Inc. & Charlestown High School	Charlestown High 	CHS	Dragon Spirit	Charlestown, MA, USA	2007
2112	Caterpillar Inc/Multi-Talent Resource Center & Pembroke Consolidated Schools #259	PHP Robo Warriors	PHP Robo Warriors	Beastie Boy	Hopkins Park, IL, USA	2007
2115	Motorola & Mundelein High School	M^3	MCubed	Rngr Eatr	Mundelein, IL, USA	2007
2116	RobotFutures / NASA / AutomationPlus / StoughtonTrailers / Kiwanis / Stoughton Area Community Foundation / GlobalQuota & Stoughton High School	RobotFutures	RobotFutures	Forest Gump	Stoughton, WI, USA	2007
2119	Southern Engineering Services/NASA/Women in Technology- Atlanta GA/GE Volunteers & Sequoyah High School & Creekview High School	Wild About Robotics	W. A. R. 	 	Canton, GA, USA	2007
2120	Doncaster Aimhigher high school	Doncaster 	doncaster 	 	doncaster, UK, Great Britain	2007
2121	Washington Metropolitan Area Transit Authority & Francis L. Cardozo Senior High School	Metro Clerks	CCEXCLUSIVE	MetaDozo_J5	Washington, DC, USA	2007
2122	Hewlett Packard / M. J. Murdock Charitable Trust / NASA / Micron Technology, Inc. & Professional Technical Center High School	Team Tater	PTEC	Tator Bot	Boise, ID, USA	2007
2124	Olin College/Smith Family Foundation of Boston & Hyde Park Educational Complex	Hyde Park Ed. Complex	X-Factor	 	Hyde Park, MA, USA	2007
2125	Smith Family Foundation & Urban Science Academy High School	Urban Science Academy	Urban Science	 	West Roxbury, MA, USA	2007
2126	Smith Family Foundation of Boston & Boston Community Leadership Academy	BCLA	BCLA	 	Brighton, MA, USA	2007
2127	Smith Family Foundation & Josiah Quincy Upper High School	Quincy Upper	JQUS	 	Boston, MA, USA	2007
2128	AM Fab / Arizona Science Foundation & South Mountain High School & Cesar Chavez High School	South Chavez	Sci Tech	Vivo	Phoenix, AZ, USA	2007
2129	Nonin Medical / Discount Steel / NASA & Mpls. Southwest High School	Mpls. SW HS Robotics	Ultraviolet	 	Minneapolis, MN, USA	2007
2130	NASA/M.J.Murdock Charitable Trust/Encoder Products Company & Bonners Ferry High School	Alpha+	Alpha+	Bosco	Bonners Ferry, ID, USA	2007
2132	NASA/Maryland Space Grant Consortium/Morgan State University/NASA & Mergenthaler Vocational Technical High School	MERVO	Mustangs	Chuck 	Baltimore, MD, USA	2007
2134	Corona del Sol High School	Corona del Sol Aztecs	Aztecs	Aztecbot	Tempe, AZ, USA	2007
2135	Presentation High School	Presentation H.S.	Panthers	Tie Wrap	San Jose, CA, USA	2007
2136	Illinois Manufacturing Foundation/NASA & Impossible Mission Force	I. M. F.	Impossible Mission Force	The Protector	Chicago, IL, USA	2007
2137	Chrysler Foundation / NASA / Delta Technologies Group & Oxford High School	Oxford High School	Robocats	 	Oxford, MI, USA	2007
2139	NASA & SECTA High School	SNVTC Robots	Road Runners	 	Las Vegas, NV, USA	2007
2140	Novartis Pharmaceuticals / ADP Foundation / The Hilliard House & Pemberton Township High School	PTHS Robotics Team	Team Synergy	Thor	Pemberton, NJ, USA	2007
2141	AT&T West / Deloitte / EMC Corporation / Partners in Business Systems, Inc & De La Salle High School	DLS Robotics Team	Spartonics	Leonidas	Concord, CA, USA	2007
2143	ILC Alumni Association / NASA & Immanuel Lutheran High School	Team Tobor	Team Tobor	TOBOR	Eau Claire, WI, USA	2007
2144	Sacred Heart Preparatory High School	SHP RADbotics	RADbot	RADbot Reloaded	Atherton, CA, USA	2007
2145	The Chrysler Foundation / Automated Systems & Lake Fenton High School & Lake Fenton Community Schools	Lake Fenton	HAZMATs	 	Fenton Area, MI, USA	2007
2147	NASA/Altek/Lloyd Industries/US Motion & West Valley High School	West Valley / NASA	Agent Eagle	 	Spokane, WA, USA	2007
2148	Altek/Lloyd Industries & East Valley High School	East Valley	Knights	 	Spokane, WA, USA	2007
2149	NASA/Altek/Lloyd Industries/Spokane Regional Chamber of Commerce & Central Valley School District	CV Bears	CV Bears	 	Spokane Valley, WA, USA	2007
2150	Northrop Grumman / El Camino College & Chadwick School	Wicked Wobotics	W-Squared	Wicked Wobot	Palos Verdes Peninsula, CA, USA	2007
2151	Hardwood Line/NASA & Proviso Math and Science Academy High School	NASA Python turn left	Monty Python	Monty	Forest Park, IL, USA	2007
2152	NASA / Embry-Riddle Aeronautical University / Daytona Beach Community College & Spruce Creek High School & Mainland High School & New Smyrna Beach High School	Team Daytona	Team Daytona	RoT (Robot of Tomorrow)	Port Orange, FL, USA	2007
2153	NASA & Chassell Township High School	NASA/CTS	Snow Panthers	 	Chassell, MI, USA	2007
2154	William Moreno Jr High School	The AzTechs	AzTechs	MonTechZuma	Calexico, CA, USA	2007
2156	Sacramento City Unified School District & HJHS Transportation Academy & Hiram W. Johnson High School	Wire Heads	Wire Heads	 	Sacramento, CA, USA	2007
2157	The Education Foundation of Harris County / Mc Bride Electric / CSTEM / Houston Robotics & Sharpstown High School	Sharpstown	Apollo 	Apollo KMD	Houston, TX, USA	2007
2158	National Instruments / Houston Robotics and BAE Systems / University of Texas at Austin & Anderson High School	ausTIN CANs	ausTIN CANs	Tin Man	Austin, TX, USA	2007
2159	NASA / Abbott Diabetes Care, A Div. of Abbot Laboratories / BAE Systems / ACE Hardware of San Leandro / Coast Aluminum and Architectural, INC. / Wal*Mart / OSI & San Leandro High School	SLHS Robotics	RoboPirates	Robotany Bay	San Leandro, CA, USA	2007
2161	BOVIS Lend Lease/NASA/SUNY at Stony Brook/CD-Adapco/PM Engineering & Walt Whitman High School	Whitman Robocats	Robocats	Widow Maker	Huntington Station, NY, USA	2007
2163	Durakon Industries & Lapeer West High School	Chrome Panthers	Panthers	 	Lapeer, MI, USA	2007
2164	NASA / John Deere / Commerce Bank & Harrisonville High School	Harrisonville Corps	the corps	Atlas	Harrisonville, MO, USA	2007
2165	NASA/Conoco Phillips/AEP/ARVEST Bank/Bartlesville Rotary Club & Tri County Technology Center	Tri County Tech 	Trailblazers	Scarab	Bartlesville, OK, USA	2007
2166	Appleby College/Extrude's-A-Trim/University of Toronto/MDA Robotics & Appleby College (High School)	Bluebotics	Bluebotics	Double Blue Bot	Oakville, ON, Canada	2007
2167	Missouri Academy of Science, Mathematics, and Computing	Studbots	MASMabots	MA-1	Maryville, MO, USA	2007
2168	Fitch Senior High School	Cyber Falcons	Cyber Falcons	 	Groton, CT, USA	2007
2169	BOSTON SCIENTIFIC CORP/Prior Lake Optimist Club & Prior Lake High School	KING TeC	KING TeC	The Protector	Savage, MN, USA	2007
2170	United Technologies Corporation / NASA & Glastonbury High School	TitaniumTomahawks 	Titanium Tomahawks	Tomahawk Chief	Glastonbury, CT, USA	2007
2171	NASA/Indiana Department of Workforce Development & Crown Point High School	Crown Point Robo Dogs	Robo Dogs	 	Crown Point, IN, USA	2007
2172	Advanced Polymer Coatings Ltd./JBC Technologies/American Tank and Fabricating Co & Saint Edward High School	St.Eds-APC-JBC 	street lEAGLE	 	Lakewood, OH, USA	2007
2173	NASA / AVL / Mississippi Power & St. Stanislaus College High School	St. Stanislaus	Robo Rocks	R Squared	Bay St. Louis, MS, USA	2007
2174	Verbum Dei High School	Verbum Dei Robotics	Iron Eagles	 	Watts, CA, USA	2007
2175	3M/Carestream Health/Lockheed Martin & Woodbury Math and Science Academy	3M, Carestream  & MSA	The Fighting Calculators	 	Woodbury, MN, USA	2007
2176	NASA & Starkville Academy	SA	MAD SCIENTIST ASSOCIATION	Alucardbot	Starkville, MS, USA	2007
2177	Boston Scientific & Convent of the Visitation High School	BSC Robettes	The Robettes	Suthy	Mendota Heights, MN, USA	2007
2180	Sun Chemical Corporation / HTEA and NJEA / NASA / DRS C3 Systems, LLC / Special Technical Services / Karl Mey's Collision & Paint Center / Computer Vision Technology, Inc / National / Reliable Plastics / FindSurge.com & Hamilton High School East- Steinert	Zero G's	Zero Gravity	ARES- Greek God of War	Hamilton, NJ, USA	2007
2181	Medtronic & Blaine High School-CEMS	The Medtronic Bengals	Survivor	Stormin' Norman	Blaine, MN, USA	2007
2182	Chalmette Refining/NASA & St. Tammany Parish Public Schools & Slidell High School	Slidell Robotix	Tyborgs	Tyborg I	Slidell, LA, USA	2007
2183	University of New Orleans LEAP / BLAST (Building Louisiana Science and Technology) / Northrop Grumman Shipbuilding & Hahnville High School	Hahnville LEAP	Purple Reign	Prince	Boutte, LA, USA	2007
2185	Etobicoke Collegiate Institute & TDSB	RoboRams	Rams	ROBORAM	Toronto, ON, Canada	2007
2186	Northrop Grumman & Westfield High School	Westfield Robotics	Bulldogs	 	Chantilly, VA, USA	2007
2187	NASA/Horry Electric/Horry Telephone/Conway National Bank & Academy for Technology and Academics High School	ATA	ATA	 	Conway, SC, USA	2007
2188	Stahlin Enclosures / Graphite Engineering / City of Belding / Rayborn Ace Hardware / Caribbean Pools & Fiberglass / Chemical Bank / FIRST BANK / Belco Industries / Weisen Inc. / Extruded Aluminum / Ostrander Roofing & Siding / Ionia County Community Found	Belding High School	Hurricanes	The Hurricane	Belding, MI, USA	2007
2189	NASA/Chicano And Latino Engineers and Scientist Society (CALESS)/Society of Mexican American Engineers and Scientists (MAES) & Woodland and Pioneer High School	woodland Robotics	woodland Robotics	wolfie	Woodland, CA, USA	2007
2190	NASA & Petal School District	Panther Peril	Panthers	Panther Peril	Petal, MS, USA	2007
2191	NASA & Nottingham High School	Northstars	Flux Core	 	Trenton, NJ, USA	2007
2192	NASA / Georgia-Pacific / Confederated Tribes of Siletz Indians / Halco Welding / Riddell Sheet Metal & Newport High School	Newport High Robotics	DAC Attack	HAL 97365	Newport, OR, USA	2007
2193	AT&T/Otay Valley Ranch Company/Qualcomm & Hilltop High School	Hilltop High	Hilltop	 	Chula Vista, CA, USA	2007
2194	Mercury Marine/Moraine Park Technical College/NASA & Six Different Area High Schools	Mercury/MPTC	Fondy Fire	Fire Ball	Fond du Lac, WI, USA	2007
2196	Shiprock High School	Shiprock High School	Béésh Bááh Alchini	Béésh Nááh Gháhii	Shiprock, NM, USA	2007
2197	Howmet-Alcoa/NRP-Jones & New Prairie High School	Las Pumas	Las Pumas	Sparky 2	New Carlisle, IN, USA	2007
2198	L'Amoreaux C.I.@ TORONTO DISTRICT SCHOOL BD	Laminators	L'Ams	Prometheus	Toronto, ON, Canada	2007
2199	NASA / VoiceMetrix / General Dynamics Robotic Systems & Liberty High School	Liberty High Lions	Robo-Lions	John Mayo, Jr	Eldersburg, MD, USA	2007
2200	RBC Dominion Securities / McMaster University (Mechanical Eng.) / First Robotics Canada & M. M. Robinson High School	MMRAMbotics	Rambos	project 2200 reloaded	Burlington, ON, Canada	2007
2201	Ewing Marion Kauffman Foundation / Peterson Manufacturing / Spidertel / Team Mentors & Touch of Grace Ministries	TGM Robotics	TGM	Hyper-Nikao JR (More than Conquerors!!!!)	Grandview, MO, USA	2007
2202	ABB Robotics / ABB Drives / GE Volunteers / NASA / Marquette University College of Engineering / TCI / NVISIA / Stratagem & Brookfield East High School & Elmbrook Education Foundation	Beast Robotics	Team Hazmat	Adkins	Brookfield, WI, USA	2007
2203	Verizon Communications, Inc./Consolidated Edison/The Eagle Academy Foundation & The Eagle Academy for Young Men	Cyber-Eagles	Cyber-Eagles	 	Bronx, NY, USA	2007
2204	Google / GSD Group, Inc. & Chinese Christian High School	Rambots	Rambots	 	San Leandro, CA, USA	2007
2205	Advanced Network Systems, Inc./IBM T. J. Watson Research Center & The Montfort Academy	Montfort Juggernauts	Juggernauts	 	Katonah, NY, USA	2007
2206	University of New Orleans & John Ehret High School	John Ehret	Ehret Patriots	 	Marrero, LA, USA	2007
2207	Medtronic Inc. & White Bear Lake Area High Schools	White Bear Lake	Prime 329	Schnell bahn	White Bear Lake, MN, USA	2007
2210	FIRST Israel & Yarka High School	Yarka High School	Yarka High School	 	Yarka, Northern, Israel	2007
2211	Israel Aircraft Industries & Ort Israel Aircraft Industries High School	Ort IAI	Ort IAI	 	Lod, Central, Israel	2007
2212	Bank Hapoalim & Aleh Lod High School	Aleh Lod High School	Aleh Lod High School	Kamibot	Lod, Central, Israel	2007
2213	FIRST Israel & Amal Nahariya High School	Amal Nahariya	Amal Nahariya	 	Nahariya, Northern, Israel	2007
2214	Israel Navy Ship Yard & Yemin Orde High School	RobOrde Assist	RobOrde	RobOrde Assist	Yemin Orde, Haifa, Israel	2007
2215	Ort Akko High School	Napoleon Team	 Akkoleon	 	Akko, Northern, Israel	2007
2216	Sacta Rashi Foundation & Zinman High School	Zinman High School	LuckyBot	LuckyBot	Dimona, Southern, Israel	2007
2217	Alubin/Hamlet Advanced Technologies & Kiryat Motzkin High School	Kiryat Motzkin	Kiryat Motzkin	 	Kiryat Motzkin, Northern, Israel	2007
2219	Southern Illinois University at Carbondale, College of Engineering/IEEE & Brehm Preparatory School, Inc.	Megahurtz	Megahurtz	 	Carbondale, IL, USA	2007
2220	Lockheed Martin & Eagan High School	Eagan Robotics Team	Blue Twilight 	Johnny 5	Eagan, MN, USA	2007
2221	BLAST Foundation / LEAP / Lockheed Martin Human Space Servies / Northrop Gruman Ship Systems & Fontainebleau High School	FHS&LHMSS	FHS Robodawgs	 	Mandeville, LA, USA	2007
2224	Diallo,Cromer,Toussaint,Posey&Polk,P.L.L.C / MIMI LLC / Contractors Welding Supply & Service / Ford Motor Company-Team Ford First & Renaissance High School & A. Philip Randolph Career & Technical Center	PHOENIX PHENOMS II	PHOENIX PHENOMS II	R.A.I. (Renaissance Artificial Intelligence)	DETROIT, MI, USA	2007
2225	Caterpillar, Inc. & Champlin Park High School & Secondary Technical Education Program High School	CPHS / STEP / CAT	Robot Rebels	Sagacious Mantis	Champlin, MN, USA	2007
2226	Energy Solutions / Recapture Metals / JM Welding / Eagle Air Med & San Juan School District	San Juan Broncos	Bronc's	SlickRock	Blanding, UT, USA	2007
2227	Medtronic & Fridley High School	Fridley	Tigers	 	Fridley, MN, USA	2007
2228	Alstom / Sage Rutty Financial / n-tara / Vuzix / Southco / Guida's Pizza / Kirkwood Oil & Honeoye Falls-Lima High School	Cougar Tech	Courgar Tech	Rover	Honeoye Falls, NY, USA	2007
2229	Colonial School District	PW	Colonials	 	Plymouth Meeting, PA, USA	2007
2230	Herzliya  Municipality & Handasaim-Herzliya High School	Handasaim- Herzliya	Zcharia's Angles	 	Herzliya, Central, Israel	2007
2231	Shoham High School	Shoham High School	Onyxtronix	The H	Shoham, Central, Israel	2007
2232	Pentair Corporation / Custom Fire Apparatus, Inc. & Anoka High School	Deus ex Machina	Deus ex Machina	 	Anoka, MN, USA	2007
2234	The Edmar Abrasive Company / North American Machine Works / RADCorp & The Episcopal Academy	EA Robotics	The Reverend	The Reverend	Merion, PA, USA	2007
2237	Beckley Area Foundation / American Electric Power / Ralph A. Hiller Company / 80-20.net / Cogar Mine Supply / State Electric / Meadows Machining / Brea Signs / Precision Electric Inc. / ESI .INC / Kevin's Electronics & Academy of Careers and Technology	Robo's	The Junkyard Robo's	JR squared	Beckley, WV, USA	2007
2239	ev3 & Hopkins High School	Technocrats	Technocrats	 	Minnetonka, MN, USA	2007
2240	Lockheed Martin Space Systems Company / University of Denver Department of Engineering & Denver School of Science and Technology High School	DSST	Brute Force	 	Denver, CO, USA	2007
2241	Boston Scientific & Coon Rapids High School	Coon Rapids SWAT	SWAT team	Spirit of St. Louis	Coon Rapids, MN, USA	2007
2242	Lockeed Martin / Northrop Grumman Corp / LEAP University of New Orleans / Blast Foundation & Algiers Charter Schools Association & EDNA KARR HIGH SCHOOL	Karr Cougars	Cougars	Hercules	New Orleans, LA, USA	2007
2243	Fundação Bradesco Campinas Fundação Bradesco	Fundação Bradesco	BRATECC	GAMBER II  	Campinas, SP, Brazil	2007
2244	Fundação Bradesco Osasco I Fundação Bradesco	Free Access Evolution	The Chips	 	Osasco, SP, Brazil	2007
2245	FHS Engineers & Frankfort High School	FHS PANTHERS	PANTHERS	Purple Panther  (p-squared)	frankfort, MI, USA	2007
2246	Johannesburg High School	Joburg High School	J L Gen I	Code Red	Johannesburg, MI, USA	2007
2247	Fundação Bradesco Gravataí Fundação Bradesco	FB High Tech	FB HT	Guasca	Gravataí, RS, Brazil	2007
2250	Lockheed Martin & Abraham Lincoln High School	Lancerbotics	Lancerbotics	# 2	Denver, CO, USA	2007
2252	Sierra Lobo, Inc./BGSU Firelands College & EHOVE Career Center	The Mavericks	The Mavericks	 	Milan, OH, USA	2007
2254	Nelvana / Atomic Energy Canada Ltd. / International Dairy & John Fraser Secondary High Schools	Twisted Transistors	Twisted Transistors	Hell Raiser	Mississauga, ON, Canada	2007
2257	Sacta Rashi Foundation & Afula High School	Afula High School	Afula High School	 	Afula, Northern, Israel	2007
2259	Colorado University/Lockheed Marin Aeronautical Systems & CEC Middle College	CECCULOCKHEEDPHOENIX	CEC	 	Denver, CO, USA	2007
2261	Ball Aerospace & Technologies Corp/IBM/Lockheed Martin/Seagate Corp. & Colorado MESA & St. Vrain MESA	Casa de la  Esperanza	Casa MESA	 	Longmont, CO, USA	2007
2262	Holliston High School	Most Significant Bits	Most Significant Bits	Robopantherz	Holliston, MA, USA	2007
2264	Boston Scientific & Wayzata High School	Trojans	Trojan Robots	 	Plymouth, MN, USA	2007
2265	The Alumni Association of The Bronx High School  of Science / Credit Suisse / The Hennessy Family Foundation / Bloomberg / ConEdison & The Bronx High School of Science	Fe Maidens	Fe Maidens	Rosie the Rivetted	Bronx, NY, USA	2007
2272	Haas Automation/ITT Technical Institue & Newbury Park High School & Thousand Oaks High School & Westlake High School	Haas-ITT-Army-Conejo	Metalheads	speed racer	Thousand Oaks, CA, USA	2007
2273	Honda Canada Inc. / Future Shop / Kodak Graphic Communications Canada Company & School District 36 Surrey	SHIM	The Mechanix Coalition	ATLAS	Surrey, BC, Canada	2007
2274	Larry Ackman / Bloomberg / Credit Suisse & Fordham Leadership, Roosevelt Campus High School	Fordham Heat	Fuego	 	Bronx, NY, USA	2007
2275	Montbello High School	Montbello	Warriors	 	Denver, CO, USA	2007
2276	Houston Robotics & Cypress Springs High School	STARS of Cypress	STARS	RASCAL	Cypress, TX, USA	2007
2279	Butler County Area Vo-Tech School	Butler Tech	The Butlers	The BUTLER	Butler, PA, USA	2007
2280	YWCA of Greater Pittsburgh	TechGYRLS	YWCA DELTA F.O.R.C.E.	 	Pittsburgh, PA, USA	2007
2283	GM Mexico/Explora Descubre y Crea A.C. & Universidad Panamericana  High School	UP Preparatoria	Panteras	Ocelotl	Mexico City, DF, Mexico	2007
2285	ADP & Irvington High School	Knights	Knights	 	Irvington, NJ, USA	2007
2287	HOUSTON ROBOTICS / Bezos Foundation / AEP, Texas & Sinton High School	RoboTech Pirates	RoboTech Pirates	Rebel the Robot	Sinton, TX, USA	2007
2330	J Adams Multimedia Productions / Shiflett Transport Service / First National Bank of Fletcher / American Health Partners / Oklahoma Department of Education & Fletcher High School	Fletcher Tech	F-Tech	El Chupacabra	Fletcher, OK, USA	2008
2332	Pendpac Manufacturing / NASA & Fairview High School	Fairview Team Lucky	Team Lucky	Lucky	Fairview, OK, USA	2008
2333	NASA / Oklahoma State Department of Education / Bartlett Foundation & Sapulpa High School	Sapulpa Chieftains	Chieftains	 	Sapulpa, OK, USA	2008
2334	Ewing Marion Kauffman Foundation & Blue Valley High School	Tiger Robotics 	Tigers	 	Stilwell, KS, USA	2008
2335	Ewing Marion Kauffman Foundation & Shawnee Mission East High School	Lancer Pride	Sargon	The Brave Little Toaster	Prairie Village, KS, USA	2008
2336	NASA & Cosby High School	Cosby Robotics Club	Titan Crusaders	NUUR	Midlothian, VA, USA	2008
2337	FANUC Robotics America/The Chrysler Foundation/Davison Tool & Engineering, L.L.C./Premier Tooling Systems/Faurecia Automotive Seating/Diversified Machine, Inc. & Grand Blanc High School	EngiNERDs	EngiNERDs	 	Grand Blanc, MI, USA	2008
2338	Caterpillar, Inc./NASA & Oswego East High School	Oswego High Schools	Gear It Forward	Agnes	Oswego, IL, USA	2008
2339	MDM Architects/NASA & Antelope Valley High School	A V Robotics	Robolopes	Sysiphus	Lancaster, CA, USA	2008
2340	Xerox Corporation & Nazareth Academy High School	NAZa.r.e.X	NAZa.r.e.X	TYRA	Rochester, NY, USA	2008
2341	NASA / Enviro Systems Inc. / Oklahoma State Department of Education & Macomb Public Schools High School & Gordon Cooper Technology Center	Gordon Cooper Tech	Trojans	 	Shawnee, OK, USA	2008
2342	NASA / BAE SYSTEMS / NYPRO, Inc / Precision Manufacturing, L.L.C. / Daniel Webster College / Greater Nashua FIRST Robotics, Inc. & Greater Nashua Area High Schools	Team Phoenix	Team Phoenix	FENIX I	Merrimack, NH, USA	2008
2343	Oklahoma Department of Education / Bill Beaulieu / Major Mike McCartney & Inola High School	Inola Robotics Team	Deceptibots	Scavenger	Inola, OK, USA	2008
2344	Dr. Andrew and Judith Economos Foundation / Crane Co. / NASA / Con Edison / Manhattan College School Of Engineering / Dott-Communications, LLC & Saunders Trades and Technical High School	SaundersDroidFactory 	The Saunders Droid Factory 	Linda	Yonkers, NY, USA	2008
2345	Ewing Marion Kauffman Foundation & Kearney High School	Kearney	Bulldogs	 	Kearney, MO, USA	2008
2346	Ewing Marion Kauffman Foundation / Eskridge Inc. & Archbishop O'Hara High School	O'Hara Celtics	Celtics	iCelticRobot	Kansas City, MO, USA	2008
2347	School Construction Consultants Incorporated & Walter G. O'Connell Copiague High School	O'Connell Copiague HS	C - Bots	Spartan	Copiague, NY, USA	2008
2348	BAE Systems / NASA & Moanalua High School	MOHS & NASA ROBOTICS	MOHS & NASA ROBOTICS	 	Honolulu, HI, USA	2008
2349	NASA & Wayland High School	Wayland First	Hurriquake	 	Wayland, MA, USA	2008
2352	Chickasaw Nation & Pontotoc Technology Center	Chickasaw Nation/PTC	Metal Mayhem	Iron Man	Ada, OK, USA	2008
2353	Ewing Marion Kauffman Foundation & Pembroke Hill High School	PHS Raider Robotics	Raider Robotics	 	Kansas City, MO, USA	2008
2354	The Toy Shop / Storage-R-Us / Wilco Machine and Fab / State of Oklahoma / Halliburton / NASA & Duncan High School	DuncanHS	Wheeliebots	Wheeliebot	Duncan, OK, USA	2008
2357	NASA & RayPec High School Panthers	panthers	Panthers	 	Peculiar, MO, USA	2008
2358	MPC Products & LZ Bears High SChool	LZ MPC Bears	Lake Zurich MPC Bears	Smokey	Lake Zurich, IL, USA	2008
2359	George Cohlmia / Wachovia Securities / Oklahoma Christian University / Pelco Products / NASA & Edmond Santa Fe High School	Edmond Santa Fe	Wolves	 	Edmond, OK, USA	2008
2360	Rolls Royce Corporation / Indiana University Purdue University- Indianapolis / Water Jet Cutting of Indiana / Indiana Department of Workforce Development & Indianapolis Area Schools	RRC/IUPUI/POWER	POWER-Storm	 	Indianapolis, IN, USA	2008
2361	KML Building Solutions / Canadian Tire / Clarity Management & P.A.C.E. Academy	P.A.C.E. Invaders	p.Rob[i]otics	M.a.r.v.i.n.	Richmond Hill, ON, Canada	2008
2362	General Dynamics Armament and Technical Products / Charlotte Mechanical, LLC / CPI Security Systems / Schaeffler KG & School of Math, Engineering, Technology, and Science at Olympic High School	GDATP-CMLLC-OHS METS	Olympic Robotics	Prometheus	Charlotte, NC, USA	2008
2363	US Army Research Laboratory/The Friends of Phillip Hamilton/Eagle Aviation Technologies, Inc. & Menchville High School	Menchville Robotics	Triple Helix	Snowflake	Newport News, VA, USA	2008
2364	Community Foundation of Northern Illinois / Oregon Hawks Booster Club / Kiwanis Club of Oregon Illinois / National Aeronautics and Space Administration Marshall Space Flight Center FIRST Robotics Alliance Project 2007-2008 / Oregon Rotary Club / Community	Oregon RoboHawks	Oregon RoboHawks	Chief BlackHawk	Oregon, IL, USA	2008
2365	Science Foundation Arizona & Alhambra High School	Lions Robotics	Lions	 	Phoenix, AZ, USA	2008
2366	Ewing Marion Kauffman Foundation / ATK (Alliant Techsystems) / Black & Veatch & Fort Osage High School	Tesla Robotics	T-Bots	Schuler	Independence, MO, USA	2008
2367	BAE SYSTEMS & Saint Francis High School	SFHS Lancer	SOLPWC/CFP	 	Mountain View, CA, USA	2008
2368	Terre Haute South Vigo High School & Vigo County School Corporation	Terre Haute South	Braves 	South Robotics	Terre Haute, IN, USA	2008
2369	Meridian Technology & Meridian Technology Center	MTC	MTC	MTC	Stillwater, OK, USA	2008
2370	Alderman Chevrolet and Toyota / GE Volunteers & Rutland County Students	iBots	iBots	TIN MAN	Rutland, VT, USA	2008
2371	OSU-Okmulgee / NASA & Morris Public Schools	Morris	Eagle Pride	 	Morris, OK, USA	2008
2372	NASA / BAE SYSTEMS & Elgin High School	BAE Elgin	Robo-Hooters	 	Elgin, OK, USA	2008
2373	NASA / Oklahoma Natural Gas Company / Caddo Electric / Technology Department Southwestern Oklahoma State University / Oklahoma Education Enhancement Foundation & Caddo Kiowa Technology Center & Mountain View Gotebo High School	NASA CKTC MVG 2373	Crickets	Space Cricket	Fort Cobb, OK, USA	2008
2374	Metal Innovations / Intel & Jesuit High School	Jesuit Crusaders	CrusaderBots	The Gutbucket	Portland, OR, USA	2008
2375	Bioscience High School	Bioscience	BioHazards	"Gizmo" the Biobot	Phoenix, AZ, USA	2008
2376	McElroy Manufacturing/NASA & Bishop Kelley High School	Bishop Kelley HS	RoboCOMETS	The Comet-ator	Tulsa, OK, USA	2008
2377	St. John Properties / NASA-GSFC / SAIC / Northrop Grumman / Harris Corp. & Chesapeake High School (AA)	St Johns & CHS	C Company	 	Pasadena, MD, USA	2008
2378	NASA / Oklahoma State Department of Education / Western Medical & Drug / Dewey County Abstract / First American Bank / Horton Studios, Inc. / Edward Jones: Lowell Flaming / Wheeler Brothers' Grain & Taloga High School	Taloga High School	Team Mako 2378	 	Taloga, OK, USA	2008
2380	Science Foundation AZ / Employees of Microchip Technology Inc. / NSC / Tram Tek Inc / Real Eyes Media / Articulate / Harbinger Knowledge Products / Blatant Media / Rapid Intake / Motherboards and Upgrades / FedEx Kinkos 1379 / Di's Creative Edge & Desert 	Jag Robotics	Jag Robotics	Jag I	Mesa, AZ, USA	2008
2381	After School Matters and Motorola & The Ark of St. Sabina	The Ark of St. Sabina	The Ark	 	1210 W 78th Place, IL, USA	2008
2382	Mueller Constructio & Colbert High School & Colbert Public Schools high school	Colbert Radiation	Radiation	The radiator	Colbert, OK, USA	2008
2383	American Heritage High School	American Heritage	Patriots	 	Plantation, FL, USA	2008
2385	Marco Mfg. Inc./NASA & Wright Christian Academy	WCA	Obelisk Trio	 	Tulsa, OK, USA	2008
2386	Eaton & Burlington Central Home School	BCHS	Trojans	Billy	Burlington, ON, Canada	2008
2387	NASA / Battelle Memorial Institute / AEP-American Electric Power / The Columbus Foundation / Martha Holden Jennings Foundation / The Ohio State University / DeVry Univeristy / Tubular Techniques / Honda R&D Americas / Southeast Career Center - / CAHS PTA 	Alternative Robotics	Alternative Robotics	Iron Pegasus	Columbus, OH, USA	2008
2388	Oklahoma State Department of Education / Autobotics, Inc / Spirit Aerosystems / Preston-Eastin / W.M. Heitgras / The Exchange Bank, Sperry & Sperry High School	Pirates	Pirate	 	Sperry, OK, USA	2008
2389	Oklahoma State Department of Education / Stillwater Designs (Kicker) / Cimarron Glass / The Quapaw Company / Earl-Le Dozer / Drumright High School / Mid South Technologies & Central Technology Center	Central Tech 	Pirate Robotics	Captain Jack	Drumright, OK, USA	2008
2390	Abbott Diabetes Care, A Div. of Abbot Laboratories & San Ramon Valley Education Foundation - & Dougherty Valley High School	Wildcat Robotics	Wildcats	Robert Jackson	San Ramon, CA, USA	2008
2391	NASA / Wallace Engineering / Allied Bearings & Broken Arrow Senior High School	Tiger Drive	Tiger Drive	Steve	Broken Arrow, OK, USA	2008
2393	Knoxville Catholic High School	Robotichauns	Robotichauns	 	Knoxville, TN, USA	2008
2394	Southwestern Oklahoma State University (SWOSU) & Watonga High School	Watonga Eagles	Eagles	SHAZAM!	Watonga, OK, USA	2008
2395	NASA / ITT Technical Institute / Oklahoma College of Construction / OKC Life Member Pioneer Club / Boyes Construction / Forest Lumber / Steve's Wholesale Tools / WebGuy Communications / Vantage Point Asset Solutions & Oklahoma City Home School & Oklahoma 	NASA OKC 4-H	OKC 4-H Robotics	Stanley	Oklahoma City, OK, USA	2008
2396	Wilspec Technologies / Tyler Sheet Metal, Inc. / Linihan Insulation Inc. / Terracon / Universal Trailers / Darr and Collins / Streets, Inc.  Mechanical Contratcors & Canadian Valley Technology Center & Tuttle High School	cvtech	SeeHawks	 	El Reno, OK, USA	2008
2397	Science Foundation AZ & Phoenix Union Cyber High School	C_Y_13_3_R_182	Cyborgs	Hackers	Phoenix, AZ, USA	2008
2398	Cherokee Nation / Northeastern State University & Sequoyah High School (Tahlequah)	The Robot Tribe 	Robot Tribe	 	Tahlequah, OK, USA	2008
2399	NASA / Case Western Reserve University & Hathaway Brown School High School	TeamHB / Case / NASA	TeamHB	 	Shaker Heights, OH, USA	2008
2400	Rio Tinto Energy America / NASA / Spring Creek Coal Mine / Woming Space Grant Consortium / Pearl Development / Sheridan Winnelson / Craftco / Zowada Recycling / Knechts Ace Hardware / Action Plumbing / Connie's Glass / Bloedorn Lumber / Vista West Enginee	SheridanHS/NASA/WYSGC	Wyoming!?	Wally!?	Sheridan, WY, USA	2008
2401	nasa & north dakota space grant / hardware hank / fugleberg  seed and bean / neset repair / University of North Dakota & May-Port C.G. High School	MAYPORT C.G./UND	PATRIOTS	WALDO 3	MAYVILLE, ND, USA	2008
2402	NASA / GM Powertrain / McQ Inc. / New World Associates / Wilkinson Woodworking & James Monroe High School	JamesMonroebotics	JamesMonroebotics	RoboJacket 1: The Guillotine	Fredericksburg, VA, USA	2008
2403	Red Mountain High School	Red Mountain Lions	RMHS Lions	 	Mesa, AZ, USA	2008
2404	NASA / Neighbors Empowering Youth / Mustangs on the Move & John Muir High School	Team NEY Techs	TNT	 	Pasadena, CA, USA	2008
2405	Alcoa Foundation/Herman Miller, Inc & Fruitport High School	ALCOA HermanMiller FH	Divided By Zero	ZERO	Fruitport, MI, USA	2008
2406	Arizona Science Foundation / Verde Valley Robotics, Inc. & Camp Verde High School & South Verde High School	South Verde Bulldogs	Bulldogs	 	Camp Verde, AZ, USA	2008
2407	Parker Hannifin & Leetonia Schools	Techno Bears	Bearnicks	 	Leetonia, OH, USA	2008
2408	Emerson Tool Company & Hazelwood West High School	HWHS Robotics	Wildbots	Myrtle the Turtle	Hazelwood, MO, USA	2008
2409	NASA & Greater New Bedford Regional Voc-Tec High School	New Bedford Voc-Tec	Da Bears	 	New Bedford, MA, USA	2008
2410	Ewing Marion Kauffman Foundation & Blue Valley North High School	Kauffman & BVN	Metal Mustang Robotics	 	Overland Park, KS, USA	2008
2411	NASA / MJ Murdock Foundation & Joseph L. Meek Professional Technical High School	Meek Protech Robotics	Meek Protech Robotics	 	Portland, OR, USA	2008
2412	Sammamish High School	Sammamish Robotics	Totems	 	Bellevue, WA, USA	2008
2413	Science Foundation Arizona & Maryvale High School	Panther Robotics	Panthers	 	Phoenix, AZ, USA	2008
2414	Science Foundation of Arizona & Camelback High School	Camelback	Spartans	Pretty 'n' Peligro!	Phoenix, AZ, USA	2008
2415	NASA/Women in Technology- Atlanta GA/Georgia Institute of Technology RoboJackets/The Shanor Family/www.sevaa.com & Kell High School Team 1311 & The Westminster Schools-High School	WIREDCATS	WIREDCATS	 	Atlanta, GA, USA	2008
2417	Mitchell's Restaurant / The Tobacco Commission / US FIRST & Nottoway High School	Cougars	RoboCougars	Blitzkrieg	Crewe, VA, USA	2008
2418	University of North Dakota & Northern Lights Council-Boy Scouts	Great Plains tomahaks	tomahaks	byaaahhhhh	Minot, ND, USA	2008
2419	Action Mold & Tool / Test-Tek / Southland Painting & Wallcovering & Brea Olinda Unified School District & Brea Olinda High School	BOUSD  & Brea Olinda	Team MonRobot	 	Brea, CA, USA	2008
2420	Georgia Tech Robojackets / Sentrinics & Tech High School	TechHigh TechnoTitans	TechnoTitans	 	Atlanta, GA, USA	2008
2421	Rockwell Collins / Intellectual Property Research & Harvester Teaching Services	RTR	Rolling Thunder Robotics	RTR1	Springfield, VA, USA	2008
2422	NASA/Walt Disney World Company & Ridge Community High School	NASA/Disney/RCHS 	Bucket O' Bolts	B.O.B. v1.5	Davenport, FL, USA	2008
2423	NASA / BBN Technology / United Electric Controls & Watertown High School	WatertownHS, BBN, UEC	 The KWARQS	Jack	Watertown, MA, USA	2008
2424	Samson Oil and Gas / Bill and Diana Beaulieu / Camden Homes / Hambone Management, LLC / Callidus Technologies / Hydraquip / Tulsa Talons Arena Football / J. H. Davidon & Associates / WhitewayChristmas.com / Kimberly Clark & Bixby High School	Bixby Robotics	Bixby	Leonidas	Bixby, OK, USA	2008
2425	Primerica Financial Services / NASA / Hillsborough Education Foundation / Verizon & Hillsborough High School	Hillsborough HS	Hydra	 	Tampa, FL, USA	2008
2427	THALES Canada / Genome Quebec / McGill University & Marianopolis College	ThalesGenomeMcgill	Techno Beavers	 	Westmount, QC, Canada	2008
2428	Sewickley Academy	SA	Gremlins	 	Sewickley, PA, USA	2008
2429	Jet Propulsion Lab & La Canada High School	La Cañada Engineering	LCE	LC1.0	La Cañada, CA, USA	2008
2430	Capsugel/FujiFilm Inc./Partnership Alliance/Piedmont Technical College & GRIP (Greenwood Robotics Interactive Partners)	.Cyber Storm	.Cyber Storm	 	Greenwood, SC, USA	2008
2431	Ford Motor & Detroit Northwestern HS and STEM	The TechnoColts	TechnoColts	 	Detroit, MI, USA	2008
2432	Boeing & Hales Franciscan High School	Hales	Spartans	 	Chicago, IL, USA	2008
2433	After School Matters and Motorola & Austin Polytech Academy High School	Austin Polytech	Tech Tigers	 	Chicago, IL, USA	2008
2434	Blue Print Automation & Hopewell Public Schools	TBD	TBD	 	Hopewell, VA, USA	2008
2435	Comanche Home Center / Chick-fil-A, Inc. / Wicker Construction Co., Inc. / AEP / NASA / Great Plains Technology Center Foundation / Goodyear Tire & Rubber Company / McMahon Foundation / Multi-County Counseling, Inc. & Great Plains Technology Center & Indi	Southern Riot	Riots	Southern Storm	Lawton, OK, USA	2008
2436	Oklahoma State Department of Education / 3B Mechanical / TallGrass Graphics / Oklahoma Educators Credit Union / Noble Hardware & Noble Public Schools	Noble High School	Bearacudas	Frank Wayne	Noble, OK, USA	2008
2437	Okada Trucking Co., Ltd. / NASA / Stryker Consulting, Inc. / Trimble Foundation & Sacred Hearts Academy	SHA Lancer Robotics	 Alphabots	Lance	Honolulu, HI, USA	2008
2438	BAE SYSTEMS/DATAHOUSE/NASA & 'Iolani School	Iolani Robotics	'Iobotics	Auto-Pirate	Honolulu, HI, USA	2008
2439	NASA/Dowling Company, Inc./MECO/UH Maui Community College & H.P. Baldwin High School	Baldwin Robotics	Bearbotics	Burly	Wailuku, HI, USA	2008
2440	NASA & St. Louis High School High School	Crusaders	Saints	 	Honolulu, HI, USA	2008
2441	BAE SYSTEMS/NASA & Maryknoll School High School	Maryknoll Robotics	Maryknoll Robotics	 	Honolulu, HI, USA	2008
2443	Boeing LTS Inc/Hawaii Space Grant Consortium/Maui Economic and Development Board (MEDB) & Maui High School	Maui High	MHFT (Maui High First Team)	Fantastically Awesomerific 13	Kahului, HI, USA	2008
2444	Cedric D. O. Chong And Associates & Kamehameha High School	Kamehameha	Imua !	The Rat Trap	Honolulu, HI, USA	2008
2445	NASA & Kapolei High School	Hurricanes	Na Makani Pahili	LOOK OUT!!!!!	Kapolei, HI, USA	2008
2446	Foothill High School	Slingshots	Pleasanton Slingshots	 	Pleasanton, CA, USA	2008
2447	Phoenix Masonic Lodge & South Shore Vo-Tech High School	Vikings	Vikes	Thor	Hanover, MA, USA	2008
2448	Stephen Lawrence Trust high school	SLT	SLT	 	London, UK, Great Britain	2008
2449	Orbital Sciences/Science Foundation AZ & James Madison High School & Marcos De Niza High School	Out of Orbit Robotics	The OOOberbots	OOOberbot	Tempe, AZ, USA	2008
2450	Cretin-Derham Hall High School	CDH Raiders	Raiderbots	 	St. Paul, MN, USA	2008
2453	Spirent Communications & Hawaii Baptist Academy High School	HBA Robotics Club	Eagles	 	Honolulu, HI, USA	2008
2454	BAE SYSTEMS/NASA & Radford High School	RambotX	RoboRams	Gizmo	Honolulu, HI, USA	2008
2455	Echrays / Joint Astronomy Centre / TATA Built Technology / NASA / W.M. Keck Observatory & Honoka'a High School	Honoka'a	Dragons	 	Honoka'a, HI, USA	2008
2456	LRG Capital & Branson & Drake High School	Branson & Drake	The Missing Three's	 	San Anselmo, CA, USA	2008
2457	AmerenUE / Sunsource Hydraulic Service and Repair / Monroe Pharmacy & Lawson High School	Cardinal Law	The Law	Guido	Lawson, MO, USA	2008
2458	Gill St. Bernards High School	GSB School	Team Chaos	 	Gladstone, NJ, USA	2008
2459	Cedric D. O. Chong & Assoc Inc/Hawaii Space Grant Consortium & Nanakuli High School	NHIS Robotics	Golden Hawks	 	Waianae, HI, USA	2008
2460	NASA / CruiseHawaii & Kohala High School	Na Paniolo	Cowboys	Woody Paniolo	Kapaau, HI, USA	2008
2461	Dell, Inc & OKC Public Schools	WARRIOR BOTS	REDSKINS	Geronimo	OKC, OK, USA	2008
2462	NASA & Marine Military High School	BULLDOGS	BULLDOGS	Devil Dog	CHICAGO, IL, USA	2008
2463	Tripple Strange & North Davidson High School & Davidson County Academy of pre Engineering	NHDS Tri-Strange	The Siege 	Jr	Lexington, NC, USA	2008
2464	NASA & Pahrump Valley High School	Pahrump Trojans	Trojans	 	Pahrump, NV, USA	2008
2465	Hotwire Hawaii/Kauai Island Utility Cooperative/NASA & Island School High School	Island School Robots	ibots	Cerberus	Lihue, HI, USA	2008
2466	Oceanit / Pioneer / PMRF / NASA / STU, LLC / Textron / Young Brothers / KEDB Aloha 'Ike / BAE Systems & Waimea High School	Waimea High Robotics 	Menehune Robots	Mini Menehune	Waimea, HI, USA	2008
2467	NASA/Pearl Harbor Naval Shipyard & IMF/Hawaii Pacific University & James Campbell High School	Sabertron 	Sabers	Gussy	Ewa Beach, HI, USA	2008
2468	NASA / National Instruments / Luminary Micro / MLC CAD Systems & Eanes Independent School District	Chaparral Robotics	Team Appreciate	 	Austin, TX, USA	2008
2469	Sporos Computers / Oklahoma State Department of Education / Idabel Foundation for Academic Excellence / NASA & Idabel High School	Idabel Robotics	Idabots	 	Idabel, OK, USA	2008
2470	Best Buy Company, Inc. & Bloomington ISD #271	Bloomington Bots	Blitz Team	 	Bloomington, MN, USA	2008
2471	NASA/Teradyne & Camas High School	Camas Mean Machine	TEAM Mean Machine	Terabot	Camas, WA, USA	2008
2472	Medtronic / Solid Design Solutions, Inc / St. Paul Machine & Design, Inc / Safe Operation Service, Inc / Abbey Carpet / ESG Architects, Inc & Centennial Senior High School	CHSroboMedtronicSolid	Centurions	Hercules	Circle Pines, MN, USA	2008
2473	NASA & Cupertino High School	CHS Robotics	CHS Robotics	 	Cupertino, CA, USA	2008
2474	Mid-States Bolt & Screw Company / AACOA Extrusions Company / AEP-American Electric Power / Lake Michigan College & Niles Area Home School Organization & Galien High School & Homeschool HUB Home School	LMC/AEP/HOME	X-CEL	 	Niles, MI, USA	2008
2475	NASA / Parker School & Earl's Garage	Waimea Community Team	Caution!	Mobius	Kamuela, HI, USA	2008
2476	Sewanhaka High School	Shock Therapy	Mind Games	EMP	Floral Park, NY, USA	2008
2477	IEEE Hawai`i Section / UH HIG&P Hawai`i Mapping Research Group / NASA / Min Plastics / UH College of Engineering, Mechanical Engineering Department & Waipahu High School Engineers Club: Robotics	Marauder FRC	Rascals	6l-l057 12ll)312 	Waipahu, HI, USA	2008
2478	Westwood High School	WARRIOR ROBOTICS	STINGER	SCORPION	MESA, AZ, USA	2008
2479	General Mills, Alternatives & North High School	Alternatives	Urban Supreme	 	Minneapolis, MN, USA	2008
2480	GE Volunteers TwinCities & Roosevelt High School	RHS/GE	Teddies	Turbo Teddy	Minneapolis, MN, USA	2008
2481	Caterpillar, Inc, & Tremont High School	CAT and TREMONT HS	Roboteers	 	Tremont, IL, USA	2008
2483	NASA / Dupont-Fayetteville Works & Westover High School	WOHS	Clawbotz	Clawbotz	Fayetteville, NC, USA	2008
2484	US FIRST / Rocky Mountain Space Grant Consortium / University of Utah / Honeywell / L3 Communications & Woods Cross High School	Woods Cross High	Team Implosion	NITRO	Woods Cross, UT, USA	2008
2485	QUALCOMM  Incorporated / FIRST & Francis W. Parker High School	Q/F Parker W.A.R.L.s	W.A.R.Lords	Xerxes	San Diego, CA, USA	2008
2486	Arizona Science Foundation / Northern Arizona University / WL Gore & Flagstaff Unified School District #1	SFAZ Coconino H.S.	CocoNuts	RoboDawg	Flagstaff, AZ, USA	2008
2487	Precision Restoration & Sayville High School	Mechanical Animals	Mechanical Animals	 	West Sayville, NY, USA	2008
2488	McNeilus / NASA / Back and Neck Clinic & Studio Academy High School	Studio Academy H.S.	Plasma Pumas	Atlas	Rochester, MN, USA	2008
2489	BAE Systems/Playing @ Learning & Mission San Jose High School -	Insomniacs	MSJ Insomniacs	 	Fremont, CA, USA	2008
2490	Boeing & chicago hope academy high school	chicago hope academy	eagles	 	chicago, IL, USA	2008
2491	Thomas, McNerney & Partners & Great River High School	Great River School	Rapids	 	St. Paul, MN, USA	2008
2493	NASA / The Thomas W. Wathen Foundation / Farwest Aviation / Ace Metals / Universal Machining Services / Smurfit Stone Container Corp & River Springs Charter school Renaissance High School	Riversprings Robokong	Robokong	 	Riverside, CA, USA	2008
2495	ADP / HTEA-NJEA & Hamilton High School West	Hamilton West Hornets	Hornets	Bert	Hamilton, NJ, USA	2008
2496	Beckman Coulter & Arnold O. Beckman High School	Beckman Robotics	BLEET Robotics Club	 	Irvine, CA, USA	2008
2497	Natick High School	NHS	roboNatick	Scarab	Natick, MA, USA	2008
2498	Thomas McNerney & Partners and the Blake School & The Blake High School	Blake BearBotics	BearBotics	HAL	Minneapolis, MN, USA	2008
2499	University of Minnesota Foundation & Hibbing High School	UMF & HHS Bluejackets	Jackets	Psibot	Hibbing, MN, USA	2008
2500	General Mills & Patrick Henry High School	Herobotics	Henry Heros	Amida	Minneapolis, MN, USA	2008
2501	3M & North High School	North Polars	Polars	 	North St. Paul, MN, USA	2008
2502	Best Buy & Eden Prairie High School	Eden Prairie	EPRobotics	 	Eden Prairie, MN, USA	2008
2503	University of Minnesota/Central Lakes College & Brainerd High School	Brainerd	UofM and Brainerd High School	 	Brainerd, MN, USA	2008
2504	NASA / University of Hawaii -KCC / Pearl Harbor Naval Shipyard / University of Hawaii College of Engineering / Hawaii  National Guard & W. R. Farrington High School	The Governors	The GOVS	The Governator	Honolulu, HI, USA	2008
2505	Don Mills Collegiate Institute / St. Andrew's Junior High School & Toronto District School Board	Don Mills CI	The Electric Sheep	 	North York, ON, Canada	2008
2506	Pentair Water a division of Fleck Controls/Rockwell Automation & Franklin High School	Saber Robotics	Sabers	 	Franklin, WI, USA	2008
2508	3M & Stillwater Area High School	Stillwater	Ponies	 	Stillwater, MN, USA	2008
2509	3M & Hutchinson High School- Tigerbots	Tigerbots	Tigers	Tigger	Hutchinson, MN, USA	2008
2510	University of Minnesota -Twin Cities - & albrook & cloquet school dist & fond du lac ojibwe school	ogichidaag	anishinaabe	 	Cloquet, MN, USA	2008
2511	St. Jude Medical & Lakeview High School	St. Jude - Lakeville	Cougars	 	Lakeville, MN, USA	2008
2512	NASA / University of Minnesota, Duluth / Lake Superior College / Northland Foundation & Central High School & Denfeld High School & Duluth East High School	Duluth FIRST	Penguins	The Sea Lion	Duluth, MN, USA	2008
2513	Graco & Thomas Edison High School	 T.E.R.T.O.L.A.	 T.E.R.T.O.L.A.	 	Minneapolis, MN, USA	2008
2514	3M & Mahtonedi High School	3M Mahtomedi HS	3M MHS	Zephyr	Mahtomedi, MN, USA	2008
2515	General Dynamics / BH Electronics / Independant Lumber / Runnings Farm and Fleet / Pride of the Tiger Foundation / Marshall PTA / Brad & Lynn Pohlman / Minnesota West Community & Technical College & Marshall High School	Marshall High School	TigerBots	The Tiger Bot	Marshall, MN, USA	2008
2517	NASA / Bezos Foundation / Rockwell-Collins / SEMI / Riverview Community Bank / Parkrose Hardware / ASCO Machine Inc. & Evergreen High School	NASA/BEZOS/EVERGREEN	Green Wrenches	Allen	Vancouver, WA, USA	2008
2518	St. Jude Medical & Simley High School	Spartans of St. Jude	Spartans	Leonidas	Inver Grove Heights, MN, USA	2008
2520	Bearing Belt and Chain / Albertsons & Valley High School	Robotics 9000	Robotics 9000	Caribooster 9001	Las Vegas, NV, USA	2008
2521	The Christianson Family / FIRST & South Eugene High School	South Eugene Robotics	The Axemen	 	Eugene, OR, USA	2008
2522	NASA / DANTERRY, INC & Lynnwood High School	Lynnwood High School	Fighting Lyons	 	Lynnwood, WA, USA	2008
2523	NASA/Norwich University David Crawford School of Engineering & St. Johnsbury Academy	Lab Rats	Lab Rats	 	St. Johnsbury, VT, USA	2008
2524	Andrew and Judith Economos Foundation / Berkeley College & Roosevelt High School-YPS	YAMETS	YAMETS631	YAMETS631	Yonkers, NY, USA	2008
2525	BOSTON SCIENTIFIC & Armstrong High School	Bos Sci Arm	Falcons	ART II	Plymouth, MN, USA	2008
2526	Boston Scientific & Maple Grove High School	MGSH	Crimson	 	Maple Grove, MN, USA	2008
2528	Netzer Metalcraft / Baltimore City Public School System / Morgan State University / Key Technologies Inc / NASA & Western High School	Western High School	Robo Doves	Columba	Baltimore, MD, USA	2008
2529	Humboldt High School	Medtronic Humboldt Sr	Medtronic Hawks	 	St. Paul, MN, USA	2008
2530	Medtronic Inc.-- & Rochester Public Schools	Medtronic-Rochester	Medtronic--Rochester Public Schools	 	Rochester, MN, USA	2008
2531	Lake Region Manufacturing & Chaska High School	CH Robotics	Hawks	 	Chaska, MN, USA	2008
2532	St Jude Medical & Forest Lake Senior High School	Forest Lake & St Jude	Rangers	Mojo Jojo Judo Robo	Forest Lake, MN, USA	2008
2533	Boeing & Juarez High School	STARS	S.T.A.R.S.	Code Name SUCCESS	Chicago, IL, USA	2008
2534	NASA / Engel & Engel, P.A. / AXA Advisors LLC / Rehbein Enterprises / Vane Brothers / Ascentium / Bedford Insurance Group & Boys' Latin School of Maryland High School	Lakers	Lumberjacks	OFR (Our First Robot)	Baltimore, MD, USA	2008
2535	Cargill Corporation & Minneapolis South High School	Cargill & MPLS-South 	South	 	Minneapolis, MN, USA	2008
2536	Morgan State University / Baltimore City Public School / NASA & Carver Vocational  Technical  High School	Carver Bears	Carver Bears	 	Baltimore, MD, USA	2008
2537	NASA/Booz Allen Hamilton/Columbia Bank/Contour Adjustable Beds/Lazarus Foundation & Atholton High School	NASA/Atholton	RAID	RAID	Columbia, MD, USA	2008
2538	Superior Industries/University of Minnesota Foundation & Morris Area High School	Morris is Superior	The Plaid Pillagers	Plaidinum Piper	Morris, MN, USA	2008
2539	NASA & Palmyra High School	Palmyra High School	Krypton Cougars	 	Palmyra, PA, USA	2008
2540	Northrop Grumman Ship Systems / NASA & South Pontotoc High School	SPARC	SPARC	SPARCY	Pontotoc, MS, USA	2008
2542	NASA/M.J .Murdock Charitable Trust/Platt Electric Supply & Gresham High School	Go4Bots	Go4bots	 	Gresham, OR, USA	2008
2543	Baum Family / FIRST Robotics / Qualcomm / AT&T / EastLake Educational Foundation / Mr. & Mrs. Elder / Innovation Vinyl Windows / Auday Arabo / Mr.& Mrs. Arteaga / Mr.& Mrs. Garcia / Jack West CNC INC. / BAE Systems / Frutas 100% Natural / South Bay Carpet	NARA Acronaughts	Titan-BOT	T.R x 10^20	Chula Vista, CA, USA	2008
2544	GE Volunteers & Harbor Creek School District	GE/Harborcreek	HC RC	Fred	Harborcreek, PA, USA	2008
2545	BAE Systems/NASA & Columbia Heights High School	BAE, NASA & CHHS	BAE NASA High Jumps	Scottie	Columbia Heights, MN, USA	2008
2546	NASA / Morgan State University & Baltimore City Public Schools & Digital Harbor High School	Digital Harbor Rams	Steel Wool	RAM-bo	Baltimore, MD, USA	2008
2547	NASA/Rockwell Automation/GE Volunteers/Hayes Bicycle/Nighthawk Radiology & Bay View High School	NASA/Rockwll/GE Robos	Redcat Robos	Blade Runner	Milwaukee, WI, USA	2008
2549	NASA / The Cargill Foundation & MPLS-Washburn High School	Washburn	Millerbots	The Millerbot	Minneapolis, MN, USA	2008
2550	Autodesk Inc. / Starbucks / Taco Del Mar / URS Electronics / Sunstone Circuits / SAO- Tech start / Phoenix Gold / NASA / Mentor Graphics & Oregon City School District	OC PRO	Pioneer Robotics Organization	 	Oregon City, OR, USA	2008
2551	LRG Capital Group & San Marin High School	LRG & San Marin High	Penguin Empire	Cthulhu	Novato, CA, USA	2008
2553	NASA & Pearl High School	Pirate Robotics	Pirates	Jolly Roger	Pearl, MS, USA	2008
2554	NASA / West Machine Works, Inc. & John P Stevens High School	The War Hawks	The War Hawks	 	Edison, NJ, USA	2008
2555	FIRSTWA / Murdock Foundation / Dimmer Foundation & Wilson High School	Wilson Robotics	RoboRams	TonyTron	Tacoma, WA, USA	2008
2556	NASA / Uiversity of West Florida & CHOICE IT Institute Niceville High School	choiceIT	choiceIT	 	Niceville, FL, USA	2008
2557	Tacoma School of the Arts HIgh School	SOTA	Renegades	 	Tacoma, WA, USA	2008
2558	SCITECH HIGH SCHOOL	SciBot	SciBot	 	Harrisburg, PA, USA	2008
2559	Dauphin County Technical High School	DCTS	DC Techs	 	Harrisurg, PA, USA	2008
2560	Ewing Marion Kauffman Foundation & Consolidated School District #4	RoboDogs	Dogs	 	Grandview, MO, USA	2008
2561	3M & Arlington High School	3M_Arlingotn	3M_Arlington	 	Saint Paul, MN, USA	2008
2562	PRIOR / Polytechnic University of P.R. & Robinson High School	Robinson	Robinson	ROBIT	San Juan, PR, USA	2008
2563	PRIOR/Polytechnic University of P.R. & Manuela Toro High School	Toros	Toros	Longhorn	Caguas, PR, USA	2008
2564	PRIOR/Polytechnic University of P.R. & San Antonio High School	Red Hawks	Red Hawks	Guaraguao	San Juan, PR, USA	2008
2565	Polytechnic University of P.R./PRIOR & Bonneville High School	Technovations	Technovations	Boriken	Cupey, PR, USA	2008
2566	PRIOR/Polytechnic University of P.R & Uiversity Gardens High School	University	Universitiers	Pupil	San Juan, PR, USA	2008
2567	PRIOR/Polytechnic University of P.R. & Vocacional Miguel Such High School	Miguel	Miguel	Electrobot	San Juan, PR, USA	2008
2568	Polytechnic University of P.R./PRIOR & Jose E. Aponte de la Torre  High School	Pa' Los Duros	STORM	Stormtronic	Carolina, PR, USA	2008
2569	PRIOR/Polytechnic University of P.R. & Central de Artes Visuales High School	CAV	Artist Engineers	Centralbot	San Juan, PR, USA	2008
2570	Sahuarita High School	Mustangs	SHS	Liarsenic	Sahuarita, AZ, USA	2008
2571	Haileyville Public Schools	Warriors	Chief robot	 	Haileyville, OK, USA	2008
2572	3M & Johnson Senior High School	governors	governors	 	Saint Paul, MN, USA	2008
2573	Brooklyn Amity High School	BAM	Mustang	 	Brooklyn, NY, USA	2008
2574	Medtronic Inc. & St. Anthony Village High School	St. Anthony HuskieBot	RoboHuskie	HuskieBot	Saint Anthony Village, MN, USA	2008
2575	B&S Solutions/Rotary Clube Santa Branca & Escola Estadual Prof. Waldemar Salgado High School	BS & Waldemar Salgado	White Hurricane	WS1	Santa Branca, SP, Brazil	2008
2576	Universidad Andres Bello/Silva & Cia./Talleres Lucas & Region Metropolitana	Corazón de Chileno	Chilean Heart	Chupacabras	Santiago, SG, Chile	2008
2577	The Pingry School	Pingry	Pingry	 	Martinsville, NJ, USA	2008
2579	NASA / Port Authority of New York and New Jersey / Con Edison / Chino's Auto Service / MTA NYC Transit & Long Island City High School	Long Island City HS	LIC Robodogs	El Chino	New York, NY, USA	2008
2580	Northrop Grumman Corp / NASA-Lockeed Martin & St. Augustine High School	Mecha-Knights	Mecha-Knights	Knight 1	New Orleans, LA, USA	2008
2581	NASA / LEAP Program University Of New Orleans & Carroll High School	CHS Robotics	Bulldog Robotic Team	RoboDogs	Monroe, LA, USA	2008
2582	NASA/Angelina Community College/Pax-Sun Engineering & Lufkin High School	Lufkin Robotics	PantherBots	 	Lufkin, TX, USA	2008
2583	3M & Westwood High School	Westwood-3M	Westwood Elite	My FIRST Robot	Austin, TX, USA	2008
2584	The Annenberg Foundation / ITT Technical Institute / Reseda Women's Club / Valley Bob's Driving School & Reseda High School	Annenberg ITT Reseda	Reseda Regents Robotics R Cubed	Tux Bot	Reseda, CA, USA	2008
2585	ARC Specialties / Newport Construction Services / Houston Robotics & Bellaire High School	Scitobors	Scitobors	 	Bellaire, TX, USA	2008
2586	FIRST Robotics / Cleveland-Cliffs -Michigan Operations & Calumet High School	Calumet	Copper Kings	 	Calumet, MI, USA	2008
2587	Houston Robotics/Rice University & Lamar High School	Lamar Robotics	Disco Bots	Afro Bot	Houston, TX, USA	2008
2588	DIamond Ranch High School	DRHS Robotics	JAVA	 	Pomona, CA, USA	2008
2589	Reeves Automation & Triton Regional High School	Triton Robots	Vikings	notyet	Byfield, MA, USA	2008
2590	Washington Education Foundation / NASA / Wham Engineering Services & Robbinsville High School	NEMESIS	NEMESIS	 	Robbinsville, NJ, USA	2008
2591	Davis Aerospace Technical High School	Davis Aero	SuperNova	 	Detroit, MI, USA	2008
2592	Rio Rico High School	RRHS	Hawks	Bronze Bruce	Rio Rico, AZ, USA	2008
2593	Peabody Veterans Memorial High School	Team Brobot	Brobot	 	Peabody, MA, USA	2008
2594	Idaho National Laboratory/Micron Technology Foundation, Inc./M. J. Murdock Charitable Trust & Nampa School District High Schools	NASCO Robotics	NASCO Bots	 	Nampa, ID, USA	2008
2595	CSULA Engineering and Technology Department / Jacobs Engineering / NASA & Wallis Annenberg High School	Annenberg-CSULA-NASA	Illuminati	Illuminati (Sub Zero)	Los Angeles, CA, USA	2008
2596	New Jersey-New York Port Authority / Goldman Sachs / NASA & Ferris High School- Jersey City	FBI Robotics	Ferrous Bulldog Inovations 	Paradox	Jersey City, NJ, USA	2008
2597	Home Depot / REAL / TRICE / NASA & Sterling High School	Raider Robots	Raider bots	 	Houston, TX, USA	2008
2598	Bio-Rad / ConocoPhillips / CLYM Environmental / Hercules Community Partnership & CCCOE ROP & Hercules Middle High School	Neofighters	Neofighters	 	Hercules, CA, USA	2008
2599	NASA / QUALCOMM Incorporated / Dynegy & Alternative Education, Sweetwater School District High School	FULL THROTTLE	Full Throttle	AWESOME-O	CHULA VISTA, CA, USA	2008
2600	Picatinny Arsenal & JeffersonTwsp. High School	Picatinny & JTHS	Team Falcon	 	Oak Ridge, NJ, USA	2008
2601	Lawrence D. Ackman / Barry Weinberg / Con Edison / Howard Rose / Vinson Friedman, Esq. / Queens College, CUNY / Townsend Harris Alumni Assoc. / THHS  PTA & Townsend Harris High School	THHS	Steel Hawks	Terra Hawk	Flushing, NY, USA	2008
2602	Foothill High School	Foothill Falcons	Falcons	Raptor	Henderson, NV, USA	2008
2603	NASA & Highland High School	Highland High School	Team Hornet	"Sting"	Medina, OH, USA	2008
2604	Witco, Inc. / The Chrysler Foundation / Sterling Tool, Inc. / Champion Steel / Keihin Michigan Mfg. & Capac Community Schools	Capac	Metal and Soul	R-835	Capac, MI, USA	2008
2605	Murdock Foundation / Wilson Motors / Heath Tecna / Comcast / Hardware Sales / WECU / Western Washington University / Vacation Land RV & Bellingham School District	Sehome Wilson Motors	A2D_16	ErFi	Bellingham, WA, USA	2008
2606	Lockheed Martin & Rosemount High School	Lockheed Martin & RHS	Lockheed Martin & Rosemount High School	 	Rosemount, MN, USA	2008
2607	Archbishop Wood High School	Wood Robotics Team 	Fighting Robo-Vikings	 	Warminster, PA, USA	2008
2608	MiGHT Home School	MiGHT	MiGHT	Mighty Mite	Farmington Hills, MI, USA	2008
2609	Research In Motion / Linamar & Our Lady of Lourdes High School	Crusader FIRST	Our Lady of Lourdes	Pac Man	Guelph, ON, Canada	2008
2611	ALRO Steel / Classic Turning / DASI Solutions / Technique Inc. / Great Lakes Industry, Inc. & Jackson County Intermediate School District	JCISD	Jacktown Vectors	 	Jackson, MI, USA	2008
2612	US Army TARDEC/FANUC Robotics Inc. & Waterford Mott High School	The Syntax Errors	The Syntax Errors	Mott-bot 1	Waterford, MI, USA	2008
2613	CCAISD	Twisted Metals	tm	Mr. Norris	Van Horn, TX, USA	2008
2614	West Virginia University / NASA & Mountaineer Area Robotics & Mountaineer Boys and Girls Club	Mnt. Area Robotics	MARS	 	Morgantown, WV, USA	2008
2617	General Motors & J.W. Sexton High School Science, Math, and Engineering Magnet	Robo Reds	Robo Reds	Red	Lansing, MI, USA	2008
2618	Shady Side Academy	SSA	RURobot	Helena	Pittsburgh, PA, USA	2008
2619	Modern Metalcraft & H. H. Dow High School	The Charge	The Charge	 	Midland, MI, USA	2008
2620	Southgate Anderson High School	Southgate Titans	Titans	Scarab	Southgate, MI, USA	2008
2621	Entegris / FLIR Systems & Bedford High School	Bedford HS & Entegris	Bucs	Automaton Phenomenon	Bedford, MA, USA	2008
2622	Clairemont High School	Team 1	Team 1	 	San Diego, CA, USA	2008
2623	Deer Valley High School	lovenpeace	lovenpeace	r2	Antioch, CA, USA	2008
2624	The University of Toronto -- Engineering Faculty & The Bishop Strachan School	BSS BotCatz	BotCatz	BotCat	Toronto, ON, Canada	2008
2625	St. Joan of Arc High School	ARCADIANS	ARCADIANS	spArc 1	Mississauga, ON, Canada	2008
2626	Bombardier Recreational Products Inc./Sherbrooke University & Séminaire de Sherbrooke High School	BRP, U de S, S de S	Barons	 	Sherbrooke, QC, Canada	2008
2627	Grace Center for Arts and Technology	Grace Techies 	Techies	Gracie	Ann Arbor, MI, USA	2008
2628	Treasure Island Job Corps / Velocity11 & SIATech High School	Island Bots	TI BOTS	 	San Francisco, CA, USA	2008
2629	MAC, S.A. / CIATEQ & COLEGIO ALAMOS HIGH SCHOOL	halcones.alamos	Halcones	TEQUILA	QUERETARO, OA, Mexico	2008
2630	Tapuach Hapais	Emek Hefer	Thunderbolts	Maximus	Emek hefer, Central, Israel	2008
2632	Amherst Steele High School	Comet Robot	Comet Robot	 	Amherst, OH, USA	2008
2633	Contra Costa County ROP & Pittsburg High School Home School	Pittsburg High School	Pittsburg Pirates	 	Pittsburg, CA, USA	2008
2634	Canadian Space Agency / CAD MicroSolutions Inc. / Seimens & Chaminade College High School & Toronto Catholic DSB	The Shooterz	The Shooterz	Bullet	Toronto, ON, Canada	2008
2635	Rapid4Mation & Lake Oswego School District & Lakeridge High School	LHS	Team Hazmat	 	Lake Oswego, OR, USA	2008
2637	Peninsula Education Foundation/El Camino College & PV Peninsula High School	PEN~ELCO	SMERT	Panzer	Rolling Hills Estates, CA, USA	2008
2638	Great Neck South High School	GNSHS	Rebels	Rebellion	Great Neck, NY, USA	2008
2640	Piedmont Triad Partnership & Reidsville High School	Reidsville High Schoo	Rams	 	Reidsville, NC, USA	2008
2641	Pittsburgh Central Catholic High School	PCC	VIKINGS	 	Pittsburgh, PA, USA	2008
2642	South Central High School Home School	Falconators	Falcons	Fluffy	Winterville, NC, USA	2008
2643	House Foundation & Gunderson HIgh School	Gunderson	Grizzlies	 	San Jose, CA, USA	2008
2644	North Catholic High School	NC Trojans	Trojans	 	Pittsburgh, PA, USA	2008
2645	T.Q. Machining / Spec Abrasives & Reeths-Puffer High School	Rockets	PowerSurge	Thor	Muskegon, MI, USA	2008
2647	Arizona State Universty & North High School	mustang robot	north2d2	 	Phoenix, AZ, USA	2008
2648	Messalonskee High School	MHS Robotics	Infinite Loop	Wrababot 47	Oakland, ME, USA	2008
2649	Procempa & EMEF Emilio Meier High School	Emilio Meyer	Meyer Robotics	EREM1	Porto Alegre, RS, Brazil	2008
2650	Atid Elahleya High School	ATID ELAHLEYA	ELAHLYA	 	Om- Elfahem, Haifa, Israel	2008
2652	University of Texas at El Paso & Bel Air HIgh School	Big Red HEAT	Highlander Engineering and Technology	 	El Paso, TX, USA	2008
2653	Master High School	Colegio Master	Master Robotics	 	Aracaju, SE, Brazil	2008
2654	Polaris Industries & Roseau High School	Roseau	Rams	 	Roseau, MN, USA	2008
2655	Volvo Trucks of North America / Piedmont Triad Partnership & Southwest Guilford High School -High Point	Southwest Guilford HS	CYBER	 	High Point, NC, USA	2008
2656	Gateway High School	Gateway High School	Gateway	 	Monroeville, PA, USA	2008
2657	NASA & Deming High School	Deming High School	Oonagi	Oonagi	Deming, NM, USA	2008
2658	Rancho Bernardo High School	Rancho Bernardo High	Bucking Broncos	 	San Diego, CA, USA	2008
2659	The Annenberg Foundation, Xerox Corp, Walt Disney Imagineering, Dr. Villalobos & Bishop Alemany High School	A-Team	RoboWarriors	 	Mission Hills, CA, USA	2008
2660	BE Aerospace & Arts & Technology High School	Marysville A&T	B/E Pengbots	Herr Chaos	Marysville, WA, USA	2008
2661	Sierra Cannyon High School	Sierra Canyon School	Trailblazers	 	Chatsworth, CA, USA	2008
2662	Tolleson High School	Annihilators	The Latorz	 	Tolleson, AZ, USA	2008
2663	Grossmont High School	Grossmont	The Foothillers	 	El Cajon, CA, USA	2008
2664	CSTEM & Chavez High School	CSTEM & Chavez HS	Lobos	 	Houston, TX, USA	2008
2665	Thurgood Marshall Academic Magnet Academy	CougarBots	CougarBots	 	Dayton, OH, USA	2008
2667	Flint HIlls Resources & Apple Valley High School	AVHs & Flint H Res	How 'bout dem apples	 	Apple Valley, MN, USA	2008
2668	BAE Systems / Raytheon / Stein Seal & North Montco Technical Career Center	North Montco 	North Montco Vortex	 	Lansdale, PA, USA	2008
2669	Rabin High School	KY	KY Bots	UZI	Kiryat Yam, Northern, Israel	2008
2670	York Memorial Collegiate High School	Memo Mustangs	Mustangs	 	Toronto, ON, Canada	2008
2672	Osfia High School	Osfia High School	Osfia	 	Osfia, Other, Israel	2008
2673	Ford Motor Company-Team Ford First & Cass Technical High School	Cass Tech HS	Tenacious Technicians	 	Detroit, MI, USA	2008
2674	Escolas Integradas Nilton Lins High School	Escolas Nilton Lins	Nilton Lins	 	Manaus, AM, Brazil	2008
2675	Colégio São João Ulbra High School & Colégio Ulbra São Lucas High School	ABCTech	ABCTech	 	Canoas, RS, Brazil	2008
2676	Ecorse Community High School	Ecorse	Ecorse	 	Ecorse, MI, USA	2008
2678	Boyer High School	Brauder High School	Brauder	 	Jerusalem, Jerusalem, Israel	2008
2679	Liyada High School	Liyada	Liyada	 	Jerusalem, Jerusalem, Israel	2008
2680	Index Robótica / Vex Robotics / EM Minas do Leão	Vex Minas	Vex Minas	 	Minas do Leão, RS, Brazil	2008
2681	Bezos Family/Credit Suisse & George Westinghouse High School	Bezos/Cr.Suisse/GWest	Lady G-House Pirates	Dorie	Brooklyn, NY, USA	2008
\.


--
-- Data for Name: team_score; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY team_score (match_level, match_number, match_index, alliance_color_id, "position", score_attribute_id, value) FROM stdin;
0	25	0	2	0	250	6
0	25	0	2	0	251	15
0	24	0	1	0	1	0
0	24	0	1	0	11	1
0	24	0	1	0	240	0
0	24	0	1	0	241	0
0	24	0	1	0	249	6
0	24	0	1	0	250	2
0	24	0	1	0	251	2
0	24	0	2	0	1	0
0	24	0	2	0	11	0
0	24	0	2	0	240	1
0	24	0	2	0	241	0
0	24	0	2	0	249	2
0	24	0	2	0	250	11
0	24	0	2	0	251	0
0	23	0	1	0	1	0
0	23	0	1	0	11	1
0	23	0	1	0	240	0
0	23	0	1	0	241	0
0	23	0	1	0	249	5
0	23	0	1	0	250	0
0	23	0	1	0	251	1
0	23	0	2	0	1	0
0	23	0	2	0	11	1
0	23	0	2	0	240	0
0	23	0	2	0	241	0
0	23	0	2	0	249	2
0	23	0	2	0	250	7
0	23	0	2	0	251	0
0	22	0	1	0	1	0
0	22	0	1	0	11	0
0	22	0	1	0	240	1
0	22	0	1	0	241	0
0	22	0	1	0	249	1
0	22	0	1	0	250	8
0	22	0	1	0	251	0
0	22	0	2	0	1	0
0	22	0	2	0	11	1
0	22	0	2	0	240	0
0	22	0	2	0	241	0
0	22	0	2	0	249	8
0	22	0	2	0	250	7
0	22	0	2	0	251	1
0	21	0	1	0	1	0
0	21	0	1	0	11	1
0	21	0	1	0	240	0
0	21	0	1	0	241	0
0	21	0	1	0	249	1
0	21	0	1	0	250	2
0	21	0	1	0	251	0
0	21	0	2	0	1	0
0	21	0	2	0	11	0
0	21	0	2	0	240	0
0	21	0	2	0	241	0
0	21	0	2	0	249	0
0	21	0	2	0	250	7
0	21	0	2	0	251	2
0	20	0	1	0	1	0
0	20	0	1	0	11	1
0	20	0	1	0	240	1
0	20	0	1	0	241	1
0	20	0	1	0	249	14
0	20	0	1	0	250	3
0	20	0	1	0	251	0
0	20	0	2	0	1	0
0	20	0	2	0	11	2
0	20	0	2	0	240	0
0	20	0	2	0	241	0
0	20	0	2	0	249	1
0	20	0	2	0	250	0
0	20	0	2	0	251	13
0	19	0	1	0	1	0
0	19	0	1	0	11	1
0	19	0	1	0	240	1
0	19	0	1	0	241	1
0	19	0	1	0	249	0
0	19	0	1	0	250	8
0	19	0	1	0	251	0
0	19	0	2	0	1	0
0	19	0	2	0	11	1
0	19	0	2	0	240	0
0	19	0	2	0	241	0
0	19	0	2	0	249	0
0	19	0	2	0	250	0
0	19	0	2	0	251	19
0	18	0	1	0	1	0
0	18	0	1	0	11	1
0	18	0	1	0	240	0
0	18	0	1	0	241	0
0	18	0	1	0	249	3
0	18	0	1	0	250	0
0	18	0	1	0	251	10
0	18	0	2	0	1	0
0	18	0	2	0	11	2
0	18	0	2	0	240	0
0	18	0	2	0	241	0
0	18	0	2	0	249	3
0	18	0	2	0	250	3
0	18	0	2	0	251	2
0	17	0	1	0	1	1
0	17	0	1	0	11	2
0	17	0	1	0	240	1
0	17	0	1	0	241	0
0	17	0	1	0	249	0
0	17	0	1	0	250	14
0	17	0	1	0	251	0
0	17	0	2	0	1	0
0	17	0	2	0	11	2
0	17	0	2	0	240	0
0	17	0	2	0	241	1
0	17	0	2	0	249	4
0	17	0	2	0	250	0
0	17	0	2	0	251	13
0	16	0	1	0	1	0
0	16	0	1	0	11	1
0	16	0	1	0	240	0
0	16	0	1	0	241	0
0	16	0	1	0	249	0
0	16	0	1	0	250	8
0	16	0	1	0	251	1
0	16	0	2	0	1	2
0	16	0	2	0	11	1
0	16	0	2	0	240	1
0	16	0	2	0	241	1
0	16	0	2	0	249	0
0	16	0	2	0	250	7
0	16	0	2	0	251	0
0	15	0	1	0	1	0
0	15	0	1	0	11	0
0	15	0	1	0	240	0
0	15	0	1	0	241	0
0	15	0	1	0	249	0
0	15	0	1	0	250	0
0	15	0	1	0	251	0
0	15	0	2	0	1	0
0	15	0	2	0	11	0
0	15	0	2	0	240	1
0	15	0	2	0	241	0
0	15	0	2	0	249	0
0	15	0	2	0	250	19
0	15	0	2	0	251	0
0	14	0	1	0	1	0
0	14	0	1	0	11	1
0	14	0	1	0	240	0
0	14	0	1	0	241	0
0	14	0	1	0	249	0
0	14	0	1	0	250	1
0	14	0	1	0	251	9
0	14	0	2	0	1	0
0	14	0	2	0	11	0
0	14	0	2	0	240	1
0	14	0	2	0	241	0
0	14	0	2	0	249	4
0	14	0	2	0	250	1
0	14	0	2	0	251	6
0	13	0	1	0	1	0
0	13	0	1	0	11	1
0	13	0	1	0	240	0
0	13	0	1	0	241	0
0	13	0	1	0	249	4
0	13	0	1	0	250	1
0	13	0	1	0	251	2
0	13	0	2	0	1	0
0	13	0	2	0	11	1
0	13	0	2	0	240	1
0	13	0	2	0	241	0
0	13	0	2	0	249	11
0	13	0	2	0	250	0
0	13	0	2	0	251	19
0	12	0	1	0	1	0
0	12	0	1	0	11	0
0	12	0	1	0	240	0
0	12	0	1	0	241	1
0	12	0	1	0	249	0
0	12	0	1	0	250	7
0	12	0	1	0	251	0
0	12	0	2	0	1	0
0	12	0	2	0	11	2
0	12	0	2	0	240	1
0	12	0	2	0	241	0
0	12	0	2	0	249	1
0	12	0	2	0	250	10
0	12	0	2	0	251	1
0	11	0	1	0	1	6
0	11	0	1	0	11	1
0	11	0	1	0	240	0
0	11	0	1	0	241	1
0	11	0	1	0	249	2
0	11	0	1	0	250	5
0	11	0	1	0	251	3
0	11	0	2	0	1	0
0	11	0	2	0	11	1
0	11	0	2	0	240	1
0	11	0	2	0	241	0
0	11	0	2	0	249	0
0	11	0	2	0	250	11
0	11	0	2	0	251	1
0	10	0	1	0	1	0
0	10	0	1	0	11	2
0	10	0	1	0	240	1
0	10	0	1	0	241	0
0	10	0	1	0	249	1
0	10	0	1	0	250	9
0	10	0	1	0	251	1
0	10	0	2	0	1	0
0	10	0	2	0	11	0
0	10	0	2	0	240	0
0	10	0	2	0	241	1
0	10	0	2	0	249	1
0	10	0	2	0	250	0
0	10	0	2	0	251	1
0	9	0	1	0	1	0
0	9	0	1	0	11	1
0	9	0	1	0	240	0
0	9	0	1	0	241	0
0	9	0	1	0	249	0
0	9	0	1	0	250	0
0	9	0	1	0	251	3
0	9	0	2	0	1	0
0	9	0	2	0	11	0
0	9	0	2	0	240	0
0	9	0	2	0	241	0
0	9	0	2	0	249	0
0	9	0	2	0	250	2
0	9	0	2	0	251	3
0	8	0	1	0	1	0
0	8	0	1	0	11	0
0	8	0	1	0	240	0
0	8	0	1	0	241	0
-1	0	0	1	0	1	0
-1	0	0	1	0	11	0
-1	0	0	1	0	240	0
-1	0	0	1	0	241	0
-1	0	0	1	0	249	0
-1	0	0	1	0	250	0
-1	0	0	1	0	251	0
-1	0	0	2	0	1	0
-1	0	0	2	0	11	0
-1	0	0	2	0	240	0
-1	0	0	2	0	241	0
-1	0	0	2	0	249	0
-1	0	0	2	0	250	0
-1	0	0	2	0	251	0
0	8	0	1	0	249	10
0	8	0	1	0	250	0
0	8	0	1	0	251	9
0	8	0	2	0	1	0
0	8	0	2	0	11	1
0	8	0	2	0	240	1
0	8	0	2	0	241	0
0	8	0	2	0	249	0
0	8	0	2	0	250	3
0	8	0	2	0	251	0
0	7	0	1	0	1	0
0	7	0	1	0	11	0
0	7	0	1	0	240	0
0	7	0	1	0	241	1
0	7	0	1	0	249	2
0	7	0	1	0	250	9
0	7	0	1	0	251	0
0	7	0	2	0	1	1
0	7	0	2	0	11	0
0	7	0	2	0	240	0
0	7	0	2	0	241	0
0	7	0	2	0	249	2
0	7	0	2	0	250	4
0	7	0	2	0	251	0
0	6	0	1	0	1	0
0	6	0	1	0	11	1
0	6	0	1	0	240	0
0	6	0	1	0	241	0
0	6	0	1	0	249	2
0	6	0	1	0	250	5
0	6	0	1	0	251	0
0	6	0	2	0	1	0
0	6	0	2	0	11	1
0	6	0	2	0	240	1
0	6	0	2	0	241	0
0	6	0	2	0	249	0
0	6	0	2	0	250	12
0	6	0	2	0	251	1
0	5	0	1	0	1	1
0	5	0	1	0	11	1
0	5	0	1	0	240	0
0	5	0	1	0	241	0
0	5	0	1	0	249	0
0	5	0	1	0	250	9
0	5	0	1	0	251	1
0	5	0	2	0	1	0
0	5	0	2	0	11	1
0	5	0	2	0	240	1
0	5	0	2	0	241	0
0	5	0	2	0	249	1
0	5	0	2	0	250	2
0	5	0	2	0	251	15
0	4	0	1	0	1	0
0	25	0	1	0	1	0
0	25	0	1	0	11	2
0	25	0	1	0	240	0
0	25	0	1	0	241	0
0	25	0	1	0	249	1
0	25	0	1	0	250	2
0	25	0	1	0	251	6
0	25	0	2	0	1	0
0	25	0	2	0	11	1
0	25	0	2	0	240	1
0	25	0	2	0	241	0
0	25	0	2	0	249	1
0	4	0	1	0	11	0
0	4	0	1	0	240	0
0	4	0	1	0	241	0
0	4	0	1	0	249	7
0	4	0	1	0	250	1
0	4	0	1	0	251	0
0	4	0	2	0	1	1
0	4	0	2	0	11	1
0	4	0	2	0	240	1
0	4	0	2	0	241	1
0	4	0	2	0	249	13
0	4	0	2	0	250	15
0	4	0	2	0	251	3
0	3	0	1	0	1	0
0	3	0	1	0	11	1
0	3	0	1	0	240	1
0	3	0	1	0	241	0
0	3	0	1	0	249	3
0	3	0	1	0	250	8
0	3	0	1	0	251	2
0	3	0	2	0	1	0
0	3	0	2	0	11	1
0	3	0	2	0	240	0
0	3	0	2	0	241	0
0	3	0	2	0	249	2
0	3	0	2	0	250	17
0	3	0	2	0	251	1
0	2	0	1	0	1	0
0	2	0	1	0	11	1
0	2	0	1	0	240	0
0	2	0	1	0	241	0
0	2	0	1	0	249	7
0	2	0	1	0	250	6
0	2	0	1	0	251	4
0	2	0	2	0	1	0
0	2	0	2	0	11	0
0	2	0	2	0	240	1
0	2	0	2	0	241	1
0	2	0	2	0	249	0
0	2	0	2	0	250	8
0	2	0	2	0	251	4
0	1	0	1	0	1	0
0	1	0	1	0	11	0
0	1	0	1	0	240	0
0	1	0	1	0	241	1
0	1	0	1	0	249	11
0	1	0	1	0	250	0
0	1	0	1	0	251	1
0	1	0	2	0	1	0
0	1	0	2	0	11	1
0	1	0	2	0	240	1
0	1	0	2	0	241	0
0	1	0	2	0	249	1
0	1	0	2	0	250	4
0	1	0	2	0	251	2
0	26	0	1	0	1	0
0	26	0	1	0	11	2
0	26	0	1	0	240	0
0	26	0	1	0	241	0
0	26	0	1	0	249	4
0	26	0	1	0	250	4
0	26	0	1	0	251	6
0	26	0	2	0	1	0
0	26	0	2	0	11	1
0	26	0	2	0	240	0
0	26	0	2	0	241	0
0	26	0	2	0	249	1
0	26	0	2	0	250	0
0	26	0	2	0	251	1
0	27	0	1	0	1	1
0	27	0	1	0	11	1
0	27	0	1	0	240	0
0	27	0	1	0	241	0
0	27	0	1	0	249	0
0	27	0	1	0	250	1
0	27	0	1	0	251	0
0	27	0	2	0	1	0
0	27	0	2	0	11	0
0	27	0	2	0	240	1
0	27	0	2	0	241	0
0	27	0	2	0	249	4
0	27	0	2	0	250	0
0	27	0	2	0	251	11
0	28	0	1	0	1	0
0	28	0	1	0	11	0
0	28	0	1	0	240	0
0	28	0	1	0	241	0
0	28	0	1	0	249	1
0	28	0	1	0	250	4
0	28	0	1	0	251	1
0	28	0	2	0	1	0
0	28	0	2	0	11	1
0	28	0	2	0	240	0
0	28	0	2	0	241	1
0	28	0	2	0	249	0
0	28	0	2	0	250	14
0	28	0	2	0	251	18
0	29	0	1	0	1	0
0	29	0	1	0	11	1
0	29	0	1	0	240	1
0	29	0	1	0	241	0
0	29	0	1	0	249	3
0	29	0	1	0	250	13
0	29	0	1	0	251	10
0	29	0	2	0	1	0
0	29	0	2	0	11	0
0	29	0	2	0	240	0
0	29	0	2	0	241	0
0	29	0	2	0	249	8
0	29	0	2	0	250	0
0	29	0	2	0	251	0
0	30	0	1	0	1	0
0	30	0	1	0	11	1
0	30	0	1	0	240	1
0	30	0	1	0	241	0
0	30	0	1	0	249	0
0	30	0	1	0	250	11
0	30	0	1	0	251	0
0	30	0	2	0	1	0
0	30	0	2	0	11	1
0	30	0	2	0	240	0
0	30	0	2	0	241	1
0	30	0	2	0	249	2
0	30	0	2	0	250	0
0	30	0	2	0	251	2
0	31	0	1	0	1	0
0	31	0	1	0	11	2
0	31	0	1	0	240	0
0	31	0	1	0	241	0
0	31	0	1	0	249	1
0	31	0	1	0	250	11
0	31	0	1	0	251	1
0	31	0	2	0	1	0
0	31	0	2	0	11	1
0	31	0	2	0	240	1
0	31	0	2	0	241	1
0	31	0	2	0	249	0
0	31	0	2	0	250	10
0	31	0	2	0	251	0
0	32	0	1	0	1	0
0	32	0	1	0	11	1
0	32	0	1	0	240	1
0	32	0	1	0	241	1
0	32	0	1	0	249	1
0	32	0	1	0	250	4
0	32	0	1	0	251	2
0	32	0	2	0	1	2
0	32	0	2	0	11	2
0	32	0	2	0	240	0
0	32	0	2	0	241	0
0	32	0	2	0	249	0
0	32	0	2	0	250	0
0	32	0	2	0	251	0
0	33	0	1	0	1	0
0	33	0	1	0	11	2
0	33	0	1	0	240	0
0	33	0	1	0	241	1
0	33	0	1	0	249	2
0	33	0	1	0	250	4
0	33	0	1	0	251	1
0	33	0	2	0	1	0
0	33	0	2	0	11	0
0	33	0	2	0	240	1
0	33	0	2	0	241	0
0	33	0	2	0	249	3
0	33	0	2	0	250	3
0	33	0	2	0	251	2
0	34	0	1	0	1	2
0	34	0	1	0	11	2
0	34	0	1	0	240	0
0	34	0	1	0	241	1
0	34	0	1	0	249	6
0	34	0	1	0	250	9
0	34	0	1	0	251	1
0	34	0	2	0	1	0
0	34	0	2	0	11	1
0	34	0	2	0	240	1
0	34	0	2	0	241	0
0	34	0	2	0	249	6
0	34	0	2	0	250	0
0	34	0	2	0	251	2
0	35	0	1	0	1	0
0	35	0	1	0	11	0
0	35	0	1	0	240	1
0	35	0	1	0	241	0
0	35	0	1	0	249	0
0	35	0	1	0	250	2
0	35	0	1	0	251	1
0	35	0	2	0	1	1
0	35	0	2	0	11	1
0	35	0	2	0	240	0
0	35	0	2	0	241	0
0	35	0	2	0	249	8
0	35	0	2	0	250	15
0	35	0	2	0	251	0
0	36	0	1	0	1	0
0	36	0	1	0	11	0
0	36	0	1	0	240	1
0	36	0	1	0	241	0
0	36	0	1	0	249	1
0	36	0	1	0	250	6
0	36	0	1	0	251	0
0	36	0	2	0	1	0
0	36	0	2	0	11	1
0	36	0	2	0	240	0
0	36	0	2	0	241	0
0	36	0	2	0	249	6
0	36	0	2	0	250	2
0	36	0	2	0	251	1
0	37	0	1	0	1	0
0	37	0	1	0	11	0
0	37	0	1	0	240	0
0	37	0	1	0	241	1
0	37	0	1	0	249	10
0	37	0	1	0	250	0
0	37	0	1	0	251	0
0	37	0	2	0	1	0
0	37	0	2	0	11	2
0	37	0	2	0	240	1
0	37	0	2	0	241	0
0	37	0	2	0	249	7
0	37	0	2	0	250	6
0	37	0	2	0	251	0
0	38	0	1	0	1	0
0	38	0	1	0	11	1
0	38	0	1	0	240	0
0	38	0	1	0	241	0
0	38	0	1	0	249	1
0	38	0	1	0	250	6
0	38	0	1	0	251	2
0	38	0	2	0	1	0
0	38	0	2	0	11	0
0	38	0	2	0	240	0
0	38	0	2	0	241	0
0	38	0	2	0	249	1
0	38	0	2	0	250	14
0	38	0	2	0	251	7
0	40	0	1	0	1	0
0	40	0	1	0	11	1
0	40	0	1	0	240	0
0	40	0	1	0	241	0
0	40	0	1	0	249	2
0	40	0	1	0	250	0
0	40	0	1	0	251	12
0	40	0	2	0	1	0
0	40	0	2	0	11	1
0	40	0	2	0	240	0
0	40	0	2	0	241	0
0	40	0	2	0	249	10
0	40	0	2	0	250	2
0	40	0	2	0	251	4
0	41	0	1	0	1	0
0	41	0	1	0	11	1
0	41	0	1	0	240	1
0	41	0	1	0	241	0
0	41	0	1	0	249	1
0	41	0	1	0	250	16
0	41	0	1	0	251	0
0	41	0	2	0	1	0
0	41	0	2	0	11	2
0	41	0	2	0	240	0
0	41	0	2	0	241	0
0	41	0	2	0	249	6
0	41	0	2	0	250	1
0	41	0	2	0	251	2
0	43	0	1	0	1	0
0	43	0	1	0	11	1
0	43	0	1	0	240	0
0	43	0	1	0	241	0
0	43	0	1	0	249	3
0	43	0	1	0	250	0
0	43	0	1	0	251	3
0	43	0	2	0	1	0
0	43	0	2	0	11	0
0	43	0	2	0	240	1
0	43	0	2	0	241	1
0	43	0	2	0	249	0
0	43	0	2	0	250	7
0	43	0	2	0	251	2
0	44	0	1	0	1	0
0	44	0	1	0	11	0
0	44	0	1	0	240	1
0	44	0	1	0	241	0
0	44	0	1	0	249	9
0	44	0	1	0	250	1
0	44	0	1	0	251	3
0	44	0	2	0	1	0
0	44	0	2	0	11	1
0	44	0	2	0	240	0
0	44	0	2	0	241	0
0	44	0	2	0	249	3
0	44	0	2	0	250	9
0	44	0	2	0	251	0
0	45	0	1	0	1	0
0	45	0	1	0	11	2
0	45	0	1	0	240	0
0	45	0	1	0	241	1
0	45	0	1	0	249	1
0	45	0	1	0	250	21
0	45	0	1	0	251	0
0	45	0	2	0	1	0
0	45	0	2	0	11	0
0	45	0	2	0	240	0
0	45	0	2	0	241	0
0	45	0	2	0	249	1
0	45	0	2	0	250	0
0	45	0	2	0	251	0
0	46	0	1	0	1	0
0	46	0	1	0	11	0
0	46	0	1	0	240	0
0	46	0	1	0	241	1
0	46	0	1	0	249	5
0	46	0	1	0	250	0
0	46	0	1	0	251	2
0	46	0	2	0	1	1
0	46	0	2	0	11	2
0	46	0	2	0	240	1
0	46	0	2	0	241	0
0	46	0	2	0	249	11
0	46	0	2	0	250	0
0	46	0	2	0	251	6
0	47	0	1	0	1	0
0	47	0	1	0	11	2
0	47	0	1	0	240	0
0	47	0	1	0	241	0
0	47	0	1	0	249	21
0	47	0	1	0	250	0
0	47	0	1	0	251	1
0	47	0	2	0	1	1
0	47	0	2	0	11	2
0	47	0	2	0	240	1
0	47	0	2	0	241	0
0	47	0	2	0	249	3
0	47	0	2	0	250	10
0	47	0	2	0	251	7
0	48	0	1	0	1	0
0	48	0	1	0	11	0
0	48	0	1	0	240	0
0	48	0	1	0	241	0
0	48	0	1	0	249	0
0	48	0	1	0	250	2
0	48	0	1	0	251	3
0	48	0	2	0	1	0
0	48	0	2	0	11	0
0	48	0	2	0	240	1
0	48	0	2	0	241	1
0	48	0	2	0	249	0
0	48	0	2	0	250	8
0	48	0	2	0	251	2
0	49	0	1	0	1	0
0	49	0	1	0	11	2
0	49	0	1	0	240	0
0	49	0	1	0	241	1
0	49	0	1	0	249	0
0	49	0	1	0	250	0
0	49	0	1	0	251	10
0	49	0	2	0	1	2
0	49	0	2	0	11	2
0	49	0	2	0	240	0
0	49	0	2	0	241	0
0	49	0	2	0	249	0
0	49	0	2	0	250	3
0	49	0	2	0	251	6
0	50	0	1	0	1	0
0	50	0	1	0	11	1
0	50	0	1	0	240	0
0	50	0	1	0	241	0
0	50	0	1	0	249	3
0	50	0	1	0	250	0
0	50	0	1	0	251	11
0	50	0	2	0	1	0
0	50	0	2	0	11	2
0	50	0	2	0	240	1
0	50	0	2	0	241	1
0	50	0	2	0	249	0
0	50	0	2	0	250	0
0	50	0	2	0	251	5
0	51	0	1	0	1	0
0	51	0	1	0	11	1
0	51	0	1	0	240	1
0	51	0	1	0	241	0
0	51	0	1	0	249	5
0	51	0	1	0	250	6
0	51	0	1	0	251	4
0	51	0	2	0	1	1
0	51	0	2	0	11	3
0	51	0	2	0	240	0
0	51	0	2	0	241	0
0	51	0	2	0	249	7
0	51	0	2	0	250	1
0	51	0	2	0	251	1
0	52	0	1	0	1	0
0	52	0	1	0	11	0
0	52	0	1	0	240	0
0	52	0	1	0	241	0
0	52	0	1	0	249	0
0	52	0	1	0	250	5
0	52	0	1	0	251	11
0	52	0	2	0	1	0
0	52	0	2	0	11	0
0	52	0	2	0	240	1
0	52	0	2	0	241	0
0	52	0	2	0	249	2
0	52	0	2	0	250	10
0	52	0	2	0	251	6
0	53	0	1	0	1	0
0	53	0	1	0	11	1
0	53	0	1	0	240	0
0	53	0	1	0	241	1
0	53	0	1	0	249	2
0	53	0	1	0	250	4
0	53	0	1	0	251	1
0	53	0	2	0	1	3
0	53	0	2	0	11	1
0	53	0	2	0	240	1
0	53	0	2	0	241	0
0	53	0	2	0	249	0
0	53	0	2	0	250	8
0	53	0	2	0	251	5
0	54	0	1	0	1	0
0	54	0	1	0	11	2
0	54	0	1	0	240	0
0	54	0	1	0	241	0
0	54	0	1	0	249	35
0	54	0	1	0	250	0
0	54	0	1	0	251	0
0	54	0	2	0	1	0
0	54	0	2	0	11	1
0	54	0	2	0	240	0
0	54	0	2	0	241	0
0	54	0	2	0	249	2
0	54	0	2	0	250	4
0	54	0	2	0	251	0
0	39	0	1	0	1	1
0	39	0	1	0	11	1
0	39	0	1	0	240	1
0	39	0	1	0	241	0
0	39	0	1	0	249	5
0	39	0	1	0	250	0
0	39	0	1	0	251	0
0	39	0	2	0	1	2
0	39	0	2	0	11	2
0	39	0	2	0	240	0
0	39	0	2	0	241	0
0	39	0	2	0	249	2
0	39	0	2	0	250	1
0	39	0	2	0	251	6
0	42	0	1	0	1	0
0	42	0	1	0	11	0
0	42	0	1	0	240	1
0	42	0	1	0	241	0
0	42	0	1	0	249	7
0	42	0	1	0	250	0
0	42	0	1	0	251	1
0	42	0	2	0	1	0
0	42	0	2	0	11	0
0	42	0	2	0	240	0
0	42	0	2	0	241	1
0	42	0	2	0	249	0
0	42	0	2	0	250	3
0	42	0	2	0	251	0
1	1	1	1	0	1	0
1	1	1	1	0	11	1
1	1	1	1	0	240	1
1	1	1	1	0	241	1
1	1	1	1	0	249	20
1	1	1	1	0	250	18
1	1	1	1	0	251	2
1	1	1	2	0	1	4
1	1	1	2	0	11	1
1	1	1	2	0	240	0
1	1	1	2	0	241	0
1	1	1	2	0	249	4
1	1	1	2	0	250	0
1	1	1	2	0	251	16
1	2	1	1	0	1	0
1	2	1	1	0	11	1
1	2	1	1	0	240	1
1	2	1	1	0	241	1
1	2	1	1	0	249	1
1	2	1	1	0	250	16
1	2	1	1	0	251	0
1	2	1	2	0	1	1
1	2	1	2	0	11	1
1	2	1	2	0	240	0
1	2	1	2	0	241	0
1	2	1	2	0	249	0
1	2	1	2	0	250	5
1	2	1	2	0	251	2
1	1	2	1	0	1	0
1	1	2	1	0	11	2
1	1	2	1	0	240	1
1	1	2	1	0	241	0
1	1	2	1	0	249	9
1	1	2	1	0	250	15
1	1	2	1	0	251	0
1	1	2	2	0	1	2
1	1	2	2	0	11	0
1	1	2	2	0	240	0
1	1	2	2	0	241	0
1	1	2	2	0	249	6
1	1	2	2	0	250	0
1	1	2	2	0	251	10
1	2	2	1	0	1	0
1	2	2	1	0	11	0
1	2	2	1	0	240	1
1	2	2	1	0	241	1
1	2	2	1	0	249	0
1	2	2	1	0	250	15
1	2	2	1	0	251	0
1	2	2	2	0	1	0
1	2	2	2	0	11	0
1	2	2	2	0	240	0
1	2	2	2	0	241	0
1	2	2	2	0	249	1
1	2	2	2	0	250	1
1	2	2	2	0	251	12
1	3	1	1	0	1	0
1	3	1	1	0	11	0
1	3	1	1	0	240	0
1	3	1	1	0	241	1
1	3	1	1	0	249	2
1	3	1	1	0	250	6
1	3	1	1	0	251	1
1	3	1	2	0	1	3
1	3	1	2	0	11	2
1	3	1	2	0	240	0
1	3	1	2	0	241	0
1	3	1	2	0	249	1
1	3	1	2	0	250	7
1	3	1	2	0	251	2
1	4	1	1	0	1	0
1	4	1	1	0	11	0
1	4	1	1	0	240	0
1	4	1	1	0	241	0
1	4	1	1	0	249	2
1	4	1	1	0	250	6
1	4	1	1	0	251	1
1	4	1	2	0	1	0
1	4	1	2	0	11	0
1	4	1	2	0	240	1
1	4	1	2	0	241	0
1	4	1	2	0	249	5
1	4	1	2	0	250	0
1	4	1	2	0	251	5
1	3	2	1	0	1	0
1	3	2	1	0	11	0
1	3	2	1	0	240	0
1	3	2	1	0	241	1
1	3	2	1	0	249	1
1	3	2	1	0	250	4
1	3	2	1	0	251	1
1	3	2	2	0	1	1
1	3	2	2	0	11	1
1	3	2	2	0	240	0
1	3	2	2	0	241	0
1	3	2	2	0	249	4
1	3	2	2	0	250	3
1	3	2	2	0	251	1
1	4	2	1	0	1	0
1	4	2	1	0	11	0
1	4	2	1	0	240	0
1	4	2	1	0	241	0
1	4	2	1	0	249	2
1	4	2	1	0	250	4
1	4	2	1	0	251	5
1	4	2	2	0	1	0
1	4	2	2	0	11	0
1	4	2	2	0	240	0
1	4	2	2	0	241	0
1	4	2	2	0	249	3
1	4	2	2	0	250	0
1	4	2	2	0	251	4
1	5	1	1	0	1	0
1	5	1	1	0	11	1
1	5	1	1	0	240	1
1	5	1	1	0	241	0
1	5	1	1	0	249	0
1	5	1	1	0	250	23
1	5	1	1	0	251	1
1	5	1	2	0	1	0
1	5	1	2	0	11	0
1	5	1	2	0	240	0
1	5	1	2	0	241	1
1	5	1	2	0	249	2
1	5	1	2	0	250	0
1	5	1	2	0	251	2
1	6	1	1	0	1	0
1	6	1	1	0	11	1
1	6	1	1	0	240	1
1	6	1	1	0	241	0
1	6	1	1	0	249	11
1	6	1	1	0	250	7
1	6	1	1	0	251	3
1	6	1	2	0	1	0
1	6	1	2	0	11	1
1	6	1	2	0	240	0
1	6	1	2	0	241	1
1	6	1	2	0	249	13
1	6	1	2	0	250	3
1	6	1	2	0	251	9
1	5	2	1	0	1	0
1	5	2	1	0	11	3
1	5	2	1	0	240	1
1	5	2	1	0	241	0
1	5	2	1	0	249	0
1	5	2	1	0	250	15
1	5	2	1	0	251	2
1	5	2	2	0	1	0
1	5	2	2	0	11	1
1	5	2	2	0	240	0
1	5	2	2	0	241	1
1	5	2	2	0	249	2
1	5	2	2	0	250	0
1	5	2	2	0	251	15
1	6	2	1	0	1	0
1	6	2	1	0	11	1
1	6	2	1	0	240	0
1	6	2	1	0	241	1
1	6	2	1	0	249	8
1	6	2	1	0	250	2
1	6	2	1	0	251	1
1	6	2	2	0	1	0
1	6	2	2	0	11	1
1	6	2	2	0	240	0
1	6	2	2	0	241	0
1	6	2	2	0	249	2
1	6	2	2	0	250	0
1	6	2	2	0	251	8
1	7	1	1	0	1	0
1	7	1	1	0	11	1
1	7	1	1	0	240	0
1	7	1	1	0	241	1
1	7	1	1	0	249	0
1	7	1	1	0	250	3
1	7	1	1	0	251	0
1	7	1	2	0	1	0
1	7	1	2	0	11	0
1	7	1	2	0	240	1
1	7	1	2	0	241	0
1	7	1	2	0	249	1
1	7	1	2	0	250	4
1	7	1	2	0	251	3
1	8	1	1	0	1	0
1	8	1	1	0	11	3
1	8	1	1	0	240	0
1	8	1	1	0	241	0
1	8	1	1	0	249	13
1	8	1	1	0	250	1
1	8	1	1	0	251	8
1	8	1	2	0	1	0
1	8	1	2	0	11	2
1	8	1	2	0	240	1
1	8	1	2	0	241	1
1	8	1	2	0	249	7
1	8	1	2	0	250	4
1	8	1	2	0	251	10
1	7	2	1	0	1	0
1	7	2	1	0	11	1
1	7	2	1	0	240	0
1	7	2	1	0	241	1
1	7	2	1	0	249	0
1	7	2	1	0	250	5
1	7	2	1	0	251	0
1	7	2	2	0	1	0
1	7	2	2	0	11	1
1	7	2	2	0	240	1
1	7	2	2	0	241	0
1	7	2	2	0	249	0
1	7	2	2	0	250	5
1	7	2	2	0	251	0
1	8	2	1	0	1	0
1	8	2	1	0	11	2
1	8	2	1	0	240	1
1	8	2	1	0	241	0
1	8	2	1	0	249	18
1	8	2	1	0	250	0
1	8	2	1	0	251	4
1	8	2	2	0	1	0
1	8	2	2	0	11	3
1	8	2	2	0	240	0
1	8	2	2	0	241	0
1	8	2	2	0	249	8
1	8	2	2	0	250	0
1	8	2	2	0	251	16
2	1	1	1	0	1	0
2	1	1	1	0	11	2
2	1	1	1	0	240	0
2	1	1	1	0	241	0
2	1	1	1	0	249	9
2	1	1	1	0	250	17
2	1	1	1	0	251	0
2	1	1	2	0	1	0
2	1	1	2	0	11	3
2	1	1	2	0	240	1
2	1	1	2	0	241	1
2	1	1	2	0	249	0
2	1	1	2	0	250	14
2	1	1	2	0	251	0
2	2	1	1	0	1	0
2	2	1	1	0	11	1
2	2	1	1	0	240	1
2	2	1	1	0	241	1
2	2	1	1	0	249	12
2	2	1	1	0	250	5
2	2	1	1	0	251	0
2	2	1	2	0	1	0
2	2	1	2	0	11	0
2	2	1	2	0	240	0
2	2	1	2	0	241	0
2	2	1	2	0	249	1
2	2	1	2	0	250	0
2	2	1	2	0	251	0
2	1	2	1	0	1	0
2	1	2	1	0	11	0
2	1	2	1	0	240	1
2	1	2	1	0	241	0
2	1	2	1	0	249	2
2	1	2	1	0	250	15
2	1	2	1	0	251	0
2	1	2	2	0	1	0
2	1	2	2	0	11	0
2	1	2	2	0	240	0
2	1	2	2	0	241	1
2	1	2	2	0	249	0
2	1	2	2	0	250	7
2	1	2	2	0	251	0
2	2	2	1	0	1	0
2	2	2	1	0	11	0
2	2	2	1	0	240	1
2	2	2	1	0	241	1
2	2	2	1	0	249	11
2	2	2	1	0	250	5
2	2	2	1	0	251	1
2	2	2	2	0	1	0
2	2	2	2	0	11	0
2	2	2	2	0	240	0
2	2	2	2	0	241	0
2	2	2	2	0	249	1
2	2	2	2	0	250	1
2	2	2	2	0	251	2
2	1	3	1	0	1	0
2	1	3	1	0	11	0
2	1	3	1	0	240	0
2	1	3	1	0	241	0
2	1	3	1	0	249	10
2	1	3	1	0	250	7
2	1	3	1	0	251	0
2	1	3	2	0	1	0
2	1	3	2	0	11	0
2	1	3	2	0	240	1
2	1	3	2	0	241	1
2	1	3	2	0	249	0
2	1	3	2	0	250	11
2	1	3	2	0	251	1
2	3	1	1	0	1	0
2	3	1	1	0	11	2
2	3	1	1	0	240	0
2	3	1	1	0	241	0
2	3	1	1	0	249	2
2	3	1	1	0	250	0
2	3	1	1	0	251	0
2	3	1	2	0	1	2
2	3	1	2	0	11	2
2	3	1	2	0	240	1
2	3	1	2	0	241	1
2	3	1	2	0	249	8
2	3	1	2	0	250	1
2	3	1	2	0	251	2
2	4	1	1	0	1	0
2	4	1	1	0	11	2
2	4	1	1	0	240	1
2	4	1	1	0	241	0
2	4	1	1	0	249	4
2	4	1	1	0	250	17
2	4	1	1	0	251	2
2	4	1	2	0	1	0
2	4	1	2	0	11	2
2	4	1	2	0	240	0
2	4	1	2	0	241	1
2	4	1	2	0	249	15
2	4	1	2	0	250	0
2	4	1	2	0	251	11
2	3	2	1	0	1	0
2	3	2	1	0	11	2
2	3	2	1	0	240	0
2	3	2	1	0	241	0
2	3	2	1	0	249	0
2	3	2	1	0	250	2
2	3	2	1	0	251	0
2	3	2	2	0	1	0
2	3	2	2	0	11	1
2	3	2	2	0	240	0
2	3	2	2	0	241	0
2	3	2	2	0	249	1
2	3	2	2	0	250	0
2	3	2	2	0	251	8
2	4	2	1	0	1	0
2	4	2	1	0	11	2
2	4	2	1	0	240	1
2	4	2	1	0	241	0
2	4	2	1	0	249	3
2	4	2	1	0	250	1
2	4	2	1	0	251	7
2	4	2	2	0	1	0
2	4	2	2	0	11	0
2	4	2	2	0	240	0
2	4	2	2	0	241	1
2	4	2	2	0	249	10
2	4	2	2	0	250	1
2	4	2	2	0	251	4
2	3	3	1	0	1	1
2	3	3	1	0	11	1
2	3	3	1	0	240	0
2	3	3	1	0	241	0
2	3	3	1	0	249	2
2	3	3	1	0	250	0
2	3	3	1	0	251	0
2	3	3	2	0	1	1
2	3	3	2	0	11	0
2	3	3	2	0	240	1
2	3	3	2	0	241	0
2	3	3	2	0	249	7
2	3	3	2	0	250	5
2	3	3	2	0	251	0
3	1	1	1	0	1	0
3	1	1	1	0	11	0
3	1	1	1	0	240	1
3	1	1	1	0	241	0
3	1	1	1	0	249	0
3	1	1	1	0	250	20
3	1	1	1	0	251	1
3	1	1	2	0	1	0
3	1	1	2	0	11	0
3	1	1	2	0	240	0
3	1	1	2	0	241	0
3	1	1	2	0	249	2
3	1	1	2	0	250	3
3	1	1	2	0	251	10
3	2	1	1	0	1	2
3	2	1	1	0	11	1
3	2	1	1	0	240	1
3	2	1	1	0	241	1
3	2	1	1	0	249	2
3	2	1	1	0	250	6
3	2	1	1	0	251	15
3	2	1	2	0	1	0
3	2	1	2	0	11	1
3	2	1	2	0	240	0
3	2	1	2	0	241	0
3	2	1	2	0	249	0
3	2	1	2	0	250	2
3	2	1	2	0	251	9
3	1	2	1	0	1	0
3	1	2	1	0	11	1
3	1	2	1	0	240	0
3	1	2	1	0	241	0
3	1	2	1	0	249	0
3	1	2	1	0	250	9
3	1	2	1	0	251	0
3	1	2	2	0	1	0
3	1	2	2	0	11	2
3	1	2	2	0	240	1
3	1	2	2	0	241	1
3	1	2	2	0	249	2
3	1	2	2	0	250	7
3	1	2	2	0	251	10
3	2	2	1	0	1	1
3	2	2	1	0	11	0
3	2	2	1	0	240	1
3	2	2	1	0	241	1
3	2	2	1	0	249	1
3	2	2	1	0	250	3
3	2	2	1	0	251	0
3	2	2	2	0	1	0
3	2	2	2	0	11	1
3	2	2	2	0	240	0
3	2	2	2	0	241	0
3	2	2	2	0	249	3
3	2	2	2	0	250	0
3	2	2	2	0	251	1
3	1	3	1	0	1	0
3	1	3	1	0	11	1
3	1	3	1	0	240	0
3	1	3	1	0	241	0
3	1	3	1	0	249	3
3	1	3	1	0	250	4
3	1	3	1	0	251	1
3	1	3	2	0	1	0
3	1	3	2	0	11	0
3	1	3	2	0	240	1
3	1	3	2	0	241	0
3	1	3	2	0	249	4
3	1	3	2	0	250	0
3	1	3	2	0	251	11
4	1	0	1	0	1	0
4	1	0	1	0	11	1
4	1	0	1	0	240	0
4	1	0	1	0	241	1
4	1	0	1	0	249	0
4	1	0	1	0	250	5
4	1	0	1	0	251	8
4	1	0	2	0	1	1
4	1	0	2	0	11	1
4	1	0	2	0	240	1
4	1	0	2	0	241	0
4	1	0	2	0	249	10
4	1	0	2	0	250	3
4	1	0	2	0	251	1
4	2	0	1	0	1	0
4	2	0	1	0	11	1
4	2	0	1	0	240	0
4	2	0	1	0	241	1
4	2	0	1	0	249	0
4	2	0	1	0	250	3
4	2	0	1	0	251	5
4	2	0	2	0	1	1
4	2	0	2	0	11	0
4	2	0	2	0	240	1
4	2	0	2	0	241	0
4	2	0	2	0	249	0
4	2	0	2	0	250	2
4	2	0	2	0	251	13
\.


--
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY test (id, name) FROM stdin;
1	yo poppa
190	WPI
42	meaning of life
2	Piotr sucks
\.


--
-- Name: alliance_team_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY alliance_team
    ADD CONSTRAINT alliance_team_pkey PRIMARY KEY (match_level, match_number, match_index, alliance_color_id, "position");


--
-- Name: color_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY color
    ADD CONSTRAINT color_pkey PRIMARY KEY (color_id);


--
-- Name: display_component_effect_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY display_component_effect
    ADD CONSTRAINT display_component_effect_pkey PRIMARY KEY (effect_label, substate_label, component_label, keyframe_index);


--
-- Name: display_effect_option_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY display_effect_option
    ADD CONSTRAINT display_effect_option_pkey PRIMARY KEY (effect_label, substate_label, component_label, keyframe_index, key);


--
-- Name: display_state_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY display_state
    ADD CONSTRAINT display_state_pkey PRIMARY KEY (state_label, substate_label, display_type_label);


--
-- Name: display_substate_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY display_substate
    ADD CONSTRAINT display_substate_pkey PRIMARY KEY (substate_label);


--
-- Name: display_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY display_type
    ADD CONSTRAINT display_type_pkey PRIMARY KEY (display_type_label);


--
-- Name: event_preference_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY event_preference
    ADD CONSTRAINT event_preference_pkey PRIMARY KEY (preference_key);


--
-- Name: finals_alliance_partner_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY finals_alliance_partner
    ADD CONSTRAINT finals_alliance_partner_pkey PRIMARY KEY (finals_alliance_number, recruit_order);


--
-- Name: finals_alliance_partner_team_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY finals_alliance_partner
    ADD CONSTRAINT finals_alliance_partner_team_number_key UNIQUE (team_number);


--
-- Name: game_match_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY game_match
    ADD CONSTRAINT game_match_pkey PRIMARY KEY (match_level, match_number, match_index);


--
-- Name: game_state_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY game_state
    ADD CONSTRAINT game_state_pkey PRIMARY KEY (state_label);


--
-- Name: match_level_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY match_level
    ADD CONSTRAINT match_level_pkey PRIMARY KEY (match_level);


--
-- Name: match_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY match_status
    ADD CONSTRAINT match_status_pkey PRIMARY KEY (status_id);


--
-- Name: score_attribute_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY score_attribute
    ADD CONSTRAINT score_attribute_pkey PRIMARY KEY (score_attribute_id);


--
-- Name: team_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY team
    ADD CONSTRAINT team_pkey PRIMARY KEY (team_number);


--
-- Name: team_score_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY team_score
    ADD CONSTRAINT team_score_pkey PRIMARY KEY (match_level, match_number, match_index, alliance_color_id, "position", score_attribute_id);


--
-- Name: test_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY test
    ADD CONSTRAINT test_pkey PRIMARY KEY (id);


--
-- Name: delete; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE delete AS ON DELETE TO test DO NOTIFY test;


--
-- Name: delete4ondeck_match; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE delete4ondeck_match AS ON DELETE TO game_match DO NOTIFY ondeck_match;


--
-- Name: delete4participant_results; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE delete4participant_results AS ON DELETE TO game_match DO NOTIFY participant_results;


--
-- Name: delete4participant_results; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE delete4participant_results AS ON DELETE TO alliance_team DO NOTIFY participant_results;


--
-- Name: delete_notify; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE delete_notify AS ON DELETE TO game_match DO NOTIFY game_match;


--
-- Name: delete_notify; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE delete_notify AS ON DELETE TO alliance_team DO NOTIFY alliance_team;


--
-- Name: delete_notify; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE delete_notify AS ON DELETE TO finals_alliance_partner DO NOTIFY finals_alliance_partner;


--
-- Name: delete_notify; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE delete_notify AS ON DELETE TO display_component_effect DO NOTIFY display_component_effect;


--
-- Name: insert; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE insert AS ON INSERT TO test DO NOTIFY test;


--
-- Name: insert4ondeck_match; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE insert4ondeck_match AS ON INSERT TO game_match DO NOTIFY ondeck_match;


--
-- Name: insert4participant_results; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE insert4participant_results AS ON INSERT TO game_match DO NOTIFY participant_results;


--
-- Name: insert4participant_results; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE insert4participant_results AS ON INSERT TO alliance_team DO NOTIFY participant_results;


--
-- Name: insert_notify; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE insert_notify AS ON INSERT TO game_match DO NOTIFY game_match;


--
-- Name: insert_notify; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE insert_notify AS ON INSERT TO alliance_team DO NOTIFY alliance_team;


--
-- Name: insert_notify; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE insert_notify AS ON INSERT TO finals_alliance_partner DO NOTIFY finals_alliance_partner;


--
-- Name: insert_notify; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE insert_notify AS ON INSERT TO display_component_effect DO NOTIFY display_component_effect;


--
-- Name: update; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE update AS ON UPDATE TO test DO NOTIFY test;


--
-- Name: update4ondeck_match; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE update4ondeck_match AS ON UPDATE TO game_match DO NOTIFY ondeck_match;


--
-- Name: update4participant_results; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE update4participant_results AS ON UPDATE TO game_match DO NOTIFY participant_results;


--
-- Name: update4participant_results; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE update4participant_results AS ON UPDATE TO alliance_team DO NOTIFY participant_results;


--
-- Name: update_notify; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE update_notify AS ON UPDATE TO game_match DO NOTIFY game_match;


--
-- Name: update_notify; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE update_notify AS ON UPDATE TO alliance_team DO NOTIFY alliance_team;


--
-- Name: update_notify; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE update_notify AS ON UPDATE TO finals_alliance_partner DO NOTIFY finals_alliance_partner;


--
-- Name: update_notify; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE update_notify AS ON UPDATE TO display_component_effect DO NOTIFY display_component_effect;


--
-- Name: alliance_team_alliance_color_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alliance_team
    ADD CONSTRAINT alliance_team_alliance_color_id_fkey FOREIGN KEY (alliance_color_id) REFERENCES color(color_id);


--
-- Name: alliance_team_match_level_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alliance_team
    ADD CONSTRAINT alliance_team_match_level_fkey FOREIGN KEY (match_level, match_number, match_index) REFERENCES game_match(match_level, match_number, match_index);


--
-- Name: alliance_team_team_number_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alliance_team
    ADD CONSTRAINT alliance_team_team_number_fkey FOREIGN KEY (team_number) REFERENCES team(team_number);


--
-- Name: display_component_effect_substate_label_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY display_component_effect
    ADD CONSTRAINT display_component_effect_substate_label_fkey FOREIGN KEY (substate_label) REFERENCES display_substate(substate_label);


--
-- Name: display_effect_option_effect_label_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY display_effect_option
    ADD CONSTRAINT display_effect_option_effect_label_fkey FOREIGN KEY (effect_label, substate_label, component_label, keyframe_index) REFERENCES display_component_effect(effect_label, substate_label, component_label, keyframe_index);


--
-- Name: display_state_display_type_label_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY display_state
    ADD CONSTRAINT display_state_display_type_label_fkey FOREIGN KEY (display_type_label) REFERENCES display_type(display_type_label);


--
-- Name: display_state_state_label_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY display_state
    ADD CONSTRAINT display_state_state_label_fkey FOREIGN KEY (state_label) REFERENCES game_state(state_label);


--
-- Name: display_state_substate_label_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY display_state
    ADD CONSTRAINT display_state_substate_label_fkey FOREIGN KEY (substate_label) REFERENCES display_substate(substate_label);


--
-- Name: game_match_match_level_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY game_match
    ADD CONSTRAINT game_match_match_level_fkey FOREIGN KEY (match_level) REFERENCES match_level(match_level);


--
-- Name: game_match_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY game_match
    ADD CONSTRAINT game_match_status_id_fkey FOREIGN KEY (status_id) REFERENCES match_status(status_id);


--
-- Name: game_match_winner_color_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY game_match
    ADD CONSTRAINT game_match_winner_color_id_fkey FOREIGN KEY (winner_color_id) REFERENCES color(color_id);


--
-- Name: team_score_score_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY team_score
    ADD CONSTRAINT team_score_score_attribute_id_fkey FOREIGN KEY (score_attribute_id) REFERENCES score_attribute(score_attribute_id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

