-- Campus Companion: initial schema, Row Level Security and helpers.
--
-- Roles: student (default) < professor < admin. Everything is denied unless a
-- policy below allows it, and suspended users are denied everywhere except
-- reading their own profile (so the app can tell them why they are blocked).

create type public.user_role as enum ('student', 'professor', 'admin');

-- Tables --------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  display_name text check (char_length(display_name) <= 80),
  role public.user_role not null default 'student',
  is_suspended boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 40),
  created_at timestamptz not null default now()
);

create unique index categories_name_unique on public.categories (lower(btrim(name)));

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 1 and 120),
  body text not null check (char_length(btrim(body)) between 1 and 5000),
  created_by uuid default auth.uid () references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create index announcements_created_at_idx on public.announcements (created_at desc);

create table public.announcement_categories (
  announcement_id uuid not null references public.announcements (id) on delete cascade,
  category_id uuid not null references public.categories (id) on delete cascade,
  primary key (announcement_id, category_id)
);

create index announcement_categories_category_idx
  on public.announcement_categories (category_id);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid () references public.profiles (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 120),
  description text check (char_length(description) <= 2000),
  due_date timestamptz,
  is_done boolean not null default false,
  created_at timestamptz not null default now()
);

create index tasks_user_idx on public.tasks (user_id);

-- Helpers used by the policies ---------------------------------------------

-- SECURITY DEFINER so the policies can read profiles without recursing into
-- the profiles policies themselves.
create function public.is_active_member ()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid ()) and not is_suspended
  );
$$;

create function public.is_admin ()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid ()) and role = 'admin' and not is_suspended
  );
$$;

create function public.can_manage_announcements ()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid ())
      and role in ('professor', 'admin')
      and not is_suspended
  );
$$;

revoke execute on function public.is_active_member () from public, anon;
revoke execute on function public.is_admin () from public, anon;
revoke execute on function public.can_manage_announcements () from public, anon;
grant execute on function public.is_active_member () to authenticated;
grant execute on function public.is_admin () to authenticated;
grant execute on function public.can_manage_announcements () to authenticated;

-- Profile creation and protection -------------------------------------------

-- Every new auth user gets a profile. The role is always 'student': nothing a
-- client sends can choose it.
create function public.handle_new_user ()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    coalesce(new.email, ''),
    nullif(btrim(coalesce(new.raw_user_meta_data ->> 'display_name', '')), '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user ();

-- Only admins may change roles or suspension, and nobody may change their own
-- (so the last admin cannot lock themselves out). Calls made without a user
-- (service role, migrations, seeds) are trusted.
create function public.protect_profile_columns ()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if (select auth.uid ()) is null then
    return new;
  end if;

  if new.id is distinct from old.id or new.email is distinct from old.email then
    raise exception 'This field cannot be changed' using errcode = '42501';
  end if;

  if new.role is distinct from old.role
     or new.is_suspended is distinct from old.is_suspended then
    if not public.is_admin () then
      raise exception 'Only administrators can change roles or suspension'
        using errcode = '42501';
    end if;
    if new.id = (select auth.uid ()) then
      raise exception 'You cannot change your own role or suspension'
        using errcode = '42501';
    end if;
  end if;

  return new;
end;
$$;

create trigger protect_profile_columns
before update on public.profiles
for each row execute function public.protect_profile_columns ();

-- Row Level Security --------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.announcements enable row level security;
alter table public.announcement_categories enable row level security;
alter table public.tasks enable row level security;

-- profiles: read your own (even if suspended) or, as admin, everyone's.
create policy "profiles are readable by their owner and admins"
on public.profiles for select to authenticated
using (id = (select auth.uid ()) or public.is_admin ());

create policy "owners update their profile, admins update anyone"
on public.profiles for update to authenticated
using (
  public.is_admin ()
  or (id = (select auth.uid ()) and public.is_active_member ())
)
with check (
  public.is_admin ()
  or (id = (select auth.uid ()) and public.is_active_member ())
);

-- categories
create policy "active members read categories"
on public.categories for select to authenticated
using (public.is_active_member ());

create policy "admins manage categories"
on public.categories for all to authenticated
using (public.is_admin ())
with check (public.is_admin ());

-- announcements
create policy "active members read announcements"
on public.announcements for select to authenticated
using (public.is_active_member ());

create policy "professors and admins create announcements"
on public.announcements for insert to authenticated
with check (
  public.can_manage_announcements () and created_by = (select auth.uid ())
);

create policy "professors and admins edit announcements"
on public.announcements for update to authenticated
using (public.can_manage_announcements ())
with check (public.can_manage_announcements ());

create policy "professors and admins delete announcements"
on public.announcements for delete to authenticated
using (public.can_manage_announcements ());

create policy "active members read announcement categories"
on public.announcement_categories for select to authenticated
using (public.is_active_member ());

create policy "professors and admins manage announcement categories"
on public.announcement_categories for all to authenticated
using (public.can_manage_announcements ())
with check (public.can_manage_announcements ());

-- tasks: strictly private to their owner.
create policy "owners manage their tasks"
on public.tasks for all to authenticated
using (user_id = (select auth.uid ()) and public.is_active_member ())
with check (user_id = (select auth.uid ()) and public.is_active_member ());

-- Atomic announcement save --------------------------------------------------

-- Creates or updates an announcement and replaces its categories in one
-- transaction. SECURITY INVOKER: the caller's own policies still apply.
create function public.save_announcement (
  p_id uuid,
  p_title text,
  p_body text,
  p_category_ids uuid[]
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if p_id is null then
    insert into public.announcements (title, body)
    values (p_title, p_body)
    returning id into v_id;
  else
    update public.announcements
    set title = p_title, body = p_body
    where id = p_id
    returning id into v_id;

    if v_id is null then
      raise exception 'Announcement not found' using errcode = 'P0002';
    end if;

    delete from public.announcement_categories where announcement_id = v_id;
  end if;

  insert into public.announcement_categories (announcement_id, category_id)
  select distinct v_id, c from unnest(coalesce(p_category_ids, '{}')) as c;

  return v_id;
end;
$$;

revoke execute on function public.save_announcement (uuid, text, text, uuid[])
  from public, anon;
grant execute on function public.save_announcement (uuid, text, text, uuid[])
  to authenticated;
