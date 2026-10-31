// Deletes a user account. Only administrators may call it.
//
// The app cannot delete other people's accounts itself: that needs the
// service-role key, which must never ship inside a mobile app. This function
// checks who is calling with the caller's own token, then does the privileged
// work server-side.

import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function respond(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return respond(405, { error: 'Method not allowed' });

  const authorization = request.headers.get('Authorization');
  if (!authorization) return respond(401, { error: 'Sign in first' });

  const url = Deno.env.get('SUPABASE_URL')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? serviceKey;

  // Who is calling? Acting as the caller, so Row Level Security applies.
  const asCaller = createClient(url, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const { data: caller, error: callerError } = await asCaller.auth.getUser();
  if (callerError || !caller.user) return respond(401, { error: 'Sign in first' });

  const { data: isAdmin, error: adminError } = await asCaller.rpc('is_admin');
  if (adminError || isAdmin !== true) {
    return respond(403, { error: 'Only administrators can delete accounts' });
  }

  let userId: unknown;
  try {
    ({ user_id: userId } = await request.json());
  } catch {
    return respond(400, { error: 'Send a JSON body with user_id' });
  }
  if (typeof userId !== 'string' || !UUID.test(userId)) {
    return respond(400, { error: 'user_id must be a valid id' });
  }
  if (userId === caller.user.id) {
    return respond(400, { error: 'You cannot delete your own account' });
  }

  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
  const { error } = await admin.auth.admin.deleteUser(userId);
  if (error) {
    console.error('deleteUser failed', error.message);
    return respond(error.status === 404 ? 404 : 500, {
      error: error.status === 404 ? 'That account no longer exists' : 'Could not delete the account',
    });
  }

  // The profile, tasks and sessions are removed by the database (ON DELETE CASCADE).
  return respond(200, { deleted: userId });
});
