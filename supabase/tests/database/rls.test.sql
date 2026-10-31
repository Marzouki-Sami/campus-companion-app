begin;

select plan(25);

-- Fixtures (run as the superuser, so auth.uid() is null and triggers trust us)
insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-000000000001', 'student@test.local', '{"display_name": "Sam Student"}'),
  ('00000000-0000-0000-0000-000000000002', 'other@test.local', '{}'),
  ('00000000-0000-0000-0000-000000000003', 'prof@test.local', '{}'),
  ('00000000-0000-0000-0000-000000000004', 'admin@test.local', '{}'),
  ('00000000-0000-0000-0000-000000000005', 'banned@test.local', '{}');

update public.profiles set role = 'professor'
  where id = '00000000-0000-0000-0000-000000000003';
update public.profiles set role = 'admin'
  where id = '00000000-0000-0000-0000-000000000004';
update public.profiles set is_suspended = true
  where id = '00000000-0000-0000-0000-000000000005';

insert into public.categories (id, name)
  values ('10000000-0000-0000-0000-000000000001', 'Fixture category');

insert into public.tasks (user_id, title)
  values ('00000000-0000-0000-0000-000000000002', 'Other person''s task');

-- Totals as the superuser sees them, so assertions hold with or without demo data.
create temp table expected as
  select (select count(*)::int from public.categories) as categories,
         (select count(*)::int from public.profiles) as profiles;
grant select on expected to anon, authenticated;

-- Profile creation ----------------------------------------------------------
select is(
  (select role::text from public.profiles where id = '00000000-0000-0000-0000-000000000001'),
  'student',
  'new users are students'
);
select is(
  (select display_name from public.profiles where id = '00000000-0000-0000-0000-000000000001'),
  'Sam Student',
  'display name is copied from sign-up metadata'
);

-- Anonymous visitors --------------------------------------------------------
set local role anon;
select is((select count(*)::int from public.categories), 0, 'anon sees no categories');
select is((select count(*)::int from public.profiles), 0, 'anon sees no profiles');
reset role;

-- Student -------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated"}', true);
set local role authenticated;

select is((select count(*)::int from public.profiles), 1, 'a student sees only their own profile');
select throws_ok(
  $$update public.profiles set role = 'admin' where id = '00000000-0000-0000-0000-000000000001'$$,
  '42501',
  null,
  'a student cannot promote themselves'
);
select lives_ok(
  $$update public.profiles set display_name = 'Sam' where id = '00000000-0000-0000-0000-000000000001'$$,
  'a student can rename themselves'
);
select is(
  (select count(*)::int from public.categories),
  (select categories from expected),
  'a student can read every category'
);
select throws_ok(
  $$insert into public.categories (name) values ('Hacked')$$,
  '42501',
  null,
  'a student cannot create categories'
);
select throws_ok(
  $$select public.save_announcement(null, 'Hello', 'World', '{}')$$,
  '42501',
  null,
  'a student cannot publish announcements'
);
select lives_ok(
  $$insert into public.tasks (title) values ('My task')$$,
  'a student can create a task'
);
select is((select count(*)::int from public.tasks), 1, 'a student sees only their own tasks');
select throws_ok(
  $$insert into public.tasks (user_id, title) values ('00000000-0000-0000-0000-000000000002', 'Planted')$$,
  '42501',
  null,
  'a student cannot create a task for someone else'
);
reset role;

-- Professor -----------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-000000000003", "role": "authenticated"}', true);
set local role authenticated;

select lives_ok(
  $$select public.save_announcement(null, 'Welcome', 'First announcement',
      array['10000000-0000-0000-0000-000000000001']::uuid[])$$,
  'a professor can publish an announcement with categories'
);
select is(
  (select count(*)::int from public.announcement_categories ac
    join public.announcements a on a.id = ac.announcement_id
    where a.title = 'Welcome'),
  1,
  'the category link was stored'
);
select lives_ok(
  $$select public.save_announcement(
      (select id from public.announcements where title = 'Welcome'), 'Welcome!', 'Edited', '{}')$$,
  'a professor can edit an announcement and clear its categories'
);
select is(
  (select count(*)::int from public.announcement_categories ac
    join public.announcements a on a.id = ac.announcement_id
    where a.title = 'Welcome!'),
  0,
  'editing replaced the category links'
);
select is(
  (select count(*)::int from public.profiles),
  1,
  'a professor does not see other profiles'
);
select throws_ok(
  $$insert into public.categories (name) values ('Nope')$$,
  '42501',
  null,
  'a professor cannot create categories'
);
reset role;

-- Student again: cannot delete what the professor published ------------------
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated"}', true);
set local role authenticated;
delete from public.announcements where title = 'Welcome!';
select is(
  (select count(*)::int from public.announcements where title = 'Welcome!'),
  1,
  'a student cannot delete announcements'
);
reset role;

-- Admin ---------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-000000000004", "role": "authenticated"}', true);
set local role authenticated;

select is(
  (select count(*)::int from public.profiles),
  (select profiles from expected),
  'an admin sees every profile'
);
select lives_ok(
  $$update public.profiles set role = 'professor' where id = '00000000-0000-0000-0000-000000000002'$$,
  'an admin can change another user''s role'
);
select throws_ok(
  $$update public.profiles set role = 'student' where id = '00000000-0000-0000-0000-000000000004'$$,
  '42501',
  null,
  'an admin cannot demote themselves'
);
select throws_ok(
  $$insert into public.categories (name) values ('FIXTURE CATEGORY')$$,
  '23505',
  null,
  'category names are unique regardless of case'
);
reset role;

-- Suspended user ------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-000000000005", "role": "authenticated"}', true);
set local role authenticated;

select is(
  (select count(*)::int from public.announcements),
  0,
  'a suspended user cannot read announcements'
);

select * from finish();

rollback;
