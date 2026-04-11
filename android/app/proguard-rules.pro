# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Firebase / Google Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Agora RTC Engine — keep JNI bridge so native .so can call back into Java
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# Razorpay
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# OkHttp / Retrofit (used by many plugins internally)
-dontwarn okhttp3.**
-dontwarn okio.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Pedometer / sensors
-keep class androidx.health.** { *; }

# General: keep annotations and native methods
-keepattributes *Annotation*
-keepattributes Signature
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepclasseswithmembernames class * {
    native <methods>;
}
