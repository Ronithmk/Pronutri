# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Firebase / Google Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# gRPC — Firestore uses gRPC channels; R8 strips enum values() needed at runtime
-keep class io.grpc.** { *; }
-keep enum io.grpc.** { *; }
-dontwarn io.grpc.**
-keep class io.grpc.internal.** { *; }
-keep class io.grpc.okhttp.** { *; }

# Preserve enum values()/valueOf() on ALL enums (fixes NoSuchMethodException: *.values [])
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Conscrypt / TLS (gRPC TLS provider)
-keep class org.conscrypt.** { *; }
-dontwarn org.conscrypt.**
-keep class com.google.android.gms.internal.p019firestore.** { *; }

# Agora RTC Engine — keep JNI bridge so native .so can call back into Java
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# Razorpay
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# androidx.window extensions & sidecar (exist on-device at runtime, not in compile classpath)
-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.sidecar.**

# OkHttp / Retrofit (used by many plugins internally)
-dontwarn okhttp3.**
-dontwarn okio.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Pedometer / sensors
-keep class androidx.health.** { *; }

# printing / pdf / share_plus
-keep class net.nfet.flutter.printing.** { *; }
-dontwarn net.nfet.flutter.printing.**
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# Android print framework
-keep class android.print.** { *; }
-dontwarn android.print.**

# General: keep annotations and native methods
-keepattributes *Annotation*
-keepattributes Signature
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepclasseswithmembernames class * {
    native <methods>;
}
