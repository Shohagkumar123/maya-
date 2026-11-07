# Maya Ai — reconstructed Android app (clone of `maya-v5.2.53.apk`)

This is a **source reconstruction** of `com.getmaya.android` version 5.2.53
(versionCode 242), built from the shipped APK by reverse engineering — same
package, same manifest surface, same features, same look. See
[`REA_ANALYSIS.md`](REA_ANALYSIS.md) for the full evidence trail and the list of
things that could not be recovered.

> ⚠️ **You must build the APK yourself.** This working environment (Android
> device shell) has **no JDK, Gradle or Android SDK**, so no APK could be
> produced here. Open this folder in **Android Studio (JDK 17)** and press Run /
> *Build APK*, or run `gradle assembleDebug` on a machine with JDK 17 +
> Android SDK 34. The Gradle wrapper is configured for **Gradle 8.7**.

> **Note:** The wrapper scripts (`gradlew`, `gradlew.bat`) and
> `gradle/wrapper/gradle-wrapper.jar` are **not committed** (a binary JAR can't
> be generated without Gradle). Either open the project in Android Studio —
> which creates them automatically — or run `gradle wrapper` once on a machine
> that has Gradle 8.7. `./build-apk.sh` detects this and falls back to the
> system `gradle`, and the GitHub Actions workflow pins Gradle 8.7 for you.

## What it is

A voice-first AI assistant for Android: talk to it (wake phrase "Hey Maya Ai"),
or let it use the screen, the camera, accessibility, notifications and Termux to
get things done. UI is **100 % Jetpack Compose**, dark-first, warm-amber accent.
Copy is English + Hinglish, matching the original.

## Features reproduced

- **Home / Talk** — animated amber orb, status line, character switcher,
  composer (mic / send / attach), skills rail.
- **Characters** — Maya, Maya Soul, Jarvis, Friday, Venom, Ultron; Pro Max
  gating; rename her.
- **Voice engine** — STT (Hunter STT on-device, Deepgram, Android, Gemini Live),
  TTS (Gemini TTS / Gemini Live / Google Cloud / OpenRouter / Pocket TTS /
  Android), wake words ‹Hey Maya› ‹Hello Maya› ‹Wake up Maya›, 43 bundled voice
  preview clips, echo guard (AEC3 + DTLN), media mode, Hinglish.
- **Voice Guardian** — on-device speaker recognition, never uploaded; downloads
  `rdn2b6s` / `ecapa6s` models with sha256 + `.part`/`.ok` caching.
- **Face Lock / FACE ID / Watchman** — face gate, intruder view.
- **Touch Guard** — every touch photos/warns/sirens (no first warning, short
  repeating burst, unlock counts as a touch, stop only by voice).
- **God Mode** — on by voice, never off by voice.
- **Advanced Agentic Mode + built-in macros** — the accessibility macro engine
  executes the 5 shipped macros (`chatgpt image`, `gemini image`,
  `gemini video`, `chatgpt se poochho`, `gemini se poochho`) with the JSON's
  exact optional-step semantics.
- **Memory** — chats, remembered facts, face prints (as numbers).
- **Maya Rules / Maya Sites / Connectors / Termux / Phone Link (QR) / Root /
  Live scene wallpaper / Theme ("orange light theme")**.
- **Providers** — Groq, OpenRouter, NVIDIA NIM, DeepSeek, Together, Mistral,
  Claude, OpenAI-compatible, Gemini; Tavily / SerpAPI / Brave / Places.
- **Services & receivers** — voice interaction service + session, recognition
  service, assist activity, foreground service (mic + camera + data sync),
  accessibility service, notification listener, live wallpaper, boot / phone /
  mic-capture / driving-off / reminder / nudge / social / marketing / Termux
  receivers, FileProvider, OAuth redirect, screen-capture consent.

## Real vs. reconstructed

