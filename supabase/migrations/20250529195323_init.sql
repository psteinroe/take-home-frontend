set check_function_bodies = 'off';

create schema private;

grant usage on schema private to postgres, anon, authenticated, service_role;
alter default privileges in schema private grant all on tables to postgres, anon, authenticated, service_role;
alter default privileges in schema private grant all on functions to postgres, anon, authenticated, service_role;
alter default privileges in schema private grant all on sequences to postgres, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION "private"."organisation_id"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  select (
    case
        -- when authenticated, auth.uid() is never null
        when auth.role() = 'authenticated' then (select organisation_id from public.employee where user_id = auth.uid())
    end
);
$$;

CREATE TABLE IF NOT EXISTS "public"."organisation" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL PRIMARY KEY,
    "name" "text" NOT NULL
);


CREATE TABLE IF NOT EXISTS "public"."employee" (
    "id" "uuid" PRIMARY KEY DEFAULT "gen_random_uuid"(),
    "organisation_id" "uuid" NOT NULL references organisation on update restrict on delete cascade default private.organisation_id(),
    "user_id" "uuid",
    "username" "text" NOT NULL,
    "email" "text" NOT NULL
);

CREATE OR REPLACE FUNCTION "public"."accept_employee_invite"("employee_id" "uuid") RETURNS "public"."employee"
LANGUAGE "plpgsql" SECURITY DEFINER
SET "search_path" TO ''
AS $$
declare
    v_employee public.employee;
begin
    if exists (
        select
            email
        from
            public.employee
        where
            id = employee_id
            and email is not null
            and email = auth.jwt () ->> 'email') then

    update
        public.employee
    set
        user_id = auth.uid ()
    where
        id = employee_id
    returning
        * into v_employee;

    update
        public.employee_invite
    set
        accepted = true
    where
        email = v_employee.email;

    return v_employee;
else
    raise exception 'Unauthorized';
end if;
end
$$;

ALTER TABLE "public"."organisation" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "employee_select" ON "public"."organisation" FOR SELECT TO "authenticated" USING ((( SELECT "private"."organisation_id"() AS "organisation_id") = "id"));

ALTER TABLE "public"."employee" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "invitee_select" ON "public"."employee" FOR SELECT TO "authenticated" USING (("email" = (( SELECT "auth"."jwt"() AS "jwt") ->> 'email'::"text")));

CREATE POLICY "invitee_update" ON "public"."employee" FOR UPDATE TO "authenticated" USING (("email" = (( SELECT "auth"."jwt"() AS "jwt") ->> 'email'::"text"))) WITH CHECK (("email" = (( SELECT "auth"."jwt"() AS "jwt") ->> 'email'::"text")));

create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
security definer
as $$
declare
    v_employee_id uuid;
    v_organisation_id uuid;
    v_claims jsonb := event -> 'claims';
  begin
    select id, organisation_id into v_employee_id, v_organisation_id from public.employee where user_id = (event ->> 'user_id')::uuid;

    return jsonb_set(event, array['claims', 'app_metadata'], event -> 'claims' -> 'app_metadata' || jsonb_build_object('organisation_id', v_organisation_id, 'employee_id', v_employee_id));
  end
$$;

grant execute
  on function public.custom_access_token_hook
  to supabase_auth_admin;

grant usage on schema public to supabase_auth_admin;

revoke execute
  on function public.custom_access_token_hook
  from authenticated, anon;

