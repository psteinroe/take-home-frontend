-- We want to store all of this in the tests schema to keep it separate from any application data
create schema if not exists tests;

-- anon and authenticated should have access to tests schema
grant USAGE on schema tests to anon, authenticated, service_role;

-- Don't allow public to execute any functions in the tests schema
alter default PRIVILEGES in schema tests revoke execute on FUNCTIONS from public;

-- Grant execute to anon and authenticated for testing purposes
alter default PRIVILEGES in schema tests grant execute on FUNCTIONS to anon, authenticated, service_role;


/**
 * ### tests.create_user(identifier text, domain text)
 *
 * Creates user if none exist.
 *
 * Parameters:
 * - `identifier` - A unique identifier for the user. We recommend you keep it memorable like "test_owner" or "test_member"
 * - `domain` - A domain to use for the email
 *
 * Returns:
 * - `user_id` - The UUID of the user in the `auth.users` table
 *
 * Example:
 * ```sql
 *   SELECT tests.create_user('test_owner', 'test');
 * ```
 */
create or replace function tests.create_user (identifier text, domain text)
    returns uuid
    security definer
    as $$
declare
    user_id uuid := (
        select
            id
        from
            auth.users
        where
            raw_user_meta_data ->> 'test_identifier' = identifier
        limit 1);
begin
    if user_id is not null then
        return user_id;
    else
        user_id := gen_random_uuid();
    end if;
    insert into auth.users (instance_id, id, aud, "role", email, encrypted_password, email_confirmed_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, confirmation_token, email_change, email_change_token_new, recovery_token)
        values ('00000000-0000-0000-0000-000000000000'::uuid, user_id, 'authenticated', 'authenticated', identifier || '@' || domain, '$2a$10$PznXR5VSgzjnAp7T/X7PCu6vtlgzdFt1zIr41IqP0CmVHQtShiXxS', '2022-02-11 21:02:04.547', '2022-02-11 22:53:12.520', '{"provider": "email", "providers": ["email"]}', json_build_object('test_identifier', identifier), false, '2022-02-11 21:02:04.542', '2022-02-11 21:02:04.542', null, null, '','', '','')
    returning
        id into user_id;
    insert into auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, provider_id)
        values (user_id, user_id, json_build_object('sub', user_id), 'email', now(), now(), now(), gen_random_uuid());
    return user_id;
end;
$$
language plpgsql;

/**
 * ### tests.create_organisation(domain text)
 *
 * Creates organisation if none exist.
 *
 * Parameters:
 * - `domain` - The domain to use for the organisation
 *
 * Returns:
 * - `organisation_id` - The UUID of the organisation
 *
 * Example:
 * ```sql
 *   SELECT tests.create_organisation('test.com');
 * ```
 */
create or replace function tests.create_organisation (domain text)
    returns uuid
    security definer
    as $$
declare
    organisation_id uuid := (
        select
            id
        from
            organisation
        where
            name = domain
        limit 1
    );
begin
    if organisation_id is not null then
        return organisation_id;
    end if;
    organisation_id := gen_random_uuid();
    insert into organisation (id, name) values (organisation_id, domain);
    return organisation_id;
end;
$$
language plpgsql;


/**
 * ### tests.get_organisation_id(domain text)
 *
 * Returns organisation by domain.
 *
 * Parameters:
 * - `domain` - The domain to use for the organisation
 *
 * Returns:
 * - `organisation_id` - The UUID of the organisation
 *
 * Example:
 * ```sql
 *   SELECT tests.get_organisation_id('test.com');
 * ```
 */
create or replace function tests.get_organisation_id (domain text)
    returns uuid
    security definer
    as $$
declare
    organisation_id uuid := (
        select id from organisation where name = domain limit 1
    );
begin
    if organisation_id is null then
        raise exception 'Organisation with domain % not found', identifier;
    end if;
    return organisation_id;
end;
$$
language plpgsql;


/**
 * ### tests.create_employee(identifier, domain text)
 *
 * Creates employee if none exist.
 * Will also create user and organisation if they do not exist.
 *
 * Parameters:
 * - `identifier` - The identifer to use for the employee and the user
 * - `domain` - The domain to use for the organisation
 *
 * Returns:
 * - `employee_id` - The UUID of the employee
 *
 * Example:
 * ```sql
 *   SELECT tests.create_employee('admin', 'test.com', true);
 * ```
 */
create or replace function tests.create_employee (identifier text, domain text)
    returns uuid
    security definer
    as $$
declare
    v_user_id uuid := tests.create_user(identifier, domain);
    v_organisation_id uuid := tests.create_organisation(domain);
    v_employee_id uuid := (
        select id from employee where username = identifier and organisation_id = v_organisation_id limit 1
    );
begin
    if v_employee_id is not null then
        return v_employee_id;
    end if;
    insert into employee (organisation_id, user_id, username, email)
        values (v_organisation_id, v_user_id, identifier, identifier || '@' || domain)
    returning
        id into v_employee_id;
    return v_employee_id;
end;
$$
language plpgsql;

do $$
begin
    perform tests.create_organisation('test.com');
    perform tests.create_user('invited', 'test.com');
end
$$;

