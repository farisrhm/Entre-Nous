// Only the Edge Function environment holds this service account's private key.
import { importPKCS8, SignJWT } from "npm:jose@6.1.3";
let cached: { token: string; expires: number } | undefined;
export type FcmAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};
export function firebaseAccount(): FcmAccount {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) throw Error("FIREBASE_SERVICE_ACCOUNT missing");
  const account = JSON.parse(raw) as FcmAccount;
  if (
    account.project_id !== "entrenous-69391" || !account.client_email ||
    !account.private_key
  ) throw Error("Unexpected Firebase project");
  return account;
}
export async function fcmAccessToken(account: FcmAccount): Promise<string> {
  if (cached && cached.expires > Date.now() + 60000) return cached.token;
  const key = await importPKCS8(account.private_key, "RS256");
  const jwt = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256" }).setIssuer(account.client_email)
    .setAudience("https://oauth2.googleapis.com/token").setIssuedAt()
    .setExpirationTime("1h").sign(key);
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
    signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) throw Error(`Google authentication ${response.status}`);
  const result = await response.json();
  cached = {
    token: result.access_token,
    expires: Date.now() + Number(result.expires_in) * 1000,
  };
  return cached.token;
}
