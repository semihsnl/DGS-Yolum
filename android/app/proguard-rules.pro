# Audioplayers kütüphanesinin kodlarının R8 tarafından silinmesini engeller
-keep class xyz.luan.audioplayers.** { *; }
-keep class com.blueprint.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**