// Firebase Cloud Messaging Service Worker for TruckLink PK
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker with the project's web config
firebase.initializeApp({
  apiKey: "AIzaSyBzwPSkAOpeAK3f4Sx-Dt5JiOYIPuCP7FY",
  authDomain: "trucker-s-website.firebaseapp.com",
  projectId: "trucker-s-website",
  storageBucket: "trucker-s-website.firebasestorage.app",
  messagingSenderId: "626967020032",
  appId: "1:626967020032:web:f354683bcd369b8c660ee5",
  measurementId: "G-24WC4CPKM6"
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages
const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);
  const notificationTitle = payload.notification?.title || payload.data?.title || 'TruckLink PK Notification';
  const notificationOptions = {
    body: payload.notification?.body || payload.data?.body || 'New logistics update received.',
    icon: '/icons/Icon-192.png',
    badge: '/favicon.png',
    data: payload.data || {},
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
