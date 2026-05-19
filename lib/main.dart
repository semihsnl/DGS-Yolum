import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemChrome için bu kütüphane şart
import 'screens/home_page.dart';
import 'screens/splash_screen.dart'; // YENİ: Açılış ekranını kullanabilmek için import ettik

void main() {
  // Flutter bağlamını ve servislerini başlatır
  WidgetsFlutterBinding.ensureInitialized();
  
  // Üstteki bildirim çubuğunu tamamen gizler (Ekran görüntüsü için en temiz yöntem)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
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
      // GÜNCELLEME: Uygulama artık doğrudan HomePage ile değil, SplashScreen ile başlıyor
      home: const SplashScreen(),
    );
  }
}