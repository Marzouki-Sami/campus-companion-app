// Seeds the Firebase Emulator Suite with demo accounts and sample data.
//
//   node tool/seed_emulator.mjs <projectId>
//
// <projectId> is the projectId found in lib/firebase_options.dart. Requires
// Node 18+ and the emulators running (see README, "Run with the Firebase
// Emulator"). Existing emulator data is wiped first. Never point this at a
// real project: it only talks to localhost.

import { randomBytes } from 'node:crypto';

const projectId = process.argv[2];
if (!projectId) {
  console.error('Usage: node tool/seed_emulator.mjs <projectId>');
  process.exit(1);
}

const authHost = process.env.AUTH_EMULATOR_HOST ?? '127.0.0.1:9099';
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080';
// A fresh random password per run, printed at the end. Set DEMO_PASSWORD to
// choose your own instead.
const password = process.env.DEMO_PASSWORD ?? `${randomBytes(9).toString('base64url')}-1aA`;

const documents = `http://${firestoreHost}/v1/projects/${projectId}/databases/(default)/documents`;
const headers = { 'Content-Type': 'application/json', Authorization: 'Bearer owner' };

const str = (stringValue) => ({ stringValue });
const bool = (booleanValue) => ({ booleanValue });
const time = (date) => ({ timestampValue: date.toISOString() });
const daysFromNow = (days) => new Date(Date.now() + days * 86_400_000);

async function request(method, url, body) {
  const res = await fetch(url, { method, headers, body: body && JSON.stringify(body) });
  if (!res.ok) throw new Error(`${method} ${url} -> ${res.status} ${await res.text()}`);
  return res.json().catch(() => ({}));
}

const put = (path, fields) => request('PATCH', `${documents}/${path}`, { fields });

async function createUser(email, displayName, role) {
  const { localId } = await request(
    'POST',
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo`,
    { email, password, displayName, returnSecureToken: true },
  );
  await put(`users/${localId}`, {
    email: str(email),
    displayName: str(displayName),
    role: str(role),
    isSuspended: bool(false),
  });
  return localId;
}

await request('DELETE', `http://${authHost}/emulator/v1/projects/${projectId}/accounts`);
await request('DELETE', `http://${firestoreHost}/emulator/v1/projects/${projectId}/databases/(default)/documents`);

const student = await createUser('demostudent@campus-companion.test', 'Demo Student', 'student');
await createUser('demoprofessor@campus-companion.test', 'Prof. Martin', 'professor');
await createUser('demoadmin@campus-companion.test', 'Admin Dana', 'admin');
await createUser('alex@campus-companion.test', 'Alex Rivera', 'student');
await createUser('jordan@campus-companion.test', 'Jordan Lee', 'student');

const categories = { exams: 'Exams', events: 'Events', campus: 'Campus life' };
for (const [id, name] of Object.entries(categories)) {
  await put(`categories/${id}`, { name: str(name), createdAt: time(new Date()) });
}

const announcements = [
  ['a1', 'Midterm schedule published', 'The midterm exam timetable is now available on the student portal. Check your room assignment carefully.', 'exams', 1],
  ['a2', 'Career fair next Thursday', 'More than 40 companies will be on campus. Bring your CV and register at the front desk.', 'events', 2],
  ['a3', 'Library opening hours extended', 'During exam season the library stays open until midnight, Monday to Saturday.', 'campus', 3],
  ['a4', 'Hackathon registration open', 'Form teams of up to four people and sign up before Friday.', 'events', 5],
];
for (const [id, title, body, category, ageInDays] of announcements) {
  await put(`announcements/${id}`, {
    title: str(title),
    body: str(body),
    createdAt: time(daysFromNow(-ageInDays)),
    categories: { arrayValue: { values: [str(category)] } },
  });
}

const tasks = [
  ['t1', 'Submit algorithms assignment', 'Problem set 4, upload as PDF', -1, false],
  ['t2', 'Prepare database project demo', 'Slides and live demo', 3, false],
  ['t3', 'Read chapter 7: Networking', null, 5, false],
  ['t4', 'Book study room', null, 1, false],
  ['t5', 'Register for the hackathon', 'Team of four', -3, true],
];
for (const [id, title, description, dueInDays, isDone] of tasks) {
  const fields = { title: str(title), dueDate: time(daysFromNow(dueInDays)), isDone: bool(isDone) };
  if (description) fields.description = str(description);
  await put(`users/${student}/tasks/${id}`, fields);
}

console.log(`Seeded project "${projectId}". Sign in with <role>@campus-companion.test / ${password}`);
console.log('Accounts: demostudent, demoprofessor, demoadmin, alex, jordan');
