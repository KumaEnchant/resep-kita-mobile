importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDOSYWe1Nk4JWxm2oC1t7nzrU15CXqDTzk",
  authDomain: "resep-kita-19eb5.firebaseapp.com",
  projectId: "resep-kita-19eb5",
  storageBucket: "resep-kita-19eb5.firebasestorage.app",
  messagingSenderId: "131772921897",
  appId: "1:131772921897:web:69b89371bc5dbebf850438",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Background message:", payload);
  const { title, body } = payload.notification;
  self.registration.showNotification(title, { body });
});