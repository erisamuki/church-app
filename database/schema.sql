--
-- PostgreSQL database dump
--

\restrict YZSD17AyAlHk9MF6cCJc3OyalUUmFt1z8OcsW7RP7XxR1dLlx0xXIjaYnqMcqh7

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: announcements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.announcements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    church_id uuid,
    title character varying(255) NOT NULL,
    content text NOT NULL,
    category character varying(50),
    priority character varying(20) DEFAULT 'normal'::character varying,
    target_audience character varying(50) DEFAULT 'all'::character varying,
    status character varying(50) DEFAULT 'draft'::character varying,
    created_by uuid,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: churches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.churches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    denomination character varying(255),
    address character varying(255),
    city character varying(100),
    state character varying(100),
    phone character varying(50),
    email character varying(255),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: donations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.donations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    church_id uuid,
    member_id uuid,
    category_id uuid,
    amount numeric(12,2) NOT NULL,
    payment_method character varying(50),
    donation_date date NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    notes text,
    recorded_by uuid
);


--
-- Name: event_attendance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_attendance (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid,
    member_id uuid,
    checked_in_at timestamp without time zone DEFAULT now(),
    guest_name character varying(255),
    guest_email character varying(255),
    guest_phone character varying(50),
    checked_in_by uuid,
    check_in_method character varying(50) DEFAULT 'app'::character varying
);


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    church_id uuid,
    title character varying(255) NOT NULL,
    event_type character varying(50),
    start_datetime timestamp without time zone NOT NULL,
    location character varying(255),
    max_attendees integer,
    status character varying(50) DEFAULT 'draft'::character varying,
    created_by uuid,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    description text,
    end_datetime timestamp without time zone
);


--
-- Name: giving_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.giving_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    church_id uuid,
    name character varying(255) NOT NULL,
    description text,
    is_tax_deductible boolean DEFAULT true,
    goal_amount numeric(12,2),
    color character varying(20),
    created_at timestamp without time zone DEFAULT now(),
    is_active boolean DEFAULT true
);


--
-- Name: group_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    group_id uuid,
    member_id uuid,
    role character varying(50) DEFAULT 'member'::character varying,
    joined_at timestamp without time zone DEFAULT now()
);


--
-- Name: members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    church_id uuid,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(255),
    phone character varying(50),
    membership_status character varying(50) DEFAULT 'member'::character varying,
    membership_date date,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    photo_url character varying(500),
    date_of_birth date,
    gender character varying(20),
    marital_status character varying(20),
    address text,
    city character varying(100),
    state character varying(100),
    zip_code character varying(20),
    baptism_date date,
    emergency_contact_name character varying(255),
    emergency_contact_phone character varying(50),
    notes text
);


--
-- Name: ministers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ministers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    church_id uuid,
    full_name character varying(255) NOT NULL,
    title character varying(255) NOT NULL,
    department character varying(255),
    photo_url character varying(500),
    bio text,
    phone character varying(50),
    email character varying(255),
    display_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    church_id uuid,
    user_id uuid,
    title character varying(255) NOT NULL,
    message text,
    type character varying(50) DEFAULT 'general'::character varying,
    related_id uuid,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: sermon_series; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sermon_series (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    church_id uuid,
    title character varying(255) NOT NULL,
    description text,
    speaker character varying(255),
    start_date date,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: sermons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sermons (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    church_id uuid,
    series_id uuid,
    title character varying(255) NOT NULL,
    speaker character varying(255),
    scripture_reference character varying(255),
    preached_date date,
    duration_seconds integer,
    created_by uuid,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: small_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.small_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    church_id uuid,
    name character varying(255) NOT NULL,
    description text,
    group_type character varying(50),
    leader_id uuid,
    meeting_day character varying(20),
    meeting_time time without time zone,
    meeting_location character varying(255),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    church_id uuid,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    phone character varying(50),
    role character varying(50) DEFAULT 'member'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    is_active boolean DEFAULT true,
    last_login timestamp without time zone,
    reset_token character varying(255),
    reset_token_expires timestamp without time zone
);


--
-- Name: volunteer_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.volunteer_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid,
    member_id uuid,
    role_id uuid,
    status character varying(50) DEFAULT 'confirmed'::character varying,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: volunteer_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.volunteer_roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    church_id uuid,
    name character varying(255) NOT NULL,
    description text,
    department character varying(100),
    color character varying(20),
    created_at timestamp without time zone DEFAULT now(),
    is_active boolean DEFAULT true
);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: churches churches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.churches
    ADD CONSTRAINT churches_pkey PRIMARY KEY (id);


--
-- Name: churches churches_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.churches
    ADD CONSTRAINT churches_slug_key UNIQUE (slug);


--
-- Name: donations donations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_pkey PRIMARY KEY (id);


--
-- Name: event_attendance event_attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_attendance
    ADD CONSTRAINT event_attendance_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: giving_categories giving_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.giving_categories
    ADD CONSTRAINT giving_categories_pkey PRIMARY KEY (id);


--
-- Name: group_members group_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_pkey PRIMARY KEY (id);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (id);