| Area | Status |
|---|---|
| Manifest (components/permissions/queries) | **Recovered 1:1** from the decoded manifest |
| App copy / feature strings | **Recovered** from `resources.arsc` |
| Fonts | **Recovered** (Inter 400/500/600/700 + Nunito ExtraLight, real files) |
| Assets (tflite/ogg/json/licences) | **Copied verbatim** |
| Macro engine behaviour | **Recovered** from `builtin_macros.json` |
| Guardian model-store behaviour | **Recovered** from `guardian/README.txt` + `models.json` |
| Compose screens | **Reconstructed** (the DEX is R8-minified) |
| Colour palette | **Inferred** (Compose palette is not in `resources.arsc`) |
| Launcher icon | **Hand-made** (original icon resources are obfuscated) |
| Native audio/STT/TTS engines | **Stubbed** Kotlin JNI bridges (no `.so` shipped here) |
| Cloud AI behaviour | **Surface only** (vendor prompts/endpoints not recoverable) |

## Layout

```
maya-clone/
├── settings.gradle.kts, build.gradle.kts, gradle.properties
├── gradle/wrapper/gradle-wrapper.properties
├── REA_ANALYSIS.md            ← findings, method, limitations
└── app/
    ├── build.gradle.kts       (AGP, Compose, SDK 34, versionCode 242)
    ├── proguard-rules.pro     (keeps app classes + native methods)
    └── src/main/
        ├── AndroidManifest.xml
        ├── assets/            ← 14 MB: wakeword, guardian, dtln, macros, voices, licences
        ├── res/               ← fonts (real), values, xml configs, icons, themes
        └── java/com/getmaya/android/
            ├── MainActivity.kt · MayaApplication.kt
            ├── assistant/     voice interaction (x2), recognition, assist activity
            ├── automation/    accessibility service, notification listener, MacroEngine
            ├── core/          Prefs, foreground service, 6 receivers, engine/, memory/
            ├── security/      TouchGuard
            ├── voice/         guardian model store, AEC3 bridge
            ├── agentic/       Hunter STT / Pocket TTS bridges, PcmSink
            ├── msa/vad/       VadSegment
            ├── data/          Http, WikiWorker
            ├── notify/ marketing/ social/ termux/ telemetry/ connectors/
            ├── model/         characters, wake words, skills, voice catalog
            ├── wallpaper/     MayaWallpaperService
            └── ui/            theme, components, screens, facelock, browser, avatar/
```

## Build steps

1. Open `maya-clone/` in **Android Studio Ladybug+** (JDK 17). Studio creates the
   missing Gradle wrapper automatically and writes `local.properties` for you.
2. Let Gradle sync (it fetches AGP 8.5.2, Kotlin 1.9.24, Compose BOM
   2024.06.00 and WorkManager — see the dependency note below).
3. Run on a device/emulator (minSdk 26). Tap through **Onboarding → Talk**.
4. Optional: add API keys in **Tools → Model & search keys** to enable cloud
   replies (the app works offline with the on-device paths otherwise).

Command line equivalent (on a machine with JDK 17 + Android SDK 34 + Gradle 8.7):

```bash
cd maya-clone
gradle wrapper                 # only if gradlew is missing
./gradlew assembleDebug        # → app/build/outputs/apk/debug/app-debug.apk
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

Or the helper script, which preflights JDK/SDK and falls back to a system
`gradle`:

```bash
./build-apk.sh
```

### Dependencies

The clone is intentionally dependency-light: the sources only reference
`core-ktx`, `activity-compose`, the Compose BOM (ui / foundation / animation /
material3 / icons-extended / ripple), WorkManager and the stdlib. The original
APK also bundled ONNX Runtime, TFLite, CameraX, ML Kit and an HTTP client; here
those engines are **stubbed in Kotlin**, so pulling those artifacts would only
add download weight and build risk. To wire the real engines, re-add them in
`app/build.gradle.kts` (see the upgrade notes).

## Notes for a faithful upgrade

- To wire the **real** native engines, drop the original
  `jniLibs/<abi>/lib*.so` from the APK into `app/src/main/jniLibs/`; the Kotlin
  `external` signatures in `agentic/`, `voice/barge/` and `core/engine/turn/`
  already match the intended shape. Confirm the exact JNI symbol names against
  the binaries before enabling.
- The original icon can be restored by exporting the adaptive icon from the APK
  once the obfuscated `res/` names are mapped.
- Swap `Prefs` (SharedPreferences) for DataStore + EncryptedSharedPreferences for
  key storage; call sites were kept behind the `Prefs` object on purpose.
