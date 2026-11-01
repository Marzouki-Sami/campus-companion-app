begin;

select plan(49);

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
select lives_ok(
  $$insert into public.tasks (title, due_date, remind_days_before)
    values ('Reminded', now() + interval '3 days', 1)$$,
  'a student can set a reminder on a task'
);
select throws_ok(
  $$insert into public.tasks (title, remind_days_before) values ('Too early', 30)$$,
  '23514',
  null,
  'a reminder cannot be more than two weeks ahead'
);
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
select lives_ok(
  $$insert into public.announcement_images (announcement_id, path, position)
    select id, id::text || '/first.jpg', 0 from public.announcements where title = 'Welcome!'$$,
  'a professor can attach a photo'
);
select lives_ok(
  $$insert into public.announcement_images (announcement_id, path, position)
    select a.id, a.id::text || '/extra-' || n || '.jpg', n
    from public.announcements a, generate_series(1, 7) as n
    where a.title = 'Welcome!'$$,
  'a professor can attach up to 8 photos'
);
select throws_ok(
  $$insert into public.announcement_images (announcement_id, path, position)
    select id, id::text || '/ninth.jpg', 8 from public.announcements where title = 'Welcome!'$$,
  '23514',
  null,
  'a ninth photo is refused'
);
select lives_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('announcement-images', 'professor-upload.jpg')$$,
  'a professor can upload to the photo bucket'
);
select is(
  (select count(*)::int from storage.objects where bucket_id = 'announcement-images'),
  1,
  'a professor can look up photo files (needed to delete them)'
);
select lives_ok(
  $$select public.save_announcement(null, 'Open day', 'Come along', '{}',
      '2030-05-01 09:00+00', '2030-05-01 12:00+00', '  Main hall  ')$$,
  'a professor can publish an event with a place'
);
select is(
  (select location from public.announcements where title = 'Open day'),
  'Main hall',
  'the place is trimmed'
);
select throws_ok(
  $$select public.save_announcement(null, 'Backwards', 'Ends first', '{}',
      '2030-05-01 12:00+00', '2030-05-01 09:00+00', null)$$,
  '23514',
  null,
  'an event cannot end before it starts'
);
select throws_ok(
  $$select public.save_announcement(null, 'Place only', 'No date', '{}',
      null, null, 'Somewhere')$$,
  '23514',
  null,
  'a place needs an event date'
);
select lives_ok(
  $$select public.save_announcement(
      (select id from public.announcements where title = 'Open day'),
      'Open day', 'Come along', '{}')$$,
  'editing without event details turns the event back into a plain announcement'
);
select is(
  (select event_start from public.announcements where title = 'Open day'),
  null,
  'the event date was cleared'
);
select lives_ok(
  $$select public.save_announcement(
      (select id from public.announcements where title = 'Open day'),
      'Open day', 'Come along', '{}', null, null, null, true)$$,
  'a professor can pin an announcement'
);
select is(
  (select is_pinned from public.announcements where title = 'Open day'),
  true,
  'the announcement is pinned'
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
select is(
  (select count(*)::int from public.announcement_images),
  8,
  'a student can see announcement photos'
);
select throws_ok(
  $$insert into public.announcement_images (announcement_id, path, position)
    select id, id::text || '/student.jpg', 0 from public.announcements limit 1$$,
  '42501',
  null,
  'a student cannot attach photos'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('announcement-images', 'student-upload.jpg')$$,
  '42501',
  null,
  'a student cannot upload to the photo bucket'
);
select is(
  (select count(*)::int from storage.objects where bucket_id = 'announcement-images'),
  0,
  'a student cannot list photo files'
);
update public.announcements set is_pinned = true where title = 'Welcome!';
select is(
  (select is_pinned from public.announcements where title = 'Welcome!'),
  false,
  'a student cannot pin an announcement'
);
select lives_ok(
  $$insert into public.announcement_reads (announcement_id)
    select id from public.announcements where title = 'Welcome!'$$,
  'a student can mark an announcement as read'
);
select throws_ok(
  $$insert into public.announcement_reads (user_id, announcement_id)
    select '00000000-0000-0000-0000-000000000002', id
    from public.announcements where title = 'Welcome!'$$,
  '42501',
  null,
  'a student cannot mark things as read for someone else'
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
select is(
  (select count(*)::int from public.announcement_reads),
  0,
  'an admin cannot see other people''s read state'
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
select is(
  (select count(*)::int from public.announcement_images),
  0,
  'a suspended user cannot see announcement photos'
);

select * from finish();

rollback;
