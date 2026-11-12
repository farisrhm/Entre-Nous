import assert from "node:assert/strict";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2.119.0";
Deno.env.set("SUPABASE_URL", "https://test.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "test-only-key");
const { listEntries, userFromAuthHeader, membersFor } = await import(
  "../functions/_shared/db.ts"
);
Deno.test("pagination returns more than 1000 entries exactly once", async () => {
  const rows = Array.from(
    { length: 1007 },
    (_, i) => ({
      id: String(i).padStart(5, "0"),
      entry_id: String(i),
      kind: "dream",
      author_id: "a",
      fields: { title: "Dream" },
      created_at: "2026-01-01",
    }),
  );
  let calls = 0;
  const admin = {
    from() {
      let cursor = "";
      let max = 0;
      const query = {
        select() {
          return query;
        },
        order() {
          return query;
        },
        limit(n: number) {
          max = n;
          return query;
        },
        gt(_key: string, value: string) {
          cursor = value;
          return query;
        },
        then(resolve: (value: unknown) => unknown) {
          calls++;
          return Promise.resolve(
            resolve({
              data: rows.filter((r) => r.id > cursor).slice(0, max),
              error: null,
            }),
          );
        },
      };
      return query;
    },
  } as unknown as SupabaseClient;
  const entries = await listEntries(admin);
  assert.equal(entries.length, 1007);
  assert.equal(new Set(entries.map((e) => e.id)).size, 1007);
  assert.equal(calls, 12);
});
Deno.test("missing and invalid JWTs never become an authenticated actor", async () => {
  const admin = {
    auth: {
      getUser: () =>
        Promise.resolve({ data: { user: null }, error: new Error("invalid") }),
    },
  } as unknown as SupabaseClient;
  await assert.rejects(userFromAuthHeader(null, admin));
  await assert.rejects(userFromAuthHeader("Bearer forged", admin));
});
Deno.test("a user outside the two configured members is denied", async () => {
  const query = {
    select() {
      return query;
    },
    eq() {
      return query;
    },
    order() {
      return query;
    },
    limit() {
      return Promise.resolve({
        data: [{ user_id: "a", display_name: "A" }, {
          user_id: "b",
          display_name: "B",
        }],
        error: null,
      });
    },
  };
  const admin = { from: () => query } as unknown as SupabaseClient;
  await assert.rejects(membersFor("outsider", admin));
  assert.equal((await membersFor("a", admin)).length, 2);
});
