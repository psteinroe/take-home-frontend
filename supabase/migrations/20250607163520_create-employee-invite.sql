CREATE TABLE IF NOT EXISTS employee_invite (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  employee_id uuid references employee(id) on delete cascade,
  organisation_id uuid references organisation(id) on delete cascade,
  created_at timestamp with time zone default now(),
  accepted boolean default false
);