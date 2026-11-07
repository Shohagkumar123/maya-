# Maya Ai 5.2.53 — reverse-engineering analysis (REA)

Target: `/storage/emulated/0/My file/test/rea/maya-v5.2.53.apk` (41,056,648 bytes, 651 files).
Clone: `maya-clone/`.

This document records **what was recovered, how, and what could not be recovered**.
Every claim below is backed by an artefact in `.rea_work/` or by a file in the
APK; inferences are labelled as such.

---

## 1. Target identity

| Property | Value | Evidence |
|---|---|---|
| Package | `com.getmaya.android` | `AndroidManifest.decoded.xml` |
| Label | "Maya" / "Maya Ai" | `arsc_strings.txt`, `@0x7f10004a` |
| versionCode / versionName | 242 / 5.2.53 | manifest `binary` header |
| min / target / compile SDK | 26 / 34 / 34 | manifest |
| Vendor | The Hunter Ai (getmaya.online) | strings, `licences/`, site |
| Gradle / Kotlin / Java | 8.7 / 1.9.24 / 17 | DEX build metadata |
| `extractNativeLibs` / `allowBackup` | true / false | manifest |
| Application class | `com.getmaya.android.MayaApplication` | manifest |

Product (from getmaya.online, captured during recon): voice-first AI for
Windows PC + Android + smart home; Android pitch = *"Calls, WhatsApp and any app
by voice"*, *"Camera & screen vision"*; ₹699 one-time with a free tier of
"10 min voice chat a day for 2 days, then 5"; fluent English + Hindi/Hinglish;
persistent memory; wake phrase **"Hey Maya Ai"**.

---

## 2. Method

1. Unzipped the APK with `unzip` (no build tools are available on this Android
   device and `jadx`/`apktool`/`aapt` are blocked, so all parsing was done by
   hand with `xxd`/`dd`/`grep` + a JavaScript AXML/ARSC parser run through the
   `execute` tool).
2. Decoded `AndroidManifest.xml` (binary AXML) into
   `.rea_work/AndroidManifest.decoded.xml` (410 lines) with a hand-written chunk
   parser.
3. Extracted printable strings from `resources.arsc` → `.rea_work/arsc_strings.txt`
   (1,679 strings) using `grep -aoE '[ -~]{4,150}'`.
4. Extracted the named (non-R8-minified) app classes from `classes.dex` and
   `classes2.dex` → `.rea_work/app_classes_d1.txt` (36) + `app_classes_d2.txt` (4).
5. Inventoried native libs, assets, fonts and images.
6. Parsed each font's `name` + `OS/2` tables to identify families/weights.
7. Reconstructed the Compose UI from the string evidence + the product page.

> Note: the string-extraction constraints are documented in the clone README so
> the process is reproducible (`grep -aoE` with a **bounded** repetition count;
> `tr -c '[:print:]'` and unbounded quantifiers return empty/timed out and must
> not be used).

---

## 3. Manifest — components recovered (all mirrored 1:1 in the clone)

**Activities:** `MainActivity` (LAUNCHER + `SEND`/`SEND_MULTIPLE` for
`audio/*`, `application/ogg`), `ui.browser.BrowserActivity`,
`ui.ScreenCapturePermissionActivity`, `ui.facelock.FaceLockActivity`,
`ui.facelock.WatchmanActivity`, `ui.UnlockActivity` (showWhenLocked,
turnScreenOn, noHistory), `connectors.OAuthRedirectActivity` (schemes
`com.getmaya.android.oauth` and
`com.googleusercontent.apps.994106688046-mc0kjd0u5no7kl1sndvam504a0uhalur`),
`termux.TermuxPermissionActivity`, `assistant.MayaAssistActivity`
(exported, `ACTION_ASSIST`).

