# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Supabase specific rules
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }

# Google Services and Maps
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.maps.** { *; }

# Facebook SDK
-keep class com.facebook.** { *; }

# Image picker and camera
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.camera.** { *; }

# Networking and HTTP
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-keep class com.squareup.okhttp3.** { *; }

# JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Prevent obfuscation of classes with native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep classes that are referenced in AndroidManifest.xml
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# OpenAI Dart specific rules
-keep class openai_dart.** { *; }

# Sign in with Apple
-keep class com.aboutyou.dart_packages.sign_in_with_apple.** { *; }

# Image picker and file handling
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class androidx.exifinterface.** { *; }

# Table calendar
-keep class table_calendar.** { *; }

# Lottie animations
-keep class com.airbnb.lottie.** { *; }

# Carousel slider
-keep class carousel_slider.** { *; }

# Staggered grid view
-keep class flutter_staggered_grid_view.** { *; }

# Shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# HTTP client
-keep class dart.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }

# Disable warnings for missing classes
-dontwarn okhttp3.**
-dontwarn retrofit2.**
-dontwarn com.squareup.okhttp3.**
-dontwarn io.supabase.**
-dontwarn com.supabase.**
-dontwarn com.airbnb.lottie.**
-dontwarn androidx.exifinterface.**
-dontwarn openai_dart.**
