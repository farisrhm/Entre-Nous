import { adminClient } from "../_shared/db.ts";
import { fcmAccessToken, firebaseAccount } from "../_shared/fcm.ts";
import { pushMessage } from "../_shared/push_messages.ts";
import { json } from "../_shared/http.ts";

Deno.serve(async (req: Request) => {
  const secret = Deno.env.get("PUSH_DISPATCH_SECRET");
  if (
    req.method !== "POST" || !secret ||
    req.headers.get("Authorization") !== `Bearer ${secret}`
  ) return json({ error: "Unauthorized" }, 401);
  // Validate configuration BEFORE claiming jobs; missing credentials lose nothing.
  let account, access;
  try {
    account = firebaseAccount();
    access = await fcmAccessToken(account);
  } catch (_) {
    return json({ error: "Push provider unavailable" }, 503);
  }
  const admin = adminClient();
  const { data: jobs, error } = await admin.rpc("wedding_claim_notifications");
  if (error) return json({ error: "Queue unavailable" }, 503);
  let processed = 0;
  for (const job of jobs ?? []) {
    const finish = async (status: string, reason: string | null = null) => {
      const { error } = await admin.from("wedding_notification_queue").update({
        status,
        last_error: reason,
        completed_at: new Date().toISOString(),
        locked_at: null,
      }).eq("id", job.id).eq("lease", job.lease);
      if (error) throw Error("Completion failed");
    };
    try {
      let entry: {
        id: string;
        entry_id: string;
        kind: string;
        author_id: string;
        fields: Record<string, any>;
      } | null = null;
      let coupleId = "couple";
      if (job.event === "voucher") {
        const { data: event, error: eventError } = await admin.from(
          "couple_voucher_events",
        )
          .select("voucher_id,actor_id").eq("id", job.voucher_event_id)
          .maybeSingle();
        if (eventError) throw eventError;
        if (event) {
          const { data: voucher, error: voucherError } = await admin.from(
            "couple_vouchers",
          )
            .select("id,couple_id,sender_id,recipient_id").eq(
              "id",
              event.voucher_id,
            ).maybeSingle();
          if (voucherError) throw voucherError;
          if (
            voucher &&
            [voucher.sender_id, voucher.recipient_id].includes(
              event.actor_id,
            ) &&
            job.recipient_id ===
              (event.actor_id === voucher.sender_id
                ? voucher.recipient_id
                : voucher.sender_id)
          ) {
            coupleId = voucher.couple_id;
            entry = {
              id: voucher.id,
              entry_id: voucher.id,
              kind: "voucher",
              author_id: event.actor_id,
              fields: {},
            };
          }
        }
      } else {
        const { data, error } = await admin.from("wedding_entries")
          .select("id,entry_id,kind,author_id,fields").eq("id", job.entry_uuid)
          .maybeSingle();
        if (error) throw error;
        entry = data;
      }
      const { data: members, error: membersError } = await admin.from(
        "couple_members",
      )
        .select("user_id,display_name,notification_gender").eq(
          "couple_id",
          coupleId,
        );
      if (membersError) throw membersError;
      const author = members?.find((m) => m.user_id === entry?.author_id);
      const recipient = members?.find((m) => m.user_id === job.recipient_id);
      if (
        !entry || members?.length !== 2 || !author || !recipient ||
        author.user_id === recipient.user_id ||
        ((entry.kind === "dua" || entry.kind === "letter") &&
          entry.fields.recipientId !== recipient.user_id)
      ) {
        await finish("skipped", "Content no longer eligible");
        continue;
      }
      const eventTime = job.event === "letter_ready"
        ? new Date(entry.fields.openAt).getTime()
        : new Date(job.created_at).getTime();
      if (
        !Number.isFinite(eventTime) || eventTime > Date.now() ||
        Date.now() - eventTime > 86400000
      ) {
        await finish("skipped", "Outside delivery window");
        continue;
      }
      const { data: preference, error: prefError } = await admin.from(
        "wedding_notification_preferences",
      ).select("*").eq("user_id", recipient.user_id).maybeSingle();
      if (prefError) throw prefError;
      const category = job.event === "letter_ready" ? "letter" : job.event;
      if (!preference?.enabled || preference[category] !== true) {
        await finish("skipped", "Disabled by recipient");
        continue;
      }
      const { data: devices, error: deviceError } = await admin.from(
        "wedding_push_devices",
      ).select("token").eq("user_id", recipient.user_id).lte(
        "enabled_at",
        new Date(eventTime).toISOString(),
      );
      if (deviceError) throw deviceError;
      const { data: delivered, error: deliveredError } = await admin.from(
        "wedding_notification_deliveries",
      ).select("token").eq("notification_id", job.id);
      if (deliveredError) throw deliveredError;
      const seen = new Set(delivered?.map((d) => d.token));
      for (const device of devices ?? []) {
        if (seen.has(device.token)) continue;
        // Cancel edits/deletes and reassignments right up to the send boundary.
        const { data: live, error: liveError } = await admin.from(
          "wedding_notification_queue",
        ).select("id").eq("id", job.id).eq("lease", job.lease).eq(
          "status",
          "processing",
        ).maybeSingle();
        if (liveError) throw liveError;
        if (!live) break;
        const { data: owned, error: ownedError } = await admin.from(
          "wedding_push_devices",
        ).select("token").eq("token", device.token).eq(
          "user_id",
          recipient.user_id,
        ).maybeSingle();
        if (ownedError) throw ownedError;
        if (!owned) continue;
        const message = pushMessage(
          job.event,
          author.display_name,
          author.notification_gender,
        );
        const response = await fetch(
          `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${access}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              message: {
                token: device.token,
                notification: message,
                data: {
                  notificationId: job.id,
                  recipientId: recipient.user_id,
                  kind: entry.kind,
                  entryId: entry.entry_id,
                },
                apns: {
                  headers: {
                    "apns-push-type": "alert",
                    "apns-priority": "10",
                    "apns-collapse-id": job.id,
                    "apns-expiration": String(
                      Math.floor((eventTime + 86400000) / 1000),
                    ),
                  },
                  payload: {
                    aps: { sound: "default", "thread-id": "jusqua-nous" },
                  },
                },
              },
            }),
            signal: AbortSignal.timeout(10000),
          },
        );
        if (!response.ok) {
          const result = await response.json().catch(() => ({}));
          const invalid = result.error?.details?.some((
            d: { errorCode?: string },
          ) => d.errorCode === "UNREGISTERED");
          if (invalid) {
            const { error } = await admin.from("wedding_push_devices").delete()
              .eq("token", device.token).eq("user_id", recipient.user_id);
            if (error) throw error;
            continue;
          }
          // Never log Google's response: it can echo a device token.
          throw Error(`FCM ${response.status}`);
        }
        const { error } = await admin.from("wedding_notification_deliveries")
          .upsert({ notification_id: job.id, token: device.token });
        if (error) throw error;
      }
      await finish(
        devices?.length ? "sent" : "skipped",
        devices?.length ? null : "No eligible device",
      );
      processed++;
    } catch (_) {
      const failed = job.attempts >= 8;
      await admin.from("wedding_notification_queue").update({
        status: failed ? "failed" : "pending",
        locked_at: null,
        last_error: "Delivery failed; see provider configuration or retry",
        available_at: new Date(
          Date.now() + Math.min(3600, 30 * 2 ** job.attempts) * 1000,
        ).toISOString(),
      }).eq("id", job.id).eq("lease", job.lease);
    }
  }
  return json({ processed });
});
