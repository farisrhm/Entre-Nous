import { adminClient, membersFor, userFromAuthHeader } from "../_shared/db.ts";
import { json, preflight } from "../_shared/http.ts";

Deno.serve(async (req: Request) => {
  const early = preflight(req);
  if (early) return early;
  try {
    const admin = adminClient();
    const user = await userFromAuthHeader(
      req.headers.get("Authorization"),
      admin,
    );
    await membersFor(user.id, admin);
    const body = await req.json();
    const action = body.action;
    if (action === "preferences") {
      if (body.preferences !== undefined) {
        const allowed = [
          "enabled",
          "thought",
          "memory",
          "dua",
          "letter",
          "voucher",
        ];
        if (
          !body.preferences || typeof body.preferences !== "object" ||
          Array.isArray(body.preferences)
        ) throw Error("Réglages invalides.");
        const clean: Record<string, boolean | string> = { user_id: user.id };
        for (const [key, value] of Object.entries(body.preferences)) {
          if (!allowed.includes(key) || typeof value !== "boolean") {
            throw Error("Réglages invalides.");
          }
          clean[key] = value;
        }
        const { error } = await admin.from("wedding_notification_preferences")
          .upsert(clean);
        if (error) throw error;
      }
      const { data, error } = await admin.from(
        "wedding_notification_preferences",
      ).select("enabled,thought,memory,dua,letter,voucher").eq(
        "user_id",
        user.id,
      )
        .maybeSingle();
      if (error) throw error;
      return json({
        preferences: data ??
          {
            enabled: false,
            thought: true,
            memory: true,
            dua: true,
            letter: true,
            voucher: true,
          },
      });
    }
    const token = body.token;
    if (typeof token !== "string" || token.length < 20 || token.length > 4096) {
      throw Error("Appareil invalide.");
    }
    if (action === "register") {
      // Upsert also moves this installation when a different member signs in.
      const { data: existing, error: readError } = await admin.from(
        "wedding_push_devices",
      ).select("user_id,enabled_at").eq("token", token).maybeSingle();
      if (readError) throw readError;
      const { error } = await admin.from("wedding_push_devices").upsert({
        token,
        user_id: user.id,
        enabled_at: existing?.user_id === user.id
          ? existing.enabled_at
          : new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });
      if (error) throw error;
    } else if (action === "unregister") {
      const { error } = await admin.from("wedding_push_devices").delete().eq(
        "token",
        token,
      ).eq("user_id", user.id);
      if (error) throw error;
    } else throw Error("Action invalide.");
    return json({ ok: true });
  } catch (_) {
    return json({
      error:
        "Impossible de configurer les notifications. Vérifie ta connexion et réessaie.",
    }, 403);
  }
});
