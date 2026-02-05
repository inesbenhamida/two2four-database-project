--
-- PostgreSQL database dump
--

-- Dumped from database version 14.14 (Homebrew)
-- Dumped by pg_dump version 14.14 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: abonne; Type: TABLE; Schema: public; Owner: inesbenhamida
--

CREATE TABLE public.abonne (
    id_abonne integer NOT NULL,
    nom character varying(50) NOT NULL,
    prenom character varying(50) NOT NULL,
    num_tel character varying(15),
    email character varying(50) NOT NULL,
    num_carte character varying(20),
    mdp character varying(225) NOT NULL
);


ALTER TABLE public.abonne OWNER TO inesbenhamida;

--
-- Name: abonne_id_abonne_seq; Type: SEQUENCE; Schema: public; Owner: inesbenhamida
--

CREATE SEQUENCE public.abonne_id_abonne_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.abonne_id_abonne_seq OWNER TO inesbenhamida;

--
-- Name: abonne_id_abonne_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: inesbenhamida
--

ALTER SEQUENCE public.abonne_id_abonne_seq OWNED BY public.abonne.id_abonne;


--
-- Name: emplacement; Type: TABLE; Schema: public; Owner: inesbenhamida
--

CREATE TABLE public.emplacement (
    id_emplacement integer NOT NULL,
    id_station integer,
    type_emplacement character varying(20) NOT NULL,
    CONSTRAINT emplacement_type_emplacement_check CHECK (((type_emplacement)::text = ANY ((ARRAY['Borne vélo'::character varying, 'Parking voiture'::character varying])::text[])))
);


ALTER TABLE public.emplacement OWNER TO inesbenhamida;

--
-- Name: emplacement_id_emplacement_seq; Type: SEQUENCE; Schema: public; Owner: inesbenhamida
--

CREATE SEQUENCE public.emplacement_id_emplacement_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.emplacement_id_emplacement_seq OWNER TO inesbenhamida;

--
-- Name: emplacement_id_emplacement_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: inesbenhamida
--

ALTER SEQUENCE public.emplacement_id_emplacement_seq OWNED BY public.emplacement.id_emplacement;


--
-- Name: historique_emplacements; Type: TABLE; Schema: public; Owner: inesbenhamida
--

CREATE TABLE public.historique_emplacements (
    id integer NOT NULL,
    id_abonne integer NOT NULL,
    type_emplacement character varying(255),
    id_station integer,
    debut_reservation timestamp without time zone,
    fin_reservation timestamp without time zone
);


ALTER TABLE public.historique_emplacements OWNER TO inesbenhamida;

--
-- Name: historique_emplacements_id_seq; Type: SEQUENCE; Schema: public; Owner: inesbenhamida
--

CREATE SEQUENCE public.historique_emplacements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.historique_emplacements_id_seq OWNER TO inesbenhamida;

--
-- Name: historique_emplacements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: inesbenhamida
--

ALTER SEQUENCE public.historique_emplacements_id_seq OWNED BY public.historique_emplacements.id;


--
-- Name: historique_vehicules; Type: TABLE; Schema: public; Owner: inesbenhamida
--

CREATE TABLE public.historique_vehicules (
    id integer NOT NULL,
    id_abonne integer NOT NULL,
    modele character varying(255),
    categorie character varying(255),
    debut_reservation timestamp without time zone,
    fin_reservation timestamp without time zone
);


ALTER TABLE public.historique_vehicules OWNER TO inesbenhamida;

--
-- Name: historique_vehicules_id_seq; Type: SEQUENCE; Schema: public; Owner: inesbenhamida
--

CREATE SEQUENCE public.historique_vehicules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.historique_vehicules_id_seq OWNER TO inesbenhamida;

--
-- Name: historique_vehicules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: inesbenhamida
--

ALTER SEQUENCE public.historique_vehicules_id_seq OWNED BY public.historique_vehicules.id;


--
-- Name: reserve; Type: TABLE; Schema: public; Owner: inesbenhamida
--

CREATE TABLE public.reserve (
    id_vehicule integer NOT NULL,
    id_abonne integer NOT NULL,
    debut_reservation timestamp without time zone NOT NULL,
    fin_reservation timestamp without time zone NOT NULL,
    id_station integer,
    CONSTRAINT reserve_check CHECK ((fin_reservation >= debut_reservation))
);


ALTER TABLE public.reserve OWNER TO inesbenhamida;

--
-- Name: reserveplace; Type: TABLE; Schema: public; Owner: inesbenhamida
--

CREATE TABLE public.reserveplace (
    id_abonne integer NOT NULL,
    id_emplacement integer NOT NULL,
    reservation_emplacement timestamp without time zone NOT NULL
);


