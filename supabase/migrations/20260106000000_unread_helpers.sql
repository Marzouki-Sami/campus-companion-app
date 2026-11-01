-- Unread bookkeeping that stays correct when the app only loads one page of
-- announcements at a time. Both run as the caller, so RLS still applies.

create function public.unread_announcement_count ()
returns integer
language sql
stable
security invoker
set search_path = ''
as $$
  select count(*)::integer
  from public.announcements a
  where not exists (
    select 1
    from public.announcement_reads r
    where r.announcement_id = a.id and r.user_id = (select auth.uid ())
  );
$$;

create function public.mark_all_announcements_read ()
returns void
language sql
security invoker
set search_path = ''
as $$
  insert into public.announcement_reads (announcement_id)
  select a.id from public.announcements a
  on conflict do nothing;
$$;

revoke execute on function public.unread_announcement_count () from public, anon;
revoke execute on function public.mark_all_announcements_read () from public, anon;
grant execute on function public.unread_announcement_count () to authenticated;
grant execute on function public.mark_all_announcements_read () to authenticated;