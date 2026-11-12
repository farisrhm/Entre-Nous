import assert from "node:assert/strict";
import {
  isPrivatePhoto,
  serialize,
  validate,
  visibleToClient,
} from "../functions/_shared/policy.ts";
import { json, preflight } from "../functions/_shared/http.ts";
const a = "b52d499a-f6a9-4772-ad91-149d853e36e5",
  b = "86828ab6-34fb-4956-b54c-607d945cb445";
const members = [{ id: a, name: "Alyssa" }, { id: b, name: "Faris" }];
Deno.test("private photo references accept only canonical private object paths", () => {
  const photo = `storage:wedding-photos/${a}/${"a".repeat(32)}.jpeg`;
  assert(isPrivatePhoto(photo));
  const clean = validate(
    "memory",
    { title: "Album", photos: [photo] },
    members,
    a,
  );
  assert.equal(clean.photo, photo);
  for (
    const invalid of [
      photo.replace("wedding-photos", "public"),
      photo + "/../secret",
      "https://example.com/photo.jpg",
    ]
  ) {
    assert.throws(() =>
      validate("memory", { title: "Album", photos: [invalid] }, members, a)
    );
  }
  const entry = { id: "m", kind: "memory", authorId: a, fields: clean };
  assert.equal(visibleToClient(entry, 2), false);
  assert.equal(visibleToClient(entry, 3), true);
  assert.deepEqual(
    validate(
      "memory",
      { title: "Album", photo: "data:image/jpeg;base64,/9j/", photos: [] },
      members,
      a,
    ).photos,
    [],
  );
});
Deno.test("delayed letters stay hidden until server time", () => {
  const entry = {
    id: "l",
    kind: "letter",
    authorId: a,
    fields: {
      title: "Later",
      body: "Secret",
      recipientId: b,
      openAt: "2030-01-01T00:00:00Z",
    },
  };
  assert.equal(
    serialize(entry, b, new Date("2029-01-01"))?.fields.body,
    undefined,
  );
  assert.equal(
    serialize(entry, a, new Date("2029-01-01"))?.fields.body,
    "Secret",
  );
  assert.equal(
    serialize(entry, b, new Date("2030-01-01"))?.fields.body,
    "Secret",
  );
  assert.equal(serialize(entry, "outsider"), null);
});
Deno.test("preflight and denied replies include CORS", () => {
  assert.equal(
    preflight(new Request("https://example.com", { method: "OPTIONS" }))
      ?.status,
    204,
  );
  assert.equal(
    preflight(new Request("https://example.com", { method: "POST" })),
    null,
  );
  assert.equal(
    json({ error: "Denied" }, 403).headers.get("Access-Control-Allow-Origin"),
    "*",
  );
});