ALTER TABLE public.reserveplace OWNER TO inesbenhamida;

--
-- Name: station; Type: TABLE; Schema: public; Owner: inesbenhamida
--

CREATE TABLE public.station (
    id_station integer NOT NULL,
    adresse character varying(100) NOT NULL,
    ville character varying(50) NOT NULL
);


ALTER TABLE public.station OWNER TO inesbenhamida;

--
-- Name: station_id_station_seq; Type: SEQUENCE; Schema: public; Owner: inesbenhamida
--

CREATE SEQUENCE public.station_id_station_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.station_id_station_seq OWNER TO inesbenhamida;

--
-- Name: station_id_station_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: inesbenhamida
--

ALTER SEQUENCE public.station_id_station_seq OWNED BY public.station.id_station;


--
-- Name: stationnement; Type: TABLE; Schema: public; Owner: inesbenhamida
--

CREATE TABLE public.stationnement (
    id_vehicule integer NOT NULL,
    id_emplacement integer NOT NULL,
    debut_stationnement timestamp without time zone NOT NULL,
    fin_stationnement timestamp without time zone NOT NULL,
    CONSTRAINT stationnement_check CHECK ((fin_stationnement >= debut_stationnement))
);


ALTER TABLE public.stationnement OWNER TO inesbenhamida;

--
-- Name: vehicule; Type: TABLE; Schema: public; Owner: inesbenhamida
--

CREATE TABLE public.vehicule (
    id_vehicule integer NOT NULL,
    categorie character varying(25),
    numimmat character varying(15),
    modele character varying(30) NOT NULL,
    statut character varying(15),
    id_station integer,
    CONSTRAINT vehicule_categorie_check CHECK (((categorie)::text = ANY ((ARRAY['Vélo'::character varying, 'Voiture'::character varying])::text[]))),
    CONSTRAINT vehicule_statut_check CHECK (((statut)::text = ANY ((ARRAY['Disponible'::character varying, 'Occupé'::character varying, 'En réparation'::character varying])::text[])))
);


ALTER TABLE public.vehicule OWNER TO inesbenhamida;

--
-- Name: stats_reservations; Type: VIEW; Schema: public; Owner: inesbenhamida
--

CREATE VIEW public.stats_reservations AS
 SELECT s.id_station,
    s.adresse,
    s.ville,
    EXTRACT(dow FROM r.debut_reservation) AS jour_semaine,
    count(r.id_vehicule) AS nombre_reservations,
    count(v.id_vehicule) FILTER (WHERE ((v.statut)::text = 'Disponible'::text)) AS vehicules_disponibles
   FROM ((public.station s
     LEFT JOIN public.reserve r ON ((s.id_station = r.id_station)))
     LEFT JOIN public.vehicule v ON ((s.id_station = v.id_station)))
  GROUP BY s.id_station, s.adresse, s.ville, (EXTRACT(dow FROM r.debut_reservation))
  ORDER BY s.id_station, (EXTRACT(dow FROM r.debut_reservation));


ALTER TABLE public.stats_reservations OWNER TO inesbenhamida;

--
-- Name: vehicule_id_vehicule_seq; Type: SEQUENCE; Schema: public; Owner: inesbenhamida
--

CREATE SEQUENCE public.vehicule_id_vehicule_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.vehicule_id_vehicule_seq OWNER TO inesbenhamida;

--
-- Name: vehicule_id_vehicule_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: inesbenhamida
--

ALTER SEQUENCE public.vehicule_id_vehicule_seq OWNED BY public.vehicule.id_vehicule;


--
-- Name: abonne id_abonne; Type: DEFAULT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.abonne ALTER COLUMN id_abonne SET DEFAULT nextval('public.abonne_id_abonne_seq'::regclass);


--
-- Name: emplacement id_emplacement; Type: DEFAULT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.emplacement ALTER COLUMN id_emplacement SET DEFAULT nextval('public.emplacement_id_emplacement_seq'::regclass);


--
-- Name: historique_emplacements id; Type: DEFAULT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.historique_emplacements ALTER COLUMN id SET DEFAULT nextval('public.historique_emplacements_id_seq'::regclass);


--
-- Name: historique_vehicules id; Type: DEFAULT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.historique_vehicules ALTER COLUMN id SET DEFAULT nextval('public.historique_vehicules_id_seq'::regclass);


--
-- Name: station id_station; Type: DEFAULT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.station ALTER COLUMN id_station SET DEFAULT nextval('public.station_id_station_seq'::regclass);


