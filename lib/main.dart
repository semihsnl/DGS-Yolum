import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemChrome için bu kütüphane şart
import 'package:flutter_localizations/flutter_localizations.dart'; // 🎯 1. TÜRKÇE TAKVİM İÇİN BU IMPORT ŞART!
import 'screens/home_page.dart';
import 'screens/splash_screen.dart'; // Açılış ekranını kullanabilmek için import ettik
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  // Flutter bağlamını ve servislerini başlatır
  WidgetsFlutterBinding.ensureInitialized();
  
  // Üstteki bildirim çubuğunu tamamen gizler (Ekran görüntüsü için en temiz yöntem)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // MobileAds.instance.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DGS Yolum',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        cardColor: const Color(0xFF1C1E26),
      ),
      
      // 🎯 2. KIRMIZI EKRAN HATASINI ÇÖZEN VE TAKVİMİ TÜRKÇELEŞTİREN ASIL BLOK BURASI:
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'), // Sadece Türkçe dili desteklensin
      ],
      locale: const Locale('tr', 'TR'), // Uygulamanın varsayılan dilini Türkçe yaptık

      // Uygulama doğrudan SplashScreen ile başlıyor, senin orijinal yapın korundu
      home: const SplashScreen(),
    );
  }
}