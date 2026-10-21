import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ── App namespace ────────────────────────────────────────────────────────
    // Must match the package registered in google-services.json / Firebase Console.
    // To rename the package, first add the new package in Firebase Console,
    // download the updated google-services.json, THEN change this value.
    namespace = "com.example.wcu_orthodox"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // ── App Identity ────────────────────────────────────────────────────
        // Must match the package_name in google-services.json / Firebase Console.
        // To rename: add the new package in Firebase Console → download updated
        // google-services.json → THEN change applicationId here.
        applicationId = "com.example.wcu_orthodox"
        minSdk = flutter.minSdkVersion   // mobile_scanner ^6 requires API 21+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ── Split APKs per ABI ──────────────────────────────────────────────────
    // Generates one APK per CPU architecture instead of a fat APK.
    // Reduces download/install size from ~80 MB down to ~20–30 MB per device.
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = true   // also emit a universal APK for sideloading
        }
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: System.getenv("ANDROID_KEY_ALIAS")
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: System.getenv("ANDROID_KEY_PASSWORD")
            val storeFilePath: String? = keystoreProperties.getProperty("storeFile") ?: System.getenv("ANDROID_STORE_FILE")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
            }
            storePassword = keystoreProperties.getProperty("storePassword") ?: System.getenv("ANDROID_STORE_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists() || System.getenv("ANDROID_STORE_FILE") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Enable Crashlytics mapping file upload for de-obfuscated stack traces
            manifestPlaceholders["firebase_crashlytics_collection_enabled"] = "true"
        }
        debug {
            manifestPlaceholders["firebase_crashlytics_collection_enabled"] = "false"
            // google-services.json registers the base applicationId only.
            // Add a separate Firebase Android app before using a debug suffix.
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
