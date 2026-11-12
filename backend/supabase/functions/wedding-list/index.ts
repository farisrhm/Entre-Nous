import { json, preflight } from "../_shared/http.ts";
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { listEntries, membersFor, userFromAuthHeader } from "../_shared/db.ts";
import { serialize, visibleToClient } from "../_shared/policy.ts";

serve(async (req: Request) => {
  try {
    const early = preflight(req);
    if (early) return early;

    const body = await req.json().catch(() => ({}));
    const schemaVersion = Number(
      (body as { schemaVersion?: unknown })?.schemaVersion ?? 1,
    );

    const user = await userFromAuthHeader(req.headers.get("Authorization"));
    const members = await membersFor(user.id);
    const now = new Date();

    const entries = (await listEntries())
      .filter((entry) => visibleToClient(entry, schemaVersion))
      .map((entry) => serialize(entry, user.id, now))
      .filter(Boolean);

    return json({ userId: user.id, members, entries });
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : "Erreur serveur." },
      403,
    );
  }
});
