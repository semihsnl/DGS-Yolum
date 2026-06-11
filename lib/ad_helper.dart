import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb kontrolü için gerekli

class AdHelper {
  static String get bannerAdUnitId {
    // Eğer uygulama şu an WEB (Chrome/Safari) üzerinde çalışıyorsa boş dönsün ve çökmesin
    if (kIsWeb) {
      return ''; 
    }
    
    // Mobil cihaz kontrolü
    if (Platform.isAndroid) {
      return 'ca-app-pub-9529454395013506/8327029846';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('Bu platformda reklam desteklenmiyor');
    }
  }
}