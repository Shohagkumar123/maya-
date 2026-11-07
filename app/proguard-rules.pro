# Keep the app's own entry points and services.
-keep class com.getmaya.android.** { *; }
-keep class com.getmaya.android.MayaApplication { *; }

# JNI entry points.
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep native-facing classes referenced only from C++.
-keep class com.getmaya.android.agentic.HunterSttNative { *; }
-keep class com.getmaya.android.agentic.ondevice.PocketTtsNative { *; }
-keep class com.getmaya.android.voice.barge.Aec3Native { *; }
-keep class com.getmaya.android.core.engine.turn.TurnNative { *; }

# Compose
-dontwarn androidx.compose.**
