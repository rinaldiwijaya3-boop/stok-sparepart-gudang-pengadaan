-- Stok Sparepart Gudang Pengadaan — Supabase setup
-- Run this in Supabase Dashboard > SQL Editor.
-- Security model: anyone can read shared app_state without login; only authenticated admins can write.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role text not null default 'viewer' check (role in ('admin','viewer')),
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'viewer')
  on conflict (id) do update set email = excluded.email;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  );
$$;

create table if not exists public.app_state (
  id integer primary key check (id = 1),
  state jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

alter table public.profiles enable row level security;
alter table public.app_state enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile"
on public.profiles for select
to authenticated
using (id = (select auth.uid()) or public.is_admin());

drop policy if exists "Admins can update profiles" on public.profiles;
create policy "Admins can update profiles"
on public.profiles for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Authenticated users can read shared app state" on public.app_state;
drop policy if exists "Anyone can read shared app state" on public.app_state;
create policy "Anyone can read shared app state"
on public.app_state for select
to anon, authenticated
using (true);

drop policy if exists "Admins can insert shared app state" on public.app_state;
create policy "Admins can insert shared app state"
on public.app_state for insert
to authenticated
with check (public.is_admin());

drop policy if exists "Admins can update shared app state" on public.app_state;
create policy "Admins can update shared app state"
on public.app_state for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

revoke all on public.profiles from anon;
revoke all on public.app_state from anon;
grant select on public.app_state to anon;
grant usage on schema public to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, update on public.app_state to authenticated;

-- IMPORTANT: after creating your first user in Authentication > Users,
-- promote that user to admin by running the statement below with the exact login email:
-- update public.profiles set role = 'admin' where lower(email) = lower('EMAIL_ADMIN_ANDA');