**Services:** `assistant.MayaVoiceInteractionService`
(`BIND_VOICE_INTERACTION`, meta-data `android.voice_interaction`),
`assistant.MayaVoiceInteractionSessionService`,
`assistant.MayaRecognitionService` (`android.speech.RecognitionService`),
`automation.MayaAccessibilityService` (`BIND_ACCESSIBILITY_SERVICE`),
`automation.MayaNotificationListener` (`BIND_NOTIFICATION_LISTENER_SERVICE`),
`core.MayaForegroundService` (`foregroundServiceType=0xe1` =
DATA_SYNC|MEDIA_PROJECTION|MICROPHONE|CAMERA),
`wallpaper.MayaWallpaperService` (`BIND_WALLPAPER`).

**Receivers (9):** `core.BootReceiver` (BOOT_COMPLETED / QUICKBOOT_POWERON /
MY_PACKAGE_REPLACED), `core.PhoneStateReceiver`, `core.MicCaptureReceiver`
(action `com.getmaya.android.CAPTURE_MIC`, guarded by the signature `DUMP`
permission), `core.DrivingOffReceiver` (`com.getmaya.android.DRIVING_OFF`),
`core.ReminderReceiver`, `core.AssistantNudgeReceiver`,
`social.SocialAlarmReceiver`, `marketing.MarketingAlarmReceiver`,
`termux.TermuxResultReceiver`.

**Providers:** `FileProvider` (`com.getmaya.android.fileprovider`).

**Permissions (38):** INTERNET, ACCESS_NETWORK_STATE, RECORD_AUDIO, CAMERA,
USE_BIOMETRIC, ACCESS_FINE/COARSE_LOCATION, FLASHLIGHT,
ACCESS_NOTIFICATION_POLICY, WRITE_SETTINGS, CALL_PHONE, SEND_SMS,
MODIFY_AUDIO_SETTINGS, BLUETOOTH_CONNECT, BLUETOOTH_SCAN
(`usesPermissionFlags=0x10000`), BLUETOOTH + BLUETOOTH_ADMIN (maxSdk 30),
POST_NOTIFICATIONS, READ_PHONE_STATE, READ_CONTACTS, ANSWER_PHONE_CALLS,
READ_CALL_LOG, READ_MEDIA_IMAGES/VIDEO/AUDIO, READ_MEDIA_VISUAL_USER_SELECTED,
READ_EXTERNAL_STORAGE (maxSdk 32), SYSTEM_ALERT_WINDOW, WAKE_LOCK,
DISABLE_KEYGUARD, FOREGROUND_SERVICE (+ MICROPHONE, MEDIA_PROJECTION, CAMERA,
DATA_SYNC), SET_ALARM, USE_EXACT_ALARM, SCHEDULE_EXACT_ALARM, the custom
**`com.huntercode.mobile.permission.MAYA_BRIDGE`**, and
`DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.

**`<queries>`:** WhatsApp, WhatsApp Business, YouTube, YouTube Music, Gaana,
Chrome, `com.huntercode.mobile`, Spotify, Termux.

---

## 4. Native libraries (prebuilt binaries)

`libonnxruntime.so` 17.5 MB, `libtensorflowlite_jni.so` 3.4 MB,
`libbarhopper_v3.so` 4.9 MB (ML Kit barcode), `libpockettts_jni.so` 1.04 MB,
`libmaya_aec3.so` 445 KB, `libhunterstt_jni.so` 336 KB,
`libturndetector_jni.so` 329 KB, `libimage_processing_util_jni.so`,
`libdatastore_shared_counter.so`, `libandroidx.graphics.path.so`.
ABIs: `arm64-v8a`, `armeabi-v7a`.

Clone impact: the JNI entry points are exposed as Kotlin `external` stubs with
graceful `System.loadLibrary` fallbacks (`agentic/HunterSttNative.kt`,
`agentic/ondevice/PocketTtsNative.kt`, `voice/barge/Aec3Native.kt`,
`core/engine/turn/TurnNative.kt`). The `externalNativeBuild`/CMake block was
**removed** from `app/build.gradle.kts` because no C++ sources ship with this
clone — see §9.

---

## 5. Assets (all copied verbatim into the clone)

- `wakeword/`: `embedding_model.tflite`, `hey_maya.tflite`,
  `hello_maya.tflite`, `wake_up_maya.tflite`, `melspectrogram.tflite`.
- `guardian/`: `silero_vad.tflite`, `models.json`, `README.txt`.
- `dtln/`: `dtln_aec_128_1.tflite`, `dtln_aec_128_2.tflite`.
- `mlkit_barcode_models/`: 3 `.tflite` files.
- `macros/builtin_macros.json`: **version 3**, 5 accessibility macros.
- `voices/`: 43 `.ogg` preview clips across `maya_*`, `friday_*`, `venom_*`.
- `licences/`: 14 files.
- `dexopt/`: `baseline.prof`, `baseline.profm`.

### Voice Guardian (from `guardian/README.txt`, verbatim facts)

On-device speaker recognition, **never uploaded**. `SpeechGate.kt` drives the
Silero LSTM; speaker models are fetched from
`https://getmaya.online/models/guardian/manifest.json`. Two documented ids —
**`rdn2b6s`** (Powerful / ReDimNet2-B6 / 3 s window) and **`ecapa6s`** (Medium /
ECAPA-TDNN / 6 s window). `GuardianModelStore` writes
`filesDir/guardian_models/<id>/` with sha256 verification and `.part`/`.ok`
sidecars. **The ids are a wire format — never rename them.** This behaviour is
implemented in
`voice/guardian/GuardianModelStore.kt`.

