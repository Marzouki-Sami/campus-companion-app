-- Photos on announcements ----------------------------------------------------
--
-- Files live in a public Storage bucket under "<announcement id>/<random>.jpg".
-- Paths are unguessable, so reading is open to anyone holding a link; writing is
-- restricted to professors and admins. The bucket itself refuses anything that is
-- not a small image.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'announcement-images',
  'announcement-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy "professors and admins upload announcement images"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'announcement-images' and public.can_manage_announcements ()
);

-- Storage looks objects up through these policies before it deletes them, so
-- the select policy is what makes removing a photo actually remove the file.
create policy "professors and admins read announcement image files"
on storage.objects for select to authenticated
using (
  bucket_id = 'announcement-images' and public.can_manage_announcements ()
);

create policy "professors and admins delete announcement images"
on storage.objects for delete to authenticated
using (
  bucket_id = 'announcement-images' and public.can_manage_announcements ()
);

create table public.announcement_images (
  id uuid primary key default gen_random_uuid(),
  announcement_id uuid not null references public.announcements (id) on delete cascade,
  path text not null unique check (path like announcement_id::text || '/%'),
  position smallint not null default 0 check (position >= 0),
  created_at timestamptz not null default now()
);

create index announcement_images_announcement_idx
  on public.announcement_images (announcement_id, position);

alter table public.announcement_images enable row level security;

create policy "active members read announcement images"
on public.announcement_images for select to authenticated
using (public.is_active_member ());

create policy "professors and admins manage announcement images"
on public.announcement_images for all to authenticated
using (public.can_manage_announcements ())
with check (public.can_manage_announcements ());

-- At most 8 photos per announcement, whatever the client does.
create function public.limit_announcement_images ()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (
    select count(*) from public.announcement_images
    where announcement_id = new.announcement_id
  ) > 8 then
    raise exception 'An announcement can have at most 8 photos'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger announcement_images_limit
after insert on public.announcement_images
for each row execute function public.limit_announcement_images ();
