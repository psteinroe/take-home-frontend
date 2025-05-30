# Take-Home Exercise For Frontend Engineers

Welcome. Today, we will work with Supabase to create a simple onboarding flow.

In this repository, you find a Next app as well as Supabase.

The Next app already has Supabase integrated with a working authentication flow.

Our goal today is to allow a user to accept an invite to an organisation after signup. The flow should be:

1. The organisation invites a new user (already prepared in this task)
2. The user receives an email (not required for this task)
3. The user then signs up using that email (the signup flow is already setup)
4. After a successful login, we want to check if the user is already an employee of an organisation. If not, the user should be redirected to a new onboarding page where a list of invites is presented. The invite can be accepted by calling the `accept_employee_invite` rpc.
5. After the invite is accepted, the user should be forwarded to a welcome page.
6. Bonus points if our login screen + onboarding flow supports `forward_to`: After login and after accepting the invite, the user is forwarded to the path passed via `forward_to`.

## Getting Started

- `pnpm supabase start` to start Supabase
- `pnpm run dev` to run the NextJs app
- There is already an invited employee in the database. You can login via `invited@test.com` and `password`.
- The Supabase types are generated in `src/lib/supabase/database.ts`

## Hints

- Check out the migration file to understand the data model. Do not worry, it is very simple.
- We employ a Supabase Auth Hook to add the `organisation_id` and the `employee_id` to the `app_metadata` of the JWT if the user is connected. That data is available via `getClaims()`.
- Shadcn + Tailwind is setup. Please use it! :)