### Macros (from `macros/builtin_macros.json`)

The 5 shipped macros: `chatgpt image`, `gemini image`, `gemini video`,
`chatgpt se poochho`, `gemini se poochho`. The tool vocabulary the JSON uses is
`open_app_by_name`, `wait`, `tap_text`, `type_text`,
`wait_for_screen_text` (`mode` appear/disappear + `timeout_seconds`),
`read_screen_text`, `go_back`; steps may carry `_optional: true`. Implemented in
`automation/MacroEngine.kt` with the exact skip-on-optional semantics the file's
own `_why` comments describe.

---

## 6. Fonts (resolved)

Parsed each TTF's `name` + `OS/2` tables:

| APK file | Family | Weight | Clone file |
|---|---|---|---|
| `res/dW.ttf` | Inter Regular | 400 | `font/inter_regular.ttf` |
| `res/OZ.ttf` | Inter Medium | 500 | `font/inter_medium.ttf` |
| `res/XS.ttf` | Inter SemiBold | 600 | `font/inter_semibold.ttf` |
| `res/H8.ttf` | Inter Bold | 700 | `font/inter_bold.ttf` |
| `res/LM.ttf` | Nunito ExtraLight (variable: fvar/gvar/HVAR/STAT/avar) | 200 | `font/nunito_extralight.ttf` |

The build therefore ships **Inter (4 weights) + Nunito ExtraLight**; the clone's
`font/inter.xml` and `font/nunito.xml` families reproduce this.

---

## 7. Feature set (from `arsc_strings.txt`)

**Characters:** Maya, Maya Soul, Maya Pro, Maya Pro Max, Maya Swift, Friday,
Venom, Ultron, Jarvis (+ rename her). **Plans:** free tier + Pro + Pro Max.
**God Mode** — "turns ON by voice, never OFF by voice" (mirrored literally in
`MayaVoiceCommands`). **Touch Guard** — every touch = photo + warn + siren; no
first warning; a short **repeating** burst; an unlock counts as a touch; only
"touch guard band karo" stops it. **Voice Guardian** — on-device speaker
recognition, never uploaded. **Face Lock / FACE ID** — faceprints as numbers, not
photos. **Voice engine picker**: Gemini, Gemini Live, Gemini TTS, Google Cloud
TTS, OpenRouter TTS, Deepgram, Hunter STT; Hinglish, `hi-IN`, 16 kHz.
**LLM / API providers**: Groq, OpenRouter, NVIDIA NIM, DeepSeek, Together,
Mistral, Claude, OpenAI-compatible, Tavily, SerpAPI, Brave Search, Places, flux,
Pollinations. **Advanced Agentic Mode / Agentic Plan / Sub-agents**, Media mode,
Live voice, Live scene, Conversation mode, Memory, Maya Rules, Maya Sites,
Connectors, Focus mode/DND, Autostart, Battery/Data Saver, Root manager, Termux,
Phone Link (QR), HUD. **Integrations**: WhatsApp, Instagram, Facebook, LinkedIn,
X, Telegram, YouTube, Reels, Meta Ads Manager, Paytm/PhonePe/Google Pay, SMTP.

