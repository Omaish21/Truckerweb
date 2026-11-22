const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

exports.onNotificationCreated = onDocumentCreated(
  {
    document: "notifications/{notifId}",
    region: "asia-south1",
    retry: false,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const notifData = snap.data();
    const notifId = event.params.notifId;
    const recipientId = notifData.recipientId || notifData.recipient_id;
    const title = notifData.title || "TruckLink PK Alert";
    const body = notifData.body || "New update regarding your load or route.";
    const type = notifData.type || "general";
    const loadId = notifData.loadId || notifData.load_id || "";

    const dataPayload = {
      notifId: String(notifId),
      type: String(type),
      loadId: String(loadId),
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    };
    if (notifData.metadata && typeof notifData.metadata === "object") {
      for (const [key, val] of Object.entries(notifData.metadata)) {
        if (val !== undefined && val !== null) {
          dataPayload[key] = typeof val === "object" ? JSON.stringify(val) : String(val);
        }
      }
    }

    try {
      if (recipientId === "broadcast") {
        console.log(`[FCM Broadcast] Broadcasting ${type} to topic "road_hazards": ${title}`);
        const topicMessage = {
          topic: "road_hazards",
          notification: { title, body },
          data: dataPayload,
          webpush: {
            notification: {
              title,
              body,
              icon: "/favicon.png",
              badge: "/favicon.png",
            },
            fcmOptions: {
              link: "https://trucklink-pk.web.app",
            },
          },
        };
        const response = await messaging.send(topicMessage);
        await snap.ref.update({
          dispatchedAt: FieldValue.serverTimestamp(),
          dispatchStatus: "broadcast_sent",
          messageId: response,
        });
        return { status: "broadcast_sent", messageId: response };
      }

      console.log(`[FCM Targeted] Looking up tokens for: ${recipientId}`);
      let tokens = [];

      try {
        const userDoc = await db.collection("users").doc(recipientId).get();
        if (userDoc.exists) {
          const uData = userDoc.data();
          if (Array.isArray(uData.fcmTokens)) tokens.push(...uData.fcmTokens);
          else if (typeof uData.fcmTokens === "string" && uData.fcmTokens.length > 0) tokens.push(uData.fcmTokens);
          if (Array.isArray(uData.fcm_tokens)) tokens.push(...uData.fcm_tokens);
          else if (typeof uData.fcm_tokens === "string" && uData.fcm_tokens.length > 0) tokens.push(uData.fcm_tokens);
        }
      } catch (err) {
        console.warn(`[FCM] Could not read users/${recipientId}:`, err);
      }

      try {
        const profileDoc = await db.collection("profiles").doc(recipientId).get();
        if (profileDoc.exists) {
          const pData = profileDoc.data();
          if (Array.isArray(pData.fcmTokens)) tokens.push(...pData.fcmTokens);
          else if (typeof pData.fcmTokens === "string" && pData.fcmTokens.length > 0) tokens.push(pData.fcmTokens);
          if (Array.isArray(pData.fcm_tokens)) tokens.push(...pData.fcm_tokens);
          else if (typeof pData.fcm_tokens === "string" && pData.fcm_tokens.length > 0) tokens.push(pData.fcm_tokens);
        }
      } catch (err) {
        console.warn(`[FCM] Could not read profiles/${recipientId}:`, err);
      }

      tokens = [...new Set(tokens.filter((t) => typeof t === "string" && t.trim().length > 10))];

      if (tokens.length === 0) {
        console.log(`[FCM Targeted] No active FCM tokens found for ${recipientId}`);
        await snap.ref.update({
          dispatchedAt: FieldValue.serverTimestamp(),
          dispatchStatus: "no_registered_tokens",
        });
        return { status: "no_tokens" };
      }

      console.log(`[FCM Targeted] Dispatching to ${tokens.length} token(s) for ${recipientId}`);
      const multicastMessage = {
        tokens,
        notification: { title, body },
        data: dataPayload,
        webpush: {
          notification: {
            title,
            body,
            icon: "/favicon.png",
            badge: "/favicon.png",
          },
          fcmOptions: {
            link: "https://trucklink-pk.web.app",
          },
        },
      };

      const batchResponse = await messaging.sendEachForMulticast(multicastMessage);
      console.log(`[FCM Targeted] Success: ${batchResponse.successCount}, Failures: ${batchResponse.failureCount}`);

      const tokensToRemove = [];
      batchResponse.responses.forEach((resp, idx) => {
        if (!resp.success && resp.error) {
          const errorCode = resp.error.code;
          if (
            errorCode === "messaging/invalid-registration-token" ||
            errorCode === "messaging/registration-token-not-registered"
          ) {
            tokensToRemove.push(tokens[idx]);
          }
        }
      });

      if (tokensToRemove.length > 0) {
        console.log(`[FCM Cleanup] Removing ${tokensToRemove.length} stale token(s) for ${recipientId}`);
        const removeArray = FieldValue.arrayRemove(...tokensToRemove);
        await Promise.allSettled([
          db.collection("users").doc(recipientId).set({ fcmTokens: removeArray, fcm_tokens: removeArray }, { merge: true }),
          db.collection("profiles").doc(recipientId).set({ fcmTokens: removeArray, fcm_tokens: removeArray }, { merge: true }),
        ]);
      }

      await snap.ref.update({
        dispatchedAt: FieldValue.serverTimestamp(),
        dispatchStatus: batchResponse.successCount > 0 ? "sent" : "failed",
        successCount: batchResponse.successCount,
        failureCount: batchResponse.failureCount,
      });

      return {
        status: "sent",
        successCount: batchResponse.successCount,
        failureCount: batchResponse.failureCount,
      };
    } catch (err) {
      console.error(`[FCM Error] Failed to dispatch push notification ${notifId}:`, err);
      await snap.ref.update({
        dispatchedAt: FieldValue.serverTimestamp(),
        dispatchStatus: "error",
        error: String(err),
      });
      return { status: "error", error: String(err) };
    }
  }
);
