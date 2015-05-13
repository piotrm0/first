--
-- PostgreSQL database dump
--

SET client_encoding = 'SQL_ASCII';
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pgsql
--

COMMENT ON SCHEMA public IS 'Standard public schema';


SET search_path = public, pg_catalog;

--
-- Name: max(integer, integer); Type: FUNCTION; Schema: public; Owner: TacOps
--

CREATE FUNCTION max(integer, integer) RETURNS integer
    AS $_$
	SELECT CASE WHEN $1 > $2 THEN $1 ELSE $2 END
$_$
    LANGUAGE sql STRICT;


ALTER FUNCTION public.max(integer, integer) OWNER TO "TacOps";

--
-- Name: min(integer, integer); Type: FUNCTION; Schema: public; Owner: TacOps
--

CREATE FUNCTION min(integer, integer) RETURNS integer
    AS $_$
	SELECT CASE WHEN $1 < $2 THEN $1 ELSE $2 END
$_$
    LANGUAGE sql STRICT;


ALTER FUNCTION public.min(integer, integer) OWNER TO "TacOps";

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: alliance_team; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
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


ALTER TABLE public.alliance_team OWNER TO "TacOps";

--
-- Name: color; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
--

CREATE TABLE color (
    color_id smallint NOT NULL,
    name character varying,
    rgb_value character varying
);


ALTER TABLE public.color OWNER TO "TacOps";

--
-- Name: display_component_effect; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
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


ALTER TABLE public.display_component_effect OWNER TO "TacOps";

--
-- Name: display_effect_option; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
--

CREATE TABLE display_effect_option (
    effect_label character varying NOT NULL,
    substate_label character varying NOT NULL,
    component_label character varying NOT NULL,
    keyframe_index smallint NOT NULL,
    "key" character varying NOT NULL,
    value character varying
);


ALTER TABLE public.display_effect_option OWNER TO "TacOps";

--
-- Name: display_state; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
--

CREATE TABLE display_state (
    state_label character varying NOT NULL,
    substate_label character varying NOT NULL,
    display_type_label character varying NOT NULL
);


ALTER TABLE public.display_state OWNER TO "TacOps";

--
-- Name: display_substate; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
--

CREATE TABLE display_substate (
    substate_label character varying NOT NULL,
    description character varying
);


ALTER TABLE public.display_substate OWNER TO "TacOps";

--
-- Name: display_type; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
--

CREATE TABLE display_type (
    display_type_label character varying NOT NULL,
    default_quality smallint,
    default_fullscreen boolean,
    description character varying
);


ALTER TABLE public.display_type OWNER TO "TacOps";

--
-- Name: event_preference; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
--

CREATE TABLE event_preference (
    preference_key character varying NOT NULL,
    value character varying
);


ALTER TABLE public.event_preference OWNER TO "TacOps";

--
-- Name: finals_alliance_partner; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
--

