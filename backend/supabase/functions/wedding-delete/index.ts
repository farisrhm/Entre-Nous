import { json, preflight } from "../_shared/http.ts";
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { adminClient, membersFor, userFromAuthHeader } from "../_shared/db.ts";
import { keyFrom } from "../_shared/policy.ts";

serve(async (req: Request) => {
  try {
    const early = preflight(req);
    if (early) return early;

    const admin = adminClient();
    const user = await userFromAuthHeader(
      req.headers.get("Authorization"),
      admin,
    );
    await membersFor(user.id, admin);

    const body = await req.json();
    const payload = body as { kind?: unknown; id?: unknown };
    const kind = String(payload.kind ?? "");
    const id = String(payload.id ?? "");
    keyFrom(kind, id);
    const { error } = await admin.rpc("wedding_delete_atomic", {
      p_actor: user.id,
      p_kind: kind,
      p_id: id,
    });
    if (error) throw new Error("Suppression impossible.");

    return json({ deleted: true });
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : "Erreur serveur." },
      403,
    );
  }
});
