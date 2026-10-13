# ==========================================
# FLUTTER ENGINE & BASE RULES
# ==========================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.UnusedClass { *; }
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler

# ==========================================
# FLUTTER LOCAL NOTIFICATIONS
# ==========================================
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.io.ObjectStreamMethodData writeReplace();
    java.io.ObjectStreamMethodData readResolve();
}

# ==========================================
# SENTRY FLUTTER SDK
# ==========================================
-keep class io.sentry.** { *; }
-keepclassmembers class io.sentry.** { *; }
-dontwarn io.sentry.**
-keepattributes *Annotation*, SourceFile, LineNumberTable
