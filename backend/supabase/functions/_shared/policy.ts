export type Member = { id: string; name: string };
export type WeddingEntry = {
  id: string;
  kind: string;
  authorId: string;
  fields: Record<string, unknown>;
};

const legacyKinds = new Set([
  "memory",
  "letter",
  "dream",
  "promise",
  "thought",
]);
const kinds = new Set([
  ...legacyKinds,
  "openWhen",
  "happiness",
  "dua",
  "intention",
]);
const personalKinds = new Set([
  "letter",
  "promise",
  "thought",
  "openWhen",
  "happiness",
  "dua",
]);

export function assertMember(
  userId: string | null | undefined,
  members: Member[],
) {
  if (
    !userId || members.length !== 2 || !members.some((m) => m.id === userId)
  ) {
    throw new Error("Cet espace est réservé aux deux membres du couple.");
  }
}

export function keyFrom(kind: string, id: string) {
  if (!/^[a-zA-Z0-9_-]{1,100}$/.test(id)) {
    throw new Error("Identifiant invalide.");
  }
  return `${kind}:${id}`;
}

function text(
  fields: Record<string, unknown>,
  key: string,
  max: number,
  required = false,
): string {
  const raw = fields[key] ?? "";
  if (typeof raw !== "string") throw new Error(`Champ invalide : ${key}`);
  const value = raw.trim();
  if (value.length > max || (required && !value)) {
    throw new Error(`Champ invalide : ${key}`);
  }
  return value;
}

export function validate(
  kind: string,
  fields: unknown,
  members: Member[],
  userId: string,
  now = new Date(),
) {
  if (!kinds.has(kind)) throw new Error("Contenu invalide.");
  if (!fields || typeof fields !== "object" || Array.isArray(fields)) {
    throw new Error("Contenu invalide.");
  }

  const source = fields as Record<string, unknown>;
  const clean: Record<string, unknown> = {
    title: text(source, "title", 160, true),
  };

  if (
    ["memory", "letter", "promise", "openWhen", "happiness", "dua", "intention"]
      .includes(kind)
  ) {
    clean.body = text(
      source,
      "body",
      20000,
      ["letter", "openWhen", "dua"].includes(kind),
    );
  }

  if (kind === "memory") {
    clean.date = text(source, "date", 100);
    const legacy = text(source, "photo", 12000000);
    const photos = source.photos === undefined
      ? (legacy ? [legacy] : [])
      : source.photos;
    if (!Array.isArray(photos) || photos.length > 8) {
      throw new Error("Un album contient au maximum 8 photos.");
    }
    if (
      photos.some(
        (p) =>
          typeof p !== "string" ||
          p.length > 12000000 ||
          !/^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$/.test(p) &&
            !isPrivatePhoto(p),
      )
    ) {
      throw new Error(
        "Les photos doivent être importées depuis la photothèque.",
      );
    }
    if (photos.reduce((sum, p) => sum + p.length, 0) > 50000000) {
      throw new Error("Cet album est trop volumineux.");
    }
    clean.photos = photos;
    clean.photo = photos[0] ?? "";
  }

  if (kind === "dream") {
    if (typeof source.done !== "boolean") {
      throw new Error("État du rêve invalide.");
    }
    clean.done = source.done;
  }

  if (["letter", "openWhen", "dua"].includes(kind)) {
    const recipientId = source.recipientId;
    const recipient = members.find((m) => m.id === recipientId);
    if (!recipient) throw new Error("Destinataire invalide.");
    clean.recipientId = recipient.id;
    clean.recipient = recipient.name;
  }

  if (kind === "letter") {
    const openAt = new Date(text(source, "openAt", 40, true));
    if (!Number.isFinite(openAt.getTime())) throw new Error("Date invalide.");
    clean.openAt = openAt.toISOString();
  }

  if (kind === "happiness") {
    const date = text(source, "date", 10, true);
    const parsed = new Date(`${date}T12:00:00Z`);
    if (
      !/^\d{4}-\d{2}-\d{2}$/.test(date) || !Number.isFinite(parsed.getTime()) ||
      parsed.toISOString().slice(0, 10) !== date
    ) {
      throw new Error("Date du bonheur invalide.");
    }
    if (typeof source.gratitude !== "boolean") {
      throw new Error("Gratitude invalide.");
    }
    clean.date = date;
    clean.gratitude = source.gratitude;
  }

  if (kind === "intention") {
    clean.action = text(source, "action", 1000, true);
  }

  if (!legacyKinds.has(kind)) clean.createdAt = now.toISOString();
  if (kind === "promise") {
    clean.title = members.find((m) => m.id === userId)?.name ?? "Promesse";
  }
  if (kind === "thought") {
    clean.title = "Je pense à toi";
    clean.sentAt = now.toISOString();
  }

  return clean;
}

export function canEdit(entry: WeddingEntry, userId: string) {
  return !personalKinds.has(entry.kind) || entry.authorId === userId;
}

export function serialize(
  entry: WeddingEntry,
  userId: string,
  now = new Date(),
) {
  const fields: Record<string, unknown> = { ...(entry.fields ?? {}) };
  if (["letter", "openWhen", "dua"].includes(entry.kind)) {
    if (entry.authorId !== userId && fields.recipientId !== userId) return null;
  }
  if (entry.kind === "letter") {
    const openAt = new Date(String(fields.openAt ?? ""));
    const available = Number.isFinite(openAt.getTime()) &&
      now.getTime() >= openAt.getTime();
    fields.available = available;
    if (entry.authorId !== userId && !available) delete fields.body;
  }
  return { ...entry, fields };
}

export function visibleToClient(entry: WeddingEntry, schemaVersion: number) {
  if (
    entry.kind === "memory" && Array.isArray(entry.fields.photos) &&
    entry.fields.photos.some((p) =>
      typeof p === "string" && isPrivatePhoto(p)
    ) && schemaVersion < 3
  ) return false;
  return schemaVersion >= 2 || legacyKinds.has(entry.kind);
}

export function assertAlbumVersion(entry: WeddingEntry, schemaVersion: number) {
  const photos = Array.isArray(entry.fields.photos)
    ? entry.fields.photos.length
    : 0;
  if (entry.kind === "memory" && photos > 1 && !(schemaVersion >= 2)) {
    throw new Error(
      "Mets l’application à jour pour modifier un album de plusieurs photos.",
    );
  }
}

export function isPrivatePhoto(value: string): boolean {
  return /^storage:wedding-photos\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/[0-9a-f]{32}\.(jpeg|png|webp)$/
    .test(value);
}
