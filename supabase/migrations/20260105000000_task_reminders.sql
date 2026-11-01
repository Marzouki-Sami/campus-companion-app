-- Task reminders: how many days before the due date to be reminded (0 = on the
-- day itself). The phone schedules the actual notification; null means none.
alter table public.tasks
  add column remind_days_before smallint
  check (remind_days_before between 0 and 14);