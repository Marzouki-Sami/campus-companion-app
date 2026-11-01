-- Events: an announcement can describe something happening at a date and place.

alter table public.announcements
  add column event_start timestamptz,
  add column event_end timestamptz,
  add column location text;

alter table public.announcements
  add constraint announcements_event_window check (
    event_end is null or (event_start is not null and event_end >= event_start)
  ),
  add constraint announcements_location_length check (
    location is null or char_length(btrim(location)) between 1 and 120
  ),
  add constraint announcements_location_needs_event check (
    location is null or event_start is not null
  );

create index announcements_event_start_idx
  on public.announcements (event_start)
  where event_start is not null;

-- Same atomic save as before, now carrying the optional event details.
drop function public.save_announcement (uuid, text, text, uuid[]);

create function public.save_announcement (
  p_id uuid,
  p_title text,
  p_body text,
  p_category_ids uuid[],
  p_event_start timestamptz default null,
  p_event_end timestamptz default null,
  p_location text default null
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
    insert into public.announcements (title, body, event_start, event_end, location)
    values (p_title, p_body, p_event_start, p_event_end, v_location)
    returning id into v_id;
  else
    update public.announcements
    set title = p_title,
        body = p_body,
        event_start = p_event_start,
        event_end = p_event_end,
        location = v_location
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
  uuid, text, text, uuid[], timestamptz, timestamptz, text
) from public, anon;
grant execute on function public.save_announcement (
  uuid, text, text, uuid[], timestamptz, timestamptz, text
) to authenticated;
