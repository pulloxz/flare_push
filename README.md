# flare_push

Push notifications for Flutter apps on **Android** and **iPhone**, powered by the Flare service.

Flare handles Firebase, Apple's notification service, retries, scheduling and delivery reports. This package is the small piece that goes inside the app. It connects each phone to a Flare project, so notifications can be sent to everyone, to one user, to a topic, or to test phones only.

**What the package provides**

- No Firebase files or Firebase code inside the app: no `google-services.json`, no Gradle plugin, no `firebase_messaging`.
- iPhones are reached directly through Apple, with no Firebase needed for iOS.
- Notifications can be sent from the Flare dashboard or from a backend.
- Delivery reports show who received each notification and why a send failed.

## How it works

1. A project is created in the Flare dashboard, and Android and/or iPhone are connected to it.
2. This package is added to the app and started with the project's **App ID**.
3. Phones appear in the dashboard. A notification is sent, and Flare delivers it.

## Requirements

| Requirement | Reason |
|---|---|
| A Flare account and a project | Sign up in the dashboard and click **Add project** |
| Flutter 3.27 or newer | The package uses recent Flutter plugin features |
| Android phones with Google Play services | Android notifications travel through Firebase. Huawei phones are coming soon |
| An iPhone and an Apple Developer account (for iOS) | Apple only delivers notifications to real iPhones, never to the simulator |

## Quick start

### 1. Connect the platforms in the dashboard

Open the project, then **Set up** (the gear icon on the project card).

**Android**

