// One-command local setup for development.
//
//   npx supabase start          # needs Docker
//   node tool/setup_local.mjs   # writes env.json and loads demo data
//
// It talks to the local Supabase only (read from `supabase status`), writes an
// uncommitted env.json for the app, and (re)creates a handful of demo
// accounts. A fresh random password is generated on every run and printed at
// the end; set DEMO_PASSWORD to choose your own. Never point this at a hosted
// project.

import { execSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { existsSync, writeFileSync } from 'node:fs';

const run = (command) => execSync(command, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });

function localStatus() {
  let output;
  try {
    output = run('npx --yes supabase status -o env');
  } catch {
    console.error('Local Supabase is not running. Start it with: npx supabase start');
    process.exit(1);
  }
  const env = {};
  for (const line of output.split('\n')) {
    const match = line.match(/^([A-Z_]+)="?(.*?)"?$/);
    if (match) env[match[1]] = match[2];
  }
  return env;
}

const status = localStatus();
const url = status.API_URL;
const publishableKey = status.PUBLISHABLE_KEY ?? status.ANON_KEY;
const serviceKey = status.SERVICE_ROLE_KEY ?? status.SECRET_KEY;
if (!url || !publishableKey || !serviceKey) {
  console.error('Could not read the local Supabase keys from `supabase status`.');
  process.exit(1);
}

if (!existsSync('env.json') || process.argv.includes('--force-env')) {
  writeFileSync(
    'env.json',
    `${JSON.stringify({ SUPABASE_URL: url, SUPABASE_PUBLISHABLE_KEY: publishableKey }, null, 2)}\n`,
  );
  console.log('Wrote env.json');
}

const password = process.env.DEMO_PASSWORD ?? `${randomBytes(9).toString('base64url')}-1aA`;
const headers = {
  'Content-Type': 'application/json',
  apikey: serviceKey,
  Authorization: `Bearer ${serviceKey}`,
};

async function call(method, path, body, extraHeaders = {}) {
  const res = await fetch(`${url}${path}`, {
    method,
    headers: { ...headers, ...extraHeaders },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${await res.text()}`);
  const text = await res.text();
  return text ? JSON.parse(text) : null;
}

const daysFromNow = (days) => new Date(Date.now() + days * 86_400_000).toISOString();

const accounts = [
  ['demostudent', 'Demo Student', 'student'],
  ['demoprofessor', 'Prof. Martin', 'professor'],
  ['demoadmin', 'Admin Dana', 'admin'],
  ['alex', 'Alex Rivera', 'student'],
  ['jordan', 'Jordan Lee', 'student'],
].map(([name, displayName, role]) => ({ email: `${name}@campus-companion.test`, displayName, role }));

// Start from a clean slate: remove previous demo users (profiles and tasks cascade).
const existing = await call('GET', '/auth/v1/admin/users?per_page=1000');
for (const user of existing.users ?? []) {
  if (user.email?.endsWith('@campus-companion.test')) {
    await call('DELETE', `/auth/v1/admin/users/${user.id}`);
  }
}
await call('DELETE', '/rest/v1/announcements?id=not.is.null');
await call('DELETE', '/rest/v1/categories?id=not.is.null');

const ids = {};
for (const account of accounts) {
  const user = await call('POST', '/auth/v1/admin/users', {
    email: account.email,
    password,
    email_confirm: true,
    user_metadata: { display_name: account.displayName },
  });
  ids[account.email] = user.id;
  if (account.role !== 'student') {
    await call('PATCH', `/rest/v1/profiles?id=eq.${user.id}`, { role: account.role });
  }
}

const categories = await call(
  'POST',
  '/rest/v1/categories',
  ['Exams', 'Events', 'Campus life'].map((name) => ({ name })),
  { Prefer: 'return=representation' },
);
const categoryId = Object.fromEntries(categories.map((c) => [c.name, c.id]));

const professorId = ids['demoprofessor@campus-companion.test'];
const announcements = [
  ['Midterm schedule published', 'The midterm exam timetable is now available on the student portal. Check your room assignment carefully.', 'Exams', 1],
  ['Career fair next Thursday', 'More than 40 companies will be on campus. Bring your CV and register at the front desk.', 'Events', 2, { daysAhead: 4, hours: 3, location: 'Main hall' }],
  ['Library opening hours extended', 'During exam season the library stays open until midnight, Monday to Saturday.', 'Campus life', 3],
  ['Hackathon registration open', 'Form teams of up to four people and sign up before Friday.', 'Events', 5, { daysAhead: 9, hours: 8, location: 'Engineering building, room B2' }],
];
for (const [title, body, category, ageInDays, event] of announcements) {
  const start = event ? new Date(daysFromNow(event.daysAhead)) : null;
  if (start) start.setUTCHours(13, 0, 0, 0);
  const [row] = await call(
    'POST',
    '/rest/v1/announcements',
    [
      {
        title,
        body,
        created_by: professorId,
        created_at: daysFromNow(-ageInDays),
        is_pinned: title === 'Midterm schedule published',
        ...(start && {
          event_start: start.toISOString(),
          event_end: new Date(start.getTime() + event.hours * 3600000).toISOString(),
          location: event.location,
        }),
      },
    ],
    { Prefer: 'return=representation' },
  );
  await call('POST', '/rest/v1/announcement_categories', [
    { announcement_id: row.id, category_id: categoryId[category] },
  ]);
}

const studentId = ids['demostudent@campus-companion.test'];
const tasks = [
  ['Submit algorithms assignment', 'Problem set 4, upload as PDF', -1, false],
  ['Prepare database project demo', 'Slides and live demo', 3, false],
  ['Read chapter 7: Networking', null, 5, false],
  ['Book study room', null, 1, false],
  ['Register for the hackathon', 'Team of four', -3, true],
];
await call(
  'POST',
  '/rest/v1/tasks',
  tasks.map(([title, description, dueInDays, isDone]) => ({
    user_id: studentId,
    title,
    description,
    due_date: daysFromNow(dueInDays),
    is_done: isDone,
  })),
);

console.log('\nDemo data loaded. Accounts (all use the same password):');
for (const account of accounts) console.log(`  ${account.email}  (${account.role})`);
console.log(`Password: ${password}`);
console.log('\nRun the app with: flutter run --dart-define-from-file=env.json');
