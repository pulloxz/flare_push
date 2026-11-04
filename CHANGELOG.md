## 0.5.0

* Notifications now show as a banner while the app is open, on Android and iPhone, the same as when the app is closed or in the background.

## 0.4.0

* `Flare.login(userId, identityToken: ...)`: projects with identity verification (on by default for new projects) need a token made by your backend, so nobody else can receive a user's notifications. Apps that only use anonymous devices do not need it.

## 0.3.0

* Removed `firebase_core` and `firebase_messaging`. Android asks Firebase for the push token through a small built-in plugin using the settings saved in Flare. iOS gets the Apple push token directly, with no Firebase at all.

## 0.2.0

* `Flare.init` now starts Firebase by itself using the settings saved in Flare, so the app needs no `google-services.json`, `GoogleService-Info.plist`, Gradle plugin, or `Firebase.initializeApp()`.

## 0.1.0

* First version: `Flare.init`, `login`, `logout`, `subscribe`, `unsubscribe`.
