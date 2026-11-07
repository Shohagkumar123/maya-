plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.getmaya.android"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.getmaya.android"
        minSdk = 26
        targetSdk = 34
        // Mirrors the analysed shipping build.
        versionCode = 242
        versionName = "5.2.53"

        vectorDrawables { useSupportLibrary = true }

        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Mirror the shipping build's R8 configuration.
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.14"
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
        jniLibs {
            useLegacyPackaging = true
        }
    }

    androidResources {
        noCompress += listOf("tflite")
    }

    lint {
        abortOnError = false
    }
}

dependencies {
    // The clone is deliberately dependency-light: everything below is actually
    // referenced by the reconstructed sources. The shipping build bundled the
    // heavy native runtimes (ONNX / TFLite) and vision/camera SDKs; here those
    // engines are stubbed in Kotlin, so those artifacts are intentionally not
    // pulled. See README "Notes for a faithful upgrade" to re-add them.

    // ---- Core / Kotlin ----
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")

    // ---- Compose (the shipping build is fully Compose) ----
    implementation(platform("androidx.compose:compose-bom:2024.06.00"))
    implementation("androidx.activity:activity-compose:1.9.0")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.animation:animation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.material:material-ripple")

    // ---- Background work (WikiWorker / NoticeWorker / OpsUploader) ----
    implementation("androidx.work:work-runtime-ktx:2.9.0")

    // ---- Tests ----
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
}
