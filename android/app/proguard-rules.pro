# ===== iText FIX =====
-keep class com.itextpdf.** { *; }
-dontwarn com.itextpdf.**

# Required for encryption / PDF internals
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Keep annotations & signatures
-keepattributes *Annotation*
-keepattributes Signature

# (Optional but safe)
-keep class kotlin.** { *; }
-dontwarn kotlin.**