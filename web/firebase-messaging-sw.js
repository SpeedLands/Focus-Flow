// Please see this file for the latest firebase-js-sdk version:
// https://github.com/firebase/flutterfire/blob/master/packages/firebase_core/firebase_core_web/lib/src/firebase_sdk_version.dart
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyCpaXCDivIrEIyfX9rewKRtUK_f5Bv6Ilw",
    authDomain: "focusflow-acd29.firebaseapp.com",
    databaseURL: "...",
    projectId: "focusflow-acd29",
    storageBucket: "focusflow-acd29.firebasestorage.app",
    messagingSenderId: "943908511382",
    appId: "1:943908511382:web:b367d2d5f28cf010b2acb7",
    measurementId: 'G-T47PHQSBKE',
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {
    console.log("onBackgroundMessage", message);
});