// Entry point of the local Edge Functions container. It hands each request to
// the function named in the first path segment, e.g. /admin-delete-user.
// (The Supabase CLI generates the same kind of router for `supabase start`.)

Deno.serve(async (request: Request) => {
  const name = new URL(request.url).pathname.split('/')[1];
  if (!name || !/^[a-z0-9-]+$/i.test(name)) {
    return new Response(JSON.stringify({ error: 'Function not found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    // deno-lint-ignore no-explicit-any
    const worker = await (globalThis as any).EdgeRuntime.userWorkers.create({
      servicePath: `/home/deno/functions/${name}`,
      memoryLimitMb: 256,
      workerTimeoutMs: 60_000,
      noModuleCache: false,
      importMapPath: null,
      envVars: Object.entries(Deno.env.toObject()),
    });
    return await worker.fetch(request);
  } catch (error) {
    console.error(`Function ${name} failed`, error);
    return new Response(JSON.stringify({ error: 'Function failed' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});