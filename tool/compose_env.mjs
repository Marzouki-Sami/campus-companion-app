// Creates the secrets for `docker compose up`: a .env for Docker and an
// env.json for the app. Everything is random and stays on your machine
// (both files are git-ignored). Run it again with --force to start over.
//
//   node tool/compose_env.mjs

import { createHmac, randomBytes } from 'node:crypto';
import { existsSync, writeFileSync } from 'node:fs';

const force = process.argv.includes('--force');
if (existsSync('.env') && !force) {
  console.log('.env already exists; keeping it. Use --force to replace it (this also invalidates the database password).');
  process.exit(0);
}

const base64url = (input) => Buffer.from(input).toString('base64url');

function jwt(role, secret) {
  const header = base64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const now = Math.floor(Date.now() / 1000);
  const payload = base64url(
    JSON.stringify({ role, iss: 'campus-companion-local', iat: now, exp: now + 10 * 365 * 24 * 3600 }),
  );
  const signature = createHmac('sha256', secret).update(`${header}.${payload}`).digest('base64url');
  return `${header}.${payload}.${signature}`;
}

const jwtSecret = randomBytes(36).toString('base64url');
const postgresPassword = randomBytes(24).toString('base64url');
const anonKey = jwt('anon', jwtSecret);
const serviceKey = jwt('service_role', jwtSecret);
const publicUrl = 'http://127.0.0.1:8000';

writeFileSync(
  '.env',
  [
    `POSTGRES_PASSWORD=${postgresPassword}`,
    `JWT_SECRET=${jwtSecret}`,
    `ANON_KEY=${anonKey}`,
    `SERVICE_ROLE_KEY=${serviceKey}`,
    `PUBLIC_URL=${publicUrl}`,
    '',
  ].join('\n'),
);
writeFileSync(
  'env.json',
  `${JSON.stringify({ SUPABASE_URL: publicUrl, SUPABASE_PUBLISHABLE_KEY: anonKey }, null, 2)}\n`,
);

console.log('Wrote .env and env.json. Next: docker compose up -d');
console.log('On a physical phone, set PUBLIC_URL in .env and "SUPABASE_URL" in env.json to http://<your computer\'s IP>:8000,');
console.log('or use `adb reverse tcp:8000 tcp:8000` and keep 127.0.0.1.');