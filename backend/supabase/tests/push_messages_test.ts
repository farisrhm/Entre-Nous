import {
  assertEquals,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { pushMessage } from "../functions/_shared/push_messages.ts";
Deno.test("letter gender describes sender, not recipient", () => {
  assertEquals(
    pushMessage("letter", "Alyssa", "feminine").title,
    "Une lettre de ta bien-aimée 💌",
  );
  assertEquals(
    pushMessage("letter", "Faris", "masculine").title,
    "Une lettre de ton bien-aimé 💌",
  );
  assertEquals(
    pushMessage("letter", "Camille", "neutral").title,
    "Une lettre pour toi 💌",
  );
});
Deno.test("only generic messages, no letter body or invented prayer completion", () => {
  assertEquals(
    pushMessage("dua", "Faris", "masculine").body,
    "Faris t’a dédié une dou‘a.",
  );
  assertEquals(
    pushMessage("thought", "Alyssa", "feminine").title,
    "Alyssa pense à toi 🤍",
  );
  assertEquals(
    pushMessage("letter_ready", "Alyssa", "feminine").body,
    "Tu peux maintenant ouvrir la lettre d’Alyssa.",
  );
  assertThrows(() => pushMessage("invalid", "Faris", "masculine"));
});

Deno.test("voucher notifications do not disclose personal messages", () => {
  const message = pushMessage("voucher", "Alyssa", "feminine");
  assertEquals(message.title, "Les petites attentions");
  assertEquals(
    message.body,
    "Alyssa a laissé du nouveau dans votre carnet d’attentions.",
  );
});
