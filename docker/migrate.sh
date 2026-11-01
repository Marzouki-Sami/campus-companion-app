#!/bin/sh
# Applies supabase/migrations to the database once the auth and storage
# services have created their own schemas (the migrations refer to them).
# Applied migrations are remembered in supabase_migrations.schema_migrations,
# the same table the Supabase CLI uses, so it is safe to run repeatedly.
set -eu

export PGPASSWORD="${POSTGRES_PASSWORD}"
psql_run() { psql -v ON_ERROR_STOP=1 -h db -U postgres -d postgres "$@"; }

echo "Waiting for the auth and storage schemas..."
until psql_run -Atc "select to_regclass('auth.users') is not null and to_regclass('storage.buckets') is not null" 2>/dev/null | grep -q t; do
  sleep 2
done

psql_run -q <<'SQL'
create schema if not exists supabase_migrations;
create table if not exists supabase_migrations.schema_migrations (
  version text primary key,
  name text,
  statements text[]
);
SQL

for file in /migrations/*.sql; do
  version=$(basename "$file" | cut -d_ -f1)
  applied=$(psql_run -Atc "select 1 from supabase_migrations.schema_migrations where version = '$version'")
  if [ "$applied" = "1" ]; then
    continue
  fi
  echo "Applying $(basename "$file")"
  psql_run -q -1 -f "$file"
  psql_run -q -c "insert into supabase_migrations.schema_migrations (version, name) values ('$version', '$(basename "$file")')"
done

# Let the REST API notice the new tables and functions.
psql_run -q -c "notify pgrst, 'reload schema'"
echo "Database is up to date."