--
-- Name: ministers ministers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ministers
    ADD CONSTRAINT ministers_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: sermon_series sermon_series_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sermon_series
    ADD CONSTRAINT sermon_series_pkey PRIMARY KEY (id);


--
-- Name: sermons sermons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sermons
    ADD CONSTRAINT sermons_pkey PRIMARY KEY (id);


--
-- Name: small_groups small_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.small_groups
    ADD CONSTRAINT small_groups_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: volunteer_assignments volunteer_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.volunteer_assignments
    ADD CONSTRAINT volunteer_assignments_pkey PRIMARY KEY (id);


--
-- Name: volunteer_roles volunteer_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.volunteer_roles
    ADD CONSTRAINT volunteer_roles_pkey PRIMARY KEY (id);


--
-- Name: idx_donations_church; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_donations_church ON public.donations USING btree (church_id);


--
-- Name: idx_donations_member; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_donations_member ON public.donations USING btree (member_id);


--
-- Name: idx_events_church; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_events_church ON public.events USING btree (church_id);


--
-- Name: idx_group_members_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_group_members_group ON public.group_members USING btree (group_id);


--
-- Name: idx_group_members_member; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_group_members_member ON public.group_members USING btree (member_id);


--
-- Name: idx_members_church; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_members_church ON public.members USING btree (church_id);


--
-- Name: idx_users_church; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_church ON public.users USING btree (church_id);


--
-- Name: announcements announcements_church_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_church_id_fkey FOREIGN KEY (church_id) REFERENCES public.churches(id) ON DELETE CASCADE;


--
-- Name: announcements announcements_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: donations donations_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.giving_categories(id);


--
-- Name: donations donations_church_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_church_id_fkey FOREIGN KEY (church_id) REFERENCES public.churches(id) ON DELETE CASCADE;


--
-- Name: donations donations_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id);


--
-- Name: donations donations_recorded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.users(id);


--
-- Name: event_attendance event_attendance_checked_in_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_attendance
    ADD CONSTRAINT event_attendance_checked_in_by_fkey FOREIGN KEY (checked_in_by) REFERENCES public.users(id);


--
-- Name: event_attendance event_attendance_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_attendance
    ADD CONSTRAINT event_attendance_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: event_attendance event_attendance_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_attendance
    ADD CONSTRAINT event_attendance_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: events events_church_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_church_id_fkey FOREIGN KEY (church_id) REFERENCES public.churches(id) ON DELETE CASCADE;


--
-- Name: events events_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: giving_categories giving_categories_church_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.giving_categories
    ADD CONSTRAINT giving_categories_church_id_fkey FOREIGN KEY (church_id) REFERENCES public.churches(id) ON DELETE CASCADE;


--
-- Name: group_members group_members_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.small_groups(id) ON DELETE CASCADE;


--
-- Name: group_members group_members_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: members members_church_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_church_id_fkey FOREIGN KEY (church_id) REFERENCES public.churches(id) ON DELETE CASCADE;


--
-- Name: ministers ministers_church_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ministers
    ADD CONSTRAINT ministers_church_id_fkey FOREIGN KEY (church_id) REFERENCES public.churches(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_church_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_church_id_fkey FOREIGN KEY (church_id) REFERENCES public.churches(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: sermon_series sermon_series_church_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sermon_series
    ADD CONSTRAINT sermon_series_church_id_fkey FOREIGN KEY (church_id) REFERENCES public.churches(id) ON DELETE CASCADE;


--
-- Name: sermons sermons_church_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sermons
    ADD CONSTRAINT sermons_church_id_fkey FOREIGN KEY (church_id) REFERENCES public.churches(id) ON DELETE CASCADE;


--
-- Name: sermons sermons_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sermons
    ADD CONSTRAINT sermons_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: sermons sermons_series_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sermons
    ADD CONSTRAINT sermons_series_id_fkey FOREIGN KEY (series_id) REFERENCES public.sermon_series(id);


--
-- Name: small_groups small_groups_church_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.small_groups
    ADD CONSTRAINT small_groups_church_id_fkey FOREIGN KEY (church_id) REFERENCES public.churches(id) ON DELETE CASCADE;


--
-- Name: small_groups small_groups_leader_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.small_groups
    ADD CONSTRAINT small_groups_leader_id_fkey FOREIGN KEY (leader_id) REFERENCES public.members(id);


--
-- Name: users users_church_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_church_id_fkey FOREIGN KEY (church_id) REFERENCES public.churches(id) ON DELETE CASCADE;


--
-- Name: volunteer_assignments volunteer_assignments_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.volunteer_assignments
    ADD CONSTRAINT volunteer_assignments_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: volunteer_assignments volunteer_assignments_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.volunteer_assignments
    ADD CONSTRAINT volunteer_assignments_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: volunteer_assignments volunteer_assignments_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.volunteer_assignments
    ADD CONSTRAINT volunteer_assignments_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.volunteer_roles(id);


--
-- Name: volunteer_roles volunteer_roles_church_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.volunteer_roles
    ADD CONSTRAINT volunteer_roles_church_id_fkey FOREIGN KEY (church_id) REFERENCES public.churches(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict YZSD17AyAlHk9MF6cCJc3OyalUUmFt1z8OcsW7RP7XxR1dLlx0xXIjaYnqMcqh7