--
-- Name: vehicule id_vehicule; Type: DEFAULT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.vehicule ALTER COLUMN id_vehicule SET DEFAULT nextval('public.vehicule_id_vehicule_seq'::regclass);


--
-- Data for Name: abonne; Type: TABLE DATA; Schema: public; Owner: inesbenhamida
--

COPY public.abonne (id_abonne, nom, prenom, num_tel, email, num_carte, mdp) FROM stdin;
32	Dupont 	Élise	0611223344	elisedpt@gmail.com	CARD045657	pbkdf2:sha256:1000000$pYnWKJnguXa0nBIe$1765d46870cfca7b0b8f65c26aedd450d26d0dadfea3b996bb549e9032141507
33	Martin	Nicolas	0622334455	nicolas.martin@gmail.com	CARD451995	pbkdf2:sha256:1000000$tuLWFtjKGJObbP2U$036a7bb55b45abbcdccf9b4b407ecd73814608890baa083b839cba1a4387998f
34	Nguyen	Linh	\N	linh@gmail.com	CARD838887	pbkdf2:sha256:1000000$NacCUXBg6xPZ1tm9$d252d0e1f64a2f57952230742c9b9608d6f35ef234813b7352a0673d2ddfdb82
35	Ali	Zayn	\N	zayn.ali@gmail.com	CARD292272	pbkdf2:sha256:1000000$4PAFukg1LFsQBUVR$9684a692112b60d20618b3a25a4bc099fc2d22daa327d43ce20a892d068267c1
36	Kim	Jiwoo	0660607070	jiwoo.kim@gmail.com	CARD199395	pbkdf2:sha256:1000000$ZAHYlrQYzvM0Yi2h$167c01ade7e43ada22ab36424d3aa23bad0ce27d9b42c5afc7568d419b450cb0
37	Bernard	Sophie	0633445566	sophie@gmail.com	CARD803049	pbkdf2:sha256:1000000$3fFSVB6Alvfp7ma3$f0767744d5e94d8cd551bb292891ecb2cc6c4a646fb593cd22e8047a525790af
\.


--
-- Data for Name: emplacement; Type: TABLE DATA; Schema: public; Owner: inesbenhamida
--

COPY public.emplacement (id_emplacement, id_station, type_emplacement) FROM stdin;
1	1	Borne vélo
2	1	Parking voiture
3	1	Borne vélo
4	1	Parking voiture
5	2	Borne vélo
6	2	Parking voiture
7	2	Borne vélo
8	2	Parking voiture
9	3	Borne vélo
10	3	Parking voiture
11	3	Borne vélo
12	3	Parking voiture
13	4	Borne vélo
14	4	Parking voiture
15	4	Borne vélo
16	4	Parking voiture
\.


--
-- Data for Name: historique_emplacements; Type: TABLE DATA; Schema: public; Owner: inesbenhamida
--

COPY public.historique_emplacements (id, id_abonne, type_emplacement, id_station, debut_reservation, fin_reservation) FROM stdin;
1	26	Borne vélo	4	2024-12-14 18:39:00	2024-12-14 19:39:00
2	22	Parking voiture	4	2024-12-17 15:29:00	2024-12-17 16:29:00
3	26	Borne vélo	4	2024-12-20 18:11:00	2024-12-20 19:11:00
4	28	Borne vélo	3	2024-12-21 15:28:00	2024-12-21 16:28:00
\.


--
-- Data for Name: historique_vehicules; Type: TABLE DATA; Schema: public; Owner: inesbenhamida
--

COPY public.historique_vehicules (id, id_abonne, modele, categorie, debut_reservation, fin_reservation) FROM stdin;
1	26	Vélo tout chemin	Vélo	2024-12-14 17:57:00	2024-12-14 17:58:00
2	26	Vélo tout chemin	Vélo	2024-12-14 18:25:00	2024-12-14 18:26:00
3	26	Vélo tout chemin	Vélo	2024-12-15 02:05:00	2024-12-15 03:05:00
4	26	VTT	Vélo	2024-12-17 00:12:00	2024-12-17 01:11:00
5	26	Vélo de course	Vélo	2024-12-17 14:17:00	2024-12-17 14:19:00
6	28	Citroën C3	Voiture	2024-12-18 14:28:00	2024-12-18 15:28:00
7	22	Volkswagen Polo	Voiture	2024-12-17 15:29:00	2024-12-17 16:29:00
8	26	Ford Fiesta	Voiture	2024-12-17 16:12:00	2024-12-17 17:12:00
9	26	Volkswagen Polo	Voiture	2024-12-18 18:43:00	2024-12-18 19:43:00
10	28	VTT	Vélo	2024-12-20 15:37:00	2024-12-20 16:37:00
11	28	VTT	Vélo	2024-12-20 18:10:00	2024-12-20 19:10:00
12	26	Ford Fiesta	Voiture	2024-12-20 18:11:00	2024-12-20 20:13:00
13	23	Vélo de course	Vélo	2024-12-20 21:11:00	2024-12-20 22:11:00
14	23	Toyota Yaris	Voiture	2024-12-20 18:12:00	2024-12-20 20:12:00
15	1	VTT	Vélo	2024-12-21 12:00:00	2024-12-21 14:00:00
16	1	Vélo de ville	Vélo	2024-12-21 08:00:00	2024-12-21 10:00:00
17	26	VTT	Vélo	2024-12-21 17:03:00	2024-12-21 18:03:00
\.


