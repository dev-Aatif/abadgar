# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# JSON Serialization
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Flutter optional Play Core deferred-components references
-dontwarn com.google.android.play.core.**

# Keep the Kotlin standard library
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
