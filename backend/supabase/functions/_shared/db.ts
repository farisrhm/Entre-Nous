import {
  createClient,
  SupabaseClient,
} from "npm:@supabase/supabase-js@2.119.0";
import { assertMember, Member, WeddingEntry } from "./policy.ts";

const url = Deno.env.get("SUPABASE_URL");
const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!url || !serviceRole) {
  throw new Error(
    "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required in Edge Functions env.",
  );
}

export function adminClient(): SupabaseClient {
  return createClient(url!, serviceRole!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export async function userFromAuthHeader(
  authHeader: string | null,
  admin = adminClient(),
): Promise<{ id: string }> {
  if (!authHeader) throw new Error("Connexion requise.");
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) throw new Error("Connexion requise.");
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) throw new Error("Session invalide.");
  return { id: data.user.id };
}

export async function membersFor(
  userId: string,
  admin = adminClient(),
): Promise<Member[]> {
  const { data, error } = await admin
    .from("couple_members")
    .select("user_id, display_name")
    .eq("couple_id", "couple")
    .order("created_at", { ascending: true })
    .limit(3);

  if (error) throw new Error("Impossible de lire la configuration du couple.");

  const members: Member[] = (data ?? []).map((row) => ({
    id: row.user_id as string,
    name: (row.display_name as string) || "Membre",
  }));

  assertMember(userId, members);
  return members;
}

export async function listEntries(
  admin = adminClient(),
): Promise<WeddingEntry[]> {
  const rows: Record<string, unknown>[] = [];
  let cursor: string | undefined;
  for (;;) {
    let query = admin.from("wedding_entries")
      .select("id, entry_id, kind, author_id, fields, created_at")
      .order("id", { ascending: true }).limit(100);
    if (cursor) query = query.gt("id", cursor);
    const { data, error } = await query;
    if (error) throw new Error("Impossible de lire les entrées.");
    if (!data?.length) break;
    rows.push(...data);
    cursor = String(data[data.length - 1].id);
  }
  rows.sort((a, b) =>
    String(a.created_at).localeCompare(String(b.created_at)) ||
    String(a.id).localeCompare(String(b.id))
  );
  return rows.map((row) => ({
    id: row.entry_id as string,
    kind: row.kind as string,
    authorId: row.author_id as string,
    fields: (row.fields as Record<string, unknown>) ?? {},
  }));
}

export async function getEntryByKey(
  key: string,
  admin = adminClient(),
): Promise<WeddingEntry | null> {
  const { data, error } = await admin
    .from("wedding_entries")
    .select("entry_id, kind, author_id, fields")
    .eq("key", key)
    .maybeSingle();
  if (error) throw new Error("Impossible de lire cette entrée.");
  if (!data) return null;
  return {
    id: data.entry_id as string,
    kind: data.kind as string,
    authorId: data.author_id as string,
    fields: (data.fields as Record<string, unknown>) ?? {},
  };
}