--
-- Data for Name: reserve; Type: TABLE DATA; Schema: public; Owner: inesbenhamida
--

COPY public.reserve (id_vehicule, id_abonne, debut_reservation, fin_reservation, id_station) FROM stdin;
3	36	2024-12-22 22:22:00	2024-12-22 23:22:00	\N
\.


--
-- Data for Name: reserveplace; Type: TABLE DATA; Schema: public; Owner: inesbenhamida
--

COPY public.reserveplace (id_abonne, id_emplacement, reservation_emplacement) FROM stdin;
\.


--
-- Data for Name: station; Type: TABLE DATA; Schema: public; Owner: inesbenhamida
--

COPY public.station (id_station, adresse, ville) FROM stdin;
1	123 Rue de Paris	Paris
2	45 Avenue des Champs	Paris
3	10 Place Bellecour	Lyon
4	3 Rue de la République	Marseille
\.


--
-- Data for Name: stationnement; Type: TABLE DATA; Schema: public; Owner: inesbenhamida
--

COPY public.stationnement (id_vehicule, id_emplacement, debut_stationnement, fin_stationnement) FROM stdin;
\.


--
-- Data for Name: vehicule; Type: TABLE DATA; Schema: public; Owner: inesbenhamida
--

COPY public.vehicule (id_vehicule, categorie, numimmat, modele, statut, id_station) FROM stdin;
3	Voiture	AB-123-CD	Peugeot 208	Occupé	1
11	Voiture	QR-789-ST	Fiat 500	En réparation	3
9	Vélo	\N	Vélo de course	Disponible	3
8	Voiture	MN-456-OP	Toyota Yaris	Disponible	2
2	Vélo	\N	VTT	Disponible	1
5	Vélo	\N	Vélo électrique	Disponible	2
6	Vélo	\N	VTT	Disponible	2
4	Voiture	EF-456-GH	Renault Clio	Disponible	1
7	Voiture	IJ-789-KL	Citroën C3	Disponible	2
10	Vélo	\N	Vélo tout chemin	Disponible	3
1	Vélo	\N	Vélo de ville	Disponible	1
13	Vélo	\N	Vélo pliant	En réparation	4
12	Voiture	UV-123-WX	Ford Fiesta	Disponible	3
14	Vélo	\N	VTT	Disponible	4
16	Voiture	BB-789-CC	Volkswagen Polo	Disponible	4
15	Voiture	YZ-456-AA	Opel Astra	En réparation	4
\.


--
-- Name: abonne_id_abonne_seq; Type: SEQUENCE SET; Schema: public; Owner: inesbenhamida
--

SELECT pg_catalog.setval('public.abonne_id_abonne_seq', 37, true);


--
-- Name: emplacement_id_emplacement_seq; Type: SEQUENCE SET; Schema: public; Owner: inesbenhamida
--

SELECT pg_catalog.setval('public.emplacement_id_emplacement_seq', 1, false);


--
-- Name: historique_emplacements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: inesbenhamida
--

SELECT pg_catalog.setval('public.historique_emplacements_id_seq', 4, true);


--
-- Name: historique_vehicules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: inesbenhamida
--

SELECT pg_catalog.setval('public.historique_vehicules_id_seq', 17, true);


--
-- Name: station_id_station_seq; Type: SEQUENCE SET; Schema: public; Owner: inesbenhamida
--

SELECT pg_catalog.setval('public.station_id_station_seq', 1, false);


--
-- Name: vehicule_id_vehicule_seq; Type: SEQUENCE SET; Schema: public; Owner: inesbenhamida
--

SELECT pg_catalog.setval('public.vehicule_id_vehicule_seq', 1, false);


--
-- Name: abonne abonne_email_key; Type: CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.abonne
    ADD CONSTRAINT abonne_email_key UNIQUE (email);


