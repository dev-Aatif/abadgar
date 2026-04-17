# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# PowerSync
-keep class io.powersync.** { *; }

# Supabase
-keep class io.supabase.** { *; }

# JSON Serialization
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Keep the Kotlin standard library
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
