# ============================================================================
# WCU Orthodox Fellowship — ProGuard / R8 Rules
# ============================================================================

# --- Flutter / Dart bridge --------------------------------------------------
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# --- Firebase / Google Play Services ----------------------------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# --- Firebase Crashlytics ---------------------------------------------------
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# --- Firebase Performance Monitoring ----------------------------------------
-keep class com.google.firebase.perf.** { *; }
-dontwarn com.google.firebase.perf.**

# --- Firebase App Check -----------------------------------------------------
-keep class com.google.firebase.appcheck.** { *; }
-dontwarn com.google.firebase.appcheck.**

# --- Kotlin Serialisation & Coroutines --------------------------------------
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Lazy { *; }

# --- OkHttp / Retrofit (used by Firebase internally) -----------------------
-dontwarn okhttp3.**
-dontwarn okio.**

# --- Suppress warnings for reflection-only APIs used inside AAR libraries ---
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