--
-- Name: abonne abonne_num_carte_key; Type: CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.abonne
    ADD CONSTRAINT abonne_num_carte_key UNIQUE (num_carte);


--
-- Name: abonne abonne_num_tel_key; Type: CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.abonne
    ADD CONSTRAINT abonne_num_tel_key UNIQUE (num_tel);


--
-- Name: abonne abonne_pkey; Type: CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.abonne
    ADD CONSTRAINT abonne_pkey PRIMARY KEY (id_abonne);


--
-- Name: emplacement emplacement_pkey; Type: CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.emplacement
    ADD CONSTRAINT emplacement_pkey PRIMARY KEY (id_emplacement);


--
-- Name: historique_emplacements historique_emplacements_pkey; Type: CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.historique_emplacements
    ADD CONSTRAINT historique_emplacements_pkey PRIMARY KEY (id);


--
-- Name: historique_vehicules historique_vehicules_pkey; Type: CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.historique_vehicules
    ADD CONSTRAINT historique_vehicules_pkey PRIMARY KEY (id);


--
-- Name: reserve reserve_pkey; Type: CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.reserve
    ADD CONSTRAINT reserve_pkey PRIMARY KEY (id_vehicule, id_abonne, debut_reservation);


--
-- Name: reserveplace reserveplace_pkey; Type: CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.reserveplace
    ADD CONSTRAINT reserveplace_pkey PRIMARY KEY (id_abonne, id_emplacement, reservation_emplacement);


--
-- Name: station station_pkey; Type: CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.station
    ADD CONSTRAINT station_pkey PRIMARY KEY (id_station);


--
-- Name: stationnement stationnement_pkey; Type: CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.stationnement
    ADD CONSTRAINT stationnement_pkey PRIMARY KEY (id_vehicule, id_emplacement, debut_stationnement);


--
-- Name: vehicule vehicule_numimmat_key; Type: CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.vehicule
    ADD CONSTRAINT vehicule_numimmat_key UNIQUE (numimmat);


--
-- Name: vehicule vehicule_pkey; Type: CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.vehicule
    ADD CONSTRAINT vehicule_pkey PRIMARY KEY (id_vehicule);


--
-- Name: emplacement emplacement_id_station_fkey; Type: FK CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.emplacement
    ADD CONSTRAINT emplacement_id_station_fkey FOREIGN KEY (id_station) REFERENCES public.station(id_station) ON DELETE CASCADE;


--
-- Name: vehicule fk_station; Type: FK CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.vehicule
    ADD CONSTRAINT fk_station FOREIGN KEY (id_station) REFERENCES public.station(id_station) ON DELETE SET NULL;


--
-- Name: reserve fk_station_reserve; Type: FK CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.reserve
    ADD CONSTRAINT fk_station_reserve FOREIGN KEY (id_station) REFERENCES public.station(id_station) ON DELETE SET NULL;


--
-- Name: reserve reserve_id_abonne_fkey; Type: FK CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.reserve
    ADD CONSTRAINT reserve_id_abonne_fkey FOREIGN KEY (id_abonne) REFERENCES public.abonne(id_abonne) ON DELETE CASCADE;


--
-- Name: reserve reserve_id_vehicule_fkey; Type: FK CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.reserve
    ADD CONSTRAINT reserve_id_vehicule_fkey FOREIGN KEY (id_vehicule) REFERENCES public.vehicule(id_vehicule) ON DELETE CASCADE;


--
-- Name: reserveplace reserveplace_id_abonne_fkey; Type: FK CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.reserveplace
    ADD CONSTRAINT reserveplace_id_abonne_fkey FOREIGN KEY (id_abonne) REFERENCES public.abonne(id_abonne) ON DELETE CASCADE;


--
-- Name: reserveplace reserveplace_id_emplacement_fkey; Type: FK CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.reserveplace
    ADD CONSTRAINT reserveplace_id_emplacement_fkey FOREIGN KEY (id_emplacement) REFERENCES public.emplacement(id_emplacement) ON DELETE CASCADE;


--
-- Name: stationnement stationnement_id_emplacement_fkey; Type: FK CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.stationnement
    ADD CONSTRAINT stationnement_id_emplacement_fkey FOREIGN KEY (id_emplacement) REFERENCES public.emplacement(id_emplacement) ON DELETE CASCADE;


--
-- Name: stationnement stationnement_id_vehicule_fkey; Type: FK CONSTRAINT; Schema: public; Owner: inesbenhamida
--

ALTER TABLE ONLY public.stationnement
    ADD CONSTRAINT stationnement_id_vehicule_fkey FOREIGN KEY (id_vehicule) REFERENCES public.vehicule(id_vehicule) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

