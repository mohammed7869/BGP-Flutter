importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// Initialize the Firebase app in the service worker by passing in your app's Firebase config object.
// Using values from your android google-services.json
firebase.initializeApp({
  apiKey: "AIzaSyDWWtLItMO10lVta87drHP4iPMajVAYXzQ",
  authDomain: "burhani-guards-pune.firebaseapp.com",
  projectId: "burhani-guards-pune",
  storageBucket: "burhani-guards-pune.firebasestorage.app",
  messagingSenderId: "850751814134",
  appId: "1:850751814134:web:YOUR_WEB_APP_ID" // Ideally this should be the Web App ID from Firebase Console, but the Sender ID is usually enough for the background worker.
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
});