CREATE TABLE finals_alliance_partner (
    finals_alliance_number smallint NOT NULL,
    recruit_order smallint NOT NULL,
    team_number integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.finals_alliance_partner OWNER TO "TacOps";

--
-- Name: game_match; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
--

CREATE TABLE game_match (
    match_level smallint NOT NULL,
    match_number smallint NOT NULL,
    match_index smallint NOT NULL,
    status_id smallint,
    time_scheduled timestamp without time zone,
    winner_color_id smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.game_match OWNER TO "TacOps";

--
-- Name: game_state; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
--

CREATE TABLE game_state (
    state_label character varying NOT NULL,
    description character varying,
    menu_order smallint,
    menu_label character varying
);


ALTER TABLE public.game_state OWNER TO "TacOps";

--
-- Name: match_level; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
--

CREATE TABLE match_level (
    match_level smallint NOT NULL,
    abbreviation character varying,
    description character varying
);


ALTER TABLE public.match_level OWNER TO "TacOps";

--
-- Name: match_status; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
--

CREATE TABLE match_status (
    status_id smallint NOT NULL,
    description character varying
);


ALTER TABLE public.match_status OWNER TO "TacOps";

--
-- Name: ondeck_match; Type: VIEW; Schema: public; Owner: TacOps
--

CREATE VIEW ondeck_match AS
    SELECT game_match.match_level, game_match.match_number, game_match.match_index, game_match.status_id, game_match.time_scheduled, game_match.winner_color_id FROM game_match WHERE (game_match.status_id < 3) ORDER BY game_match.time_scheduled, game_match.status_id DESC, game_match.match_level, game_match.match_number, game_match.match_index;


ALTER TABLE public.ondeck_match OWNER TO "TacOps";

--
-- Name: team; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
--

CREATE TABLE team (
    team_number integer NOT NULL,
    info text,
    short_name character varying,
    nickname character varying,
    robot_name character varying,
    "location" character varying,
    rookie_year integer
);


ALTER TABLE public.team OWNER TO "TacOps";

--
-- Name: participant_results; Type: VIEW; Schema: public; Owner: TacOps
--

CREATE VIEW participant_results AS
    SELECT summary.team_number AS team, summary.wins, summary.losses, ((summary.num_matches - summary.wins) - summary.losses) AS ties, (((((2 * summary.wins) + ((summary.num_matches - summary.wins) - summary.losses)))::numeric(6,3) / (max(1, summary.num_matches))::numeric))::numeric(6,3) AS record, (((summary.points_sum)::numeric(6,3) / (max(1, summary.num_matches))::numeric))::numeric(6,3) AS "ave points", summary.score_max AS "max score", summary.points_sum AS "total points", team.short_name AS "team name" FROM ((SELECT alliance_team.team_number, sum(CASE WHEN ((game_match.winner_color_id = alliance_team.alliance_color_id) AND ((alliance_team.flags & 1) = 0)) THEN 1 ELSE 0 END) AS wins, sum(CASE WHEN ((game_match.winner_color_id <> alliance_team.alliance_color_id) AND (game_match.winner_color_id <> 0)) THEN 1 ELSE 0 END) AS losses, (count(*))::integer AS num_matches, max(alliance_team.score) AS score_max, sum(alliance_team.points) AS points_sum FROM (game_match NATURAL JOIN alliance_team) WHERE ((((game_match.match_level = 0) AND (game_match.match_index = 0)) AND (game_match.status_id = 4)) AND ((alliance_team.flags & 2) = 0)) GROUP BY alliance_team.team_number) summary NATURAL JOIN team) ORDER BY (((((2 * summary.wins) + ((summary.num_matches - summary.wins) - summary.losses)))::numeric(6,3) / (max(1, summary.num_matches))::numeric))::numeric(6,3) DESC, (((summary.points_sum)::numeric(6,3) / (max(1, summary.num_matches))::numeric))::numeric(6,3) DESC, summary.score_max DESC, summary.points_sum DESC;


ALTER TABLE public.participant_results OWNER TO "TacOps";

--
-- Name: score_attribute; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
--

CREATE TABLE score_attribute (
    score_attribute_id integer NOT NULL,
    name character varying,
    description character varying
);


ALTER TABLE public.score_attribute OWNER TO "TacOps";

--
-- Name: team_score; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
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


ALTER TABLE public.team_score OWNER TO "TacOps";

--
-- Name: test; Type: TABLE; Schema: public; Owner: TacOps; Tablespace: 
--

CREATE TABLE test (
    id integer NOT NULL,
    name character varying
);


ALTER TABLE public.test OWNER TO "TacOps";

--
-- Data for Name: alliance_team; Type: TABLE DATA; Schema: public; Owner: TacOps
--

COPY alliance_team (match_level, match_number, match_index, alliance_color_id, "position", team_number, flags, score, points) FROM stdin;
0	11	0	1	1	1685	0	5	5
0	11	0	1	2	1276	0	5	5
0	11	0	1	3	173	0	5	5
0	11	0	2	1	131	0	49	35
0	11	0	2	2	40	0	49	35
0	11	0	2	3	121	0	49	35
0	26	0	1	1	125	0	32	7
0	26	0	1	2	562	0	32	7
0	26	0	1	3	1474	0	32	7
0	26	0	2	1	181	0	7	7
0	26	0	2	2	663	0	7	7
0	26	0	2	3	1124	0	7	7
0	27	0	1	1	1027	0	3	3
0	27	0	1	2	350	0	3	3
0	27	0	1	3	246	0	3	3
0	27	0	2	1	230	0	25	8
0	27	0	2	2	571	0	25	8
0	27	0	2	3	811	0	25	8
0	48	0	2	2	1519	0	46	9
0	48	0	2	3	1307	0	46	9
0	49	0	1	1	271	0	30	25
0	49	0	1	2	348	0	30	25
0	49	0	1	3	1100	0	30	25
0	49	0	2	1	121	2	15	15
0	49	0	2	2	663	0	15	15
0	49	0	2	3	173	0	15	15
0	50	0	1	1	1058	0	19	19
0	50	0	1	2	151	0	19	19
0	50	0	1	3	157	0	19	19
0	50	0	2	1	1733	0	35	19
0	50	0	2	2	571	0	35	19
0	50	0	2	3	228	0	35	19
0	51	0	1	1	190	0	42	36
0	51	0	1	2	88	0	42	36
0	51	0	1	3	175	0	42	36
0	51	0	2	1	1474	0	31	31
0	51	0	2	2	350	0	31	31
0	51	0	2	3	1126	0	31	31
0	52	0	1	1	1027	0	26	26
0	52	0	1	2	166	0	26	26
0	52	0	1	3	40	0	26	26
0	52	0	2	1	1276	2	48	26
0	52	0	2	2	562	0	48	26
0	52	0	2	3	467	2	48	26
0	53	0	1	1	177	0	30	30
0	53	0	1	2	246	0	30	30
0	53	0	1	3	1289	0	30	30
0	53	0	2	1	1124	0	29	29
0	53	0	2	2	1685	0	29	29
0	53	0	2	3	1735	0	29	29
0	54	0	1	1	157	2	45	19
0	54	0	1	2	839	0	45	19
0	54	0	1	3	195	0	45	19
0	54	0	2	1	238	0	19	19
0	54	0	2	2	230	0	19	19
0	54	0	2	3	1725	0	19	19
0	28	0	1	1	88	0	14	14
0	28	0	1	2	176	0	14	14
0	28	0	1	3	131	0	14	14
0	28	0	2	1	348	0	75	14
0	28	0	2	2	40	0	75	14
0	28	0	2	3	177	0	75	14
0	29	0	1	1	166	0	67	8
0	29	0	1	2	1126	0	67	8
0	29	0	1	3	1405	0	67	8
0	29	0	2	1	1733	0	8	8
0	29	0	2	2	839	0	8	8
0	29	0	2	3	237	0	8	8
0	30	0	1	1	1725	0	48	19
0	30	0	1	2	1100	0	48	19
0	30	0	1	3	1519	0	48	19
0	30	0	2	1	151	0	19	19
0	30	0	2	2	1289	0	19	19
0	30	0	2	3	809	0	19	19
0	31	0	1	1	1058	0	45	45
0	31	0	1	2	121	0	45	45
0	31	0	1	3	1735	0	45	45
0	31	0	2	1	126	0	55	45
0	31	0	2	2	234	0	55	45
0	31	0	2	3	467	0	55	45
0	32	0	1	1	1685	0	40	10
0	32	0	1	2	1103	0	40	10
0	32	0	1	3	238	0	40	10
0	32	0	2	1	562	0	0	0
0	32	0	2	2	271	0	0	0
0	32	0	2	3	1276	0	0	0
0	33	0	1	1	571	0	35	24
0	33	0	1	2	125	0	35	24
0	33	0	1	3	1027	0	35	24
0	33	0	2	1	1307	0	24	24
0	33	0	2	2	228	0	24	24
0	33	0	2	3	88	0	24	24
0	34	0	1	1	839	0	44	23
0	34	0	1	2	177	0	44	23
0	34	0	1	3	663	0	44	23
0	34	0	2	1	1474	0	23	23
0	34	0	2	2	157	0	23	23
0	34	0	2	3	195	0	23	23
0	35	0	1	1	1124	0	17	17
0	35	0	1	2	246	0	17	17
0	35	0	1	3	230	0	17	17
0	35	0	2	1	40	0	53	17
0	35	0	2	2	173	0	53	17
0	35	0	2	3	190	0	53	17
0	36	0	1	1	350	0	29	18
0	36	0	1	2	151	0	29	18
0	36	0	1	3	126	0	29	18
0	36	0	2	1	237	0	18	18
0	36	0	2	2	1126	0	18	18
0	36	0	2	3	1725	0	18	18
0	37	0	1	1	809	0	20	20
0	37	0	1	2	195	0	20	20
0	37	0	1	3	166	0	20	20
0	37	0	2	1	1276	0	45	20
0	37	0	2	2	811	0	45	20
0	37	0	2	3	121	0	45	20
0	38	0	1	1	562	0	26	26
0	38	0	1	2	175	0	26	26
0	38	0	1	3	467	0	26	26
0	38	0	2	1	181	0	50	26
0	38	0	2	2	176	0	50	26
0	38	0	2	3	1519	0	50	26
0	39	0	1	1	1027	0	15	20
0	39	0	1	2	1733	0	15	20
0	39	0	1	3	88	0	15	20
0	39	0	2	1	177	0	11	11
0	39	0	2	2	131	0	11	11
0	39	0	2	3	1405	0	11	11
0	40	0	1	1	348	0	19	19
0	40	0	1	2	839	0	19	19
0	40	0	1	3	1103	0	19	19
0	40	0	2	1	1100	0	25	19
0	40	0	2	2	125	0	25	19
0	40	0	2	3	1058	0	25	19
0	41	0	1	1	40	0	64	21
0	41	0	1	2	234	0	64	21
0	41	0	1	3	1685	0	64	21
0	41	0	2	1	1474	0	21	21
0	41	0	2	2	230	0	21	21
0	41	0	2	3	228	0	21	21
0	43	0	1	1	173	0	11	11
0	43	0	1	2	1289	0	11	11
0	43	0	1	3	166	0	11	11
0	43	0	2	1	151	0	43	11
0	43	0	2	2	1276	0	43	11
0	43	0	2	3	246	0	43	11
0	44	0	1	1	238	0	25	25
0	44	0	1	2	175	0	25	25
0	44	0	1	3	176	0	25	25
0	44	0	2	1	88	0	35	25
0	44	0	2	2	1735	0	35	25
0	44	0	2	3	121	0	35	25
0	45	0	1	1	177	0	84	1
0	45	0	1	2	181	0	84	1
0	45	0	1	3	1126	0	84	1
0	45	0	2	1	157	0	1	1
0	45	0	2	2	190	0	1	1
0	45	0	2	3	562	0	1	1
0	46	0	1	1	131	0	17	17
0	46	0	1	2	839	0	17	17
0	46	0	1	3	809	0	17	17
0	46	0	2	1	1027	0	32	17
0	46	0	2	2	467	0	32	17
0	46	0	2	3	195	0	32	17
0	47	0	1	1	1405	0	32	32
0	47	0	1	2	811	0	32	32
0	47	0	1	3	1103	0	32	32
0	47	0	2	1	1124	0	55	32
0	47	0	2	2	1725	0	55	32
0	47	0	2	3	126	0	55	32
0	48	0	1	1	230	0	9	9
0	48	0	1	2	237	0	9	9
0	48	0	1	3	234	0	9	9
0	48	0	2	1	125	0	46	9
0	42	0	1	1	571	0	18	18
0	42	0	1	2	1725	0	18	18
0	42	0	1	3	663	0	18	18
0	42	0	2	1	1307	0	19	18
0	42	0	2	2	1124	0	19	18
0	42	0	2	3	271	0	19	18
1	1	1	1	1	0	0	0	0
1	1	1	1	2	0	0	0	0
1	1	1	1	3	0	0	0	0
1	1	1	2	1	0	0	0	0
1	1	1	2	2	0	0	0	0
1	1	1	2	3	0	0	0	0
1	1	2	1	1	0	0	0	0
1	1	2	1	2	0	0	0	0
1	1	2	1	3	0	0	0	0
1	1	2	2	1	0	0	0	0
1	1	2	2	2	0	0	0	0
1	1	2	2	3	0	0	0	0
1	2	1	1	1	0	0	0	0
1	2	1	1	2	0	0	0	0
1	2	1	1	3	0	0	0	0
1	2	1	2	1	0	0	0	0
1	2	1	2	2	0	0	0	0
1	2	1	2	3	0	0	0	0
1	2	2	1	1	0	0	0	0
1	2	2	1	2	0	0	0	0
1	2	2	1	3	0	0	0	0
1	2	2	2	1	0	0	0	0
1	2	2	2	2	0	0	0	0
1	2	2	2	3	0	0	0	0
1	3	1	1	1	0	0	0	0
1	3	1	1	2	0	0	0	0
1	3	1	1	3	0	0	0	0
1	3	1	2	1	0	0	0	0
1	3	1	2	2	0	0	0	0
1	3	1	2	3	0	0	0	0
1	3	2	1	1	0	0	0	0
1	3	2	1	2	0	0	0	0
1	3	2	1	3	0	0	0	0
1	3	2	2	1	0	0	0	0
1	3	2	2	2	0	0	0	0
1	3	2	2	3	0	0	0	0
1	4	1	1	1	0	0	0	0
1	4	1	1	2	0	0	0	0
1	4	1	1	3	0	0	0	0
1	4	1	2	1	0	0	0	0
1	4	1	2	2	0	0	0	0
1	4	1	2	3	0	0	0	0
1	4	2	1	1	0	0	0	0
1	4	2	1	2	0	0	0	0
1	4	2	1	3	0	0	0	0
1	4	2	2	1	0	0	0	0
1	4	2	2	2	0	0	0	0
1	4	2	2	3	0	0	0	0
1	5	1	1	1	0	0	0	0
1	5	1	1	2	0	0	0	0
1	5	1	1	3	0	0	0	0
1	5	1	2	1	0	0	0	0
1	5	1	2	2	0	0	0	0
1	5	1	2	3	0	0	0	0
1	5	2	1	1	0	0	0	0
1	5	2	1	2	0	0	0	0
1	5	2	1	3	0	0	0	0
1	5	2	2	1	0	0	0	0
1	5	2	2	2	0	0	0	0
1	5	2	2	3	0	0	0	0
1	6	1	1	1	0	0	0	0
1	6	1	1	2	0	0	0	0
1	6	1	1	3	0	0	0	0
1	6	1	2	1	0	0	0	0
1	6	1	2	2	0	0	0	0
1	6	1	2	3	0	0	0	0
1	6	2	1	1	0	0	0	0
1	6	2	1	2	0	0	0	0
1	6	2	1	3	0	0	0	0
1	6	2	2	1	0	0	0	0
1	6	2	2	2	0	0	0	0
1	6	2	2	3	0	0	0	0
1	7	1	1	1	0	0	0	0
1	7	1	1	2	0	0	0	0
1	7	1	1	3	0	0	0	0
1	7	1	2	1	0	0	0	0
1	7	1	2	2	0	0	0	0
1	7	1	2	3	0	0	0	0
1	7	2	1	1	0	0	0	0
1	7	2	1	2	0	0	0	0
1	7	2	1	3	0	0	0	0
1	7	2	2	1	0	0	0	0
1	7	2	2	2	0	0	0	0
1	7	2	2	3	0	0	0	0
1	8	1	1	1	0	0	0	0
1	8	1	1	2	0	0	0	0
1	8	1	1	3	0	0	0	0
1	8	1	2	1	0	0	0	0
1	8	1	2	2	0	0	0	0
1	8	1	2	3	0	0	0	0
1	8	2	1	1	0	0	0	0
1	8	2	1	2	0	0	0	0
1	8	2	1	3	0	0	0	0
1	8	2	2	1	0	0	0	0
1	8	2	2	2	0	0	0	0
1	8	2	2	3	0	0	0	0
2	1	1	1	1	0	0	0	0
2	1	1	1	2	0	0	0	0
2	1	1	1	3	0	0	0	0
2	1	1	2	1	0	0	0	0
2	1	1	2	2	0	0	0	0
2	1	1	2	3	0	0	0	0
2	1	2	1	1	0	0	0	0
2	1	2	1	2	0	0	0	0
2	1	2	1	3	0	0	0	0
2	1	2	2	1	0	0	0	0
2	1	2	2	2	0	0	0	0
2	1	2	2	3	0	0	0	0
2	1	3	1	1	0	0	0	0
2	1	3	1	2	0	0	0	0
2	1	3	1	3	0	0	0	0
2	1	3	2	1	0	0	0	0
2	1	3	2	2	0	0	0	0
2	1	3	2	3	0	0	0	0
2	2	1	1	1	0	0	0	0
2	2	1	1	2	0	0	0	0
2	2	1	1	3	0	0	0	0
2	2	1	2	1	0	0	0	0
2	2	1	2	2	0	0	0	0
2	2	1	2	3	0	0	0	0
2	2	2	1	1	0	0	0	0
2	2	2	1	2	0	0	0	0
2	2	2	1	3	0	0	0	0
2	2	2	2	1	0	0	0	0
2	2	2	2	2	0	0	0	0
2	2	2	2	3	0	0	0	0
2	2	3	1	1	0	0	0	0
2	2	3	1	2	0	0	0	0
2	2	3	1	3	0	0	0	0
2	2	3	2	1	0	0	0	0
2	2	3	2	2	0	0	0	0
2	2	3	2	3	0	0	0	0
2	3	1	1	1	0	0	0	0
2	3	1	1	2	0	0	0	0
2	3	1	1	3	0	0	0	0
2	3	1	2	1	0	0	0	0
2	3	1	2	2	0	0	0	0
2	3	1	2	3	0	0	0	0
2	3	2	1	1	0	0	0	0
2	3	2	1	2	0	0	0	0
2	3	2	1	3	0	0	0	0
2	3	2	2	1	0	0	0	0
2	3	2	2	2	0	0	0	0
2	3	2	2	3	0	0	0	0
2	3	3	1	1	0	0	0	0
2	3	3	1	2	0	0	0	0
2	3	3	1	3	0	0	0	0
2	3	3	2	1	0	0	0	0
2	3	3	2	2	0	0	0	0
2	3	3	2	3	0	0	0	0
2	4	1	1	1	0	0	0	0
2	4	1	1	2	0	0	0	0
2	4	1	1	3	0	0	0	0
2	4	1	2	1	0	0	0	0
2	4	1	2	2	0	0	0	0
2	4	1	2	3	0	0	0	0
2	4	2	1	1	0	0	0	0
2	4	2	1	2	0	0	0	0
2	4	2	1	3	0	0	0	0
2	4	2	2	1	0	0	0	0
2	4	2	2	2	0	0	0	0
2	4	2	2	3	0	0	0	0
2	4	3	1	1	0	0	0	0
2	4	3	1	2	0	0	0	0
2	4	3	1	3	0	0	0	0
2	4	3	2	1	0	0	0	0
2	4	3	2	2	0	0	0	0
2	4	3	2	3	0	0	0	0
3	1	1	1	1	0	0	0	0
3	1	1	1	2	0	0	0	0
3	1	1	1	3	0	0	0	0
3	1	1	2	1	0	0	0	0
3	1	1	2	2	0	0	0	0
3	1	1	2	3	0	0	0	0
3	1	2	1	1	0	0	0	0
3	1	2	1	2	0	0	0	0
3	1	2	1	3	0	0	0	0
3	1	2	2	1	0	0	0	0
3	1	2	2	2	0	0	0	0
3	1	2	2	3	0	0	0	0
3	1	3	1	1	0	0	0	0
3	1	3	1	2	0	0	0	0
3	1	3	1	3	0	0	0	0
3	1	3	2	1	0	0	0	0
3	1	3	2	2	0	0	0	0
3	1	3	2	3	0	0	0	0
3	2	1	1	1	0	0	0	0
3	2	1	1	2	0	0	0	0
3	2	1	1	3	0	0	0	0
3	2	1	2	1	0	0	0	0
3	2	1	2	2	0	0	0	0
3	2	1	2	3	0	0	0	0
3	2	2	1	1	0	0	0	0
3	2	2	1	2	0	0	0	0
3	2	2	1	3	0	0	0	0
3	2	2	2	1	0	0	0	0
3	2	2	2	2	0	0	0	0
3	2	2	2	3	0	0	0	0
3	2	3	1	1	0	0	0	0
3	2	3	1	2	0	0	0	0
3	2	3	1	3	0	0	0	0
3	2	3	2	1	0	0	0	0
3	2	3	2	2	0	0	0	0
3	2	3	2	3	0	0	0	0
4	1	0	1	1	0	0	0	0
4	1	0	1	2	0	0	0	0
4	1	0	1	3	0	0	0	0
4	1	0	2	1	0	0	0	0
4	1	0	2	2	0	0	0	0
4	1	0	2	3	0	0	0	0
4	2	0	1	1	0	0	0	0
4	2	0	1	2	0	0	0	0
4	2	0	1	3	0	0	0	0
4	2	0	2	1	0	0	0	0
4	2	0	2	2	0	0	0	0
4	2	0	2	3	0	0	0	0
4	3	0	1	1	0	0	0	0
4	3	0	1	2	0	0	0	0
4	3	0	1	3	0	0	0	0
4	3	0	2	1	0	0	0	0
4	3	0	2	2	0	0	0	0
4	3	0	2	3	0	0	0	0
0	4	0	1	1	173	0	10	10
0	4	0	1	2	571	0	10	10
0	4	0	1	3	1307	0	10	10
0	4	0	2	1	1126	0	81	10
0	4	0	2	2	190	0	81	10
0	4	0	2	3	348	0	81	10
0	3	0	1	1	1733	0	44	44
0	3	0	1	2	1405	0	44	44
0	3	0	1	3	126	0	44	44
0	3	0	2	1	246	0	59	44
0	3	0	2	2	234	0	59	44
0	3	0	2	3	121	0	59	44
0	2	0	1	1	175	0	34	34
0	2	0	1	2	1735	0	34	34
0	2	0	1	3	1100	0	34	34
0	2	0	2	1	40	0	48	34
0	2	0	2	2	811	0	48	34
0	2	0	2	3	809	0	48	34
0	1	0	1	1	238	0	22	22
0	1	0	1	2	131	0	22	22
0	1	0	1	3	195	0	22	22
0	1	0	2	1	271	0	30	22
0	1	0	2	2	467	0	30	22
0	1	0	2	3	157	0	30	22
0	20	0	1	1	348	0	48	24
0	20	0	1	2	125	0	48	24
0	20	0	1	3	166	0	48	24
0	20	0	2	1	1474	0	24	24
0	20	0	2	2	571	0	24	24
0	20	0	2	3	151	0	24	24
0	19	0	1	1	1058	0	49	24
0	19	0	1	2	1103	0	49	24
0	19	0	1	3	176	0	49	24
0	19	0	2	1	195	0	24	24
0	19	0	2	2	246	0	24	24
0	19	0	2	3	40	0	24	24
0	18	0	1	1	350	0	18	18
0	18	0	1	2	181	0	18	18
0	18	0	1	3	811	0	18	18
0	18	0	2	1	131	0	24	18
0	18	0	2	2	1733	0	24	18
0	18	0	2	3	663	0	24	18
0	17	0	1	1	1519	0	57	37
0	17	0	1	2	1276	0	57	37
0	17	0	1	3	126	0	57	37
0	17	0	2	1	175	0	37	37
0	17	0	2	2	237	0	37	37
0	17	0	2	3	173	0	37	37
0	16	0	1	1	1685	0	30	30
0	16	0	1	2	228	0	30	30
0	16	0	1	3	1100	0	30	30
0	16	0	2	1	1307	0	36	30
0	16	0	2	2	121	0	36	30
0	16	0	2	3	238	0	36	30
0	15	0	1	1	1289	0	0	0
0	15	0	1	2	234	0	0	0
0	15	0	1	3	1735	0	0	0
0	15	0	2	1	271	0	67	0
0	15	0	2	2	1126	0	67	0
0	15	0	2	3	467	0	67	0
0	14	0	1	1	166	0	17	17
0	14	0	1	2	176	0	17	17
0	14	0	1	3	157	0	17	17
0	14	0	2	1	1405	0	23	17
0	14	0	2	2	809	0	23	17
0	14	0	2	3	190	0	23	17
0	13	0	1	3	663	0	14	14
0	13	0	2	1	348	0	45	14
0	13	0	2	2	151	0	45	14
0	13	0	2	3	1474	0	45	14
0	10	0	1	1	228	0	49	12
0	10	0	1	2	1126	0	49	12
0	10	0	1	3	238	0	49	12
0	10	0	2	1	811	0	12	12
0	10	0	2	2	246	0	12	12
0	10	0	2	3	1289	0	12	12
0	9	0	1	1	190	0	8	8
0	9	0	1	2	1405	0	8	8
0	9	0	1	3	271	0	8	8
0	9	0	2	1	175	0	9	8
0	9	0	2	2	1307	0	9	8
0	9	0	2	3	1733	0	9	8
0	8	0	1	1	234	0	19	19
0	8	0	1	2	195	0	19	19
0	8	0	1	3	1100	0	19	19
0	8	0	2	1	126	0	24	19
0	8	0	2	2	157	0	24	19
0	8	0	2	3	809	0	24	19
0	7	0	1	1	237	0	39	14
0	7	0	1	2	663	0	39	14
0	7	0	1	3	125	0	39	14
0	7	0	2	1	176	0	9	9
0	7	0	2	2	467	0	9	9
0	7	0	2	3	1735	0	9	9
0	6	0	1	1	151	0	22	22
0	6	0	1	2	1103	0	22	22
0	6	0	1	3	1685	0	22	22
0	6	0	2	1	1519	0	52	22
0	6	0	2	2	350	0	52	22
0	6	0	2	3	166	0	52	22
0	5	0	1	1	1058	0	28	28
0	5	0	1	2	1276	0	28	28
0	5	0	1	3	181	0	28	28
0	5	0	2	1	1289	0	37	33
0	5	0	2	2	1474	0	37	33
0	5	0	2	3	228	0	37	33
0	25	0	1	1	348	0	23	23
0	25	0	1	2	176	0	23	23
0	25	0	1	3	181	0	23	23
0	25	0	2	1	271	0	49	23
0	25	0	2	2	121	0	49	23
0	25	0	2	3	175	0	49	23
0	24	0	1	1	1058	0	19	19
0	24	0	1	2	811	0	19	19
0	24	0	1	3	1307	0	19	19
0	24	0	2	1	126	0	45	19
0	24	0	2	2	1103	0	45	19
0	24	0	2	3	131	0	45	19
0	23	0	1	1	350	0	11	11
0	23	0	1	2	237	0	11	11
0	23	0	1	3	238	0	11	11
0	23	0	2	1	809	0	28	11
0	23	0	2	2	1733	0	28	11
0	23	0	2	3	1276	0	28	11
0	22	0	1	1	1519	0	35	35
0	22	0	1	2	190	1	0	0
0	22	0	1	3	228	0	35	35
0	22	0	2	1	234	0	35	35
0	22	0	2	2	1735	0	35	35
0	22	0	2	3	173	0	35	35
0	21	0	1	1	1405	0	12	12
0	21	0	1	2	1289	0	12	12
0	21	0	1	3	1100	0	12	12
0	21	0	2	1	467	0	23	12
0	21	0	2	2	1685	0	23	12
0	21	0	2	3	157	0	23	12
0	13	0	1	1	350	0	14	14
0	13	0	1	2	1058	0	14	14
0	12	0	1	1	1103	0	31	31
0	12	0	1	2	125	0	31	31
0	12	0	1	3	181	0	31	31
0	12	0	2	1	571	0	52	31
0	12	0	2	2	1519	0	52	31
0	12	0	2	3	237	0	52	31
\.


--
-- Data for Name: color; Type: TABLE DATA; Schema: public; Owner: TacOps
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
-- Data for Name: display_component_effect; Type: TABLE DATA; Schema: public; Owner: TacOps
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
-- Data for Name: display_effect_option; Type: TABLE DATA; Schema: public; Owner: TacOps
--

COPY display_effect_option (effect_label, substate_label, component_label, keyframe_index, "key", value) FROM stdin;
\.


--
-- Data for Name: display_state; Type: TABLE DATA; Schema: public; Owner: TacOps
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
-- Data for Name: display_substate; Type: TABLE DATA; Schema: public; Owner: TacOps
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
-- Data for Name: display_type; Type: TABLE DATA; Schema: public; Owner: TacOps
--

COPY display_type (display_type_label, default_quality, default_fullscreen, description) FROM stdin;
main	0	t	This is the main display shown usually over the field.
pit	0	t	This is the pit display shown usually in the pit.
test	0	f	This is for testing only.
\.


--
-- Data for Name: event_preference; Type: TABLE DATA; Schema: public; Owner: TacOps
--

COPY event_preference (preference_key, value) FROM stdin;
\.


--
-- Data for Name: finals_alliance_partner; Type: TABLE DATA; Schema: public; Owner: TacOps
--

COPY finals_alliance_partner (finals_alliance_number, recruit_order, team_number) FROM stdin;
1	1	1519
2	1	121
1	2	1126
2	2	126
3	1	125
4	1	177
3	2	40
5	1	467
6	1	348
7	1	1733
8	1	271
9	1	190
10	1	88
11	1	1027
12	1	809
4	2	176
6	2	237
5	2	1100
7	2	1685
8	2	1103
9	2	234
10	2	228
11	2	175
12	2	571
13	1	1307
14	1	1276
15	1	1474
16	1	811
13	2	131
14	2	230
15	2	246
16	2	663
16	3	1735
15	3	562
14	3	166
13	3	350
12	3	1289
11	3	1058
10	3	1725
9	3	1405
8	3	181
7	3	173
6	3	1124
5	3	238
4	3	839
3	3	157
2	3	151
1	3	195
\.


--
-- Data for Name: game_match; Type: TABLE DATA; Schema: public; Owner: TacOps
--

COPY game_match (match_level, match_number, match_index, status_id, time_scheduled, winner_color_id) FROM stdin;
1	1	1	1	\N	0
1	1	2	1	\N	0
1	2	1	1	\N	0
1	2	2	1	\N	0
1	3	1	1	\N	0
1	3	2	1	\N	0
1	4	1	1	\N	0
1	4	2	1	\N	0
1	5	1	1	\N	0
1	5	2	1	\N	0
1	6	1	1	\N	0
1	6	2	1	\N	0
1	7	1	1	\N	0
1	7	2	1	\N	0
1	8	1	1	\N	0
1	8	2	1	\N	0
2	1	1	1	\N	0
2	1	2	1	\N	0
2	1	3	1	\N	0
2	2	1	1	\N	0
2	2	2	1	\N	0
2	2	3	1	\N	0
2	3	1	1	\N	0
2	3	2	1	\N	0
2	3	3	1	\N	0
2	4	1	1	\N	0
2	4	2	1	\N	0
2	4	3	1	\N	0
3	1	1	1	\N	0
3	1	2	1	\N	0
3	1	3	1	\N	0
3	2	1	1	\N	0
3	2	2	1	\N	0
3	2	3	1	\N	0
4	1	0	1	\N	0
4	2	0	1	\N	0
4	3	0	1	\N	0
0	1	0	4	2006-06-23 17:30:00	2
0	4	0	4	2006-06-23 17:48:00	2
0	3	0	4	2006-06-23 17:42:00	2
0	2	0	4	2006-06-23 17:36:00	2
0	25	0	4	2006-06-23 20:54:00	2
0	24	0	4	2006-06-23 20:48:00	2
0	23	0	4	2006-06-23 20:42:00	2
0	22	0	4	2006-06-23 20:36:00	0
0	21	0	4	2006-06-23 20:30:00	2
0	20	0	4	2006-06-23 20:24:00	1
0	19	0	4	2006-06-23 20:18:00	1
0	18	0	4	2006-06-23 20:12:00	2
0	17	0	4	2006-06-23 20:06:00	1
0	16	0	4	2006-06-23 20:00:00	2
0	15	0	4	2006-06-23 19:54:00	2
0	14	0	4	2006-06-23 19:48:00	2
0	13	0	4	2006-06-23 19:42:00	2
0	12	0	4	2006-06-23 19:36:00	2
0	11	0	4	2006-06-23 19:30:00	2
0	10	0	4	2006-06-23 18:24:00	1
0	9	0	4	2006-06-23 18:18:00	2
0	8	0	4	2006-06-23 18:12:00	2
0	7	0	4	2006-06-23 18:06:00	1
0	6	0	4	2006-06-23 18:00:00	2
0	5	0	4	2006-06-23 17:54:00	2
0	26	0	4	2006-06-24 08:45:00	1
0	27	0	4	2006-06-24 08:51:00	2
0	28	0	4	2006-06-24 08:57:00	2
0	29	0	4	2006-06-24 09:03:00	1
0	30	0	4	2006-06-24 09:09:00	1
0	31	0	4	2006-06-24 09:15:00	2
0	32	0	4	2006-06-24 09:21:00	1
0	33	0	4	2006-06-24 09:27:00	1
0	34	0	4	2006-06-24 09:33:00	1
0	35	0	4	2006-06-24 09:39:00	2
0	36	0	4	2006-06-24 09:45:00	1
0	37	0	4	2006-06-24 09:51:00	2
0	38	0	4	2006-06-24 09:57:00	2
0	40	0	4	2006-06-24 10:09:00	2
0	41	0	4	2006-06-24 10:15:00	1
0	43	0	4	2006-06-24 10:27:00	2
0	44	0	4	2006-06-24 10:33:00	2
0	45	0	4	2006-06-24 10:39:00	1
0	46	0	4	2006-06-24 10:45:00	2
0	47	0	4	2006-06-24 10:51:00	2
0	48	0	4	2006-06-24 10:57:00	2
0	49	0	4	2006-06-24 11:03:00	1
0	50	0	4	2006-06-24 11:09:00	2
0	51	0	4	2006-06-24 11:15:00	1
0	52	0	4	2006-06-24 11:21:00	2
0	53	0	4	2006-06-24 11:27:00	1
0	54	0	4	2006-06-24 11:33:00	1
0	39	0	4	2006-06-24 10:03:00	1
0	42	0	4	2006-06-24 10:21:00	2
\.


--
-- Data for Name: game_state; Type: TABLE DATA; Schema: public; Owner: TacOps
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
-- Data for Name: match_level; Type: TABLE DATA; Schema: public; Owner: TacOps
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
-- Data for Name: match_status; Type: TABLE DATA; Schema: public; Owner: TacOps
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
-- Data for Name: score_attribute; Type: TABLE DATA; Schema: public; Owner: TacOps
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
-- Data for Name: team; Type: TABLE DATA; Schema: public; Owner: TacOps
--

COPY team (team_number, info, short_name, nickname, robot_name, "location", rookie_year) FROM stdin;
1	DaimlerChrysler & Oakland School Technical Campus Northeast	DaimlerChryslerOSTCNE	The Juggernauts	Juggy	Pontiac, MI	1997
4	Boeing/JPL/LA Valley College/Milken Family Foundation/Roberts Tool Co. & HighTechHigh-LA	HTH-LA Robotics	Team ELEMENT	Fawkes the Phoenix	Lake Balboa, CA	2004
5	Daimler-Chrysler/FIRST Robotics/Ford FIRST Robotics/Independent Donor/ITT Tech & Melvindale High School	MHS / Ford Robocards	Robocards	Annihilator	Melvindale, MI	1998
7	Lockheed Martin/AAI Corporation & Parkville High School and Center for Mathematics, Science, and Computer Science	Team007	Team007	Golden Gear	Baltimore, MD	1997
8	North Santa Clara County ROP & Palo Alto High School	Paly Robotics	Paly Robotics	Ganginator	Palo Alto, CA	1996
9	Roosevelt High School	DANA Corp. & RHS	Roosevelt RoboRiders	Eleanor	Chicago, IL	1998
11	Mt. Olive Robotics Team	DPC,  Mt. Olive High	MORT	mort	Flanders, NJ	1997
16	Science and Technology Group & Mountain Home High School	Mtn. Home HS & STG	Bomb Squad	Two Minute Warning	Mountain Home, AR	1996
20	HostRocket.com/Rensselaer Polytechnic Institute/Advanced Manufacturing Techniques Inc. & Shenendehowa High School	Hostrocket RPI & Shen	The Rocketeers	"Team 20's Most Excellent Robot"	Clifton Park, NY	1992
21	ASRC/Boeing & Astronaut  & Titusville High School	ComBBAT Team 21	ComBBAT	Lucky	Titusville, FL	1998
22	Chatsworth High School	Chatsworth	Double Deuce	H.O.M.E.R. (Human Operated Mechanically Engineered Robot)	Chatsworth, CA	1997
25	Bristol-Myers Squibb & North Brunswick Twp. High School	BMS & NBTHS	Raider Robotix	Evil Machine 4- BINGO	North Brunswick, NJ	1997
27	ABB /American Axle & Manufacturing/Applied Manufacturing Technologies/Guardian Industries & Clarkston High School - OSMTech Academy	Clarkston OSMTech	Team RUSH	RUSH	Clarkston, MI	1997
28	PIERSON HIGH SCHOOL	Pierson HS	Mission Impossible	Mission Impossible	Sag Harbor, NY	1996
31	University of Tulsa & Jenks High School	U of Tulsa & Jenks HS	Prime Movers	Hector	Jenks, OK	1997
33	DaimlerChrysler & Notre Dame Preparatory	DmlrChry& NDP	Killer Bees	Buzz 11	Auburn Hills, MI	1996
34	Siemens VDO Automotive & Limestone County Technical Career Center	Rockets City Robotics	Rockets	Apollo III	Huntsville, AL	1997
38	Nonnewaug High School	Nonnewaug HS	Nonnebots	Geoffrey IX	Woodbury, CT	1998
39	America West Airlines Educational Grant/General Motors Desert Proving Grounds/Intel & Highland High School	Wings	The 39th Aero Squadron	Wings 1	Gilbert, AZ	1998
40	intelitek/BAE Systems & Trinity High School	Trinity High School	Pioneers	Checkmate	Manchester, NH	1998
41	Watchung Hills Regional High School	Watchung	Warriors	Chief Tommy Hawk	Warren, NJ	1997
42	Alvirne H.S.	DWC/AHS/SAVANT	P.A.R.T.S. (Precision Alvirne Robotics Team Systems)	P.A.R.T.S.	Hudson, NH	1995
45	Delphi/Ivy Tech Community College & Kokomo Center School Corporation	Delphi & Kokomo HS	TechnoKats Robotics Team	KatsKlaw	Kokomo, IN	1992
47	Delphi & Pontiac Central High School	Delphi&Pontiac Centra	Chief Delphi	CD 11	Pontiac, MI	1996
48	Delphi Corporation & Warren G. Harding High School	Delphi & Harding HS	Delphi E.L.I.T.E.	xtremachen9	Warren, OH	1998
49	Dow Chemical Company/Delphi Automotive Systems/Zimco/Sign Depot/ALRO Steel & Buena Vista High School	Dow & Buena Vista HS	Robotic Knights	Excalibur VIII	Saginaw, MI	1998
56	Ethicon & Bound Brook High School	Ethicon & Bound Brook	Robbe Xtreme	R.O.B.B.E.	Bound Brook, NJ	1997
57	ExxonMobil/Halliburton/Hydraquip/Powell Electric/Walter P. Moore & Booker T. Washington & High School for Engineering Professions	ExxonMobil&HSEP	Leopards	Big Cat 5	Houston, TX	1998
58	Fairchild Semiconductor & South Portland High School	Fairchild & S. Port.	Riot Crew	Sir Launch-A-Lot	South Portland, ME	1996
59	Miami Coral Park Sr. High School & MCPHS Engineering Magnet Program	RamTech59	RAMTECH	RT	Miami, FL	1997
60	Ford Motor Company/Laron Incorporated/Southwire/Westcoast Netting & Kingman High School	Ford, Southwire & KHS	Bionic Bulldogs	Bionic Bulldog	Kingman, AZ	1997
61	EMC/Raytheon Corp./Allegro Microsystem & Blackstone Valley Regional H.S.	Blackstone Valley H.S	Intimidators	Intimidator	Upton, MA	1995
63	GE--Transportation & McDowell High School	GE & McDowell High	The Red Barons	Red Baron	Erie, PA	1997
65	GM Powertrain & Pontiac Northern High School	GMPwrtrn&PontiacNorth	The Huskie Brigade	Powerdawg	Pontiac, MI	1997
66	General Motors Powertrain Corp & Willow Run High School	GM & Willow Run HS	The Flyers	Charlie	Ypsilanti, MI	1998
67	General Motors Milford Proving Ground & Huron Valley Schools	GM&HuronValleySchools	The HOT Team	HOTBOT	Milford, MI	1997
68	General Motors Engineering Structural Development Laboratories/ABB & Oakland County Area Schools	Truck Town Thunder	T3	Thunder	Pontiac, MI	1998
69	Gillette & Quincy Public Schools	Gillette & Quincy PS	Team HYPER (Helping Youth Pursue Engineering and Robotics)	HYPERdrive	Quincy, MA	1998
70	General Motors/Daimlerchrysler/Textron/NASA/Kettering University & Goodrich High School	More Martians	More Martians	My Other Favorite Robot	Goodrich, MI	1998
71	Beatty International/City of Hammond/PEPSI Americas & School City of Hammond	Team Hammond	Team Hammond	The Beast	Hammond, IN	1996
74	Haworth Inc./Magna Donnelly & Holland High School	Haworth/MagnaDon,HHS	Holland Dutch		Holland, MI	1995
75	J&J  Consumer and Personal Products Worldwide & Hillsborough High School	J&J/Hillsborough HS	RoboRaiders	Rebel Raider	Hillsborough, NJ	1996
79	Honeywell Inc & East Lake High School	Honeywell & ELHS	Team Krunch	Captain Krunch	Clearwater, FL	1998
81	Honeywell/Textron  & Freeport High School/Lena Winslow High School	The MetalHeads	MetalHeads	Double Vision	Freeport, IL	1994
84	DuPont & Athens Area School District & Northeast Bradford School District & Towanda Area School District & Troy Area School District	DuPont & Towanda	Chuck 84	Chuck	Towanda, PA	1998
85	Gentex/Herman Miller Foundation/ITW/Drawform/Mead/Johnson Nutritionals/Midway Machine Techlologies/Plascore/TNT/Holland Motor Freight/Town & Country Group/Trans-matic & Zeeland West High School & Zeeland East High School	BOB	B.O.B. (Built on Brains)	B.O.B.	Zeeland, MI	1996
86	JEA/Johnson & Johnson VISTAKON & Stanton College Preparatory School	Team Resistance	Team Resistance	OHMER	Jacksonville, FL	1998
87	Lockheed Martin & Rancocas Valley Regional High School	RVR & Lockheed Martin	Red Devils	Diablo	Mount Holly, NJ	1997
88	DePuy, Codman, DePuy Spine-Johnson & Johnson Companies & Bridgewater Raynam Regional High School	DePuy / BRRHS	TJ(Squared)	TJ(Squared)	Bridgewater, MA	1996
93	NASA/Plexus Corporation & Appleton Area School District	Plexus & Appleton HS	N.E.W. Apple Corps	Tobor 10	Appleton, WI	1997
94	Lear Corporation & Southfield High School	Lear/Southfield High	TechnoJays	"T.J."	Southfield, MI	1998
95	Whitman Communications, Inc/New Hampshire Industries/NH Charitable Foundation, Upper Valley Region/The Byrne Foundation /Dartmouth Hitchcock Medical Center/Chicago Soft, Ltd/Geokon, Inc/Hypertherm, Inc. /Pathways Consulting/Fluent, Inc & Lebanon, Hanover	Upper Valley Robotic	The Grasshoppers	Lilly	Lebanon, NH	1997
96	PUTNAM VOCATIONAL	Springfield Public	JESTERS	Maniac	Springfield, MA	1997
97	Cambridge Rindge and Latin	Terdyne/MIT/CHS&CRLS	RoboRuminants	Hugeness	Cambridge, MA	1996
100	SLAC & Woodside & Carlmont High School	WHS&CHS Robotics	The Wildcats		Woodside, CA	1998
101	Saint Patrick High School	Saint Patrick	Striker	STRIKER	Chicago, IL	1997
102	Ortho Clinical Diagnostics/Verizon Wireless & Somerville High School	Somerville HS	The Dexterous Gearheads	Captain Hook	Somerville, NJ	1998
103	Amplifier-Research/Beckman Coulter/Lutron Electronics, Inc/BAE Systems/Custom Finishers/Day Tool/Harro Hoflinger/Glen Magnetics/LRIG/Pathology Group of Doylestown & Palisades High School	AR/Lutron/CF/BAE	Cybersonics	Monkey Business	Kintnersville, PA	1997
104	WCASD - East High School & WCASD - Henderson High School	MEI & WCASD	Team Universal	XLR8	West Chester, PA	1998
107	Metal Flow Corp. & Holland Christian High School	MFC & HCHS	Team R.O.B.O.T.I.C.S.	The Phent	Holland, MI	1997
108	Motorola, Inc & Dilliard High School	Motorola&Dllrd&Tarvla	SigmaC@T	SigmaC@T 2004	Ft. Lauderdale, FL	1995
111	Motorola & Rolling Meadows High School & Wheeling High School	Motorola & RMHS/WHS	WildStang	WildStang	Schaumburg, IL	1996
114	AA Precision Manufacturing/San Jose City College/Applied Welding Technology/Intuitive Surgical/Advanced Laser & Waterjet Cutting/SONY/Friedmann Electric/Stanford Univ. & Los Altos High School	Los Altos Robotics	Eagle Strike	TBA	Los Altos, CA	1997
115	Lockheed Martin/Monster Cable & Monta Vista High School	Monta Vista Robotics	MVRT	El Toro IX	Cupertino, CA	1998
116	NASA Headquarters/SAIC & Herndon High School	NASA Hq & Herndon HS	Epsilon Delta	ED v7.0	Herndon, VA	1996
117	Heinz Endowments/ITT Technical Institute/University of Pittsburgh School of Engineering	Steel Dragons	The Steel Dragons	#117 Steel Dragons	Pittsburgh, PA	1998
118	NASA-JSC & Clear Creek ISD	NASA-JSC & CCISD	Robonauts	Chainzilla (2005)	League City, TX	1997
120	MBNA/Ford/Jennings Foundation/Gund Foundation/Rockwell Automation/Battelle/NASA Glenn Research Center & East Technical High School	Scarabian Knights	Scarabian Knights	SCRB	Cleveland, OH	1995
121	NAVSEA Undersea Warfare Center/University of Rhode Island & Middletown HS & Mount Hops HS & Portsmouth HS & Tiverton HS	Rhode Warriors/NUWC	Rhode Warriors	Rhode Warrior	Newport County, RI	1996
122	ASME/Jefferson Labs/NASA Langley Research Center/Thomas Nelson Community College & New Horizons Regional Education Center	Nasa/NewHorizons	NASA Knights	Excalibur	Hampton, VA	1997
123	General Motors/Cadence Innovation/Coffey Machining Services/ITT Tech/Ford & Hamtramck High School	Hamtramck High	Team - Cosmos	CosmoBot	Hamtramck, MI	1997
125	Northeastern University/Textron Systems & Boston Latin School & Brookline High School & Winthrop High School	NU-TRONS	NU-TRONS	Sweet Caroline	Boston, MA	1998
126	Nypro Inc. & Clinton High School	NYPRO & Clinton HS	Gael Force	Gael Force	Clinton, MA	1992
128	American Electric Power/AEC CADCON, Inc. & Grandview Heights High School	AEP/AECCADCON&GHHS	The Botcats	MOMMAJACK DOS	Columbus, OH	1997
131	BAE SYSTEMS/Rockwell Automation/University of New Hampshire & Central High School	BAE/Rockwell &Central	C.H.A.O.S.	CHAOS X I I	Manchester, NH	1995
133	EAGLE INDUSTRIES INC. & BONNY EAGLE HIGH SCHOOL	EAGLE IND & BEHS	B.E.R.T	BERT	Standish, ME	1997
134	BAE Systems & Pembroke Academy	Team Discovery	Team Discovery	X Bot	Pembroke, NH	1997
135	Power Lift/Patrick Metals/General Motors/BOSCH/AM General/PHM Community & Penn Robotics	PHM/Power Lift	Penn Robotics	The Black Knight	Mishawaka, IN	1998
136	National Starch & Chemical Company & Plainfield High	J&J,Nat'lStrch&PlfdHS	Killer Kardinals	Ekirt	Plainfield, NJ	1997
138	Monarch Instrument/BAE Systems & Souhegan High School	Souhegan/Monarch/BAE/	Entropy	Hummer II	Amherst, NH	1996
141	JR Automation Technologies, Inc. & West Ottawa High School	JR Automation & WOHS	WO-BOT	WO-BOT	Holland, MI	1995
145	P&GP/TBDI, Inc./Norwich Glass & Norwich HS & Unidilla Valley HS & DCMO BOCES & Sherburne-Earlville HS	P&G & Norwich HS	T-Rx	Rex	Norwich, NY	1997
148	L-3 Communications Integrated Systems & Greenville High School	L3 IS & Greenville HS	Robowranglers	Lone Star	Greenville, TX	1995
151	BAE & Nashua High School	BAE SYSTEMS&Nashua HS	Tough Techs	This space for rent	Nashua, NH	1995
155	Altuglas International / Arkema Group/Mechtron LLC & Berlin High School & C.M. McGee Middle School & New Britain High School	Berlin FIRST	The Technonuts	Nutty VII	Berlin, CT	1994
157	EMC/Intel/Raytheon & Assabet Valley Regional Technical HS	AZTECHS Team 157	AZTECHS 157	AZTECH VI	Marlborough, MA	1995
158	Solid Edge - EDS & Great Oaks	SolidEdge & Grt Oaks	The Cobras	Spitfire	Milford, OH	1996
159	LSI Logic & Poudre High School	Alpine Robotics	Alpine Robotics	Assembly 100	Fort Collins, CO	1998
165	US Naval Academy & Broadneck High School & Severn School & St. Mary's School	USNA/NAVSEA	Das Goat	Das Goat	Annapolis, MD	1998
166	BAE Systems & Merrimack High School	BAE & Merrimack HS	Chop Shop	Tommy Hawk V	Merrimack, NH	1995
167	Rockwell Collins  & City High School & West High School	RoboHawks	Children of the Corn	Herky	Iowa City, IA	1998
168	Cordis Corporation & North Miami Beach Senior High	The Flashbacks	The Flashbacks	sd6	North Miami Beach, FL	1998
171	UW-Platteville & Area Schools	UWP & Area Schools	Hard Core Engineers	"Z"	Platteville, WI	1995
172	IDEXX Laboratories/Lanco Assembly Systems & Falmouth High School & Gorham High School	Northern Force #172	Northern Force	FalGor	Gorham/Falmouth, ME	1996
173	CNC Software/JP Fabrications/Nerac, Inc./United Technologies Research Center & East Hartford High School & Rockville High School & Tolland High School	UTRC,EHHS,RHS,&THS	R.A.G.E. (Robotics & Gadget Engineering)	BullDog	East Hartford, CT	1995
174	UTC Carrier & Arctic Warriors	Liverpool HS	Arctic Warriors	The Big Chill II	Liverpool, NY	1998
175	UTC Hamilton Sundstrand Space, Land & Sea & Enrico Fermi High School	UTC/HamSund & FermiHS	Buzz Robotics	Buzz XI	Enfield, CT	1996
176	UTC Hamilton Sundstrand & Suffield High School & Windsor Locks High School	UTC/HamSund WL & Suff	Aces High	Pokerface	Windsor Locks, CT	1996
177	UTC Fuel Cells & South Windsor High School	UTCFC & S. Windsor HS	Bobcat Robotics	The Bobcat	South Windsor, CT	1995
178	UTC Otis Elevator/ebm-papst Inc./GE Consumer & Industrial/UTC Sikorsky & Farmington High School	Otis/ebmpapst/GE/FHS	2nd Law Enforcers	The Scruffy-Looking Nerf Herder	Farmington, CT	1997
179	United Technologies/EDF/Pratt & Whitney & Inlet Grove High School & Suncoast High School	UTC/PW,EDF & IGHS	The Children of the Swamp	Swampthing	Riviera Beach, FL	1998
180	UTC/Pratt & Whitney LSP/ & Manufacturers Round Table & South Fork High School & Martin County High School & Jensen Beach High School & Clark Advanced Learning Center	UTC/Pratt&Whitney LSP	S.P.A.M.	S.A.M. (Surface to AIr Meat)	Stuart, FL	1998
181	Pratt & Whitney/United Technologies & Hartford Public Schools	UTC-PrtWht&Hartford	Birds Of Prey	Birds Of Prey	Hartford, CT	1998
184	Ford Motor Company & Fordson High School	Ford & Fordson HS	F.R.E.D.	FRED	Dearborn, MI	1998
188	Scotiabank/Bell Canada/Toronto District School Board & Woburn Collegiate Institute	Woburn Robotics	Blizzard	Blizzard 7	Toronto, ON	1998
190	WPI & Massachusetts Academy of Math and Science	WPI & Mass Academy	Gompei and the H.E.R.D.	Gompei	Worcester, MA	1992
191	Xerox Corporation & Joseph C. Wilson Magnet High School	Xerox / Wilson X-CATS	The X-Cats	XO-X-CAT	Rochester, NY	1992
192	Gunn High School	Gunn Robotics Team	GRT	G-Force	Palo Alto, CA	1997
195	Smiths Medical & Southington High School	Smiths/Southington HS	Cyber Knights	Knightmare	Southington, CT	1998
201	GM & Rochester High School	GM R&D & RHS	The FEDS	The Banshee	Rochester Hills, MI	1998
203	Campbell's Soup & Camden County Technical Schools	Campbell Soup & CCTS	One TUFF Team (Team United for FIRST)	Rocky	Sicklerville, NJ	1998
204	Eastern Regional High School Board of Education /Eastern Educational Foundation/Exxon Mobil/AAA South Jersey/Thomas Builders/Dewey's Dry Cleaners/Echo Pizza & Eastern Camden County Regional High School	E.R.V.	Eastern Robotic Vikings	Ondi	Voorhees, NJ	1998
207	Walt Disney Imagineering & Centinela Valley Union High School District	METALCRAFTERS	METALCRAFTERS	El Toro Azul	Hawthorne, CA	1999
211	Marshall And Kodak	Marshall & Kodak	MAK	Super MAK	Rochester, NY	1999
213	KHS First Robotics Club	KHS Dirty Birds	The Dirty Birds	DB2K6- the new breed	Keene, NH	1999
217	Ford Motor Company/FANUC Robotics Inc./B&K Corporation & Utica Community Schools	Ford/FANUC/B&K & UCS	The ThunderChickens	Thor 2	Sterling Heights, MI	1999
219	Warren Hills Regional High School	Warren Hills Reg HS	Team Impact	C-4	Washington, NJ	1999
222	Tunkhannock Area High School	Ronco/P&G&Tnkhnnck	Tigertrons	The CLAW	Tunkhannock, PA	1999
223	Johnson & Johnson/State Electric & Piscataway Vo-Tech	j&jselectconsmcvt	Xtreme Heat	xtreme heat	Piscataway, NJ	1999
224	PSGA (A Div. of J&J) & Piscataway HS	PHS/PSGA	The Tribe	The Chief	Piscataway, NJ	1999
225	School District of the City of York/NASA GSFC/Harley-Davidson of York/Legg Mason-Funds/Siemens Building Technologies/Cabin Fever Expo & William Penn High School & William F Goodling Regional Advanced Skills Center	William Penn HS	York High Bearcats	BEAR-O-Metric	York, PA	1999
226	GM CCRW & Troy School District	GM-CCRW &Troy Schools	TEC CReW Hammerheads	Hammerhead 8	Troy, MI	1999
228	Bristol-Myers Squibb & Maloney High School & Platt High School & Wilcox Technical High School	BMS&GUS	Team "Gus"	Gus	Meriden, CT	1999
229	Division by Zero - Clarkson SPEED Program & Massena Central High School & Salmon River High School	Clrksn/Mssna/SlmRvr	Division By Zero	Irrational	Potsdam, NY	1999
230	Pitney Bowes/Unilever/UTC Sikorsky & Shelton High School	UTC/PBowes/ULVR & SHS	Gaelhawks	Talon	Shelton, CT	1999
231	United Space Alliance & Pasadena ISD	Sunoco/Oceaneering	High Voltage	Roboticus	Pasadena, TX	1998
233	NASA @Kennedy Space Center & Cocoa Beach High School & Rockledge High School	The Pink Team	The Pink Team	Roccobot	Rockledge/Cocoa Beach, FL	1999
234	Allison Transmission/Rolls-Royce/and 74 Proud Grandmas & Perry Meridian High School	Team Cyber Blue	Cyber Blue	Falcon VI	Indianapolis, IN	1999
236	Dominion Millstone Power Station & Lyme-Old Lyme High School	Millstone/LOLHS	Techno-Ticks	Tick Tank	Old Lyme, CT	1999
237	Siemon Company/Plasti-Coat Corp. & Watertown High School	Sie-H2O-Bots Siehobot	T.R.I.B.E.	P.A.L. (Professionally Automated Landrover)	Watertown, CT	1999
238	BAE Systems/Texas Instruments & Manchester Memorial High School	MMHS	Cruisin Crusaders	BAE-TI	Manchester, NH	1999
240	Jefferson High School Robotics	Jefferson High School	Tempest		Monroe, MI	1999
241	BAE/Fireye & Pinkerton Academy	Astros	Astros	Astro	Derry, NH	1999
245	Siemens VDO Automotive /GM Finance Staff & Rochester Adams High School	Siemens/GM & Adams HS	Adambots	???	Rochester Hills, MI	1999
246	Boston University & Boston University Academy	Boston University	Overclocked	RoboRhett	Boston, MA	1999
247	Comau Pico/Ford Motor Company/Terminal Supply & Berkley High School	CP/TS/Ford/BHS	Da Bears	Bearfoot 8	Berkley, MI	1999
250	GE /Knolls Atomic Power Laboratory, Inc/Rensselaer Polytechnic Institute/Verizon & Colonie Central High School	GE Verizon & Colonie	Dynamos	Glen	Colonie, NY	1999
253	DeVincenzi Metal Products/Fairchild Semiconductor & Mills High School	Fairchild/DMP&MillsHS	MRT	Twopointo	Millbrae, CA	1999
254	EA Machining inc./NASA Ames & Bellarmine College Prep	NASA Ames Robotics	Cheesy Poofs	Black Knight	San Jose, CA	1999
256	Willow Glen Foundation & Willow Glen High School	Willow Glen High	Rams	Popcorn II	San Jose, CA	1999
269	Quest Technologies/GE Healthcare & Oconomowoc High School	Quest/GE/MSI &OHS	Cooney Quest	Annie Oakley	Oconomowoc, WI	1999
270	ULC Robotics & Deer Park High School	DPHS Falcon-X	Falcons	Falcon-X	Deer Park, NY	1999
271	Bad Boys  Of Bay Shore/BAE Systems/Verizion & Bay Shore High School	Bad Boys/Bay Shore HS	Mechanical Marauders	Momentum Marauder	Bay Shore, NY	1999
272	Visteon Automotive Systems/TPS Golf -- AimPoint Technologies/Montgomery County Community College/United Auto Workers & Lansdale Catholic High School	Visteon/TPS/MCCC&LCHS	Cyber-Crusaders	Horsepower	Lansdale, PA	1999
276	Youngstown State University/Star Supply & Chaney Robotics Team	YSU Youngstown CHS	Mad Cow Engineers	Mad Cow	Youngstown, OH	1999
279	Dana Corporation & Toledo Public Schools	Dana & Toledo Public	Tech Fusion	Gemini	Ottawa Lake, MI	1999
280	Ford Motor Comapny/ITT Technical Institute & Taylor Career Center & Kennedy H.S. & Truman H.S.	Ford &Taylor Schools	TNT	Dyna	Taylor, MI	1999
281	Michelin/Greenville Tech & 4-H & GTCHS & Christ Church Episcipal & JL Mann & Southside	Michelin/4H/GTC	EnTech	E.T.	Greenville, SC	1999
284	Elk Lake HS & SCCTC	Elk Lake/SCCTC	The Crew	The Raptor	Dimock, PA	1999
287	Brookhaven National Lab & William Floyd HS	BNL/Battelle/Wm.Floyd	Floyd	Floyd	Mastic Beach, NY	1999
288	General Motivation/Roman Manufacturing/H.S. Die & Engineering/Wolverine Building General Contractors/Compucraft & Grandville Public Schools & Byron Center Public Schools	The RoboDawgs	The RoboDawgs	RD8	Grandville, MI	1999
291	GE - Transportation & Erie School District & Villa Maria Academy	GE/Erie Schools/Villa	CIA - Creativity In Action	Ultraviolet Impulse	Erie, PA	1999
292	DaimlerChrysler/Delphi & Western High School	DaimlerWesternDelphi	PantherTech	Sgt. Joe	Russiaville, IN	1999
293	Hopewell Valley Central High School	BMS & HVCHS	Team S.P.I.K.E.	SPIKE	Pennington, NJ	1999
294	Northrop Grumman & Mira Costa High School & Redondo Union High School	Beach Cities Robotics	Beach Cities Robotics	RipTide	Redondo Beach, CA	1999
295	Granite Bay	G.B.H.S. Robotics	Flying Penguins	Yohan Explosion...The Return	Granite Bay, CA	1999
296	Arial Foundation/Nortel Networks & Loyola High School	Arial/Nortel&Loyola H	Northern Knights		Montreal, QC	1999
300	West Philadelphia High School - Academy for Automotive and Mechanical Engineering	AAME	AAME	Ghetto bot v. 3.0	Philadelphia, PA	1999
302	DailmerChrysler Corp. & Lake Orion High School	Team 302	The Dragons	The Mechanical Dragon	Lake Orion, MI	1999
303	Bihler of America & Bridgewater Raritan Regional High School & The Midland School	Bihler/Mid & Brdgwate	Panther Robotics		North Branch, NJ	1999
304	Airline Hydraulics & George Washington High School & School District of Philadelphia	Robo Griffins	GWHS Robo Griffins	RoboGriff	Philadelphia, PA	1999
306	Corry Industrial Roundtable/Corry Contract Inc/Corry Lumber Co./Corry Rubber Corp./D&E Machining Inc. /Fralo Industries Inc./Rossbacher Insurance Service/State Farm Insurance/Tonnard Mfg. Corp./Viking Plastics Inc. & Corry Area High School	Corry Robotics Team	CRT	Not-So-Cattywampus	Corry, PA	1999
308	TRW & Walled Lake Schools	TRW&Walled Lake	The Monsters	Audrey 7	Farmington Hills, MI	1999
312	Baxter Healthcare of Tampa Bay & Lakewood High School	Baxter/Lkwd HS	HeatWave	Fire Starter 6	St. Petersburg, FL	1999
313	Ford Motor Company/ITT Technical Institute & Wayne-Westland Schools	WayneWestland Robotic	The Bionic Union	Sarbez6	Wayne, MI	1999
314	Delphi/GM Manufacturing/NEW TECHNOLOGIES/PENTECH & Carman-Ainsworth High School	GM/Carman HS	The Megatron Oracles	Big MO	Flint, MI	1999
316	Salem County Community College & Salem County 2000	PSEG/Dupont/SCC	LuNaTeCs	SAM	Carneys Point, NJ	1999
319	Prospect Mountain High School	Bobotics #319 ACS	Big Bad Bob	Highway Bob	Alton, NH	1999
321	Drexel University/Community College of Philadelphia & Central High School	Central High&Drexel U	RoboLancers	Cerberus	Philadelphia, PA	1999
322	General Motors Powertrain/Landaal Packaging/University of Michigan - Flint & Flint Community Schools & GEAR-UP	GMPT/ UofM/ Flint HS	Team F.I.R.E.	Fire Hazard	Flint, MI	1999
326	GM Powertrain & Romulus Community Schools	GM&RomulusHS	Xtreme Eagles		Romulus, MI	1999
329	Nortel Networks & Patchogue Medford High School	Pat-Med Robotics	P-Town Pirates		Medford, NY	1999
330	J&F Machine/NASA-JPL/NASA-Goddard/Raytheon & Hope Chapel Academy	BeachBots	BeachBots	BeachBot V	Hermosa Beach, CA	1999
331	Consolidated Edison & Washington Irving HS	Con Ed/WIHS/HSES	The Bulldogs	Where's Ed?	New York, NY	1999
333	Judy & Josh Weston/Credit Suisse/DHACNY/Cool Jewels/D & L Entertainment/Ballon Depot/East Coast Appraisal & Canarsie HS & John Dewey H S	CAN-DEW	Robot Chiefs - CAN-DEW	The Robo Chief	Brooklyn, NY	1999
334	Brooklyn Tech. Alumni Assoc./ConEd/SIAC & Brooklyn Tech. H.S.	Tech./SIAC	Techengineers	Tech. Taxi	Brooklyn, NY	1999
335	Con Edison/Dan & Mike Dubno/City Tech/Polytech & Science Skills Center HS	Skillz Tech	Skillz Tech	Little Red Robot	Brooklyn, NY	1999
337	American Electric Power & Logan County Schools & Ralph R Willis Career & Technical Center	AEP/Coal/RWC&TC/LCS	STAR-bots	STAR-bot	Logan, WV	2000
339	New World Associates/Tate, Inc./Battelle Memorial Institute/Stafford County Economic Development Authority & Commonwealth Governor's School	CGS-NWA-Tate-StfrdEDA	Rappahannock Robotics	Kilroy	Stafford, VA	2000
340	Bausch&Lomb & Churchville-Chili High School	Bausch & Lomb & CCHS	G.R.R. (Greater Rochester Robotics)	Tigrr 5	Churchville, NY	2000
341	BAE Systems/DeVry University/Johnson & Johnson PRD/Rohm & Haas Company/Siemens Corporation & Wissahickon High School	RH/BAE/JnJ/SEA/DU/WHS	Miss Daisy	Miss Daisy	Ambler, PA	2000
342	Bosch ATMO/Bosch Rexroth/Dorchester County Council/Nelson, Mullians, Riley & Scarborough/Robert Bosch Corporation/Trident Technical College & Dorchester County Career School & Fort Dorchester High School & Summerville High School & Woodland High School	SHS/FDHS/WHS/TTC	Burning Magnetos	Burnie	North Charleston, SC	2000
343	F.P Hamilton Career Center	Metal-In-Motion	Metal-In-Motion	"DR" Doug Robert	Seneca, SC	2000
345	Ford &  NORSTAR	Ford/NTVC/NORSTAR	NORSTAR	blarg	Norfolk, VA	2000
346	Alstom Power & Lloyd C. Bird Pre-Engineering Progam	LC Bird High School	RoboHawks	Skybot	Chesterfield, VA	2000
348	Mass Bay Engineering/PIAB & Norwell High School	PIAB,MBE & Norwell HS	Norwell Robotics	Hermanator	Norwell, MA	2000
350	Analog/Raytheon & Timberlane Regional High School	Timberlane Reg HS	Timberlane Robotics		Plaistow, NH	2000
352	Carle Place Educational Foundation & Carle Place High School	Carle Place H.S.	The Green Machine	The Green Machine	Carle Place, NY	2000
353	Trio Hardware & Plainview-Old Bethpage CSD	POBCSD/TRIO POBOTS	POBOTS	ROBOHAWK 3	Plainview, NY	2000
354	Bloomberg LP/Polytechnical University/Verizon Corporation & George Westinghouse High School	Verizon&GWestinghouse	Pirates	Black Pearl	Brooklyn, NY	2000
357	ITT Technical Institute/PECO Exelon & Upper Darby High School	Upper Darby HS	Royal Assault	Jester	Drexel Hill, PA	2000
358	Festo & Hauppauge H.S.	Festo/Hauppauge H.S.	Robotic Eagles	Raul	Hauppauge, NY	2000
359	NAVSEA Detachment Pacific/Castle & Cooke, Inc./Dole Plantation/McInerny Foundation/R.M. Towill Corp./Mililani Wal-Mart/Matsumoto Shave Ice & Waialua Complex 21st CCLC Grant & Waialua High School	Na Keiki O Ka Wa Hope	Hawaiian Kids	Poi Pounder VI	Waialua, HI	2000
360	Nissan of Fife & Bellarmine Prep	Bellarmine Prep	The Revolution	Rainmaker V	Tacoma, WA	2000
362	American Elements/Northrop Grumman/Raytheon/Gensler & The Archer School for Girls	Raytheon/Archer	The Muses		Los Angeles, CA	2000
364	NASA Stennis Space Center/SAIC/Seemann Composites/DuPont Delisle/Knesal Engineering Services, INC./Houston Robotics & Gulfport High School Technology Center	Team Fusion	Team Fusion	Arm-a-gettin' "The Ascender"	Gulfport, MS	2000
365	First State Robotics/DuPont Engineering/Anholt Technologies, Inc. & MOE Robotics Group	DuPont Engr MOE	Miracle Workerz	MOE	Wilmington, DE	2000
368	NASA Ames Research Center/HECO/SUMMA Technology, Inc. & McKinley High School	NASA/HECO McKinley	Kika Mana	Nai'a IV	Honolulu, HI	2000
369	BEZOS Foundation & William E. Grady High School	Grady Tech	Nuts and Volts	RoboBob	Brooklyn, NY	2000
371	Port Authority of New York and New Jersey/Con Edison/Verizon/RGBS Enterprises/Pyramid Paving, INC./Plumbers Local Union #1 & Curtis High School	PANYNJ, CE &CHS	Cyber Warriors	Fulvio	Staten Island, NY	2000
372	Electroimpact & Kamiak High School	Kamiak	The Fine Line	Mr. Roboto	Mukilteo, WA	2000
375	Verizon/Con Edison & Staten Island Technical High School	SI Tech	Robotic Plague	RAMBO	Staten Island, NY	2000
378	Delphi Thermal/UAW 686 & Newfane High School	Delphi/UAW/Newfane HS	The Circuit Stompers!		Newfane, NY	2000
379	Girard High School	Girard High School	Robocats	Cat 7	Girard, OH	2000
380	Con Edison	Gompers	G-FORCE	Panther I	Bronx, NY	2000
381	Bristol Myers Squibb & Trenton Central High School	Trenton/BMS	Tornadoes	Spider Bot	Trenton, NJ	2000
382	American Electric Power/Batelle/Columbus State Community College & Eastmoor Academy High School	ColumbusPublicSchools	Twisted Blizzard	Tux	Columbus, OH	2000
383	Provincia de Sao Pedro HS	Brazilian Machine	Brazilian Machine	Brazilian Buddy VII	Porto Alegre, RS	2000
384	GE Healthcare/Infineon Technologies of Richmond/ShowBest Fixture Corp./Specialty's Our Name/ChemTreat/Seimens Technologies  & Tucker High School	GEHC/INF/SBFC/SON/JRT	Sparky 384	Sparky 7	Richmond, VA	2000
386	Harris Corp/Intersil/bd Systems/DRS/Compass Solutions & Melbourne HS & Allendale Academy & Cocoa Beach HS & Brevard Christian School   & Eau Gallie HS & Melbourne Central Catholic HS & New Covenant Christian School   & Palm Bay HS & Satellite HS & West Sh	Voltage/Harris	TeamVoltage	Ty-Rap VI	Palm Bay, FL	2000
388	Grundy High School	Grundy HS	Maximum Oz	Oz 3.0	Grundy, VA	2000
393	Rolls-Royce Corp./BAX Global/K-T Corp. & Morristown High School & Greenfield-Central High School	Full Metal Jackets	Full Metal Jackets	Tina	Morristown, IN	2000
395	The McGraw-Hill Companies & Morris High School Campus  & Fieldston	McGraw/&Morris HS	2 TrainRobotics	The Spicy	Bronx, NY	2000
397	Delphi /Unigraphics & Flint Southwestern Academy & Bendle High School	Delphi/UG/FSWA/Bendle	Knight Riders	K.I.T.	Flint, MI	2000
398	Metaldyne & Ridgway Area High School	METALDYNE&RHS	The Thundering Herd	"Explative Deleted"	Ridgway, PA	2000
399	HR Textron/Nothrop Grumman/Lockheed/Martin/ITEA/NASA Dryden Flight Research & Antelope Valley Union High School District & Lancaster High School	NASA/Lancaster HS	Eagle Robotics	TnT	Lancaster, CA	2000
401	Virginia Tech School of Education & Montgomery County Public Schools	VT/MCPS	Hokie Guard	Moss-Covered, Three-Handled, Family Gredunza	Christiansburg, VA	2000
405	Infineon Technologies/National Society of Black Engineers & Richmond Community High School	Infineon& RCHS	The Chameleons	Chameleon	Richmond, VA	2000
406	Mumford Magnums DCX Mack Ave. & Mumford High School	Mumford/DCX Mack Ave.	Mumford Magnums	THEE MAGNUM	Detroit, MI	2000
414	Hermitage Technical Center	Hermitage Tech Center	Smokie	Smokie	Richmond, VA	2000
415	Robert Bosch Corporation/Tri-County Technical College & Hanna High School & Hanna-Westside Extension campus & Westside High	Team Bosch	Team Bosch - The Electric City Screaming Eagles	Mephisto	Anderson, SC	2000
416	GE College Bound Program & Armstrong High School	GE College Bound	Regs	J.C. 105	Richmond, VA	2000
417	AST/Frey Family Foundation & Mount Sinai High School	Mt. Sinai	Stangbot	Mount Sinai Stangbot	Mt. Sinai, NY	2000
418	LASA Robotics Association/National Instruments & Liberal Arts & Science Academy of Austin	LASA	Purple Haze	Mary PHender	Austin, TX	2000
421	Electrical Union/Argosy Foundation/Automated Data Processing/Iron Workers/Plumbers Union & Alfred E. Smith H.S.	Smith Warriors	The Warriors	INTREPID	Bronx, NY	2000
422	Dupont Advanced Fiber Systems/New Market Corporation/United Control Co. & Maggie L. Walker Governor's School	MLWGS MechTechs	The MechTechs	Phoenix v3.14	Richmond, VA	2000
423	Cheltenham High School & Eastern Center for Arts & Technology & Springfield High School	Mechanical Mayhem	SEC	Quincy	Willow Grove, PA	2000
433	McNeil Consumer and Specialty Pharmaceuticals & Mount St. Joseph Academy	McNeil-MSJA Firebirds	Firebirds	OGYA (FantI for "FIRE")	Flourtown, PA	2000
434	Fluor/Houston Robotics & Fort Bend ISD	HHSFBISD	The STORM	Stormbot	Missouri City, TX	2000
435	NCSU College of Engineering/Hunter Industries Inc./EMC-DG/Black & Decker & Southeast Raleigh Magnet High School	SRMHS Robodogs	Robodogs	RoboDog	Raleigh, NC	2000
437	DeVry University & Richardson High School	RHS Robotics	The Eagles	Pegasus 4	Richardson, TX	2000
440	Ford Motor Company/NASA/R.L.Schmitt Co. Inc & Redford HS & Cody HS	FMC/Cody & Redford HS	The Suspects	R2C2	Detroit, MI	2000
441	ASME-International Petroleum Technology Institute/Houston Robotics & Reagan High School	DEVIL DOGS	DEVIL DOGS	Thor II	Houston, TX	2000
442	Alabama A & M University & Lee High School	Lee High School	LeeGeneers		Huntsville, AL	2000
444	Lockheed Martin M&DS & MASTBAUM A.V.T.S. PANTHERS	MASTBAUM	Philly's Extreme Team		Philadelphia, PA	2000
447	Remy International/Xtreme Alternative Defense Systems/DRN Machine/Vectren Foundation/Ivy Tech Community College & Ebbertt Education Center & Anderson Community School Corporation	MadCo Partnership	Team Roboto	Mr. Roboto	Anderson, IN	2000
448	Cranbrook Kingswood School	Cranbrook	Crandroids	Johnny Botten	Bloomfield Hills, MI	2000
449	Montgomery Blair High School	Blair Robot Project	Wrenchman	Wrench Man's Ride	Silver Spring, MD	2000
451	Dana Corporation & Sylvania City Schools	DANA/The Cat Attack	The Cat Attack	Darkside	Sylvania, OH	2000
453	Paragon Technologies & L'Anse Creuse - Pankow Center	Paragon Tech & Pankow	The Sprockets	Scoopy Do	Clinton Township, MI	2000
456	NASA/Magnolia Metal and Plastic & Vicksburg-Warren Schools	Warren Central Viking	Vikings	Possum squasher	Vicksburg, MS	2000
457	SAIC/Lockheed Martin Kelly Aviation Center/Standard Aero/EG&G Logistics/Carter Burgess Engineers/Domingo Vara Chevrolet/Valero Energy Corporation/Technology Advocates of San Antonio/General Dynamics Network Systems/Alamo Community College District Foundat	SAIC/LMKAC/GD & SSHS	Grease Monkeys	Ronkey Mobot	San Antonio, TX	2000
459	Alachua County Public Schools/Fabco-Air, Inc/Subway/University of Florida College of Engineering & Eastside High School	ACPS/EHS	Rampage Robotics	Phantasm	Gainesville, FL	2000
461	Purdue FIRST Programs & West Lafayette Jr/Sr High School	Boiler Invasion	Westside Boiler Invasion	Rowdy Pete	West Lafayette, IN	2000
462	Delphi Automotive/NASA & Provine High School Robotic Team	Delphi & Provine HS	The Rambunctious Rams	The Rambler	Jackson, MS	2000
467	Intel & Shrewsbury High School	Intel & Shrewsbury	Duct Tape Bandits		Shrewsbury, MA	2000
468	Android Industries & Flushing High School	Baker Explorers	The Explorers	Aftershock	Flint, MI	2000
469	AVL/JSP/NACHI Robotics/Norgren/DELMIA/ABB/OTC-Daihen, Inc/Tokico/Rock Financial/RSR /Quexco/Eco-Bat/Maher Construction/Midtronics/IEEE/Fulk Machine Shop/Primeway Tool and Engineering/Hoyt, Brumm & Link/Lawrence Technological University/Bridgeman Machines/	AVL,JSP & IA	Las Guerrillas	Cornelius VII	Bloomfield Hills, MI	2000
470	Visteon & Ypsilanti High School	Ypsi High Robotics	Alpha Omega Robotics	F.R.E.D.	Ypsilanti, MI	2000
473	Montana Space Grant Consortium/NASA & Corvallis High School	MSGC & Corvallis MT	Montana State Robotics Team	chs	Corvallis, MT	2000
476	ConocoPhillips/Cookshack/Houston Robotics/Oklahoma State University College of Engineering (CEAT)/Precision Tool & Die & Ponca City High School	Conoco/PoncaCity HS	Wildcats	ADIDAR	Ponca City, OK	2000
481	Chevron Richmond Refinery/Google/Soroptomist International of Richmond/TAP Plastics of El Cerrito/Motel 6 #4229/The Ed Fund/Contra Costa College & Middle College High School & De Anza High School	Chevron,Google&WCCRT	The Hitchhikers	The Almighty Agrajag	San Pablo, CA	2000
484	Lockheed-Martin/GE Elfun & Haverford High School	Haverford & GE Elfun	Predators	Blue Mongoose	Havertown, PA	2000
486	3M/Dyneon/Agilent Technologies/McNeil Consumer Health Products & Strath Haven HS	Strath Haven HS	Positronic Panthers	Positronic Panther	Wallingford, PA	2000
488	Boeing/Microsoft & Franklin High School	Microsoft & Franklin	Team XBOT	Hex	Seattle, WA	2000
492	Oregon NASA Space Grant Consortium & The International School	Titan Robotics	Titan Robotics Club	Gaea	Bellevue, WA	2001
494	DaimlerChrysler/General Motors/NASA/Textron Fastening Systems & Goodrich High School	Martians	Martians	My Favorite Robot	Goodrich, MI	2001
496	Port Jefferson Robotics Club	Port Jefferson HS	Powerhouse	TBD	Port Jefferson, NY	2001
498	Honeywell International/Vitron Manufacturing & Cactus High School	Cobra Commanders	Cobra Commanders	Rage	Glendale, AZ	2001
499	Kelly Aviation Lockheed Martin/ASME - International Petroleum Technology Institute/ITT Tech/OnBoard Software/UTSA College of Engineering/DevicePoint/Boeing/Chromalloy & Edgewood ISD	Toltechs	Toltechs	Hoovernator	San Antonio, TX	2001
500	SE Connecticut and Rhode Island HS Students	CGA Team USA	The Bears	Objie 9	New London, CT	2001
501	FCI/Homeseer Technologies & West High School	FCI/Homeseer/West	The Power Knights	Y. A R.	Manchester, NH	2001
503	Intier Automotive & Novi High School	Intier/Novi	Frog Force	Big Joe	Novi, MI	2001
507	Walmart/Electrolock/Computer Dynamics & Carolina Academy	Solid Orange Robotics	Solid Orange Academy of Robotics (SOAR)	Bubo	Greenville, SC	2001
510	Infineon Technologies, Richmond & Highland Springs Technical Center	IFR & HSTC	Hawaii Five-10	Danno	Highland Springs, VA	2001
514	G&L Precision Corp./Miller Place PTO/MP Robotics Boosters & Miller Place Schools	MP Robotics	Miller Place Robotics	Entropy	Miller Place, NY	2001
515	GM CRW/ESYS Corporation & Osborn High School	Osborn/GM CRW	TechnoKnights	Oz	Detroit, MI	2001
518	GUMBO/Ferris State University/GRAPCEP/Davenport/IST/Steelcase & Ottawa Hills High School	Steelcase-FSU-IST	Blue Steel	Skittish	Grand Rapids, MI	2001
519	General Motors Foundation/GM CCRW ,ITT Technical Institute and Golightly Career and Technical Center & Pershing High School	GM/ITT& Golightly	Robo Masters	Joshua	Detroit, MI	2001
521	Dominion Millstone Power Station &  Waterford High School	Dominion&WaterfordHS	L33T CREW ("leet crew")	Dr. Fun 2.0	Waterford, CT	2001
522	New York Container Terminal/SI Bank & Trust Foundation/Con Edison/Richmond County Savings Foundation/Northfield Savings Bank & Mckee Vocational High School	McKee Voc. H.S.	ROBO WIZARDS	Annie	Staten Island, NY	2001
525	DISTek Integration, Inc/Rockwell Collins/John Deere Waterloo Operations/UNI College of Natural Sciences and Iowa Space Grant Consortium/Fred Rose/Bruce and Terry Forystek/Eason Scholarship & Cedar Falls High School	Cedar Falls HS	Swart-Dogs	Poof Daddy	Cedar Falls, IA	2001
527	Plainedge HS / Red Dragons	Red Dragons	Dragons	The Dragon	No. Massapequa, NY	2001
528	Visteon Corp. & North Penn High School	North Penn Robotics	The Persuaders	Sue	Lansdale, PA	2001
529	Mansfield High School	Mansfield Robotics	The Mansfield Hornets	Stinger	Mansfield, MA	2001
533	Lindenhurst Senior High School	PsiCoTiCs	PsiCoTiCs		Lindenhurst, NY	2001
537	Rockwell Automation/GE Healthcare/Pentair Water/Fleck Controls/QuadTech a division of Quadgraphics & Hamilton High School	GE Healthcare & HHS	Charger Robotics		Sussex, WI	2001
538	Arab High School	Arab HS	Dragon Slayers	Black Knight VI	Arab, AL	2001
539	UNITE with Virgil Brackins & Trinity Episcopal School	Titans	Titans	Titan II	Richmond, VA	2001
540	ECPI/ITT Technical Institute/ShowBest Inc./Verizon/ChemTreat Inc./Blue Print Automation/Henrico Doctor's Hospital/MacPro Solutions & Mills Godwin High School	SHWBST/VERZ/HEF/GHS	Screaming Eagles	Pandora	Richmond, VA	2001
545	Island Trees High School	ITHS	ROBO-DAWGS	DAWG-1	Levittown, NY	2001
546	UTC Sikorsky & Amity Regional & Harding High School	UTC/Sikorsky United	Technotics	Chuba IV	Woodbridge, CT	2001
547	F.E.A.R Foundation  & Lincoln Co. High School	F.E.A.R & LCHS	F.E.A.R.	NetForce	Fayetteville, TN	2001
548	Shiloh Industries & Northville High School	Northville H.S.	Robostangs	RoboStang	Northville, MI	2001
549	Steel Fab inc & Leominster High School	Raytheon/Leominster	Devil Dawgs	Cerberus	Leominster, MA	2001
550	Warren County Technical School	NanKnights	NanKnights	Dante	Washington, NJ	2001
554	Procter & Gamble & Highlands High School	P&G/Highlands	Highlanders	William Wallace	Ft. Thomas, KY	2001
555	Judy and Josh Weston & Montclair Board of Education	MHS 555	Montclair Robotics	TOM - Black Knight	Montclair, NJ	2001
558	Yale University & H.R. Career H.S.	Career High School	Robo Squad	C.R.A.S.H.	New Haven, CT	2001
562	Montachusett Regional Vocational Technical School	Monty Tech	SPARK - Students Pursuing Applied Robotics Knowledge	Sparky	Fitchburg, MA	2001
563	McNeil Pharmaceuticals / Drexel University / Phila. School District & BOK Tech High School	Bok Thrashers	Thrashers	Steelrelicus	Phila, PA	2001
564	Gershow Recycling & Longwood HS	LONGWOODCSD	Digital Impact	Diamond in the Rough	Middle Island, NY	2001
566	Middle Country School District	Hot Wired 566	Hot Wired 566	Gill-o-bot	Centereach, NY	2001
568	AREA/BP & Dimond High	Dimond Alaska	Nerds of the North	Absolute Zero Mark VI	Anchorage, AK	2001
569	Heads Up Construction & W.T. Clarke H.S.	Rams	Flounders	Caesar	Westbury, NY	2001
570	Glen Cove High School	GC HS Team Phoenix	Team Phoenix	Phoenix	Glen Cove, NY	2001
571	UTC Otis Elevator - OSC/Dymotek, Inc./Coherent DEOS/Alstom Power, Inc./Design Innovation, Inc./JAZ Industries, Inc. & The Loomis Chaffee School & Windsor High School & Metropolitan Learning Center	UTC Team Paragon	Team Paragon	Spyro	Windsor, CT	2001
573	Chrysler & Brother Rice High School	BRMarianMechWarriors	Mech Warriors	Warrior III	Bloomfield Hills, MI	2001
578	Gleason Works & Fairport High School	Blue Lightning	Blue Lightning	KG-3	Fairport, NY	2001
580	IMS & Campbell Hall School	IMS & Campbell Hall	Campbell Hall Robotics	S.T.U	North Hollywood, CA	2001
581	BAE Systems & San Jose High Academy	SJHA	Bulldog Robotics	Bradley	San Jose, CA	2001
585	NASA Dryden Flight Research Center/Northrop-Grumman/Arcata Associates, Inc. & Tehachapi High School	THS/NASA/Northrop	Warrior Robotics	Geronimo	Tehachapi, CA	2001
587	Duke University/How Stuff Works & Orange High School & Cedar Ridge High School	OHS/CRHS/StufWks/Duke	Sotobotics	Occam VI: Concentrated Entropy	Hillsborough, NC	2001
589	Charles Dunn & Crescenta Valley High School	CVHS Robotics	FalKON	FalKON	La Crescenta, CA	2001
590	NASA/Stennis Space Center & Choctaw Central High School	Chahta Warriors	Chahta Warriors	Tushka VI	Choctaw, MS	2001
596	Hopkinton High School	HHS/EMC/Intel/RTN/CLS	SciClones	Error#596	Hopkinton, MA	2001
597	USC-MESA/NASA-JPL/Raytheon & Foshay Learning Center	Foshay/USC-MESA/JPL	Wolverines	Wolvie Zeta	Los Angeles, CA	2001
599	California State Universtity, Northridge & Granada Hills Charter High School	CSUN & GHCHS	Robo-Dox	Dermatologist	Granada Hills, CA	2001
600	AREVA/Region 2000 Technology Council & Lynchburg City Schools	Region 2000 Schools	ElectricMayhem	FREEK	Lynchburg, VA	2001
602	Diversified Educational Systems & Loudoun County Public Schools	Monroe Tech	MTC	unknown	Leesburg, VA	2001
604	Leland High School	Leland Quixilver	Quixilver	Lightning 604	San Jose, CA	2001
606	King/Drew HS	Raytheon/KingDrew LA	CyberEagles	Roybot	Los Angeles, CA	2001
610	Bangor Metals/J.J. Mech Contractors/GE Plastics/Gamut Threads/Gee Jeffrey Partners Advertising/Cachelan & Crescent School	Crescent Robotics	The Coyotes	Coyobot 7	Toronto, ON	2001
611	Langley High School	Langley Saxons	Saxons	Otto	Mclean, VA	2001
612	Mitretek/SAIC/Northrup Grumman/IAI & Chantilly Academy	Chantilly	CATS	Black Knight	Chantilly, VA	2001
613	Franklin High School	FHS RoboWarriors	RoboWarriors	Gearbot	Somerset, NJ	2001
614	U.S. Army Night Vision Lab/ALION/EOIR Technologies/Fibertek/Northrop Grumman & Hayfield Secondary School Robotics Club	Hayfield Secondary	NightHawks	NightHawk	Alexandria, VA	2001
615	NASA & Ballou Senior High School	The Mighty Knights	Knights	D.O.C.	Washington, DC	2001
617	Highland Springs High School	HSHS SPRINGERS	SPRINGERS	DUKE	Highland Springs, VA	2001
618	School District of Philadelphia/ITT Technical Institute/DeVry University/JMI Software Consultants Inc./Cascabel Properties & GEAR-UP & Edison Fareira High School	E.A.R.T.H. SQUAD	E.A.R.T.H. Squad (Edison Achieving Real Technological Heights)	Omega	Philadelphia, PA	2001
619	Jagtiani + Guttag/University of Virginia/GE Fanuc/Ryobi/Becklan Construction/Advanced Network Systems/Virginia Piedmont Technology Council & Charlottesville/Albemarle Schools	UVA/GE & area schools	CARobotics	One Way	Charlottesville, VA	2001
620	ALLTECH/Collins Contracting Company/SAIC	Warbots	Warbots	Chimera	Vienna, VA	2001
623	Oakton High School	RAYTHEON/PEC/Oakton	Ohmies	Ohmwrecker	Vienna, VA	2001
624	BP Americas/Oceaneering & Cinco Ranch High School	bp/OII&Cinco Ranch HS	CRyptonite	CRyptonite	Katy, TX	2001
634	Van Nuys High School	VNHS-SFVNTMA	Rage	Rage	Van Nuys, CA	2001
637	Marotta Controls, Inc. & Montville High School	Marotta & MTHS	Horsepower	Murphy	Montville, NJ	2001
638	Chesterfield County Public Schools	Clover Hill High	Operation Oxidation	Paradox	Midlothian, VA	2001
639	AccuFab Inc/BorgWarner Morse TEC/FIRST Robotics Club, Cornell/GOLD Screen Printing Inc/ICSD/Innovative Dynamics, Inc/Innovative Metalworks/IPEI/Kionix/Moosewood Restaurant/Private Donors & Ithaca High School	Morse TEC/Ithaca HS	Code Red Robotics	The Red Tulip	Ithaca, NY	2001
640	Con Edison & Thomas A. Edison High School	Robo Elite	R6	Robo 4	Jamaica, NY	2001
647	TESCO/Operational Test Command U.S. Army & Robert M. Shoemaker High School	TESCO, OTC, Shoemaker	Cyber Wolf Corps	undetermined	Killeen, TX	2001
648	John Deere/Ken-Tronics/SME & Sherrard H.S. & Davenport West H.S.	JD/K-T/SME & QC Elite	Q. C. Elite	Alice	Sherrard, IL	2001
649	Saratoga High School	SRT	Saratoga Robotics	The Challenged IV	Saratoga, CA	2001
650	Hella Electronics Corporation/Illinois Eastern Community Colleges/Wabash Valley College & FLora High School & Clay City High School & Louiisville High School & Cisne High School	HELLA&IECC,CC,F,L,C	Hella's Angels	Little Devil 5	Flora, IL	2001
653	Bezos Foundation/ITT/Lockheed & Edison High School	BezosITTEdisonLockhee	NOSIDE	EDI-653	San Antonio, TX	2001
662	Academy School District 20	Rocky Mtn. Robotics	Highlanders		Colorado Springs, CO	2001
663	UMass Lowell & Whitinsville Christian School	WCS & UML Robonauts	Robonauts	Alexandra	Whitinsville, MA	2001
665	Lockheed Martin/Walt Disney World/Orlando Science Center/GE PolymerShapes/Miller Bearings and Motion Systems/University of Central Florida & Oak Ridge H.S. & Edgewater H.S.	M.A.Y.H.E.M.	MAYHEM	GIR	Orlando, FL	2001
668	Pioneer High School ASB	The Apes of Wrath	The Apes of Wrath	Kong Fu	San Jose, CA	2001
670	R M Hoffman Company/Mission Benefits/Outback Manufacturing Inc./Ronald C. Crane & Homestead High School	HRT	Homestead Robotics	Mustang II	Cupertino, CA	2001
675	Technology High School	THS Robotics	Tech High Robotics	SuperMegaRobotron 3000	Rohnert Park, CA	2001
677	American Electric Power/Ohio State University/Roush Honda & Columbus School for Girls	OSU/AEP/CSG Robotics	The Wirestrippers	The Bat Bot	Columbus, OH	2001
686	NASA Goddard Space Flight Center/Rinker Materials/The Kinna Family/Briddell Builders & Linganore High School	LINGANORE HS	Bovine Intervention	Sir Loin	Frederick, MD	2001
687	Filipino Community of Carson/Torrance Chipotle & Califronia Academy of Mathematics and Science & CAMS Parent Teacher Student Organization	camsRobotics	The Nerd Herd	The I.M.P.  v 2.0 (Integrated Mechanical Prototype)	Carson, CA	2001
691	JPL/ITT/HR Textron/Honda/Raytheon & Hart High School	Hart Burn	Hart Burn	Fetish	Newhall, CA	2001
692	CyboSoft & St Francis High School	St. Francis HS	THE FEMBOTS	Precious	Sacramento, CA	2001
694	Yvette & Larry Gralla/Time, Inc./The Wallace Foundation/Cox & Company, Inc/Con Edison & Stuyvesant High School Alumni Association & Parents Association & Stuyvesant High School	StuyPulse	StuyPulse	Larry	New York, NY	2001
695	Envision Radio Corporation & Beachwood High School	Beachwood HS	The Bison	Envision Radio Corporation	Beachwood, OH	2001
696	Glendale Community College & Clark Magnet High School	Clark Magnet HS	Circuit Breakers	Heather	La Crescenta, CA	2001
698	Capitol Metals/Microchip Technology Inc./Port Plastics & Hamilton High School	Microchip/HHS	HHS Microbots	Mikey's Phoenix	Chandler, AZ	2001
701	COGCO/Fairfield-Suisun Rotary/Goodrich/Travis USD & Vanden High School	Vanden Robotics	RoboVikes	Tyr	Fairfield, CA	2001
702	Raytheon/Raytheon/Fold-A-Goal/Kathy Mahan / Verizon/Culver City Education Foundation & Culver CIty High School	Bagel Bytes	Bagel Bytes	Bagel Bytes	Culver City, CA	2001
703	Delphi & Saginaw Career Complex	Delphi/Saginaw Career	Phoenix	Inferno	Saginaw, MI	2001
704	Control Products Corp./Fairfield Development LP/General Motors - Arlington Assembly/Houston Robotics/Intuitive Research & Technology/L.R. Cannon Enterprises/Lockheed Martin Missiles and Fire Control/Lone Star Park at Grand Prairie/Pratt & Whitney Eagle SV	Warriors	Warriors	Chief	Grand Prairie, TX	2001
706	Price Engineering & Arrowhead High School	AHS/PRICE ENG	A.P.E.	Optimus Primal	Hartland, WI	2001
708	Hatboro-Horsham High School & Upper Moreland High School	Motorola/HHHS/UMHS	Hard Wired Fusion	Dorothy	Horsham, PA	2001
709	The Agnes Irwin School	Femme Tech Fatale	Femme Tech Fatale	Three Dollar Pantyhose: The Final Run	Rosemont, PA	2001
710	Pine Crest School	Panther Bot	Panther Bot	PAW	Fort Lauderdale, FL	2001
711	Bezos Family/Citigroup  & Paul Robeson high School	CityGroup/POLY & PRHS	Robeson full force	BUCHITO III	Brooklyn, NY	2001
714	Technology High School	NPS/ADP/NJIT-Tech HS	Super Panthers	Scorpion	Newark, NJ	2001
716	BD/C. A. Lindell/Salisbury Bank and Trust/Specialty Minerals/Arthur G. Russell Co./21st Century Fund & Housatonic Valley Regional High School	Housatonic HS	Who'sCTEKS	Jeremiah	Falls Village, CT	2001
743	Bloomberg & Evander Childs  Campus & High School of Computers and Technology	Technobots	Technobots	The Refigerator	Bronx, NY	2002
744	Apex Machine Co. & Westminster Academy & Coral Springs Christian Academy	AWACS	Shark Attack		Ft. Lauderdale, FL	2002
751	Woodside Priory School	barn2robotics	b2r	princess stalin	Portola Valley, CA	2002
752	Newark Public Schools & Science High School	Science High School	Gods of Fury	Excalibur	Newark, NJ	2002
753	Advanced Power Technology/Bend Research/ISCO & Mountain View High School	MVHS	High Desert Droids	D=RT	Bend, OR	2002
754	NASA/NWTC/MMC/M&M Foundation/Enstrom Helicopter  & Marinette HS & Menominee HS & Peshtigo HS	FROST BYTE	FROST BYTE	ICE HOOK	Marinette, WI	2002
758	ArvinMeritor/Meritor Suspension Systems & BDHS, CKSS, JMSS, Ursuline College	ARVINMERITOR & SKY	SKY Robotics	Chimaera	Blenheim, ON	2002
759	metapurple Ltd. & Hills Road Sixth Form College	Systemetric	Systemetric	The Right Honorable Charles Erasmus Worthington-Smythe III Esquire OBE	Cambridge, UK	2002
766	Menlo-Atherton High School	MAHS	M-A Bears	TBD	Atherton, CA	2002
768	Fred Needel INC/NASA Grfc & Woodlawn High School	Technowarriors	Technowarriors	ROBO	Baltimore, MD	2002
771	St. Mildred's Lightbourn Parents Association	S.W.A.T.	SWAT	MILDREAD	Oakville, ON	2002
772	General Motors & Sandwich Secondary School	GM Canada & SSS	Sabre Bytes	BLT	LaSalle, ON	2002
773	Siemens VDO/Kingsville Greenhouse Growers & Kingsville District High School	Kingsville Kukes	Kingsville Kukes	Kukinator II	Kingsville, ON	2002
776	Anchor Lamina Inc./Geo. T White Ltd./University of Windsor/St. Anne Parents Club & St Anne HS	SATech	SATech Saints	Iron Woody	Tecumseh, ON	2002
781	Bruce Power/Power Workers' Union & Kincardine District Secondary School	Kincardine/BrucePower	Kinetic Knights	"Big Bruce"	Kincardine, ON	2002
801	Merritt Island High School	HorsePower	HorsePower	Mustang Sally	Merritt Island, FL	2002
803	Trident Technical College & Hanahan High School	HHS	Castaways	Bob	Hanahan, SC	2002
804	Comporium/Duke Energy & Applied Technology Center & Rock Hill District 3 High Schools	DUKE/COMPORIUM/RHD3	MetalMorphosis	Hoover	Rock Hill, SC	2002
806	Bishop Kearney High School & Xaverian High School	X-Men	Xaverian X-Men	Scoops	Brooklyn, NY	2002
807	NASA/Digital Fusion, Inc./CFD Research Corporation & New Century Technology High School & Columbia High School	NCTHS/CHS ROBOTICS	Monster Mechanics	Plan B	Huntsville, AL	2002
808	Westmont, Inc./Lake Erie Electric Loomis Division/SES, LLC Steel Engineering Specialists/Sarchione Sales and Service/G Weimer/D & J Burdett & Alliance High School	808 Mechanical Mayhem	Mechanical Mayhem	Cap'n Hook	Alliance, OH	2002
809	Cheney Tech	Cheney Tech	The TechnoWizards	Savanna	Manchester, CT	2002
810	Smithtown Schools	Mechanical Bulls	The Mechanical Bulls	The Tank!	Smithtown, NY	2002
811	Raytheon Company & Bishop Guertin High School	BGHS & Raytheon	Cardinals	MISTT	Nashua, NH	2002
812	The University of California at San Diego/The UCSD Machine Perception Laboratory/General Motors/The Annenberg Foundation/Qualcomm/Space and Naval Warfare Systems Center, San Diego/Northrop Grumman/The San Diego County Fair & The Preuss School at UCSD	UCSD & PREUSS	The Midnight Mechanics	M^5	San Diego, CA	2002
814	New Technology High School	New Tech Robotics	Megaforce Squadron	Blondie Girl	Napa, CA	2002
815	Visteon Corporation/ITT Technical Institute/H/J Manufacturing/Cooper and Brass Sales /Team Ford FIRST & Allen Park High School & St Frances Cabrini High School	Visteon & AP & SFC HS	Advanced Power	Advanced Power	Allen Park, MI	2002
816	BCIT Foundation & BCIT	BCIT/Westampton	Panthers	Anomaly	Westampton, NJ	2002
818	General Motors General Assembly Engineering & Warren Consolidated Schools	Team 818 GM-GAE & WCS	GENESIS '02 - "The Steel Armadillos"	Chica-La-Bamba	Warren, MI	2002
820	Professional Engineers of Ontario - North Toronto Chapter/Toronto District School Board & North Toronto Collegiate Institute	NTCI & TDSB / PEO	Team DeltaTech	DeltaBot	Toronto, ON	2002
829	ProportionAir Corporation/Rolls-Royce Corporation & Walker Career Center	Warren Robotics Team	Digital Goats	Wazoo	Indianapolis, IN	2002
830	AVL North America, INC/UMentorFIRST & Huron High School	Huron High and AVL	The Rat Pack	PackRat	Ann Arbor, MI	2002
832	Applied Systems Intelligence & Roswell High School	RHS	Chimera		Roswell, GA	2002
834	Southern Lehigh School District	LUTRON/SOUTHERNLEHIGH	SparTechs	to be announced	Center Valley, PA	2002
835	DENSO  & Detroit Country Day School	DENSO & DCDS	The Sting	Baloo	Beverly Hills, MI	2002
836	BAE Systems/O'Brien Realty - Mrs. Susan Stachelczyk/The Patuxent Partnership/The RoboBees of NASA Goddard Spaceflight Center & Dr. James A. Forrest Career & Technology Center	RoboBees	RoboBees		Leonardtown, MD	2002
839	Berkshire Power/Hamilton Sundstrand/Hartford Steam Boiler Inspection & Insurance Company & Agawam HS	Agawam High School	Rosie Robotics	Rosie 5.0	Agawam, MA	2002
840	SRI International/Jim Minkey Remax Today & Aragon High School	Aragon HS	ART		San Mateo, CA	2002
841	Chevron/Mechnics Bank/Richmond High Afterschool Program & Richmond High School	Chev/Mech/ILM & RHS	The BioMechs	MechPlow	Richmond, CA	2002
842	Arthur M. Blank Foundation/Honeywell/Intel/Phelps-Dodge/Wells-Fargo & Carl Hayden High School	Carl Hayden Falcons	Falcon Robotics	Karen	Phoenix, AZ	2002
843	Bell Canada/Dofasco/Ford Canada/Hertz /KTS Tooling/NTN Bearings/Two Stage Innovations & Halton District School Board & White Oaks Secondary School	WOW	Wildcats	Willie	Oakville, ON	2002
845	Accu Tech & Pendleton High School	Cutting Edge	Cutting Edge		Pendleton, SC	2002
846	DP Products/SJSU/Google/LAM Research & Lynbrook High School	LYNBROOK HS	The Funky Monkeys	BikBot	San Jose, CA	2002
847	Hewlett Packard & Philomath High School	PHRED	PHRED	PHRED	Philomath, OR	2002
848	Law Offices of PRINDLE, DECKER & AMARO LLP & Rolling Hills Preparatory School	Rolling Hills Prep	Robodogs	Astro	Palos Verdes Estates, CA	2002
849	Unionville High School	UHS WOLFPACK	Wolfpack	WOLF	Unionville, ON	2002
852	General Atomics/Lawrence Livermore National Laboratory/Macy's West/Northrop Grumman & The Athenian School	Athenian Robotics	The Athenian Robotics Collective	Chet	Danville, CA	2002
854	TDSB & Martingrove C. I.	Martingrove Robotics	The Iron Bears	Ursa Ferra (Iron Bear)	Toronto, ON	2002
857	NASA/DaimlerChrysler/General Motors/Ford/Michigan Technological University & Houghton High School	NASA/DCX/GM/MTU/HHS	Superior Roboworks - The Yetis	Fran+ºois VII	Houghton, MI	2002
858	Delphi Corp. & Wyoming Public Schools	Delphi Demons	Delphi Demons	Demon #5	Wyoming, MI	2002
859	West Virginia University & Monongalia County Board of Education & Morgantown High School	WVU/KLINC/MHS	BOING	B	Morgantown, WV	2002
862	Visteon/NASA/ITT Technical Institute & Plymouth-Canton Educational Park	P-CEP, Visteon & NASA	Lightning Robotics	Icarus	Canton, MI	2002
865	Toronto District School Board & Western Technical-Commercial School	WARP7 Robotics	Warp7	Prodigy 6	Toronto, ON	2002
867	Los Angeles County ROP & Arcadia Unified School District	AHS A.V.	Absolute Value	Trinity V	Arcadia, CA	2002
868	ITT TEchnical Institute /Rolls Royce/Delphi & Carmel High School	Carmel TechHOUNDS	TechHOUNDS		Carmel, IN	2002
869	Cordis Corporation (J&J) & Middlesex High School	Cordis/Middlesex HS	The Power Cord	Maximus	Middlesex, NJ	2002
870	Miller Environmental/Sea Tow International/RJN Tool and Automation/FESTO Corporation/Westhampton Glass and Metal/Lewis Marine Supply of Greenport/Westhampton True Value Hardware/Southold Rotary/Southold Kiwanis/Hart's True Value Hardware/Speonk Lumber/Luc	Southold & Company	TEAM  R. I. C. E.	R.I.C.E.  V     Fifth Generation	Southold, NY	2002
871	West Islip Robotics Booster Club, Inc. & West Islip High School	West Islip Robotechs	Robotechs	Flux	West Islip, NY	2002
872	columbus state community college & marion franklin boosters	MFHS/SEC/AEP/CSCC/GP	Techno-Devils	Woodford	Columbus, OH	2002
874	Alexander Public School	Isis	Isis	X-Evil	Alexander, ND	2002
876	ND Space Grant Consortium/American Federal & Hatton High School & Northwood High School	Hatton/Northwood	Thunder Robotics	Oscar	Northwood, ND	2002
877	UND & Cando Public School	UND/Cando Cubs	Cub Robotics	Krypobot 5	Cando, ND	2002
878	University of North Dakota/Rugby Welding & Machine/Rugby Maufacturing/Dakota Prairie Supply & Rugby High School	UND/RHS	Metal Gear	Sprocket	Rugby, ND	2002
883	Cleveland Central Catholic High School	CCC	Ironmen	Oscar	Cleveland, OH	2002
884	Malverne High School	Malverne Robotics	Quarks	r2d3	Malverne, NY	2002
885	National Life Group/Norwich University David Crawford School of Engineering/SoRo Systems, Inc/Vermont Technical College & Randolph Union High School	Vermont Robotics	GREEN TEAM	GREEN MACHINE	Randolph, VT	2002
886	TDSB & Westview Centennial SS	Wildcats	Wildcats	The Wildcat	North York, ON	2002
888	Howard County Public Schools/NASA Goddard & Glenelg	Glenelg	Robotiators	The Dean	Glenelg, MD	2002
894	Delphi/General Motors Foundaton & Flint Powers Catholic High School	Powers Chargers	Chargers	C&P1	Flint, MI	2002
896	Central High School/Newark Public Schools	CHS/NPS	Central Blue Robodevils	BDR3	Newark, NJ	2002
900	North Carolina School of Science and Mathematics	NCSSM	Team Infinity		Durham, NC	2002
903	Ford Motor Company/General Motors & Charles Chadsey High School	Chadsey/Ford/GM/NASA	Explorobots	General Ford Jr.	Detroit, MI	2002
904	Gill Industries/GM - Grand Rapids Metal Center/HS Technolgies/Siemens & Creston High School	GM/Gill/Creston HS	R2	R2 D Cubed	Grand Rapids, MI	2002
905	Platt Tech Parent Faculty Organization/United Sewer & Drain Cleaning Incorporated/American Precision Manufacturing LLC & Platt Technical High School	Platt Tech	Platt Tech Panthers	Adrenaline 5	Milford, CT	2002
907	Toronto District School Board & East York Collegiate Institute	East York Cybernetics	East York Cybernetics	Natural Disaster	Toronto, ON	2002
909	Ewing Marion Kauffman Foundation & Lawrence Free State High School & Lawrence High School	LawrenceRoboticsTeam	Junkyard Crew	Caesar	Lawrence, KS	2002
910	Foley Freeze	SVE/Foley	The Ventures	Foley Freeze	Madison Heights, MI	2002
912	TDSB & William Lyon Mackenzie CI	Iron Lyons	Iron Lyons	MSDL	Toronto, ON	2002
919	TDSB & Harbord CI	Harbord C.I.	Tigers		Toronto, ON	2002
922	AEP/Houston Robotics /SONY Corporation & United Engineering & Technology Magnet	ULTIMATE	ULTIMATE:  United Longhorn Team Inspiring Mental Attitude Towards Engineering	MUN-E-14	Laredo, TX	2002
926	Cisco Systems/ABB/GSK & Broughton HS	Cisco/Broughton	The Capacitors	Capital Punishment II	Raleigh, NC	2002
928	NASA & Benjamin Banneker Academic HS	NAS,HK,C-CW,AT&BBHS	Hounds of Steel	Meka-Kaiju	Washington, DC	2002
930	item Midwest/NASA & Mukwonago High School	M cubed	Mukwonago Masters of  Machinery	M cubed	Mukwonago, WI	2002
931	Emerson/Ranken Technical College/Tuell Tool Company & St. Louis Public Schools & Gateway Institute of Technology	Emerson/Ranken&SLPS	Perpetual Chaos	G5	St. Louis, MO	2002
932	AEP/Houston Robotics/Nordam/WilTel & Tulsa Engineering Academy at Memorial	AEP/NASA/Memorial	Circuit Chargers	TBD	Tulsa, OK	2002
935	EWING MARION KAUFFMAN FOUNDATION/Higgs Tech Consulting/Standridge Color Corp & Newton High School	NHS/Ewing/Higg/SME/AB	RaileRobotics	Protege III	Newton, KS	2002
937	Ewing Marion Kauffman Foundation/General Electric & Shawnee Mission North HS	SMN	North Stars		Overland Park, KS	2002
938	Ewing Marion Kauffman Foundation & Central Heights High School	VXR	Viking Xtreme Robotics		Richmond, KS	2002
939	Sisseton High School	Sisseton HS	Hiphopanonymous	Hiphopanonymous	Sisseton, SD	2002
945	Colonial High School	Colonial HS	Element 945	The Hulk	Orlando, FL	2002
948	Birdwell Machine & Newport High School	Newport HS	NRG (Newport Robotics Group)	Rolling Thunder	Bellevue, WA	2002
949	The Bezos Family Foundation  & Bellevue High School	Bellevue Robotics	Wolverines	Omnibot	Bellevue, WA	2002
955	Hewlett Packard/Videx & Crescent Valley High School	HP/Videx/CVHS	CV Robotics	RaiderBOT V	Corvallis, OR	2002
956	Hewlett-Packard/Videx & Santiam Christian Schools	Eagles	Eagle Cybertechnology	Grim Sweeper	Corvallis, OR	2002
957	hewlett packard/viper northwest & west albany high school	HP/Viper/West Albany	WATSON	Sherlock	Albany, OR	2002
963	AEP & Columbus East High School & south East Career Center	EAST/AEP/CSCC/SECC	Tiger Techs	POPS	Columbus, OH	2002
964	Ford, NASA GRC, and Fluke & Bedford HIgh School	Elite Technobots	Bearcats	Robocat	Bedford, OH	2002
967	ASME/BENTLEY MANUFACTURING/CARPENTERS LOCAL #308/EHA/HOST ROCKET/IEEE/INNOVATIVE SIGNS/IOWA FLUID POWER/LINN-MAR BOOSTER CLUB/LINN-MAR FOUNDATION/ROCKWELL COLLINS & Linn-Mar High School	Linn-Mar Robotics	Mean Machine	Metal Menance	Marion, IA	2002
968	West Covina High School	RAWC (West Covina HS)	RAWC (Robotics Alliance Of West Covina)	Chazawazer	West Covina, CA	2002
970	Concept XXI/ECCS/21st Century CLC/Earthman's Education Services, Inc./R P Carbone & Shaw High School	Shaw  Megabots	The Cardinals	Johnny 5	East Cleveland, OH	2002
971	Berger Manufacturing, Inc/Google, Inc./Intuitive Surgical, Inc./The Law Office of Wei Qun E & Mountain View High School	Spartan Robotics	"RoboSpartans"	Leonidas	Mountain View, CA	2002
972	Los Gatos High School	LGHS	Iron Paw	Iron Paw	Los Gatos, CA	2002
973	Cal Poly San Luis Obispo/LARON Incorporated & Atascadero High School Greyhound Revolutionary Robotics	GRR	Greybots	X10DER	Atascadero, CA	2002
974	Toyota Technical Center/Mr. & Mrs. Stephen Petty/Gerald Oppenheimer Family Foundation/I/O Controls & Marymount High School	MHS/TTC/GOF/PETTY	Nautae	Nautilus V	Los Angeles, CA	2002
975	Dominion/Verizon/CapTech Ventures, Inc./PEER Tech Prep Consortium /Karl Linn/WIlliam H Lockey, Jr./Florida Neurosurgical Associates/Fairfield Veterinary Hospital/Clay Christensen Group LLC/WR Systems, Ltd./The Library of Virginia/The Virginia Department o	Synergy: James River	Synergy Robotics	MARIO	Midlothian, VA	2002
977	Halifax High School and STEM Academy	CometBots	Cometbots	CometBot	South Boston, VA	2002
980	ThunderBots //Symantec Corp./Tweed Financial Services/Lockheed Martin/Solutions for Automation/Crystal View Corp. & Delphi Academy & Shuttleworth Academy & Renaissance Academy & LA Academy of Literacy and the Arts	ThunderBots	ThunderBots	Lightning	Southern California, CA	2002
981	HR TEXTRON & Frazier Mountain High	FMHS	Falcons	Tobor	Lebec, CA	2002
987	NASA/VSR Lock & Cimarron-Memorial High School	CMHS HighRollers	HighRollers	ACE	Las Vegas, NV	2002
989	Nevada Community Foundation & Palo Verde Science Club	Palo Verde	Rounders	Jackpot	Las Vegas, NV	2002
990	Bechtel Nevada/University Nevada Las Vegas & Advanced Technologies Academy	A-Tech	The Deadly Viper Assassination Squad	Black Momba	Las Vegas, NV	2002
991	Ryan Companies US, Inc./Tommy Gate Company/Jake's Handyman Service & Brophy College Preparatory	Brophy Robotics	The Dukes	Leroy Jenkins	Phoenix, AZ	2002
995	Mark Keppel High School	MKHS-DGRSRS	DEGREASERS	LIGHTNING A.R. 2.5	Alhambra, CA	2002
996	Casa Grande High School	CGUHS Cougars	Techno Wizards		Casa Grande, AZ	2002
997	Hewlett Packard Corporation/Videx Corporation & Corvallis High School	HP/Videx & CHS	Bombadiers	iSHOOTER	Corvallis, OR	2002
999	Sikorsky Aircraft/Amphenol/Apptech, Inc/Brimatco Corporation/Calcagni Associates Real Estate/Riff Company, Inc/Stanco, Inc/The Alphabet Garden LLC/White-Bowman, Inc/Clarion Hotel/Feldman Orthodontics/Spadola & Paul & Vincent, DMD & Cheshire High School	Sikorsky/Cheshire HS	C.R.A.S.H.        (Cheshire Robotics and Sikorsky Helicopters)	Rocky	Cheshire, CT	2002
1000	Urschel Laboratories Incorporated & Wheeler High School	Urschel/VU&Wheeler HS	Cybearcats		Valparaiso, IN	2003
1001	Rockwell Automation & Charles F. Brush High School	Brush High School	spArcs	Hacksaw	Lyndhurst, OH	2003
1002	Kimberly-Clark/Georgia Institute of Technology & Wheeler High School	GT/Wheeler HS	The CircuitRunners	C-4	Marietta, GA	2003
1006	General Motors of Canada (Engng & Product Planning) & Port Perry H.S.	PPHS & GM Canada	Fast Eddie Robotics	Fast Eddie	Port Perry, ON	2003
1007	ST Realtor & Gwinnett County Public Schools	The Tyrants	Metal Tyrants	The Mighty Tyrant	Snellville, GA	2003
1008	American Electric Power/Battelle/Beechwold ACE Hardware/Chipotle/Columbus State Community College/Liebert/Tubular Techniques & Columbus Public Schools & Southeast Career Center & Whetstone High School	WHS/Tubular Tech/ AEP	Team Lugnut	Chief Lugnut	Columbus, OH	2003
1009	Georges Vanier Secondary School & Toronto District School Board	Vanier Vikings	Vikings	Unidentified Crawling Object	North York, ON	2003
1011	IBM/ITT-Tech/NASA & Sonoran Science Academy	Sonoran Science	CRUSH	Kareem	Tucson, AZ	2003
1013	General Motors Desert Proving Grounds/Intel/Magma Engineering Co/TRW Automotive & Queen Creek HS	QCHS Robotics	The Phoenix		Queen Creek, AZ	2003
1014	OSU FIRST & Dublin City Schools	Dublin Robotics	Bad Robots	Bad Robot 3.0	Dublin, OH	2003
1015	Yazaki North America & Pioneer High School	Yazaki NA/Pioneer	Pi Hi Samurai	Katana (Samurai Battlefield Sword)	Ann Arbor, MI	2003
1018	Rolls Royce/ ITT Technical Institute/Indiana Department of Workforce Development/Waterjet Cutting of Indiana & Pike Academy of Science and Engineering	Pike Acad of Sci/Eng	Robo-Devils	Apollyon II	Indianapolis, IN	2003
1019	Westhampton Beach High School	Sons Of The Beach	Sons Of The Beach		Westhampton Beach, NY	2003
1023	La-Z-Boy Inc./Midwest Fluid Power/DTE/Fischer Tool & Die/MTS Seating/Macsteel & Bedford High School	Bedford Express	Bedford Express	Ellenator	Temperance, MI	2003
1024	Aircom Manufacturing/Beckman Coulter/Rolls-Royce Corporation & Bernard K. McKenzie Career Center	Kil-A-Bytes	Kil-A-Bytes	Kil-A-Byte	Indianapolis, IN	2003
1026	IMT York & Floyd D. Johnson technology Center	Bank of York/FDJTC	Cougars	Y2K4	York, SC	2003
1027	ITT & West Springfield High School	ITT &  WSHS	Mechatronic Maniacs	Night Vision 2	West Springfield, MA	2003
1028	Pratt & Whitney Automation & Madison County Schools	Madison Cnty Robotics	UBERGEEKS	U1	Huntsville, AL	2003
1029	Belen Jesuit & Lourdes Academy	Wolvcats	Wolvcats	Matumbo	Miami, FL	2003
1031	Google/San Francisco State University & John O'Connell High School	John O'Connell HS	The Boilermakers	GG Bot (Golden Gate Robot)	San Francisco, CA	2003
1033	Dupont Spruance & Benedictine High School & Saint Gertrude High School	Catholic Robotic Sol.	Cadets and Company	Divine Inspiration	Richmond, VA	2003
1038	P&G/Puff's /Pella Entry Systems/General Motors - Moraine/Miami University/Kingsgate Transportation/SHAN Precision & Lakota East  & Butler Technology and Career Development Schools	P&G - Lakota East	Thunderhawks	Thunderhawk	Liberty Township, OH	2003
1039	kevinro.com/Seattle Robotics Society & Chief Sealth High School	SRS/Chief Sealth	Chief Sealth Robotics	Ironhawk	Seattle, WA	2003
1040	Paideia School	Paideia	Pythons		Atlanta, GA	2003
1047	Woodbridge High School	Woodbridge NerdLinger	Nerd Lingers	Hercules IV	Irvine, CA	2003
1048	National Starch and Chemical Co., Inc/Cool-O-Matic & Manville High School	NSC/COM/Manville HS	Mustang Robotics	Stash 3	Manville, NJ	2003
1051	Marion County Technical Education Center	Marion Co. Robotics	Technical Terminators	T2	Marion, SC	2003
1053	4 Office Solutions/Algonquin College/Cognos Incorporated/General Bearing Service Inc./Loucon Metal Limited/MSDN Canada/Ottawa Carleton District School Board/Ottawa Universiry - Faculty of Engineering & Glebe Collegiate	Glebe	Glebe Gryphons		Ottawa, ON	2003
1054	TENASKA, Inc/Wise Air, INC./SCHEV & Buckingham County Public Schools	The Knightmares	Knightmares	The Golden Knight	Buckingham, VA	2003
1057	Burgess Pigment/Imerys/J. M. Huber/Sandersville Railroad/Sandersville Technical College/Thiele Kaolin & Brentwood School	BRENTWOOD	The Blue Knights	Blue Knight	Sandersville, GA	2003
1058	Londonderry High School	LHS PVC Pirates	PVC Pirates	Sir Lancelot	Londonderry, NH	2003
1062	Disney & Celebration High School	Disney/Celebration	Celebration Robotics	Hangman	Celebration, FL	2003
1065	Walt Disney World Ride and Show Engineering/South Orange Ace Hardware & Technical Education Center Osceola & Professional And Technical High School & Osceola High School	Tatsu	Tatsu	Tatsu	Kissimmee, FL	2003
1070	California State University, Northridge/Dreamworks Animation skg & Louisville High School	Royal Robotrons	Royal Robotrons	Buckbot 2	Woodland Hills, CA	2003
1071	Wolcott High School	Wolcott High School	Team Max	Max	Wolcott, CT	2003
1072	Synopsys & The Harker School	Harker Robotics	Harker Robotics	VEKTOR	San Jose, CA	2003
1073	BAE Systems & Hollis-Brookline High School	FORCE	The Force Team	Scorpius	Hollis, NH	2003
1075	Lennox Drum/NSK Bearing & Sinclair Student Parliament	Sinclair Sprockets	Sprockets		Whitby, ON	2003
1079	Economic Development Corporation of Southwest California/Guidant/Southern California Gas Company/Solid State Stamping/Magnecomp Corporation/Cosworth, Inc./Flashpoint Machine/Crowder Machine and Tool/Chaparral High School Education Foundation & Chaparral H	CREATE	Chaparral Robotic Engineers and Techno Explorers	MO DOS	Temecula, CA	2003
1084	Sunoco & St. Clair Secondary School	IronColts	IronColts	RoboColt	Sarnia, ON	2003
1086	DRHS PTSA/Flexicell/Henrico Education Foundation/Mazu Networks, Inc/Perretz & Young Architects & Deep Run High School	Deep Run	Pirates	Black Pearl III	Glen Allen, VA	2003
1087	Zephyr Engineering/West Salem Rotary/Schneider Charitable Foundation/Meyer Memorial Trust/West Salem High Education Foundation/Garmin AT & West Salem High School	West Salem Titronics	Titronics Digerati	Basket Case II	Salem, OR	2003
1089	Bristol-Myers Squibb/Machine Medic/SPECO Tile & Marble, Inc. & Hightstown High School	Hightstown Robotics	Team Mercury	Silver Lightning	Hightstown, NJ	2003
1091	Quad Tech, a Division of Quad Graphics & Hartford Union High School	Hartford & Quad Tech	Oriole Assault	Bird of Prey	Hartford, WI	2003
1093	CapTech Ventures & Collegiate School	Collegiate	Cougars	Linguo	Richmond, VA	2003
1094	Bill Davis Inc./Livingston Tool & Mfg/Pfizer & River City Robots	River City Robots	River City Robots	Mettle Tester	O'fallon, MO	2003
1095	Pittsylvania County Schools/Sartomer Corporation/Intertape Polymer Group/Mecklenberg Electric Co-operative & Chatham High School	Chatham Robotics	RoboCavs	Skidmark	Chatham, VA	2003
1098	Pfizer /Rockwood School District & Eureka High School & Lafayette High School & Marquette High School & Rockwood Summit High School	GI's	The GI's	Gip	Wildwood, MO	2003
1099	Boehringer Ingelheim/GoFastRobots & Bethel High School & Bethel Middle School & Broadview Middle School & Brookfield High School & Whisconier Middle School	GE/P/GFR/ & BHS/NMHS	LIONS	LEO	Brookfield, CT	2003
1100	Rohm and Haas & Algonquin Regional High School	Rohm and Haas & ARHS	The Tomahawks	Tomabot	Northboro, MA	2003
1102	Washington Savannah River Company/BNG American Savannah River Corporation/Bridgestone Firestone/Senator Greg and Betty Ryberg/Parsons/CSRA Robot Warriors/United Defense/South Carolina State University & Aiken County Public Schools	M'Aiken Magic	Aiken County Robotics Team M'Aiken Magic	ODIN	Aiken, SC	2003
1103	NASA & Delavan Darien High School	Delavan Darien HS	Cometron	Git r' Dun IV	Darien, WI	2003
1108	Ewing Marion Kauffman Foundation/Holy Trinity Parish/Sutherland Family Limited Partnership & Paola High School	Paola High School	Panther Robotics	R.O.S.I.E	Paola, KS	2003
1110	Highland High School	Binary Bulldogs	Binary Bulldogs	Agent Schmidt	Palmdale, CA	2003
1111	Anne Arundel Technical Council/Anteon Corporation/ARINC Technical Excellence Society/Breakthrough Conversations Inc./Invoke Systems/NASA Goddard Space Flight Center/OXKO Corporation/Shady Side Medical Associates/Tui, Inc. & South River High School	Seahawks	"The Power Hawks"	Pedro	Edgewater, MD	2003
1112	TDSB & Timothy Eaton BTI	Timothy Eaton Huskies	Huskies		Toronto, ON	2003
1113	Temple Engineering & High School of Engineering and Science	Urban Assault Squad	Urban Assault	Urban Assault Vehicle	Philadelphia, PA	2003
1114	General Motors - St. Catharines Powertrain & Governor Simcoe Secondary School	GM Simbotics	Simbotics	Beckham	St. Catharines, ON	2003
1120	Solectron Corporation/City of Milpitas/Wells Fargo/Druai Consulting/Druai Education Services & Milpitas High School	MXR	Milpitas Xtreme Robotics	MILPITAS HIGH "Xtreme Robotics" (MXR)	Milpitas, CA	2003
1123	R. Bratti Associates/Ashton Security Laboratories & Autodidactic Intelligent Minors	AIM Robotics	AIM Robotics	Firefly	Alexandria, VA	2003
1124	UTC Fire and Security & Avon High School	UTCF&S & Avon HS	UberBots	Chub-bot	Avon, CT	2003
1126	Xerox Corporation & Webster High Schools	Xerox & Webster HS	SPARX	SPARX	Webster, NY	2003
1127	Useful Software/DRIVE/Kimberly Clark/Lockheed Martin & Milton High School	Milton/Lotus Robotics	Lotus Robotics	Styro	Alpharetta, GA	2003
1132	Fredericksburg Academy & RAPTAR	RAPTAR	R.A.P.T.A.R. (Robotics Adventure Professionals of Tidewater and Richmond)	The Claw	Ashland, VA	2003
1137	Mathews High School	MATHEWS HS	The Noblemen	King Louie	Mathews, VA	2003
1138	Tyco Electronics/MBDA Missile Systems/Frazier Aviation/Medtronics/Jostens & Chaminade College Preparatory	Eagle Engineering	Eagle Engineering	Dori	West Hills, CA	2003
1139	Chamblee High School	Gear Grinders	The Chamblee Gear Grinders	Guber	Chamblee, GA	2003
1141	G.E. Canada & Thomas A. Stewart	TAS	TAS Gryphons	Mega Watt	Peterborough, ON	2003
1143	Lockheed Martin/Main Technologies/One Point Inc. & Abington Heights High School	Abington Heights	Cruzin' Comets	Curious George	Clarks Summit, PA	2003
1144	Ethicon LLC & Jos+¬ Campeche High School & Mar+¡a Cruz Buitrago High School	Coquitron	Coquitron	Coquitron	San Lorenzo, PR	2003
1147	DeVry University/Optimist Club & Elk Grove High School	Herd Robotics	The Herdinators	HK1001	Elk Grove, CA	2003
1148	Harvard-Westlake School	Harvard-Westlake	The Saracens	J	Studio City, CA	2003
1152	Olin College & Community Academy of Science and Health & The Engineering School & Social Justice Academy	Hyde Park	Blue Stars		Hyde Park, MA	2003
1153	Analog Devices & Walpole High School	WHS	Robo-Rebels	Sizzler 4.0	Walpole, MA	2003
1155	The Alumni Asscoiation of The Bronx High School of Science/The Hennessey Family Foundation/Kepco Inc./ConEdison & The Bronx High School of Science	Bronx Science	SciBorgs		Bronx, NY	2003
1156	Colegio Marista Pio XII	Under	Under Control	robozito	Novo Hamburgo, RS	2003
1157	Boulder High School	Boulder	Boulder Bots	Panther Bot	Boulder, CO	2003
1158	Collbran Job Corps/ Michael Corbett DDS/Ametek Dixson/Bureau of Reclamation/EnCana Oil & Gas/Goodwin Foundation/Hilltop/Palisade Bank/Resource Dev. Specialist/State Farm /Western Colorado Community Foundation/Western Rockies Credit Union & Grand Mesa HS	Eagle Corps	The Corps	Gove 4	Collbran, CO	2003
1159	Ramona Convent Secondary School	Ramona Rampage	Ramona Rampage	Tigerbot	Alhambra, CA	2003
1160	Chinese Club of San Marino & San Marino High School	SMHS Robotics Team	Titanium	Titanium	San Marino, CA	2003
1163	Johnson Controls/SDSGC & Faulkton Area HS	Trojans	Trojan Horses	Hector III	Faulkton, SD	2003
1164	NASA & Mayfield HS	Project NEO	Project NEO	Nebuchadnezzar	Las Cruces, NM	2003
1165	Paradise Valley High School	Team Paradise	Trojans	paradise 2	Phoenix, AZ	2003
1168	CTDI & Malvern Preparatory School & Villa Maria Academy	Malvern Robotics	Malvern and Villa Robotics	FRIARBOT	Malvern, PA	2003
1172	460 Machine Shop & Richmond Technical Center	Rich Tech	We Tek Too	Sidewinder	Richmond, VA	2003
1178	Boeing /Brown & Associates & DeSmet Jesuit High School & Ursuline High School	D.U.R.T.	D.U.R.T.	DURT	St. Louis, MO	2003
1180	Gulfstream Aerospace Corporation/Motion Industries & Sol C Johnson High School	Johnson/Gulfstream	Atomsmashers	G-Bot 2	Thunderbolt, GA	2003
1182	Air Specialists Inc/EPIC Systems Inc./Festo Corporation/Hardee's/Heat Transfer Systems/Pfizer Inc. & Parkway South High School	Patriots	Patriots	Patriots	Manchester, MO	2003
1183	Collins Hill High School	Eagles	Team Ascari	Thomas the Tank (engine)	Suwanee, GA	2003
1184	DeWALT/JE JACOBS & Harford Technical High School	Cobra Robotics	Cobra Robotics	Eleven 84	Bel Air, MD	2003
1187	Mercedes Benz/NJIT & Newark Public Shcools  & University High School	University H.S.	Brick City Flame	Firebird 2	Newark, NJ	2003
1188	INA/Behr America/ROCCU/Trophy Robotics - South Africa & Royal Oak High School	Oaktown Crewz	OAKTOWN CREWZ	Alicia	Royal Oak, MI	2003
1189	General Motors & Grosse Pointe Public Schools	GM,AUTODESK,	Gearheads		Grosse Pointe Farms, MI	2003
1190	Overland High School	Ray/Mer & OHS	ANONOBOTS	B.A.M.F.R.	Aurora, CO	2003
1195	Patriots Technology Training Center & Thomas Johnson Middle School	Patriots-TTC	Eagles Dare!	Hannibal	Seat Pleasant, MD	2003
1197	ACE Clearwater Enterprises/Raytheon Co & South High School	Spartans	The Green Machine	Sparky	Torrance, CA	2003
1203	Farmingdale University & West Babylon School District	WB PANDEMONIUM	PANDEMONIUM	AXIOM	West Babylon, NY	2003
1205	AEP/Texas A&M Int. Univ. Dept. of Math & Phy. Sci./ARC Specialties/Houston Robotics/ESAB Cutting and Welding/Tymetal & Bruni High School Robotics	Bruni HS	Badgerbots	Astrobot	Bruni, TX	2003
1208	O'Fallon High School	OTHS Robotics	Metool Brigade	Excalibur	O'fallon, IL	2003
1209	AEP/University of Tulsa/Booker T. Washington Foundation for Academic Excellence/Houston Robotics & Booker T. Washington High School	AEP, TU & BTW	Agents Orange	Booker IV	Tulsa, OK	2003
1211	BEZOS Foundation/Merceds Benz-USA/Verizon Foundation/Rajswasser-Flaherty Family/Milovich Family & Friends of Automotive High School	Automotive H.S.	Robotnics	Titan The Third	Brooklyn, NY	2003
1212	Seton Catholic	Seton Robotics	Holy Hamsters	Kobayashi Maru	Chandler, AZ	2003
1213	US ARMY TARDEC/DaimlerChrysler/Team 494 Goodrich Martians/Mabuchi Motors/Al-Craft Industries/Central Screw Products & Birmingham Groves	GROVES	GROVES	Grobot	Beverly  Hills, MI	2003
1216	KUKA/NASA & Oak Park High School	Kuka OPHS Knights	Knights	Knightmare	Oak Park, MI	2003
1218	Johnson & Johnson & Chestnut Hill Academy & Springside School	CHASS	CHASS	La Bot Amie	Philadelphia, PA	2003
1219	Apotex Inc./Seneca College/Humber River Regional Hospital Foundation & Emery Collegiate Institute & Humber Summit Middle School	TDSB/Emery CI	Iron Eagles	Iron Eagle	Toronto, ON	2003
1221	DPCDSB & St. Martin's Secondary School	Nerdbotics	Nerdbotics	THIN	Mississauga, ON	2003
1222	AMF Bakery System & Hugenot High School	Huguenot HS	Falcon	Falcon	Richmond, VA	2003
1224	Credit Suisse /MTA/Verizon & St. Pius V High School	The Pius Princesses	Team 1224 - The Pius Princesses	The Pius Princess	Bronx, NY	2003
1225	Shining Rock LLC & Henderson County Robotic R.I.O.T	Hendo Robo	RIOT	Maverick	Hendersonville, NC	2003
1227	ITT Technical Institute/Smiths Areospace & Forest Hills Public Schools & Northview Public Schools	Techno-Gremlins	Techno-Gremlins	Glass Gremlin	Grand Rapids, MI	2003
1228	Infineum/A&M Industrial Supply/Merck & Rahway High School	Rahway	a-MERCK- IN- INDIANS	Rawbot	Rahway, NJ	2003
1230	Verizon/ADP/Credit Suisse & Herbert H. Lehman High School	Lionics	The Lehman Lionics	LEO IV	Bronx, NY	2003
1236	Danville Public Schools	VerizonCorning	Phoenix Rising	The Phoenix	Danville, VA	2003
1237	Verizon/Credit Swiss First Boston/Metropolitan Transit Authority & University Neighborhood High School	L.E.S. Cyborgs	Lower East Side Cyborgs		New York, NY	2003
1241	General Motors of Canada & Rick Hansen Secondary School	GMCL & Rick Hansen SS	Theory6_The Hansen Experience of Robotic Youth	Hansen Hummer	Mississauga, ON	2004
1242	David Posnack Hebrew Day School	DPHDS	Team S.M.I.L.E.Y	LED ZAPIN	Plantation, FL	2004
1243	General Motors Flint Truck Assembly & Swartz Creek High School	GM Truck & SCHS	Dragons	Dragon-1	Swartz Creek, MI	2004
1244	Volvo Motor Graders/SIFTO & GDCI	VMG/GDCI/SCI/TG	Viking Robotics	Ragnorak	Goderich, ON	2004
1245	American Astronautical Society/Ball Aerospace/EvilRobotics.net/Impact on Education/PeakPrecisionInc & Monarch High School	mohi	MoHi Shazbots	Problem Chile	Louisville, CO	2004
1246	Rotary Club of Agincourt/TDSB & Agincourt CI	Agincourt	Agincourt Robotics	Lancer	Scarborough, ON	2004
1247	Labsphere, Inc. & Kearsarge Regional High School & Sunapee Middle/High School	KRHS/SMHS/Labsphere	Robotics of Kearsarge-Sunapee (ROKS)	ROKSbot	North Sutton, NH	2004
1248	Ford Motor Company/SMART Consortium & Midpark High School	Midpark HS Meteors	MHS Robotics		Middleburg Heights, OH	2004
1249	American Electric Power/West Virginia Department of Vocational Education & Mingo Career and Technical Center & Mingo County Schools	Mingo Career Center	Robo Rats	RoboRat 3	Delbarton, WV	2004
1250	Ford Motor Company & Henry Ford Academy & Dearborn High School	Gator-Bots	Gator-Bots	Gator	Dearborn, MI	2004
1251	First Service Realty International/Sonny's Enterprises, The Car Wash Factory & Atlantic Tech Center Magnet HS	ATC Magnet HS	TechTigers	T21v3	Coconut Creek, FL	2004
1254	Hinckley Research & Van Buren ISD	VBTC	VBTC		Lawrence, MI	2004
1255	ExxonMobil Chemical Company/Houston Robotics & Goose Creek CISD & Robert E. Lee High School & Ross S. Sterling High School	Blarglefish	Team Blarglefish	BlargleBot	Baytown, TX	2004
1256	Howell High School	Howell Highlanders	Highlanders	THE REAL MO	Howell, MI	2004
1257	Union County Board of Education	UCVTS Tech and Magnet	Parallel Universe	Vortex	Scotch Plains, NJ	2004
1258	Seattle Lutheran High School	SLHS	Celetor	Harbinger of Sorrow	Seattle, WA	2004
1259	GE Healthcare & Pewaukee High School	Paradigm Shift	Paradigm Shift	PHS 1	Pewaukee, WI	2004
1261	Cognex Corporation/Gwinnett County Schools & Peachtree Ridge High School	PRHS RoboLions	RoboLions		Suwanee, GA	2004
1262	Patrick Henry Community College/American Electric Power/Bassett Furniture, Inc./Hooker Furniture Corporation/CP Films, Inc & Piedmont Governor's School for Mathematics, Science and Technology	pgsmst	The Hatchett	Deloris	Martinsville, VA	2004
1266	San Diego School to Career & Madison High School	Madison Devil Duckies	Madison Devil Duckies	DD3	San Diego, CA	2004
1268	GE Healthcare & Washington High School	GEHC/Purgold Robotics	GEHC/Washington	Twister	Milwaukee, WI	2004
1270	Cuyahoga Community College/Youth Technology Academy & Cleveland Municipal School District	Cleveland/TRI-C/YTA	Red Dragons	Jiffy	Cleveland, OH	2004
1272	Sabin Corporation/Cook Incorporated & Hoosier Hills Career Center	Bloomington Robotics	Tyrannikal Mechanikal	Rex	Bloomington, IN	2004
1274	Ford Motor Company/SMART Consortium & Berea High School	Berea HS Braves	BHS Robotics		Berea, OH	2004
1276	Midcoast School of Technology	Kaizen Blitz	Kaizen Blitz	Fushidara-Kou	Rockland, ME	2004
1277	Siemens & Groton-Dunstable Regional High School & Lawrence Academy	GDRHS/LA/Siemens	Error -1277: Open Connection Request Failed		Groton, MA	2004
1278	Lear Rome & North Royalton High School	North Royalton HS	B.E.A.R.S	Eris - Robot of Chaos	North Royalton, OH	2004
1279	Immaculata High School	IHS	Cold Fusion	Confucius	Somerville, NJ	2004
1280	EMC Corporation & San Ramon Valley High School	Sea Biscuits	Ragin' Sea Biscuits of San Ramon Valley High	Sea Biscuit	Danville, CA	2004
1281	Town of Richmond Hill & Alexander Mackenzie High School	AlexMac	Mustang Robotics		Richmond Hill, ON	2004
1284	Metal Research/NASA & Guntersville High School	D.A.R.T.	Design Applications for Robotics Technology	Zelda	Guntersville, AL	2004
1286	Faurecia Interior Systems - North America Division/Mayo Welding & Robotics Club	OSTC-SE	The "TECH-NO-MANIACS"	MR. ROBOT	Royal Oak, MI	2004
1287	Academy of Arts, Science & Technology	AAST	Aluminum Assault	SPOOKY	Myrtle Beach, SC	2004
1288	Francis Howell District High Schools	RAVEN	RAVEN Robotics	RAVEN 3	Saint Charles, MO	2004
1289	Lawrence High School	Gearheadz-LHSRaytheon	Gearheadz	Alkatras	Lawrence, MA	2004
1290	Si Se Puede & Chandler High School	CHS-Robotics	WolfGang Robotix	1st Realm	Chandler, AZ	2004
1293	D5Robotics : School District Five of Lexington and Richland Counties & Irmo & Dutch Fork & Chapin	D5 Robotics	D5 Robotics	Bob	Columbia, SC	2004
1294	Bezos Family Foundation/Philips Medical/SAE NW Section/Prodotek/Evans Lease & Eastlake High School Robotics & Lake Washington Foundation	EHS Robotics	Top Gun	Top Gun	Sammamish, WA	2004
1295	Albert & Tammy Latner Foundation/Hinds Family/Loewen & Partners/Pinetree Capital & Royal St. George's College	RSGC Golems	The Golems	Robot	Toronto, ON	2004
1296	Dallas Optical Systems/Ultrasound Fluid Technologies & Rockwall High School	UFT/DOS/RHS/JJP	Full Metal Jackets	Schrambo	Rockwall, TX	2004
1301	Bezos Family Foundation/Diggit, Inc. & Nathan Hale High School	Hale	The Robotic Raiders	CA-BOT	Seattle, WA	2004
1302	Loral Space Communications/The Hudson Farm Foundation & Pope John XXIII Regional High School	PoJo 1302	Team Lionheart	The Ark	Sparta, NJ	2004
1303	Casper College/Automation Electronics & Natrona County School District	WYOHAZARD	WYOHAZARD	Quake	Casper, WY	2004
1304	Interlocks/Tulane University/University of New Orleans & New Orleans Charter Science and Mathematics High School	N.O. Sci/Math High	N.O. Botics	Bruce 3.0	New Orleans, LA	2004
1305	Near North Student Robotics Initiative	NNSRI	Ice Cubed	Mammoth	North Bay, ON	2004
1306	GE Healthcare & James Madison Memorial H S	GEHC BadgerBOTS	BadgerBOTS	Epsilon	Madison, WI	2004
1307	University of New Hampshire/FPL Energy/BAE Systems/Janco Electronics & St. Thomas Aquinas High School	St. Thomas Aquinas	Robosaints	STA 1	Dover, NH	2004
1308	EMI Plastics/Keystone Threaded Products & St. Ignatius High School	St. Ignatius Wildcats	Wildcats		Cleveland, OH	2004
1310	TDSB & Runnymede CI	TDSB&RCI	RUNNYMEDE ROBOTICS	INVINCIBLE 1	Toronto, ON	2004
1311	General Electric & Kell High School	Kell	G-Force	GEKoSE	Marietta, GA	2004
1312	Larson/Telesat Canada & Sacred Heart High School	Syntax Error	Syntax Error	ETHOS	Walkerton, ON	2004
1315	DaimlerChrysler St. Louis South Assembly Plant UAW Locals 100& 597/T. M. Engineering, Inc./Dodson Restoration/Tom Dismuke Engineering & Christian Home Educated Students of St. Louis & Pillar Foundation	CHESS	Robo-Knights	Excaliber	Wildwood, MO	2004
1317	The Ohio State University & Educational Robotics of Central Ohio	Digital Fusion	Digital Fusion	SMELBORP	Bexley, OH	2004
1318	Issaquah Schools Foundation & Issaquah High School	ISF/SRS & Issaquah HS	Issaquah Robotics Society	RX-495253	Issaquah, WA	2004
1319	AdvanceSC/Laughlin Racing Products/Sealed Air/Cryovac & Greenville County Schools	Hillcrest &Mauldin HS	Golden Flash	Dualie	Mauldin, SC	2004
1320	Albany International/Gates Rubber Company & Timberland High School & Berkeley High School & Cross High School	Team Work	"Beltway: The Learning Machine"	Beltway:The Learning Machine	St. Stephen, SC	2004
1322	GM/Weber Electric & G.R.A.Y.T. Leviathons	Leviathan's	Genesee Robotics Area Youth Team (GRAYT)	JugHead	Fenton, MI	2004
1323	Berry Construction/FMC Food Tech & Madera High School	FMC/Berry Const./ MHS	MadTown Robotics	Blue Crush	Madera, CA	2004
1324	Bent River Machine, Inc./Northern Arizona University/Phoenix Cement Company/Radio Shack- Camp Verde/Verde Valley Robotics, Inc. & American Heritage Academy & Camp Verde High School & Mingus Union High School & Sedona Red Rock High School & VACTE	Verde Valley Robotics	Sporks	Mousetrap 1	Sedona, AZ	2004
1325	Trinity Development Group & Gordon Graydon Memorial SS	Masters of Obvious	M.O.T.O.	MOTO	Mississauga, ON	2004
1326	FMC Technologies/Houston Robotics/Stress Engineering Services & Cypress Ridge High School	SES/HR/CRHS	Cy-Ridge Robotics	Brutus	Houston, TX	2004
1327	Actuant/Mack Tool Engineering/Notre Dame & South Bend School Corporation	South Bend Robotics	SBOTZ	Puff	South Bend, IN	2004
1329	St. Louis Priory School	Roborebels	Roborebels		St. Louis, MO	2004
1330	TDSB & Sir Robert L Borden Business & Technical Institute	Falcons	Quiet Riot	Falcon	Toronto, ON	2004
1332	Plateau Valley High School	PVHS	S.W.I.F.T.	Project 3	Collbran, CO	2004
1334	Woodbridge Technologies/Aseco Integrated Systems/Hepburn Engineering/OTIS Canada Inc./AECL/Hughes Aero Structures Inc./Susan Dianne Brown, Chartered Accountant/Laker Energy Products LTD. & Oakville Trafalgar High School	O.T.	OTHS robOTics Red Devils	rOTbot	Oakville, ON	2004
1336	Intel Corporation & Lexington School District 1 & White Knoll High School	INTEL/LCSD1	The Untouchables	Elliott	Lexington, SC	2004
1340	JAHS Parent's Association/Josh&Judy Weston Family Foundation&Arthur S. Ainsberg foundation & John Adams High School	John Adams HS	Spartans Warriors	JADY	Queens, NY	2004
1341	Sun Hydraulics Corporation & Cardinal Mooney High School	Knights Who Say "Nee"	The Knights Who Say "Nee"	Killer Rabbit	Sarasota, FL	2004
1343	Desert Vista Technology and Math Departments	DVHS.ENG	DV ROBOTICS	Murdock	Phoenix, AZ	2004
1345	DeVry University & Stranahan High School	DeVry, D&D & SHS	The Platinum Dragons	Steel Dragon	Ft Lauderdale, FL	2004
1346	General Motors Canada & David Thompson Secondary School	GMC/DTSS Vancouver	Trobotics	MAXX	Vancouver, BC	2004
1349	Flandreau Indian School	InterTribal Robotics	Inter-tribal Robotics Group	Injun-uity III	Flandreau, SD	2004
1350	Brown University/Ferguson Perforating & Wire /Raytheon & LaSalle Academy	RaytheonBrownULaSalle	RAMBOTS	RAMBOT III	Providence, RI	2004
1351	Phoenix Technologies & Archbishop Mitty High School	Mitty Robotics	TKO	Mark III	San Jose, CA	2004
1353	Atomic Energy of Canada & Lorne Park Secondary School	Lorne Park Robotics	Spartans	The Botfather	Mississauga, ON	2004
1355	Wescast & F.E. Madill Secondary School	Stallions	Stallions	Iron Stallion Mk I	Wingham, ON	2004
1357	S.A. Robotics/Kimble Precision/General Electric (G.E.)/Thrivrant Financial/Ball Aerospace & Thompson Valley High School	TV Robotics	Eagles	Elmo 3	Loveland, CO	2004
1358	The Macarthur Generals	MacArthur High Scool	The Gerneral	The General	Levittown, NY	2004
1359	Hewlett-Packard/Northwest Industries/Albany Rotary Clubs & BSA Venture Crew 308 & Linn County Schools	Crew 308	Scalawags	Peices of Eight	Albany, OR	2004
1361	American Astronautical Society/Booz, Allen and Hamilton/LSI Logic & Sierra High School	Sierra High School	Nightmares	COMrade	Colorado Springs, CO	2004
1366	West Side High School	Roughriders	wild wild west	panic	Newark, NJ	2004
1367	Barringer High School	Barringer & Tech	Blue BEAR		Newark, NJ	2004
1368	Raytheon & Countryside High School	Robotic  Cougars	Perpetual Motion		Clearwater, FL	2004
1369	Pepsi bottling Company/University of South Florida & Middleton Magnet High School	Middleton HS	Minotaur	Sledgehammer	Tampa, FL	2004
1370	Dupont/MBNA Foundation & Middletown High School	Middletown Robotics	The Blue Charge	Cavilator1370	Middletown, DE	2004
1371	Center for Engineering and Applied Technology	FDHS Astros	The Pink Panthers	Freddy	Atlanta, GA	2004
1372	Mira Mesa High School	Lambda^3	Lambda^3	Steve	San Diego, CA	2004
1373	UCONN & E.O.Smith	Panthers	Spontaneous Combustion		Storrs, CT	2004
1375	Raytheon Company/Northrop Grumman Corporation & Aurora Central High School & Denver School of Science and Technology	Plano Alto Robotics	The Drifters	"Robbie"	Aurora, CO	2004
1377	Thornton Rotary & Bollman Center	btec	BTEC Machines	FUBAR	Thornton, CO	2004
1379	Norcross High School/Nordson Corporation/EMS Technologies/LXE & Gwinnett Co Public Schools	Devil's NET	NET	WAJA	Norcross, GA	2004
1382	Johnson & Johnson & ETEP - Prof. E. Passos Technical High School	J&J BR & ETEP	The Tribotec Team	CRTec 1	Sao Jose dos Campos, SP	2004
1384	Vineland High School	Blacksheep Robotics	Vineland High School Fighting Clan	Quagbot	Vineland, NJ	2004
1386	The Hoover Foundation & Timken Senior High School	Tech Academy	The Trobots	Our Prom Date	Canton, OH	2004
1388	Melfred Borzall & Arroyo Grande High School	Eagle Robotics	Eagle Robotics	Z-¦  (Z-Cubed)	Arroyo Grande, CA	2004
1389	Walt Whitman High School	Robotics	Team Robots	Weird	Bethesda, MD	2004
1390	Disney World/Siemens Building Technologies & Saint Cloud High School	Disney/Siemens & SCHS	WELETHEDAWGSOUT	Sheila	St. Cloud, FL	2004
1391	Vanguard ID Systems & Westtown School	Westtown School	the metal moose	The Metal Moose	Westtown, PA	2004
1392	J. Clarke Richardson Collegiate	JCR Robotics	KINEMATRIX	Jay Cee	Ajax, ON	2004
1394	Burns Engineering & Mastery Charter	Mastery Robotics	THe Juggernaut	TBD	Philadelphia, PA	2004
1396	Councilman Andrew Lanza/Verizon & Tottenville High School	Tottenville Pyrobots	Pyrobots	Hsubot ver.3.0	Staten Island, NY	2004
1397	OPG, /SailRail/Bon-l/Carlyon Drywall & Ajax High School	Ajax Knobotics	Oh!  know	Knowbotic	Ajax, ON	2004
1398	W. J. Keenan High School	Keenan 1398	Robo-Raiders		Columbia, SC	2004
1401	Laureate/FESTO Neumatics & Universidad del Valle de Mexico	UVM - Mekanicats	Mekanicats	Lincerobot 1	Naucalpan, MEX	2004
1402	DeVry University/Phu Space/Walt Disney world & Freedom High School	F.O.R.C.E	Freedom FORCE	Captain Patriot	Orlando, FL	2004
1403	Convatec - Bristol-Myers Squibb  & Montgomery High School	Montgomery HS / BMS	Cougar Robotics	Mad Capper	Skillman, NJ	2004
1404	TDSB & Dr Norman Bethune CI	Bethune	Shadow-Riders	Dark Horse	Toronto, ON	2004
1405	Hoselton/Polyshot & The Charles Finney High School	Falcons Robotics	Falcons Robotics	Charlie II	Penfield, NY	2004
1408	Colorado School of Mines & Jefferson High School	JHS	The Saints	The Saintinator	Edgewater, CO	2004
1410	George Washington High School & Rocky Mountain School of Expeditionary Learning	GW	Patribot	Tlachtli	Denver, CO	2004
1412	Mercedes Benz USA & Hackensack High School	HHS  MetalHeads	The Comet Warriors	The Shooting Star #3	Hackensack, NJ	2004
1413	Mecklenburg Electric Cooperative & Mecklenburg County Public Schools	Circuit Breakers	Skrappy's Crew	Skrappy	Skipwith, VA	2004
1414	Kimberly-Clark Corporation/Siemens/BellSouth Foundation/Microsoft/IBM/Patillo Construction Co./John Whitehead/Cisco/Alcatel/Weatherly Inc./MIKON & Atlanta International School	KC-AIS iHOT	iHOT	Marvin	Atlanta, GA	2004
1415	Bytewise/Pratt & Whitney & Northside High School	P&W-Bytewise-NHS	The Flying Pumpkins	ID: 10T Error	Columbus, GA	2004
1418	Aurora Flight Sciences/Falls Church City Television & George Mason High School	Vae Victus	Vae Victus	Grue	Falls Church, VA	2004
1419	Ontario Power Generation & Courtice Secondary School	OPG & Courtice	Rustic Roboteers		Courtice, ON	2004
1421	Nasa & Picayune High School & Pearl River Central High School	Team Chaos	Pearl River County Robotics	KAT 5	Picayune, MS	2004
1422	CSUF/Grundfos/Pelco & CART	CART	CART-Bot	CART 1	Clovis, CA	2004
1425	Xerox/Mentor Graphics/West Linn Wilsonville School District/City of Wilsonville, Oregon/Tektronix/Tyco Electronics & Wilsonville High School	Wilsonville Robotics	Wilsonville Robotics	Whomper	Wilsonville, OR	2004
1428	Zuni High School	NASA-WSTF/Zuni	T-Birds		Zuni, NM	2004
1429	GE ENERGY/Houston Robotics/ITT Technical Institute & GALENA PARK HS	GPISD ROBOTICS	TEAM KAOS	MR. ROBOTO	Galena Park, TX	2004
1432	Franklin High School	Franklin Robot Team	Franklin Robotics	Unknown	Portland, OR	2004
1436	Springs Industries/UAV Corporation & Fort Mill High School	The Sting	Yellow Jackets		Fort Mill, SC	2004
1437	General Motors Foundation/Val-Tec Hydraulics, Inc & Riverview Gardens	GM/Val-tec Robot Rams	Robot Rams	What?	St. Louis, MO	2004
1438	NASA/Raytheon/MAES & Anaheim High School	Anaheim	The A Team	The Aztech Warrior 3	Anaheim, CA	2004
1444	Beta Sigma Psi Rolla Alumni/Spartan Light Metal Products/CRH Transportation/Arco Construction Co./Trinity Products/Applied Ind. Tech./Engineered Sales & Lutheran High School South	Lutheran H S South	The Lightning Lancers		St. Louis, MO	2004
1446	NASA & NSBE & Friendship Public Charter Schools	Robo-Knights	NASA Robo Knights	Tech-Knight	Washington, DC	2004
1447	Mopar/Tank Truck Service and Sales, Inc & Center Line High School	MOPAR & CENTER LINE	Panther Robotics	Gary the Snail	Center Line, MI	2004
1448	Taylor Products/Ewing Marion Kauffman Foundation/Ducommun Aerostructures/ACE Hardware/Ruskins/Dayton Superior & Parsons High School	Parsons Vikings	October Sky	Rocket Boy R3	Parsons, KS	2004
1449	Hagerstown / Washington County Industrial Foundation, Inc/JERR-DAN Corporation/Longmeadow Rotary Internatinal/The Maryland Space Business Roundtable, Inc./Volvo Powertrain/Washington County Public Schools & Parents and Friends of WHSrobocats & Williamspor	WHS  Robocats	Robocats	KaTastrophy	Williamsport, MD	2004
1450	Xerox Corp & Ben Franklin Educational Campus	XQ Robotix	XQ RobotiX	Rookies Delighted	Rochester, NY	2004
1451	Troy Chamber of Commerce & Triad High School	Triad High School	RoboKnights		Troy, IL	2004
1452	PTC Instruments & Windward School	Windward School	Wildcats		Los Angeles, CA	2004
1456	Intel & Basha High School	Intel & Basha High	GrizzlyBots	InteliBear I	Chandler, AZ	2004
1457	Sierra Nevada Corporation & Coral Academy of Science	Coral Robotics	The Last Barbarians	Yet to come	Reno, NV	2004
1458	Monte Vista High School	NASA/MV Danvillans	Monte Vista Danvillans	Laminiator	Danville, CA	2004
1464	Carroll County Career and Technology Center	Predators	PREDATORS	Alpha 1	Westminster, MD	2004
1466	Webb School of Knoxville	Webb Robotics	Webb Robotics	It Moves!	Knoxville, TN	2004
1467	National Institute of Aeronautics/Core Consulting/The King's Team (FLL Team 3849)/Gooding Construction/Commonwealth Diesel & Home School Robotics Organization, Inc.	HSRO Engineering	HSRO	HERO 3.0	Midlothian, VA	2004
1468	Hicksville High School	HICKSVILLE HS	Hicksville J-Birds	The Swiss Guard	Hicksville, NY	2004
1472	Exxon Chemical Company/High School for Engineering Professions/NASA/Shell Chemical Company & Scotlandville Magnet High School	NASA/SU/Formosa/SMHS	GENESIS		Baton Rouge, LA	2004
1474	Tewksbury Memorial High School	Raytheon-Tewksbury RC	Tewksbury Titans	Atlas	Tewksbury, MA	2004
1476	University Preparatory High School	U Prep High	UPHS		Detroit, MI	2004
1477	Anadarko Petroleum Corporation/BJ Services/Hexion & The Woodlands High School	CISD/APC/BJ	Northside Roboteers		The Woodlands, TX	2004
1480	Houston Robotics/MAES & Jefferson Davis High School	Davis Robotics	JD Squad	Spunky	Houston, TX	2004
1481	Ryder/Link Engineering Company/Akebono/Joe Gyongyosi/Discovery Business Systems Inc./Kawasaki Robobics/DRG DataRecoveryGroup/LOC Federal Credit Union & North Farmington	NFHS	RoboRaiders	Sydney	Farmington Hills, MI	2004
1482	General Motors of Canada & Bishop Grandin High School	GMC & BGHS	Ghosts	Spooky III	Calgary, AB	2004
1484	Bezos Family Foundation/British Petroleum & Hogg Middle School	Hogg Robotics	Hoggzilla	Hoggzilla	Houston, TX	2004
1489	Shuert Industries & Roeper School	Roeper / Shuert	Blood Sweat Gears		Birmingham, MI	2004
1492	Microchip & AZ Community Robotics	Microchip/AZCommunity	Team CAUTION	Homer	Tempe, AZ	2004
1493	National Grid/RPI & Albany High School	RPI & AHS	The Falcons	The Winged Wonder	Albany, NY	2004
1495	Avon Grove High School	AGHS Robotics	AGR	VERTIGO II	West Grove, PA	2004
1496	Colegio Liceo del Valle	LDV	IGUANA #1496	Ecuatron	Quito, PICHINCHA	2004
1500	Tric Tool LTD/Whitson Insulation /Zormot/ITT/Re-Soures Industies/Best Metal Products/North Coast Components/Tas CNC/Randall Tool & Manufacturing/Zatkoff Family Founation/Bond FluidAir Inc & Hudsonville Public   & Jenison Public & Home Schools & Freedom Ba	Hudsonville Robotics	Metal-Morphose		Hudsonville, MI	2005
1501	UTEC/NASA/Wabash Technologies/4H Robotics & Huntington North High School	4H Robotics	Team THRUST	Scorpion	Huntington, IN	2005
1502	ACTI/Ann Arbor Machine/Carter Lumber/Chelsea Comfort Inn and Conference Center/Chelsea Lumber/Chrysler Proving Grounds/Dyntek/Mike-Æs Home Repair/NASA/Putterz & Chelsea High School	Chrysler & Chelsea HS	Technical Difficulties		Chelsea, MI	2005
1503	General Motors - St. Catharines Powertrain & OPG & Westlane Secondary School	GM Spartonics	GM Spartonics	Spartek	Niagara Falls, ON	2005
1504	Dart Foundation/Michigan State University Students/NASA & Grand Ledge High School & Okemos High School	OHS/GLHS/ELHS & MSU	GEOmotion		East Lansing, MI	2005
1506	ABB/Kettering University/Toyota Boshoku America/UPS/Woodbridge Group & North Oakland & Macomb Schools	m^2	Metal Muscle		North Oakland County, MI	2005
1507	Delphi/NASA & Lockport High School	Delphi/NASA/Lockport	Warlocks		Lockport, NY	2005
1508	Ford Motor Company/ArvinMeritor/General Motors & Southwestern HS & Western International HS	RoboWizards	RoboWizards		Detroit, MI	2005
1509	Convergence Education Foundation/Hayes Lemmerz & Ferndale High School	Ferndale- CEF & Hayes	Screamin Eagles		Ferndale, MI	2005
1510	Synopsys/NASA/Beaverton Education Foundation/Intel/Portland Community College & Westview Robotics Team	Westview Robotics	Wildcats	Esteban the Snail	Beaverton, OR	2005
1511	Harris Corporation & Penfield High School	Harris RF & Penfield	Rolling Thunder		Penfield, NY	2005
1512	Criterium-Turner Engineers/Refurbished Equipment Marketplace & St. Paul's School	St. Paul's	St. Paul's School	Blazing Thunder III	Concord, NH	2005
1513	Wunsche Academy	4j2cb	Diablo1		Spring, TX	2005
1514	TDSB & West Humber CI	WHCI	The Vikes		Toronto, ON	2005
1515	Moog Aircraft Group/NASA/Walt Disney Imagineering & Beverly Hills High School	Disney&Beverly Hills	Mortorq		Beverly Hills, CA	2005
1516	ROP & California High School	Shockers	Grizzlies		San Ramon, CA	2005
1517	BAE Systems/Bittware, Inc & Bishop Brady High School	We, Robot	Phi Pi Pho Phun	Robie	Concord, NH	2005
1518	Harbec Plastics & Palmyra-Macedon High School	Harbec Pal-Mac	Ulterior Motive	Ulta-Bot	Palmyra, NY	2005
1519	BAE Systems & Milford Area Youth Homeschoolers Enriching Minds	BAE Systems / MAYHEM	Mechnical Mayhem	Elvis "King of Rack and Rail"2005	Milford, NH	2005
1520	CCNY & HSMSE	Omega - 13	Omega - 13		New York, NY	2005
1522	Sonic Tools & Hanover High School	DOTM1522	Defenders of the Multiverse	Defender One	Mechanicsville, VA	2005
1523	GE Healthcare & Jupiter High School	M.A.R.S.	Mega Awesome Robotic Systems	Ball-istic	Jupiter, FL	2005
1524	NASA/The Stanley Works & E.C.Goodwin Technical High School	ECRobotics	Gladiators		New Britain, CT	2005
1525	Deerfield HS Warbots	Warrior	Deerfield High School Warriors	Warby 2	Deerfield, IL	2005
1527	East county ROP/Nav-Air/Qualcomm/NASA/Ranesco & Granite Hills High School	Granitehills@Navair	Bionic Battalion	tobor II	El Cajon, CA	2005
1528	Tennneco & Monroe County Robotics & Monroe High School	Monroe County Robotic	Mechatrons		Monroe, MI	2005
1529	Fab2Order/NASA/Rolls-Royce & Southport High School	Cyber Cardinals	Southport High School Robotics Team	Lucky	Indianapolis, IN	2005
1531	APW High School & Mexico High School & Oswego County BOCES & Oswego High School & Pulaski Central High School	Oswego County Robots	Team Lake Effect		Mexico, NY	2005
1532	Case Western Reserve University/NASA & SuccessTech Academy	NASA/STA	Tech Ops	Kamikaze	Cleveland, OH	2005
1533	ABCO Automation/Thomas Build Buses/JP Financial/Tyco Electronics/North Carolina A&T State University/RF Micro Devices & The Early College at Guilford	ABCO/TBB/JP/Tyco/A&T	Triple Strange		Greensboro, NC	2005
1537	Hofstra & Uniondale Middle Schools	Knights	Robotic Knights		Uniondale, NY	2005
1538	NASA & High Tech High	NASA & HTH-SD	The Holy Cows	Yoshimi	San Diego, CA	2005
1539	Duke Energy/Process Inovation and Design & Clover School District	C.U.P.I.D	C.U.P.I.D		Clover, SC	2005
1540	Catlin Gabel School	Catlin Gabel	Flaming Chickens	Free Ranger	Portland, OR	2005
1541	Peer Consortium at JTCC/American Electrical Inc./Filtrona Fibertec/Pearson Dealerships/Velocity Micro & Midlothian High School	Midlothian H.S.	MidloCANics	SARTANYAC: Beta project	Midlothian, VA	2005
1543	DisneyWorld & Poinciana High School	PHS and Disney	The Riddler Revolution	The Riddler	Kissimmee, FL	2005
1544	NASA/USKH & Bartlett HS/CIRI Foundation/BP	Ice Bears	Arctic Ice Bears		Anchorage, AK	2005
1546	Baldwin Foundation for Education & Baldwin Senior High School	Baldwin Robotics	Chaos, Inc.		Baldwin, NY	2005
1547	General Motors of Canada & Trafalgar Castle School	GMCL&Trafalgar Castle	Where's Waldo?	Waldo	Whitby, ON	2005
1549	Washtenaw Technical Middle College	ATC	WashtenNuts	Lock-Nut Monster	Ann Arbor, MI	2005
1551	Zoetek Medical Equipment Repair, Inc/Otis Eastern Service, Inc./Pace Window and Door Corp./Skill Glass Inc. of Honeoye/Crosman Corporation/Wende Young, Brenda Keith, Priscilla and Dennis Crawford, Stephanie and Stephen Marshall, John and Janice Murphy, Ja	Naples Robotics	The Green Machine		Naples, NY	2005
1552	Seagate Corp./Front Range Engineering/Lockheed Martin Coherent Technologies Inc./Applied Design/Micro Analysis /Niwot Market/NASA/Xlinx Corp. & Niwot High School	Niwot High School	CougarBots	Cougar Trax	Niwot, CO	2005
1554	Oceanside Union Free School District	Sailors	Oceanside Sailors	Skippy	Oceanside, NY	2005
1555	Leis Machine Shop/NASA/White County Community Foundation & North White High School	Pulse	Pulse - The beating heart of robotics		Monon, IN	2005
1556	Glendale College/NASA & James Monroe High School	Monroe High School	Robo Raiders	Sparky	North Hills, CA	2005
1557	Walt Disney Co./Siemens Corp./Devry University & Lake Technical Center	12 Volt Bolt	Lake County Alliance	LARE	Eustis, FL	2005
1558	TDSB & Albert Campbell CI	Albert Campbell	ACCIdent		Toronto, ON	2005
1559	Corning Tropel & Victor High School	Victor High School	Devil-Tech	Shadow Claw	Victor, NY	2005
1560	Palo Alto Investors & Pinewood School	Pinewood School	RoboPanthers	Lizz	Los Altos Hills, CA	2005
1561	Francis Tuttle / Houston Robotics	Francis Tuttle Tech	Robo Ducks		Oklahoma City, OK	2005
1563	Arts High School	Arts High	Jaguars		Newark, NJ	2005
1564	TDSB & A.Y. Jackson SS	A.Y. Jackson S.S.	J.A.G.S.		Toronto, ON	2005
1566	Idaho State University/NASA Idaho Space Grant/NSF - GK-12 Project/Qwest & Hillcrest High School	AK	AMMOKNIGHTS	Crossbow	Idaho Falls, ID	2005
1567	Bausch&Lomb/M&T Bank & East High School & School Without Walls	Shock-a-Bots	Shock-a-Bots		Rochester, NY	2005
1568	Cooley Group/Raytheon Integrated Defense Systems & Tolman High School	Tolman Tigers	Mechanicatz	Regit Namlot (Reggie)	Pawtucket, RI	2005
1569	Idaho State University/ISU GK-12 Project -  NSF Grant/NASA University Space Grant & School District #25	Haywire Robotics	Haywire		Pocatello, ID	2005
1570	General Motors of Canada & Kitsilano Secondary	Demon Robotics	Demon Robotics	Demon	Vancouver, BC	2005
1571	ITT Technical School/JH Kelly/MicroChip & The Center for Advanced Learning	CAL	Braught Wurst		Gresham, OR	2005
1572	NASA & Construction Tech Academy - Hammer Heads -	Hammer Heads	Team Hammer Heads		San Diego, CA	2005
1573	Elbit Systems & Kfar Galim	KG & Elbit	Kfar Galim		Kfar Galim, NORTHERN	2005
1574	Iscar & Misgav	Iscar & Misgav	Misgav	MisCar	Misgav, NORTHERN	2005
1576	Tel Aviv Municipality & Eroni Chet	Eroni Chet	Eroni Chet		Tel Aviv, TEL AVIV	2005
1577	Clal Industries & Aviv	First-Israel & Aviv	steampunk	snud	Raanana, CENTRAL	2005
1578	Tel Aviv Municipality & Gimnasia Hertzelia	Tel Aviv & GH	Gymbotics	Gymbot	Tel Aviv, TEL AVIV	2005
1579	Tel Aviv Municipality & Shevach Mofet	Tel Aviv & SM	Shevach-Mofet		Tel Aviv, TEL AVIV	2005
1580	Deutsch Dagan & Ort Ronson	Deutsch & Ronson	Ronson		Ashkelon, SOUTHERN	2005
1582	Tadiran Communications & Danziger	Tadiran & Dantziger	Dantziger		Kiryat Shmona, NORTHERN	2005
1583	Ridge View Academy	Rams	Ridge View Academy Rambotix	Rambotix	Watkins, CO	2005
1584	NASA & Nederland Middle/Senior High School	NASA - Nederland H.S.	Nederland Highlanders		Nederland, CO	2005
1585	Alumni/NASA  &  RJCSD	Holzy's Army	H.A. 1585	Holzy	Shortsville, NY	2005
1590	NASA & Lorain Admiral King High School	Admiral King Rambots	Rambots		Lorain, OH	2005
1591	ITT Industries Space System Division & Greece Central High Schools	Space Systems&Greece	Greece Gladiators	Holy Hand Grenade Launcher	Rochester, NY	2005
1592	Analex Corporation & Cocoa High School	Bionic Tiger Robotics	Bionic Tigers	Bob	Cocoa, FL	2005
1594	Hennessy Family Foundation & Brearley School	Hennessy & Brearley	Double X	Entropia	New York, NY	2005
1595	NASA & Saint Georges School	NASA/SGS	Dragons		Spokane, WA	2005
1596	Korah Collegiate  & Sault Area Career Center	Sault Instigators	Twin Saults International Instigators		Sault Ste Marie, MI	2005
1597	IBM /NASA/Verizon & Bronx Aerospace Academy	BlueFalcons	BxAero		Bronx, NY	2005
1598	Danville Public Schools Gifted Resources/Gamewood Data Systems/Barkhouser Ford/Jarrett Welding & George Washington High School	GWHS	Eagles	Talon II	Danville, VA	2005
1599	Infineon Technologies Richmond/Infineon Technologies Richmond  & Atlee High School	Raiders	Hoard Core Raiders	Hoard Core	Mechanicsville, VA	2005
1600	Con Edison & Thomas Jefferson High School Campus	JeffTech	JeffTech		Brooklyn, NY	2005
1601	Devry/Stony Brook & Aviation High School	Quantum Samurai	Quantum Samurai		L.I.C., NY	2005
1602	Ford Motor Company/m80.net/Mill Steel & Consortium College Preparatory High School	NIST/Ford/CCPHS	CougarBots		Detroit, MI	2005
1604	Disney/Town of Harmony & Harmony High School	Harmony/Disney/TFI	The Harmony Hurricanes		Harmony, FL	2005
1605	TDSB & George Harvey CI	George Harvey CI	Project Da Vinci		Toronto, ON	2005
1606	Division Ave. High School	Division Avenue HS	Division Dragons		Levittown, NY	2005
1607	Northrop Grumman Corporation/Summit Instrument Corp & Roosevelt High School and Middle School	RRR	Rough Riders	Rough Rider	Roosevelt, NY	2005
1609	Siemens Energy & Automation, Inc. & Parkway West High School	Siemens/Pkwy West HS	Siemens-West Alliance for Robotic Machines - S.W.A.R.M.	SWARM - II	Ballwin, MO	2005
1610	SCHEV/BAE Systems/Paul D. Camp Community College/International Paper/Hercules, Inc./Hewett's Wood & Sheet Metal LLC/FNS Network/Coggsdale Flooring & Franklin High School	SCHEV/Hrc/IP/BAE/FHS	B.O.T. (Builders of Tomorrow)	Trouble	Franklin, VA	2005
1611	NASA/Temcor/Savannah Technical College & South Effingham High School	Mustangs	Stang's		Guyton, GA	2005
1612	University of South Florida & Nature Coast Technical High School	NCTSHARKS	Robo-Sharks	Bruce	Brooksville, FL	2005
1616	Weequahic High School	indians	weequahic indians		Newark, NJ	2005
1617	Automatic Data Processing/Newark Public Schools/Public Service Gas and Electric/Mercedes Benz, USA/New Jersey Institute of Technology & Malcolm X Shabazz High School	1617	Robo Dogs	Bull Dog One	Newark, NJ	2005
1618	Richland County School District #1 & Columbia High School	Columbia HS	Capital Robotics II		Columbia, SC	2005
1619	Lockheed Martin/NASA/Seagate & Silver Creek High School	LM/Seagate/NASA/SCHS	"Up A Creek" Robotics	Capt Hook	Longmont, CO	2005
1620	OPG - Pickering/Linear Contours & Dunbarton High School	Robolution	Robolution		Pickering, ON	2005
1622	NASA/Northrop Grumman & Poway High School	Poway	Spyder		Poway, CA	2005
1623	Banner Engineering Corp. & Shattuck St. Mary's School	SSM RoboSabres	RoboSabres	BannerBot	Faribault, MN	2005
1624	Columbia River Girl Scout Council	Girl Scouts	The Green Grinches	Max2	Vancouver, WA	2005
1625	NASA Marshall Space Flight Center/Fabricators & Manufacturers Association Foundation/Exelon Nuclear-Byron Generating Station & Winnebago High School	WHS and FMA	Winnovation		Winnebago, IL	2005
1626	St. Joseph's High School	Falcon Robotics	Falcon Robotics		Metuchen, NJ	2005
1629	NASA/Beitzel Corporation & Garrett County Public Schools	Garrett	Garrett Coalition	Meshach	Mchenry, MD	2005
1631	NASA/UNLV & Coronado High School	NASA&UNLV&CHS	Cougars		Henderson, NV	2005
1633	ITT Technical Institute & Tempe High School	RoboBuffs	RoboBuffs	RoboBuff 4	Tempe, AZ	2005
1634	KG Projections, Inc./The First Presbyterian Church of Weatherly & Weatherly School District	RotaryKGProj&WHS	Wreckers		Weatherly, PA	2005
1635	Newtown High School	Technotics	Technotics		Elmhurst, NY	2005
1636	DeVry University & Arvada Senior High School	DeVry & Arvada HS	Reds Robotics		Arvada, CO	2005
1640	Arkema Inc./Analytical Graphics Inc. & Downingtown Area School District	sab-BOT-age	sab-BOT-age	DEW BOT	Downingtown, PA	2005
1641	NASA/Scaled Composites & Mojave High School	Mojave High School	Mojave Robotics	Waldo	Mojave, CA	2005
1642	Houston Robotics/Mouser Electronics/NASA/New York Air Brake TDS Group & Dunbar High School	Dunbar HS Robotics	Neo-no-more		Ft. Worth, TX	2005
1643	Logan Machine Company & Tallmadge High School	BB in B II	Bob's Builders in Black		Tallmadge, OH	2005
1644	California State University,Los Angeles-MEP/Hispanic Egineers National Achievement Awards Corporation/LAUSD "Beyond The Bell"/Mexican American Engineers and Scientists/Raytheon/Society of Hispanic Engineers and Science Students (SHESS)/Society of Hispanic	MAX Q Robotics	Manual Arts Extreme Quadrivium		Los Angeles, CA	2005
1645	Montana Space Grant Consortium/NASA & Butte High School	BHS	Butte Bot Builders	KopperK9	Butte, MT	2005
1646	NASA/Purdue FIRST Programs & Jefferson High School	Jefferson HS	Boiler Precision Guessworks		Lafayette, IN	2005
1647	Lockheed Martin & Lenape Regional Robotics Team	Lenape Regional	Iron Devils	Top Gun	Tabernacle, NJ	2005
1648	Turner Broadcasting, Inc. & Henry W. Grady High School	Turner/Grady HS	Grady Gearbox Gangstaz		Atlanta, GA	2005
1649	Lockheed Martin & Windermere Preparatory School & WPVA	WPS	Lakerbotixs		Windemere, FL	2005
1652	LakeView Technology Academy	LakeView Tech	LakeView Legends		Kenosha, WI	2005
1653	Ewing Marion Kauffman Foundaton & Washington High School	WHS RoboKatz	Washington High School RoboKatz	Psycho Kitty	Kansas City, KS	2005
1654	Aalderink Electric Co./NASA & Phoenix High School	Phoenix High School	The Non Conformants		Holland, MI	2005
1655	NASA/TEDS & Smyth County School Board	SCTC	TEDS		Marion, VA	2005
1656	NASA/University of Pennsylvania Engineering School & The Haverford School	Fords	Fords		Haverford, PA	2005
1657	Vilar International & Mevoot Eron	Mevoot E'Ron	Mevoot E'ron	spira-zur	Kibutz E'in Shemer, NORTHERN	2005
1658	South Tech High School	South Tech	Geeks With Calculators		St. Louis, MO	2005
1660	ConEdison/Steven Institute of Technology & Rice High School & A. Phillip Randoph & The Frederick Douglass Academy	Harlem Knights	Harlem Knights	Manhattan Project	New York, NY	2005
1661	NASA & The Buckley School	Buckley Griffitrons	Griffitons	Griffitron	Sherman Oaks, CA	2005
1662	Jim Elliot Christian High School	Elliot	Raptor Force Engineering	Raptorbot	Lodi, CA	2005
1665	Kaz Inc & Hudson High School	Hudson High School	Weapons of Mass Construction	The Vaporizer II	Hudson, NY	2005
1666	Ewing Marion Kauffman Foundation/NASA & Liberal High School	LHS	Redskins	Pato del Diablo	Liberal, KS	2005
1669	Pioneer Electronics & Cabrillo High School	Cabrillo Jaganators	Pioneer Electronics Long Beach Unified Schools Cabrillo High Jaguars Robotics		Long Beach, CA	2005
1671	Lifestyle Furniture/DDBA/QED Automation LLC/SAF-T-CAB/CV Robotics & Buchanan High School	Buchanan Robotics	"DOC"	"DOC"	Clovis, CA	2005
1672	Mahwah High School Robotics Club	Tbirds	Thunderbirds		50 Ridge Ave.mahwah, NJ	2005
1674	Lake Effect-Onekama Consolidated Schools	Lake Effect	Lake Effect		Onekama, MI	2005
1675	GE Healthcare Technologies/Rockwell Automation/Milwaukee Rotary/NASA/Milwaukee School of Engineering & Lynde and Harry Bradley Technology & Trade School & Rufus King High School	GE/RA/King/B. Tech	The Ultimate Protection Squad	Super Uper	Milwaukee, WI	2005
1676	Mercedes-Benz USA & Pascack Valley Regional High School District	PI-oneer Robotics	The Pascack PI-oneers	To be announced	Montvale, NJ	2005
1677	General Motors/Western Michigan University & KAMSC	KAMSC	Quantum Ninja	RoboBronco	Kalamazoo, MI	2005
1678	Yolo County Schools	EngineeringGeneration	EnGen		Davis, CA	2005
1680	EDS Canada & Fort Erie Secondary School	FESStronics	Fort Erie Secondary School	FESStor	Fort Erie, ON	2005
1682	BP Solar/Moog Inc./NASA & La Sierra HS	La Sierra	Wired Workers	Hal 2	Riverside, CA	2005
1683	Siemens Energy and Automation & Northview HS	TechnoTitans	Techno Titans	Titan002	Duluth, GA	2005
1684	Cypress Computer Systems Inc./Durakon Industries/Mid-States Bolt & Screw Co. & Lapeer East High School	East Alchemists	East Alchemists	Full Metal	Lapeer, MI	2005
1685	Nypro & Worcester Vocational High School	Tech-Know Commandos	Tech-Know Commandos	Tank-Bot	Worcester, MA	2005
1686	Bromberg and Sunstein & Accelerated Learning Laboratory	ALL School	Team Navigator	The Immigrant	Worcester, MA	2005
1688	Port Authority of NY & NJ & Port Richmond High School	Team Stick Shift	Team Stick Shift		Staten Island, NY	2005
1689	ADP & Bloomfield High School	B1naries	B1nary B0ts		Bloomfield, NJ	2005
1690	Rafael & Ort Binyamina	Binyamina	ANTRIKOT		Binyamina, NORTHERN	2005
1691	Montana Space Grant Consortium/NASA & Sidney High School	Revolution 1737	The Magnificant Ones	X-BOT	Sidney, MT	2005
1692	Crenshaw High School	Crenshaw HS	CougarBots	CougarBots	Los Angeles, CA	2005
1693	EMC Corporation/Google & Downtown College Prep	DCP	Robo Lobos		San Jose, CA	2005
1694	Walt Disney World & Dr Phillips High School	Robo Warriors	Walt Disney Robo Warriors		Orlando, FL	2005
1695	NASA/Summit Design and Manufacturing & Capital High School	Summit & Capital HS	Capital High Bruin Crew	Bruster	Helena, MT	2005
1696	NASA & Sun River Valley Science Club	Simms HS	Mech Tiger		Simms, MT	2005
1699	Dominion Nuclear Connecticut Inc. & Bacon Academy	Robocats	Robocat	Robbie	Colchester, CT	2005
1700	IDEO & Castilleja School	Castilleja/IDEO/KPCB	Gatorbotics		Palo Alto, CA	2005
1701	U of D Jesuit High	UDJ and Compuware	RoboCubs		Detroit, MI	2005
1702	U.S. AIRFORCE & CITY HONORS HIGH SCHOOL	LXS	LXS League of Extraordinary Students		Ingelwood, CA	2005
1703	NASA & Rancho Robotic Club	Rancho Rambots	Rambots		Las Vegas, NV	2005
1706	General Motors Wentzville Assembly Plant & Timberland & Holt	Wentzville	IOWNYA		Wentzville, MO	2005
1707	Heinz Foundation & North Hills Senior High	NH Indians	NH Indians		Pghp, PA	2005
1708	Robotics Engineering Excellence/The Future is Mine/The Heinz Endowments & McKeesport Area Technology Center	Natural Selection	Natural Selection	Charles 2	McKeesport, PA	2005
1710	Ewing Marion Kauffman Foundation & Olathe Northwest High School	Kauffman & Olathe NW	The Ravonics Revolution	R.P.M.	Olathe, KS	2006
1712	Lower Merion School District & Lower Merion High School	LMSD & LMHS	Dawgma	Dawgma I	Ardmore, PA	2006
1713	Verizon/New York Air Brake/NASA & Thousand Islands CSD	Thousand Islands CSD	K-Island-Gears	Owen	Cape Vincent / Clayton, NY	2006
1714	NASA/Quad Tech, a Division of Quad Graphics/Pentair Water/Marquette University/MSOE/American Acrylics USA LLC & Team #1675 Ultimate Protection Squad & Thomas More H S	More Robotics	Thomas More Community Robotics Club	Holey Roller	South Milwaukee, WI	2006
1715	NASA/SEW Eurodrive & James F. Byrnes High School & Paul M. Dorman High School & Woodruff High School & R.D. Anderson Applied Technology Center	R.D. Anderson	RDA		Moore, SC	2006
1716	ITT-Technical Institute/NASA/Performance Sciences LLC & Ashwaubenon High	Jaguar Robotics	JagBots	Jagerbot1	Ashwaubenon, WI	2006
1717	NASA/Raytheon & Dos Pueblos High School Engineering Academy	DP Engineering	D'Penguineers	PenguinBot	Goleta, CA	2006
1718	Ford Motor Company/Industrial Extrusion Belting/L & L Products/Morse Metal Fab & Macomb Academy of Arts & Sciences	Ford & MA2S	The Fighting Pi		Armada, MI	2006
1719	NASA/Ginny and Tony Meoli/Constellation Energy Group, Inc./KLMK/National Lumber Company/Kinsley Construction Co Inc/Hollander Dental Practice/Direct Dimensions/Swales Aerospace/Black and Decker Corporation/The Bovis Corporation/Lion Brothers Corporation &	Umbrella Corporation	The Corporation	Phoenix (the robot that arrises out of the ashes)	Brooklandville, MD	2006
1720	Ball State University/NASA & Muncie-Delaware County Schools	MuncieDelawareRobotic	MDBots		Muncie, IN	2006
1721	NASA & Concord High School	CHS & NASA Robotics	Team Apollo		Concord, NH	2006
1722	NASA & Flintridge Preparatory School	Rebel Innovators	Rebel Innovators		La Canada, CA	2006
1723	Ewing Marion Kauffman Foundation & Independence School District	Independence S D	The F.B.I. - FIRST Bots of Independence	Agent X	Independence, MO	2006
1725	Intel/National Grid & Worcester Public Schools	Worcester Girls	Worcester Public School Girls All Star		Worcester, MA	2006
1726	NASA/SSVEC/Thomas McMillan Snap-on Dealer/US Army IEWTD/Westech International & Buena High School	N.E.R.D.S.	Nifty Engineering Robotics Design Squad	MegaMaid	Sierra Vista, AZ	2006
1727	NASA/Goddard Space Flight Center & Dulaney High School	Dulaney Robotics	Lions	Colossus	Timonium, MD	2006
1730	Ewing Marion Kauffman Foundation & Lee's Summit High School	Team Driven	Team Driven	DaNazBot	Lees Summit, MO	2006
1731	NASA & Fresta Valley	NASA/Fresta Valley HS	Fresta Valley Robotics Club	Musketeer	Marshall, VA	2006
1732	NASA/Rockwell Automation/Quad Tech, a Division of Quad Graphics/Titan Inc./Marquette University & Marquette University High School	Hilltopper Robotics	Hilltoppers		Milwaukee, WI	2006
1733	EMC/Quinsigamond Community College & Worcester North High School	North High School	PolarBots	bipolarbot	Worcester, MA	2006
1734	University of West Florida/NASA & Choctawhatchee High School	CHS/UWF Engineering	Team America	Derka Derka	Fort Walton Beach, FL	2006
1735	Nypro & Burncoat High School	Burncoat High	Patriots		Worcester, MA	2006
1736	Caterpillar Inc/NASA & Peoria Heights High School & Dunlap High School & Peoria Christian High School & Woodruff High School	Robot Casserole	Robot Casserole		Peoria, IL	2006
1737	Ewing Marion Kauffman Foundation & Excelsior Spring School Distict	Project eXcelsior	Project X		Excelsior Springs, MO	2006
1739	NASA/University of Illinois & Agape Werks	Chicago Opportunity	Chicago Opportunity		Chicago, IL	2006
1740	Dominion Millstone Power Station & Ledyard High School	LHS	Cyber Colonels	Metal Dragon	Ledyard, CT	2006
1741	NASA/Rolls-Royce & Center Grove School Corporation	Red Alert	Red Alert	The Revolver	Greenwood, IN	2006
1742	Houston Robotics/OU College of Engineering & Moore Norman Technolgy Center	MNTC Robotics	Howling Spotted Ligers		Norman, OK	2006
1743	NASA & City Charter High School	Short Circuits	Short Circuits	110 to ground	Pittsburgh, PA	2006
1744	Seacrest School	Seacrest	Deep Tinkers		Naples, FL	2006
1745	Houston Robotics Organization/ITT Technical Institute/McKool Smith/Richardson Bike Mart/Richardson ISD & J.J Pearce High School	Pearce Robotics	The pros		Richardson, TX	2006
1746	Automation Direct & Forsyth Alliance Robotics Team	Forsyth Alliance	Forsyth Alliance		Cumming, GA	2006
1747	NASA/Purdue FIRST Programs & William Henry Harrison High School	Harrison Robotics	Harrison Boiler Robotics	The Spirit of Luke	West Lafayette, IN	2006
1748	Army Research Laboratory/Northrop Grumman Electronic Systems/NASA/Morgan State University/NASA's Maryland Space Grant Consortium & Dunbar High School & Southwestern High School	Lab Rats	Lab Rats		Baltimore, MD	2006
1750	Advanced Web Systems/Houston Robotics/Oklahoma State University/Ray and Linda Booker & Payne County Area Home Schools	ThunderStorm Robotics	ThunderStorm Robotics		Stillwater, OK	2006
1751	North Atlantic Industries & Comsewogue High School	Comsewogue Robotics	The Warriors	Harbinger	Port Jefferson Station, NY	2006
1752	Ewing Marion Kauffman Foundation & Winnetonka HIgh School	TeamTonka	Tonka	TonkaToy	Kansas City, MO	2006
1753	NASA & Watertown High School Robotics	Gosling Robotics	Goz-Bot		Watertown, WI	2006
1755	Julian High School	ElectroBots	Valence Electrons		Chicago, IL	2006
1756	Caterpillar Inc/NASA & Manual High School & Peoria High School & Peoria Notre Dame High School & Richwoods High School	Argos	Argos		Peoria, IL	2006
1757	NASA & Westwood High School	Westwood (MA) High	Wolverines		Westwood, MA	2006
1758	ESAB Welding and Cutting Products/GE Medical/Honda of South Carolina/Progress Energy/Roche Carolina/Florence Darlington Technical College & Florence School District One	FloBots	FloBots	Brigadier General Hughes	Florence, SC	2006
1759	NASA/Raytheon & El Segundo High School	El Segundo S.T.A.R.S.	Eagles		El Segundo, CA	2006
1760	NASA/Delphi/Dr Richard Lasbury DDS & Taylor Community Schools	Taylor Robotics	Robo-Titans		Kokomo, IN	2006
1761	GE Aircraft Engines/NASA & Lynn Classical High School & Lynn Vocational Technical Institute	Lynn Schools/GE	Lynnbotics		Lynn, MA	2006
1763	Ewing Marion Kauffman Foundation/Midwest Research Institute/RETHINK INK, OPRA & Paseo Academy of Fine and Performing Arts	Paseo Robotics	RoboPirates	TaDah!	Kansas City, MO	2006
1764	EWING MARION KAUFFMAN FOUNDATION & Liberty High School	Liberty High School	De Mortales		Liberty, MO	2006
1765	ERIE 1 BOCES	Erie 1	E1B	BOCESBOTS	Cheektowaga, NY	2006
1766	Columbus Area Career Connection / NASA	Temper Metal	TM		Columbus, IN	2006
1767	Kensington Woods High School	Kensington Woods	Widget Warriors		Howell, MI	2006
1768	NASA & Nashoba Regional HS	Nashoba	Nashoba		Bolton, MA	2006
1769	Ewing Marion Kauffman Foundation & J. C. Harmon High School	Harmon Hawks	Hawks		Kansas City, KS	2006
1770	NASA/Socratic Learning & Simeon Career Academy	Simeon Wolverines	Alpha Woverines		Chicago, IL	2006
1771	North Gwinnett H.S.	North Gwinnett	No Disassemble	OBOB	Suwanee, GA	2006
1772	Carlos Becker Metalurgica Industrial Ltda/General Motors do Brasil Ltda/Prefeitura de Gravatai &   Prefeitura de Gravatai & Estate High School Heitor Villa Lobos & SCOUNIAFE	heitortec	heitortec	Gravatai 1	gravatai, RS	2006
1775	Ewing Marion Kauffman Foundation & Lincoln College Preparatory Academy	Lincobotics	Tigerbytes	Ockham	Kansas City, MO	2006
1776	Ewing Marion Kauffman Foundation & DeLaSalle Education Center/Kobets High School	Kauffman/Kobets HS	Cardinals		Kansas City, MO	2006
1777	Ewing Marion Kauffman Foundation & Shawnee Mission West High School	SMW Viking Robotics	Valkyrie Vikings		Overland Park, KS	2006
1778	NASA & Mountlake Terrace High School	Mountlake Terrace HS	Hawks	Herky01	Mountlake Terrace, WA	2006
1779	Richard & Susan Smith Family Foundation/Boston University & Excel High School	Excel Robotics	Excel Robotics	Old Dirty Bot	South Boston, MA	2006
1780	Broadbent & Associates/NASA/Valley Bank & Basic High School	Basic NASA Robotics	Wolves Robotics		Henderson, NV	2006
1781	NASA & Lindblom Math and Science Academy	Electric Eagles	Eagle-Bots		Chicago, IL	2006
1782	Ewing Marion Kauffman Foundation & Raytown High School	RAYTOWN BLUEJAYS	BLUEJAYS		RAYTOWN, MO	2006
1783	NASA & Ogemaw Heights High School	NASA Ogemaw Heights	Falcon Firebots		West Branch, MI	2006
1784	NASA/Litchfield Education Foundation/SSyD/Terrasyn Group, Inc./Keller USA & Litchfield High School	Litchfield HS	litchbots	Roboshizzle	Litchfield, CT	2006
1785	Ewing Marion Kauffman Foundation/GE Transportation Global Signaling  & Blue Springs South High School	Kauffman/GE/BSSHS	JagWired	80HD	Blue Springs, MO	2006
1787	NASA & Orange High School	OHS	Lions		Pepper Pike, OH	2006
1788	GE Power Systems/Kimberly Clark/NASA & Southside Comprehensive High School	The LASERS	The LASERS	Eagle I	Atlanta, GA	2006
1789	NASA & west grand mustangs	Rage against Machine	Steal horses		Kremmling, CO	2006
1791	Godwin Pumps/NASA & Clayton HS	Clayton HS	T.O.P. Hatters	Odd Job B.O.B.	Clayton, NJ	2006
1793	Old Dominion University/Scientific Applications International Corporation and American Systems Engineering Corporation/National Air and Space Administration & Norview High School	The Pilots	The Pilots	Spanky the Robot	Norfolk, VA	2006
1794	Central Pattern Co/NASA/Rolla Alumni of Beta Sigma Psi & Lutheran High North	Crusaders	N.I.R.D.		St. Louis, MO	2006
1795	Coca Cola/Johnson Research Development/Arthur Blank Foundation & School of Technology at Carver	SOT Technobots	SOT3 Triple Threat Technobots	Will	Atlanta, GA	2006
1796	NASA & Queens Vocational and Technical HS	SCEETERS	ROBOTIGERS	Robotiger	LongIsland City, NY	2006
1798	NASA Langley Research Center & Flowing Wells High School	NasaCaballeros	NasaRoboKnights		Tucson, AZ	2006
1799	NASA & Dakota Ridge High School	Hog Back	Happy Hog Back		Littleton, CO	2006
1800	Ewing Marion Kauffman Foundation & Bonner Springs High School	BSHS Hot Tamales	Hot Tamales	Optimus Prime	Bonner Springs, KS	2006
1801	NASA & Kountze High School	Kountze HS	The Dapper Dans	Dapper Dan	Kountze, TX	2006
1802	Ewing Marion Kauffman Foundation & Piper High School lPhysics Club	Piper	Stealth	Night Hawk	Kansas City, KS	2006
1803	Port Washington Public Schools	Port Vikings	Vikings		Port Washington, NY	2006
1804	Ewing Marion Kauffman Foundation & Oak Park High School	Oak Park High School	Northmen		Kansas City, MO	2006
1805	Burns and McDonnel/Ewing Marion Kauffman Foundation/State Street Investments & Central High School House of Technology	KC HOT BOTS	HOT BOTS	Alphie	Kansas City, MO	2006
1806	Ewing Marion Kauffman Foundation & Smithville High Tech Group	SHS WARRIORS	WARRIORS		SMITHVILLE, MO	2006
1807	Bristol-Myers Squibb/NASA/TAH Industries & Allentown High School	Allentown Robotics	Allentown robotics		Allentown, NJ	2006
1808	Freeport High School	Red Devils	Red Devils		Freeport, NY	2006
1810	Ewing Marion Kauffman Foundation & Mill Valley High School	Jag Robotics	Jaguars		Shawnee, KS	2006
1811	East Side High School	X-Virtual	X-Virtual	Loonatic	Newark, NJ	2006
1813	ADP/Mercedes Benz/New Jersey Institute of Technology/PES&G & NEWARK PUBLIC SCHOOLS	team PB & J	Roboegal	brian	Newark, NJ	2006
1814	TDSB & Northview Heights SS	Northview Heights SS	Northview Heights		Toronto, ON	2006
1815	TDSB & Sir John A Macdonald CI	Macdonald CI	Team Sigma		Toronto, ON	2006
1816	NASA/Medtronic/Edina Education Fund/Cooper Research, LLC/Big Image Corporation/Kaemmerer Group & Edina High School	Edina Robotics Team	Edina Robotics Team		Edina, MN	2006
1817	Texas Tech University/Bezos Foundation/NASA & Estacado HS & Lubbock HS & Monterey HS	LISD & Bezos/NASA/TTU	8-bit Battalion		Lubbock, TX	2006
1818	AEP SWEPCO/General Motors Shreveport Assembly Plant/NASA/Service Electric & LSUS & Southwood High School	Southwood High School	Cowboys		Shreveport, LA	2006
1820	Intelligent Automation, Inc./KRM Enterprises/Materials Handling Systems, Inc./Planet Technologies/Science Applications International Corporation/Visio Wave, Inc.-GE & Magruder High School	Team R.O.N.	Team R.O.N.	ChuckNorris	Rockville, MD	2006
1823	NASA & Lincoln High School	ping nasa	ping	ping nasa lincoln hs	portland, OR	2006
1824	NASA/Warwick Mills & Region 14 ATC	region14techcenter	atc14		Peterborough, NH	2006
1825	Ewing Marion Kauffman Foundation/Metro Academy & Johnson County Homeschool	JCH Robotics	JCH Robotics		DeSoto, KS	2006
1826	Electric Power Training Center/NASA & Faith Christian Academy	FCA	Team 1826, The Fuse	Eaglebot	Arvada, CO	2006
1827	EWING MARION KAUFFMAN FOUNDATION & Center High School	CHS Robo-Techs	Robo-Techs		Kansas City, MO	2006
1828	NASA & Vail High School	Vail High School	BoxerBots	NASA/Boxer1	Vail, AZ	2006
1829	NASA/Computer Systems Corporation & Arcadia High School	Firebots	'Da Bots	Twisted Transistor	Oak Hall, VA	2006
1830	Old Dominion University/NASA/Norfolk State Universtiy/Norfolk State University  & Booker T Washington High School	The Dynasty	The T.	Don Vito	Norfolk, VA	2006
1831	NASA/Freudenberg-NOK/Northeast Powder Tech  & Gilford High School	GIlford High School	Screaming Eagles		GIlford, NH	2006
1834	Google/NASA Robotics Education FIRST Sponsorship Program/San Jose Job Corps/MetroED & SIATech	siatechroboticsanjose	Evolution	EVO	San Jose, CA	2006
1835	TDSB & RH King Academy	RH King Academy	RH King Academy	Kingasaurus Wrecks	Toronto, ON	2006
1836	NASA & High Tech High LA Team # 4 & Mitchell Science Academy	MCHS Robotics	MCHS Robotics		Los Angeles, CA	2006
1837	Ford Motors & LouisianaTechnical College & Madison High School	Madijags	Madi		Tallulah, LA	2006
1838	Brigham Young University - Idaho/NASA & Madison High School	Madison High School	Madison		Rexburg, ID	2006
1839	Brigham Young University - Idaho/NASA & South Fremont High School	Techattack	Techattack	Sparky	Saint Anthony, ID	2006
1840	Brigham Young University - Idaho/NASA & Sugar-Salem High School	Sugar-Salem	Diggers	Excavator	Sugar City, ID	2006
1841	NASA & south plantation high school	paladins	robo knights		plantation, FL	2006
1842	Indian River Community College/CL Technologies & Centennial H.S. & Central H.S. & Lincon Park Academy & Port St. Lucie  H.S. & Westwood H.S.	SLC Robotics	Twisted E.G.O.	Vyrus	Fort Pierce, FL	2006
1843	Brigham Young University - Idaho/NASA & Rigby High School	Rigby High School	Trobots	Trojan One	Rigby, ID	2006
1845	UPS/NASA & D. M. Therrell High School	Cyber Panthers	Cyber Panthers		Atlanta, GA	2006
1846	Ecole secondaire Saint-Francois-Xavier	sfx	xaviermania	Elmo	Sarnia, ON	2006
1847	Ewing Marion Kauffman Foundation & Wyandotte High School	Wyandotte	Bulldogs		Kansas City, KS	2006
1848	Forsyth Alliance/Automation Direct/Wheeler CircuitRunners & Georgia Robotics Alliance	Georgia Alliance	GRA		Marietta, GA	2006
1849	NASA & Bell Multicultural HS	Bell Multicultural HS	Griffins	Mrs. Schmitz	Washington, DC	2006
1850	NASA & ACE Technical High School	ACE Tech Robotics	New Era of 1850		Chicago, IL	2006
1851	William C. Bannerman Foundation & Robert H. Lewis High School	Manic Mechanics	Manic Mechanics		Sun Valley, CA	2006
1852	NASA/INTEL & Desert Mountain High School	Team Amore	Team Amore		Scottsdale, AZ	2006
1853	Ewing Marion Kauffman Foundation - Ruskin High School	EMK Ruskin Robotics	Ruskin Eagles	Screeming Eagle	Kansas City, MO	2006
1855	Magnolia Science Academy	MSA Robotics Team	Robo Team	Mr. Roboto	Reseda, CA	2006
1856	NASA & Michigan Technical Academy	MTA HS	Gear Heads		Romulus, MI	2006
1858	Lockheed Martin Michoud Space Systems/NASA & Salmen High School	Mighty Spartans	Spartans	Obsidian	Slidell, LA	2006
1859	Lockheed Martin/NASA & Bogalusa High School	Almost Genious	Insane	Pi-ro	Bogalusa, LA	2006
1860	Johnson & Johnson  & CEPHAS - H.A.Souza Professional Training Center	J&J & CEPHAS	CEPHAS		Sao Jose dos Campos, SP	2006
1861	NASA & Smoky Hill High School	Smoky Hill & NASA	Smoky & NASA		Aurora, CO	2006
1862	21st Century & Cliffside Park High School	Red Knights	Red Raiders	One Knight	Cliffside Park, NJ	2006
1863	NASA & Tulsa High School for Science and Technology	Titan 7	T7		Tulsa, OK	2006
1864	Bentley World Packaging/Briggs & Stratton/CG Schmidt Construction, Inc./Marquette University/Milwaukee School of Engineering & Messmer High School	Messmer	Bishops		Milwaukee, WI	2006
1865	CSTEM/NASA/Shell Oil & Thurgood Marshall High School	Y.E.S.	Young Engineers Succeeding	The K2006	1220 Buffalo Run, TX	2006
1866	NASA & Joseph Case High School	The Cardinals	The Cardinals		Swansea, MA	2006
1867	C-STEM Teacher & Student Support Services, Inc./Shell & Phillis Wheatley High School	Wildcats	The Prowlers	RoboCat	Houston, TX	2006
1868	NASA Ames Research Center & Girl Scouts of Santa Clara County & Harbor High School	Ames Girl Scouts	Space Cookies		Moffett Field, CA	2006
1870	NOVA Chemicals & Hunting Hills High School	Team Lightning	Greased Lightning	thundervolt	Red Deer, AB	2006
1871	NASA & Charles City High School	Charles City	Panter Machine	SWAT	CHarles City, VA	2006
1872	NASA/Janssen Ortho, LLC & Colegio San Ignacio de Loyola & CSI Computer Club	Colegio San Ignacio	CSI	El Jibarito	San Juan, PR	2006
1873	AON/NASA & Rock Bridge High School	Columbia Robotics	CRT		Columbia, MO	2006
1875	NASA & Space Coast Jr/Sr High School	Category VI	Cat VI		Cocoa, FL	2006
1876	NASA/Hargray/Liberty Fellowship/Palmetto Vision Foundation & Hilton Head High School & Hilton Head Preparatory School	NASA BeachBotics	BeachBotics		Hilton Head Island, SC	2006
1877	NASA & Lumpkin County High School	Lumpkin County Miners	Gold Diggers		Dahlonega, GA	2006
1879	Armstrong Engineering Consulting/NASA & Minor High School	Minor High School	Minor High School		Adamsville, AL	2006
1880	East Harlem Tutorial Program/NASA & Central Park East High School	East Harlem Tech	EHT		New York, NY	2006
1881	ADP/BMW of NA/NJCDC/NASA & NSBE - PTGI Chapter	Garrett Morgan Academ	GMA	G-Man	Paterson, NJ	2006
1882	Howell High School_NASA	Rebel Robotics	Rebel Alliance		Farmingdale, NJ	2006
1883	NASA/UNLV & Del Sol High School	Del Sol	Dragons	The Enterprise	Las Vegas, NV	2006
1884	QK & The American School in London	ASL-QK	Griffins	Beasty McBeast Beast	London, UK	2006
1885	Lockheed Martin/TKC Communications/TKC Global Solution/NASA/DeVry University/Aurora Flight Sciences & Battlefield High School	Battlefield Robocats	Robocats	RoboCat	Haymarket, VA	2006
1886	NASA & Urbana High School	S.T.U.D.S.	Super Team Under-Dog Squad	Hawky	Ijamsville, MD	2006
1887	Idaho State University/NASA & Shelley High School	Shelley Robotics Club	Russet Robotix	Burbank	Shelley, ID	2006
1888	Houston Robotics/ITT/NASA & Plano West Senior High	West Robotics	West Robotics	1337607	plano, TX	2006
1889	NASA & Blanche Ely High School & Palm Beach Central HIgh School & Park Vista High School	Xbot 360	Xbot 360	Wilma	Wellington, FL	2006
1890	NASA/DuPont Sontara Technologies & Martin Luther King Jr Academic Magnet & Stratford Comprehensive High School	SEMAA Engineers	EOT		Nashville, TN	2006
1891	Micron Technology/NASA & Mountain View High School	Epicus Furor	Mavericks	The Bull	Meridian, ID	2006
1893	Morgan State University/NASA & Baltimore Polytechnical Institute	Poly Tech	Parrots		Baltimore, MD	2006
1894	Datta Consultants, Inc./EA Engineering Science and Technology/Maryland Space  Grant Consortium/Morgan State University/NASA & WEB DuBois High School	Algorithm Masters	Algorism	Mastermind	Baltimore, MD	2006
1895	Lockheed Martin & Osbourn High School	OHS-ScienceTeam lamda	lamdaCorps	The Crushinator	Manassas, VA	2006
1896	NASA/Interface Innovations/Castaing Family Foundation/Butch Broad/Traverse Bay Area Intermediate School District & Manufacturing Technology Academy & SCI-MA-TECH Traverse City Central High School	Xodus	Xodus		Traverse City, MI	2006
1897	NASA & South Valley Academy	SVA	SVA		Albuquerque, NM	2006
1898	C-STEM/NASA & Westside High School	Westside Wolves	Wolves		Houston, TX	2006
1899	NASA & Interlake High School	Saints Robitcs	Saints		Bellevue, WA	2006
1900	NASA & T. Roosevelt Senior High School	Roosevelt	Rough Riders		Washington, DC	2006
1901	INNO-TECH & St. Marys DCVI	St. Marys High School	Ramrod	She Thinks My Robot's Sexy	St. Marys, ON	2006
1902	Siemens Power Generation & Winter Park High School	Exploding Bacon	Mad Techs		Winter Park, FL	2006
1904	Morgan State University/NASA & Homeland Security High School	Hawks	Homeland		Baltimore, MD	2006
1905	Ewing Marion Kauffman Foundation/University of Missouri-Rolla & Alta Vista High School	Alta Vista	KCbotics	AzTech 1905	Kansas City, MO	2006
1906	Roy High School & Weber High School	We Be Roybot	WRoyBot		Roy, UT	2006
1907	Prince Edward High School	PEHS SCHEV	Eagles	Feathers	Farmville, VA	2006
1908	Northampton High School	NHS	Yellow Jackets		Eastville, VA	2006
1909	Smith Family Foundation & Parkway Academy of Technology and Health	PATH	PATH		Boston, MA	2006
1910	Ewing Marion Kauffman Foundation & Rockhurst High School	Rockhurst Robots	Hawlets		Kansas City, MO	2006
1911	Eagle Rider Motorcycle Rental/NASA/Triangle Ag-Services & Fort Benton High	Cold Steel	Longhorns	Billy	Fort Benton, MT	2006
1912	Lockheed Martin/NASA & North Shore High school	Northshore Krewe	Northshore Krewe	Rex	Slidell, LA	2006
1913	Lockheed Martin/NASA & Covington High School	Lockheed & Covington	Guttabots		Covington, LA	2006
1915	Nasa & McKinley Technology High School	MTHS Robotics	MTHS Robotics		Washington, DC	2006
1916	Madison Park Tech Voc High School	Madison Park	MAD PARK Robotics	The MP Machine	Roxbury, MA	2006
1917	Embry-Riddle/NASA & Tri City College Preparatory High School	TriCityPrep/ERAU/NASA	T.O.M. (Teckies Operating Machinery)	J.E.R.R.Y. (Jerry-rigged  Electronically Regulated Robotic Yak)	Prescott, AZ	2006
1918	DaimlerChrysler/ITT  & Fremont High School	Pack-Mon	Pack-Mon		Fremont, MI	2006
1919	Boston University/Smith Family Foundation & Monument High School	Southie Knights	The Knights		South Boston, MA	2006
1920	BLAST Foundation/Intralox/Lockheed Martin/NASA & New Orleans Public Schools	New Orleans Robotics	N.O. Storms	Katrina	New Orleans, LA	2006
1922	Osram-Sylvania & Hopkinton Middle High School & John Stark High School	OZ-Ram	OZ-Ram	Tin Man	Contoocook/Weare, NH	2006
1923	NASA & West Windsor-Plainsboro High School North	Knights	Black Knights of Machina		Plainsboro, NJ	2006
1925	NASA & New Community Jewish High School	Jagwires	Jags		West Hills, CA	2006
1926	Microchip technology/NASA & Chinle High School	Navajo Heroes	In memory of Navajo Heroes	Soldiers Todacheene, Shondee, Kieth, Cambridge, Piestewa	Chinle, AZ	2006
1927	Joe's Garage/NASA & Mercy Cross High School	MCHS	Tempest	Cornelius	Biloxi, MS	2006
1929	Credit Suisse & Montclair Board of Education	MHS Girl's Team 1929	MHS Ladybots	none yet	Montclair, NJ	2006
1930	Rush Henrietta	Delta Force	Delta Force		Henrietta, NY	2006
1931	BAE & Passaic Valley Regional High School	Passaic Valley	Hornets		Little Falls, NJ	2006
1932	Montana Space Grant Consortium /NASA/Johnson Madison Lumber Company/Big R Stores & Great Falls Public Schools	RoboRustlers	RoboRustlers	IT	Great Falls, MT	2006
1933	Doncaster Aimhigher	The Dons	The Dons		Doncaster, UK	2006
1934	Heart of London	London-AI	AI		London, UK	2006
1935	University of Toronto Schools	UTS Robotics	Team Happycat		Toronto, ON	2006
1937	Israel Aircraft Industries & Makabim Reut	Makabim Reut	Elysium	Noni	Reut, Central	2006
1938	NASA & Manhattan High School	Manhattan High School	Manhattan High School		Manhattan, MT	2006
1939	Ewing Marion Kauffman Foundation & The Barstow School	Barstow Knights	Knights	Galahad	Kansas City, MO	2006
1940	Benton Harbor High School	BHHSWhirl-Hut	Tigers		Benton Harbor, MI	2006
1941	D.R.M. Stakor and Associates/Daimler Chrysler/ITT Technical Institute/Shelby Lawhorn & Friends & Frederick Douglass College Preparatory Academy	Fred D.	Hurricanes		Detroit, MI	2006
1942	Israel Air force & ORT Tel-Nof H.S.	ORT Tel-Nof	Tel-Nof	sinderela	Tel-Nof, Central	2006
1943	RoboGroup & Begin High School	Begin High School	Neat Team	Hoborg	Rosh Hayin, Central	2006
1944	Israel Air Force & Technical Airforce H.S.	Airforce High School	Airforce High School	Alpha	Haifa, Haifa	2006
1945	Ort Nazareth High School	Most Wanted Robotics	Most Wanted Robotics		Nazareth, Northern	2006
1946	OPGAL OPTRONIC INDUSTRIES & Abu Roomi	Abu Romi	Abu Romi		Tamara, Northern	2006
1947	American Israeli Paper Mills & Sciences & Arts Amal1 H.S.	Sciences & Arts H.S.	Sciences & Arts H.S.		Hadera, Central	2006
1948	Cellcom & Ort Shapirah High School	Ort Shapirah	Ort Shapirah		Kfar Saba, Central	2006
1949	Shapira, Natanya H.S.	Shapira	shapira		Natanya, Central	2006
1950	Emek Hefer High School	Emek Hefer	Emek Hefer		Emek Hefer, Northern	2006
1951	Tel Aviv Municipality & Ort Singolovsky	Ort Singolovsky	Ort Singolovsky		Tel Aviv, Tel Aviv	2006
1952	Arming force H.S.	Arming High School	Arming High School		tzrifin, Central	2006
1954	E'roni z	E'roni z	E'roni z		Beer Sheva, Southern	2006
1955	Beit Yerah	Beit Yerah	Beit Yerah		Emek Hayarden, Northern	2006
1956	Hoom El Phachem	Hoom El Phachem	Hoom El Phachem		Hoom El Phachem, Northern	2006
1957	Nofey Golan	Ort Nof Golan	Ort Nof Golan		Katzerin, Northern	2006
1959	F/N Manufacturing/Siemens Corporation & Richland School District 2	RSD2 Siemens Corp.	Aye, Aye, Robot		Columbia, SC	2006
1960	NASA & Darby High School	Darby High	GO DARBY!		Darby, MT	2006
1961	Greenville Senior High School	GreenvilleSeniorHigh	GreenvilleSeniorHigh	Red Raider	Greenville, SC	2006
1962	Smith Family Foundation & East Boston High School	East Boston	East Boston		Boston, MA	2006
1963	Peter Symonds College	PSC Robotics	PSC Robotics		Winchester, UK	2006
1965	Smith Family Foundation & Mount Saint Joseph Academy	Smith Family & MSJA	The Schematics		Brighton, MA	2006
1966	Hellgate High School	Knights	Knights		Missoula, MT	2006
1967	Google & Notre Dame High School	Google Notre Dame	RoboRegents		San Jose, CA	2006
1970	Google & East Palo Alto High School	Bulldog Robotics	Bulldogs	Bulldog	Menlo Park, CA	2006
1972	Imperial Valley MESA Program	MESA Imperial Valley	MESA IV		El Centro, CA	2006
1973	Smith Family Foundation of Boston & Brighton High School	BRIGHT BURNING TIGERS	BBT'S	TIGGER 2006	Boston, MA	2006
1974	Google & Weber Tech	Weber Tech	Weber Tech	C.A.R.L.	Stockton, CA	2006
1975	Akamai Foundation & FontBonne Academy	QUEEN	QUEEN	Killer Queen	Millton, MA	2006
1976	AEP/Ethicon & Eden High School	Eden High School	The Missing Lynx	Bendar Bot 902107	Eden, TX	2006
1977	Loveland High School & Surrey Robotics	Loveland High School	Virtual Commandos	Uno	Loveland, CO	2006
1978	NASA/Honeywell Int. & Barry Goldwater High School	Goldwater Robotics	Bulldogs	Percy	Phoenix, AZ	2006
0	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: team_score; Type: TABLE DATA; Schema: public; Owner: TacOps
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
\.


--
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: TacOps
--

COPY test (id, name) FROM stdin;
1	yo poppa
190	WPI
42	meaning of life
2	Piotr sucks
\.


--
-- Name: alliance_team_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY alliance_team
    ADD CONSTRAINT alliance_team_pkey PRIMARY KEY (match_level, match_number, match_index, alliance_color_id, "position");


--
-- Name: color_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY color
    ADD CONSTRAINT color_pkey PRIMARY KEY (color_id);


--
-- Name: display_component_effect_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY display_component_effect
    ADD CONSTRAINT display_component_effect_pkey PRIMARY KEY (effect_label, substate_label, component_label, keyframe_index);


--
-- Name: display_effect_option_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY display_effect_option
    ADD CONSTRAINT display_effect_option_pkey PRIMARY KEY (effect_label, substate_label, component_label, keyframe_index, "key");


--
-- Name: display_state_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY display_state
    ADD CONSTRAINT display_state_pkey PRIMARY KEY (state_label, substate_label, display_type_label);


--
-- Name: display_substate_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY display_substate
    ADD CONSTRAINT display_substate_pkey PRIMARY KEY (substate_label);


--
-- Name: display_type_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY display_type
    ADD CONSTRAINT display_type_pkey PRIMARY KEY (display_type_label);


--
-- Name: event_preference_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY event_preference
    ADD CONSTRAINT event_preference_pkey PRIMARY KEY (preference_key);


--
-- Name: finals_alliance_partner_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY finals_alliance_partner
    ADD CONSTRAINT finals_alliance_partner_pkey PRIMARY KEY (finals_alliance_number, recruit_order);


--
-- Name: finals_alliance_partner_team_number_key; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY finals_alliance_partner
    ADD CONSTRAINT finals_alliance_partner_team_number_key UNIQUE (team_number);


--
-- Name: game_match_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY game_match
    ADD CONSTRAINT game_match_pkey PRIMARY KEY (match_level, match_number, match_index);


--
-- Name: game_state_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY game_state
    ADD CONSTRAINT game_state_pkey PRIMARY KEY (state_label);


--
-- Name: match_level_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY match_level
    ADD CONSTRAINT match_level_pkey PRIMARY KEY (match_level);


--
-- Name: match_status_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY match_status
    ADD CONSTRAINT match_status_pkey PRIMARY KEY (status_id);


--
-- Name: score_attribute_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY score_attribute
    ADD CONSTRAINT score_attribute_pkey PRIMARY KEY (score_attribute_id);


--
-- Name: team_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY team
    ADD CONSTRAINT team_pkey PRIMARY KEY (team_number);


--
-- Name: team_score_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY team_score
    ADD CONSTRAINT team_score_pkey PRIMARY KEY (match_level, match_number, match_index, alliance_color_id, "position", score_attribute_id);


--
-- Name: test_pkey; Type: CONSTRAINT; Schema: public; Owner: TacOps; Tablespace: 
--

ALTER TABLE ONLY test
    ADD CONSTRAINT test_pkey PRIMARY KEY (id);


--
-- Name: delete; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE "delete" AS ON DELETE TO test DO NOTIFY test;


--
-- Name: delete4ondeck_match; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE delete4ondeck_match AS ON DELETE TO game_match DO NOTIFY ondeck_match;


--
-- Name: delete4participant_results; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE delete4participant_results AS ON DELETE TO game_match DO NOTIFY participant_results;


--
-- Name: delete4participant_results; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE delete4participant_results AS ON DELETE TO alliance_team DO NOTIFY participant_results;


--
-- Name: delete_notify; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE delete_notify AS ON DELETE TO game_match DO NOTIFY game_match;


--
-- Name: delete_notify; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE delete_notify AS ON DELETE TO alliance_team DO NOTIFY alliance_team;


--
-- Name: delete_notify; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE delete_notify AS ON DELETE TO finals_alliance_partner DO NOTIFY finals_alliance_partner;


--
-- Name: delete_notify; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE delete_notify AS ON DELETE TO display_component_effect DO NOTIFY display_component_effect;


--
-- Name: insert; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE "insert" AS ON INSERT TO test DO NOTIFY test;


--
-- Name: insert4ondeck_match; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE insert4ondeck_match AS ON INSERT TO game_match DO NOTIFY ondeck_match;


--
-- Name: insert4participant_results; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE insert4participant_results AS ON INSERT TO game_match DO NOTIFY participant_results;


--
-- Name: insert4participant_results; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE insert4participant_results AS ON INSERT TO alliance_team DO NOTIFY participant_results;


--
-- Name: insert_notify; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE insert_notify AS ON INSERT TO game_match DO NOTIFY game_match;


--
-- Name: insert_notify; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE insert_notify AS ON INSERT TO alliance_team DO NOTIFY alliance_team;


--
-- Name: insert_notify; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE insert_notify AS ON INSERT TO finals_alliance_partner DO NOTIFY finals_alliance_partner;


--
-- Name: insert_notify; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE insert_notify AS ON INSERT TO display_component_effect DO NOTIFY display_component_effect;


--
-- Name: update; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE "update" AS ON UPDATE TO test DO NOTIFY test;


--
-- Name: update4ondeck_match; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE update4ondeck_match AS ON UPDATE TO game_match DO NOTIFY ondeck_match;


--
-- Name: update4participant_results; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE update4participant_results AS ON UPDATE TO game_match DO NOTIFY participant_results;


--
-- Name: update4participant_results; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE update4participant_results AS ON UPDATE TO alliance_team DO NOTIFY participant_results;


--
-- Name: update_notify; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE update_notify AS ON UPDATE TO game_match DO NOTIFY game_match;


--
-- Name: update_notify; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE update_notify AS ON UPDATE TO alliance_team DO NOTIFY alliance_team;


--
-- Name: update_notify; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE update_notify AS ON UPDATE TO finals_alliance_partner DO NOTIFY finals_alliance_partner;


--
-- Name: update_notify; Type: RULE; Schema: public; Owner: TacOps
--

CREATE RULE update_notify AS ON UPDATE TO display_component_effect DO NOTIFY display_component_effect;


--
-- Name: alliance_team_alliance_color_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: TacOps
--

ALTER TABLE ONLY alliance_team
    ADD CONSTRAINT alliance_team_alliance_color_id_fkey FOREIGN KEY (alliance_color_id) REFERENCES color(color_id);


--
-- Name: alliance_team_match_level_fkey; Type: FK CONSTRAINT; Schema: public; Owner: TacOps
--

ALTER TABLE ONLY alliance_team
    ADD CONSTRAINT alliance_team_match_level_fkey FOREIGN KEY (match_level, match_number, match_index) REFERENCES game_match(match_level, match_number, match_index);


--
-- Name: alliance_team_team_number_fkey; Type: FK CONSTRAINT; Schema: public; Owner: TacOps
--

ALTER TABLE ONLY alliance_team
    ADD CONSTRAINT alliance_team_team_number_fkey FOREIGN KEY (team_number) REFERENCES team(team_number);


--
-- Name: display_component_effect_substate_label_fkey; Type: FK CONSTRAINT; Schema: public; Owner: TacOps
--

ALTER TABLE ONLY display_component_effect
    ADD CONSTRAINT display_component_effect_substate_label_fkey FOREIGN KEY (substate_label) REFERENCES display_substate(substate_label);


--
-- Name: display_effect_option_effect_label_fkey; Type: FK CONSTRAINT; Schema: public; Owner: TacOps
--

ALTER TABLE ONLY display_effect_option
    ADD CONSTRAINT display_effect_option_effect_label_fkey FOREIGN KEY (effect_label, substate_label, component_label, keyframe_index) REFERENCES display_component_effect(effect_label, substate_label, component_label, keyframe_index);


--
-- Name: display_state_display_type_label_fkey; Type: FK CONSTRAINT; Schema: public; Owner: TacOps
--

ALTER TABLE ONLY display_state
    ADD CONSTRAINT display_state_display_type_label_fkey FOREIGN KEY (display_type_label) REFERENCES display_type(display_type_label);


--
-- Name: display_state_state_label_fkey; Type: FK CONSTRAINT; Schema: public; Owner: TacOps
--

ALTER TABLE ONLY display_state
    ADD CONSTRAINT display_state_state_label_fkey FOREIGN KEY (state_label) REFERENCES game_state(state_label);


--
-- Name: display_state_substate_label_fkey; Type: FK CONSTRAINT; Schema: public; Owner: TacOps
--

ALTER TABLE ONLY display_state
    ADD CONSTRAINT display_state_substate_label_fkey FOREIGN KEY (substate_label) REFERENCES display_substate(substate_label);


--
-- Name: game_match_match_level_fkey; Type: FK CONSTRAINT; Schema: public; Owner: TacOps
--

ALTER TABLE ONLY game_match
    ADD CONSTRAINT game_match_match_level_fkey FOREIGN KEY (match_level) REFERENCES match_level(match_level);


--
-- Name: game_match_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: TacOps
--

ALTER TABLE ONLY game_match
    ADD CONSTRAINT game_match_status_id_fkey FOREIGN KEY (status_id) REFERENCES match_status(status_id);


--
-- Name: game_match_winner_color_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: TacOps
--

ALTER TABLE ONLY game_match
    ADD CONSTRAINT game_match_winner_color_id_fkey FOREIGN KEY (winner_color_id) REFERENCES color(color_id);


--
-- Name: team_score_score_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: TacOps
--

ALTER TABLE ONLY team_score
    ADD CONSTRAINT team_score_score_attribute_id_fkey FOREIGN KEY (score_attribute_id) REFERENCES score_attribute(score_attribute_id);


--
-- Name: public; Type: ACL; Schema: -; Owner: pgsql
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM pgsql;
GRANT ALL ON SCHEMA public TO pgsql;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