---

## 8. Named app classes (40)

`.rea_work/app_classes_d1.txt` (36) + `app_classes_d2.txt` (4):
`MainActivity`, `MayaApplication`, `agentic/HunterSttNative`,
`agentic/ondevice/PcmSink`, `agentic/ondevice/PocketTtsNative`,
`core/engine/turn/TurnNative`, `msa/vad/VadSegment`, `voice/barge/Aec3Native`,
`ui/avatar/video/SceneVariant`, `data/wiki/WikiWorker`, `notify/NoticeWorker`,
`telemetry/OpsUploader`, plus the manifest components. All are present in the
clone.

**Consequence:** the Compose screens themselves are R8-minified out of the DEX,
so they could not be recovered byte-for-byte; the clone's UI is a faithful
reconstruction from the string copy + manifest structure.

---

## 9. Limitations (explicitly)

1. **Launcher icon not recoverable.** Resource names are obfuscated
   (`res/aC.webp`, `res/as.png`) and the arsc type→name map for the icon was not
   completed, so `@0x7f0d0000` could not be resolved. The clone ships a
   hand-drawn adaptive **amber-orb** vector icon instead.
2. **Colour palette is inferred.** `resources.arsc` contains 2,705 ARGB records
   but they are overwhelmingly library colours (the app is Compose, so its
   palette lives in the DEX). The clone uses a brand palette consistent with the
   evidence (amber/orange orb, "orange light theme"): `MayaBlack #FF0E0B08`,
   `MayaAmber #FFFFB300`, `MayaOrange #FFFF6D00`, … This is documented as an
   inference in `ui/theme/Color.kt`.
3. **Compose UI reconstructed**, not extracted (see §8).
4. **`Theme.Maya` style children not decoded** from `resources.arsc`; the clone
   defines it from the inferred palette.
5. **JNI is stubbed.** The `.so` files are prebuilt binaries and are *not*
   redistributed here, so the four JNI bridges are Kotlin `external` declarations
   with `available == false` fallbacks. The CMake block was removed so the clone
   builds without native sources. To restore the real engines, drop the original
   `.so` files into `app/src/main/jniLibs/<abi>/` (the class signatures already
   match), but note the exact JNI symbol names would have to be confirmed against
   the binaries.
6. **Cloud/on-device AI behaviour** (model weights, prompts used by the vendor,
   server endpoints) cannot be fully reproduced; the clone implements the
   provider *surface* and a generic chat path.
7. **No APK was built here** — this environment has no JDK/Gradle/Android SDK.

---

## 10. Evidence index (`.rea_work/`)

- `AndroidManifest.decoded.xml` — full decoded manifest (410 lines).
- `app_classes_d1.txt` (36), `app_classes_d2.txt` (4) — named app classes.
- `arsc_strings.txt` (1,679) — UI/feature/copy evidence.
- `resources.arsc`, `classes.dex`, `classes2.dex` — raw inputs.
- `assets/`, `res/` (408 files incl. the 5 TTFs), `manifest.hex`.
- Files that are scratch/junk and can be ignored: `d1.txt`, `d2.txt`, `d2.clean`,
  `d2.words.txt`, `dex1_strings.txt`, `dex2_strings.txt`, `dex1_clean.txt`,
  `manifest_strings.txt`.
