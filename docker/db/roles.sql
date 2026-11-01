-- Gives the Supabase service roles the generated database password. The
-- Postgres image runs this once, when the database volume is first created.
\set pgpass `echo "$POSTGRES_PASSWORD"`

alter user authenticator with password :'pgpass';
alter user supabase_auth_admin with password :'pgpass';
alter user supabase_storage_admin with password :'pgpass';