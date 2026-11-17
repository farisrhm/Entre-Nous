// Best-effort low-latency wakeup; cron retries independently if it is lost.
// Never let push delivery turn a successful content save into an app error.
export function wakePushWorker() {
  const secret = Deno.env.get("PUSH_DISPATCH_SECRET");
  const url = Deno.env.get("SUPABASE_URL");
  const runtime = (globalThis as unknown as {
    EdgeRuntime?: { waitUntil(promise: Promise<unknown>): void };
  }).EdgeRuntime;
  if (!secret || !url || !runtime) return;
  runtime.waitUntil(
    fetch(`${url}/functions/v1/wedding-push-dispatch`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${secret}`,
        "Content-Type": "application/json",
      },
      body: "{}",
      signal: AbortSignal.timeout(10000),
    }).then(async (response) => {
      await response.body?.cancel();
    }).catch(() => {}),
  );
}
