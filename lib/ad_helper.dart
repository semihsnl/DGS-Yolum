import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb kontrolü için

class AdHelper {
  // 🟢 1. ANASAYFA BANNER REKLAM ID'Sİ
  static String get homeBannerAdUnitId {
    if (kIsWeb) return ''; // Web üzerinde çalışıyorsa boş dönsün, çökmesin.

    if (Platform.isAndroid) {
      // 🚀 GERÇEK REKLAM AKTİF EDİLDİ:
      return 'ca-app-pub-9529454395013506/8327029846';
      
      // 🔬 Test ID'si kapatıldı:
      // return 'ca-app-pub-3940256099942544/6300978111'; 
    } else {
      return '';
    }
  }

  // 🟢 2. ÜNİVERSİTE TABAN PUANLARI SAYFASI BANNER REKLAM ID'Sİ
  static String get universityBannerAdUnitId {
    if (kIsWeb) return ''; 

    if (Platform.isAndroid) {
      // 🚀 GERÇEK REKLAM AKTİF EDİLDİ:
      return 'ca-app-pub-9529454395013506/3248203768';
      
      // 🔬 Test ID'si kapatıldı:
      // return 'ca-app-pub-3940256099942544/6300978111';
    } else {
      return '';
    }
  }
}