1. In the [Firebase console](https://console.firebase.google.com), choose the project, open **Project settings**, then **Service accounts**, and click **Generate new private key**.
2. In **Project settings**, open **General**, find the Android app, and download **google-services.json**. If no Android app is listed, click **Add app** and register it with the app's package name.
3. In the Flare dashboard, open the **Android** tile and upload the two files (or paste their content). Flare checks that they belong together.

Both files are needed. The service account lets Flare send notifications, and `google-services.json` lets this package start Firebase automatically.

**iPhone**

1. In the Apple Developer account, open **Keys**, create a key with **Apple Push Notifications** turned on, and download the `.p8` file. Note the Key ID. The file can only be downloaded once.
2. In the Flare dashboard, open the **Apple** tile, upload the `.p8` file, and enter the **Key ID**, the **Team ID** and the app's **bundle ID**. If the file keeps Apple's original name, the Key ID is filled in automatically.

### 2. Add the package

In `pubspec.yaml`:

```yaml
dependencies:
  flare_push:
    git:
      url: https://github.com/pulloxz/flare_push.git
```

Then run `flutter pub get`.

### 3. Set up iOS in Xcode (iPhone only)

Open `ios/Runner.xcworkspace`, select the **Runner** target, open **Signing & Capabilities**, click **+ Capability**, and add **Push Notifications**. Android needs nothing extra.

### 4. Start Flare in the app

```dart
import 'package:flare_push/flare_push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Flare.init(
    baseUrl: 'https://FLARE_ADDRESS',
    appId: 'APP_ID',
  );

  runApp(const MyApp());
}
```

- **`baseUrl`** is the web address used to open Flare, without `/dashboard`. In the dashboard's **Get started** checklist, the **See how** button shows this code with the real address and App ID already filled in.
- **`appId`** is shown on the project card and in the **App ID and API key** window. It is safe to include in the app.

`Flare.init` asks for notification permission, gets the phone's push token and registers the phone. It is called once, when the app starts.

### 5. Run the app and check

Open the app on a phone, then open the project's **Devices** tab in the dashboard. The phone appears within a few seconds.

### 6. Send the first notification

Open the project's **Send** tab, write a title and a message, keep **Everyone**, and press **Send notification**.

## Using the package

```dart
await Flare.login('user-42', identityToken: token);
await Flare.subscribe('news');
await Flare.unsubscribe('news');
await Flare.logout();
```

| Call | What it does |
|---|---|
| `Flare.init(baseUrl:, appId:)` | Starts Flare, asks for permission and registers the phone |
| `Flare.login(userId, identityToken:)` | Links the phone to a user, so notifications can be sent to that user |
| `Flare.logout()` | Removes that link. Called when the user signs out |
| `Flare.subscribe(topic)` | Joins a topic, so notifications can be sent to everyone in it |
| `Flare.unsubscribe(topic)` | Leaves a topic |

Good habits:

- Call `Flare.login` every time the app starts with a signed-in user. It is cheap, and it keeps the link correct if the phone's push token changed.
- Call `Flare.logout` when the user signs out, so the next person on the phone does not receive the previous user's notifications.
- Topic names can use letters, digits and `_ . ~ % -`, up to 100 characters.
- `login`, `logout`, `subscribe` and `unsubscribe` throw a `FlareException` (with `message` and `statusCode`) when Flare refuses the request or cannot be reached. The message can be shown to the user, or the call can be retried later.
- `init` does not throw for registration problems. It prints them in the debug console (lines starting with `Flare:`), and `login` or `subscribe` tries again.

## Identity verification

The App ID is inside every copy of the app, so anyone can find it. Without a check, a stranger could register a phone under another person's user ID and read that person's notifications.

New projects have identity verification **on**. The **backend** signs each user ID with the project's **identity secret**. The secret is in the dashboard under **Set up**, then **Security** (the dashboard asks for the account password first). The app receives the result from the backend and gives it to Flare:

```dart
final token = await backend.identityTokenFor(userId);
await Flare.login(userId, identityToken: token);
```

The token is the **HMAC-SHA256** of the user ID with the identity secret, written as lowercase hex. The Security window has ready-made code for Node, PHP and Python. In Node:

```js
import { createHmac } from "node:crypto";

const identityToken = createHmac("sha256", IDENTITY_SECRET).update(userId).digest("hex");
```

Rules:

- The identity secret stays on the backend and never goes inside the app.
- Without a valid token, `Flare.login` fails with a `FlareException`.
- Phones that never log in still receive notifications sent to **Everyone**, but they cannot join topics.
- Verification can be turned off per project in **Set up**, then **Security**. It is not recommended for apps that send private messages.

## Sending notifications

**From the dashboard:** the project's **Send** tab. Choose the audience (everyone, test users, specific user IDs, or a topic), choose the platforms, and optionally pick a date and time. The preview shows how the notification looks on Android, iPhone and Huawei.

**From a backend:** use the project's **API key** (the dashboard shows it after the account password is entered). The key stays secret and never goes inside the app.

```bash
curl -X POST https://FLARE_ADDRESS/v1/notifications \
  -H "Authorization: Bearer API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Order is ready",
    "body": "Pick it up at the counter.",
    "target": { "userIds": ["user-42"] }
  }'
```

Flare answers `202` with `{ "id": "..." }` and delivers the notification within a few seconds.

| Field | Meaning |
|---|---|
| `title` | Up to 200 characters |
| `body` | The message |
| `target` | One of `{ "all": true }`, `{ "userIds": ["..."] }` (up to 1000), `{ "topic": "news" }` or `{ "testUsers": true }` |
| `platforms` | Optional. `["android"]` or `["ios"]`. Left out, the notification goes to both |
| `data` | Optional. Extra text values, such as `{ "orderId": "1042" }` |
| `sendAt` | Optional. A date and time like `2026-12-01T09:00:00Z` to send later |

The whole message must stay under 4000 bytes. The result can be checked later with `GET /v1/notifications/{id}` and the same API key. The dashboard's **History** lists every notification, whether it came from the dashboard or the API, and how many phones received it.

## Notes for Android and iPhone

- **Permission:** the package asks for notification permission by itself. On Android 13 and newer, and on iPhone, the user sees the system question once.
- **While the app is open:** the package shows the notification as a banner on both Android and iPhone, the same as when the app is closed or in the background. Nothing extra is needed in the app.
- **Tapping a notification:** opening a specific screen when the user taps a notification is not built in yet.
- **Production addresses:** `Flare.init` should receive an `https://` address. Android blocks plain `http://` addresses unless the app specifically allows them.
- **Huawei phones without Google services:** coming soon.
- **Web and desktop:** not supported. `Flare.init` throws on the web.

## Troubleshooting

| Symptom | What to check |
|---|---|
| The phone never appears in **Devices** | The phone must be able to open the Flare address in its browser. Look in the debug console for lines starting with `Flare:`. Check the App ID. |
| The log says Firebase settings are not set | Upload `google-services.json` and the service account in the Android tile. |
| Android: token or Firebase errors | The phone needs Google Play services, and the app's package name must match the Android app registered in Firebase. |
| The iPhone appears, but no notification arrives | Check the Apple tile (key, Key ID, Team ID and bundle ID). Check the **Push Notifications** capability in Xcode. Test on a real iPhone. |
| `Flare.login` fails with "identity token" | The token must be made by the backend from the exact same user ID, using the project's identity secret. |
| `subscribe` fails with 403 | Topics need a verified phone. The user must be logged in with an identity token first. |
| History shows **failed** | Open the row. The reason is listed there, for example a missing Android or Apple setup. |
| Sent, but nothing shows on the phone | Check the phone's notification settings for the app, and that the notification permission was allowed. |

## What belongs in the app

| Value | In the app? |
|---|---|
| App ID | Yes |
| API key | **No.** Backend only |
| Identity secret | **No.** Backend only |
| Service account, `.p8` key | Never. Upload to the dashboard only |

## More

- [Changelog](CHANGELOG.md)