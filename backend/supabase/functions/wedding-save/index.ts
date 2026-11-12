import { json, preflight } from "../_shared/http.ts";
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { adminClient, membersFor, userFromAuthHeader } from "../_shared/db.ts";
import { keyFrom, validate } from "../_shared/policy.ts";

serve(async (req: Request) => {
  try {
    const early = preflight(req);
    if (early) return early;

    const admin = adminClient();
    const user = await userFromAuthHeader(
      req.headers.get("Authorization"),
      admin,
    );
    const members = await membersFor(user.id, admin);

    const body = await req.json();
    const payload = body as {
      kind?: unknown;
      id?: unknown;
      fields?: unknown;
      schemaVersion?: unknown;
    };

    const kind = String(payload.kind ?? "");
    const id = String(payload.id ?? "");
    const schemaVersion = Number(payload.schemaVersion ?? 1);

    keyFrom(kind, id);
    const clean = validate(kind, payload.fields, members, user.id);

    if (kind === "promise" && id !== `promise-${user.id}`) {
      throw new Error("Chacun écrit ses propres promesses.");
    }

    const { error } = await admin.rpc("wedding_save_atomic", {
      p_actor: user.id,
      p_kind: kind,
      p_id: id,
      p_fields: clean,
      p_schema_version: schemaVersion,
    });

    if (error) throw new Error("Sauvegarde impossible.");

    return json({ id });
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : "Erreur serveur." },
      403,
    );
  }
});
