-- Pinned announcements and per-user read state --------------------------------

alter table public.announcements
  add column is_pinned boolean not null default false;

create index announcements_pinned_idx
  on public.announcements (is_pinned desc, created_at desc);

create table public.announcement_reads (
  user_id uuid not null default auth.uid () references public.profiles (id) on delete cascade,
  announcement_id uuid not null references public.announcements (id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (user_id, announcement_id)
);

alter table public.announcement_reads enable row level security;

-- Read state is private: nobody sees, or writes, anybody else's.
create policy "members manage their own read state"
on public.announcement_reads for all to authenticated
using (user_id = (select auth.uid ()) and public.is_active_member ())
with check (user_id = (select auth.uid ()) and public.is_active_member ());

-- Same atomic save, now with the pin flag.
drop function public.save_announcement (
  uuid, text, text, uuid[], timestamptz, timestamptz, text
);

create function public.save_announcement (
  p_id uuid,
  p_title text,
  p_body text,
  p_category_ids uuid[],
  p_event_start timestamptz default null,
  p_event_end timestamptz default null,
  p_location text default null,
  p_pinned boolean default false
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_id uuid;
  v_location text := nullif(btrim(p_location), '');
begin
  if p_id is null then
    insert into public.announcements (
      title, body, event_start, event_end, location, is_pinned
    )
    values (
      p_title, p_body, p_event_start, p_event_end, v_location, coalesce(p_pinned, false)
    )
    returning id into v_id;
  else
    update public.announcements
    set title = p_title,
        body = p_body,
        event_start = p_event_start,
        event_end = p_event_end,
        location = v_location,
        is_pinned = coalesce(p_pinned, false)
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

revoke execute on function public.save_announcement (
  uuid, text, text, uuid[], timestamptz, timestamptz, text, boolean
) from public, anon;
grant execute on function public.save_announcement (
  uuid, text, text, uuid[], timestamptz, timestamptz, text, boolean
) to authenticated;
