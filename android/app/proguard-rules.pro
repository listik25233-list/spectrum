# Spectrum Android Proguard Rules

# --- Flutter Rust Bridge ---
-keep class com.spectrum.spectrum.rust.** { *; }
-keep class com.spectrum.spectrum.RustLib** { *; }
-keep class com.sun.jna.** { *; }
-dontwarn com.sun.jna.**

# --- Isar Database ---
-keep class io.isar.** { *; }
-dontwarn io.isar.**

# General Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keepattributes Signature,Enum,Annotation,InnerClasses,EnclosingMethod

# Play Core (Ignore missing references from Flutter)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.**

# FFmpegKit (Critical for startup stability - matching the 'new' fork package name)
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keep interface com.antonkarpenko.ffmpegkit.** { *; }
-keepclassmembers class com.antonkarpenko.ffmpegkit.** { *; }
-dontwarn com.antonkarpenko.ffmpegkit.**

# Also keep the original just in case of transitive deps
-keep class com.arthenica.ffmpegkit.** { *; }
-keep interface com.arthenica.ffmpegkit.** { *; }
-dontwarn com.arthenica.ffmpegkit.**

# Media Kit & JNI
-keep class com.media_kit.** { *; }
-keep class com.alexmercerind.mediakitandroidhelper.** { *; }

# Keep everything in our package to be safe with JNI/Rust
-keep class com.spectrum.spectrum.** { *; }
