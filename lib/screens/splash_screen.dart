import 'package:flutter/material.dart';
import 'dart:async';
import 'home_page.dart'; // Aynı screens klasöründe oldukları için doğrudan import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// TickerProviderStateMixin'i animasyon controller'ı beslemek için ekledik
class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  
  @override
  void initState() {
    super.initState();
    
    // --- AKILLI ZIPLAMA ANİMASYONU KURULUMU ---
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 350),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: -10).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Noktaları sırayla (gecikmeli) başlatıp sonsuz döngüye sokan fonksiyon
    _startAnimationChain();

    // 3 saniye sonra HomePage'e otomatik geçiş yap
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }

  void _startAnimationChain() async {
    for (int i = 0; i < _controllers.length; i++) {
      if (!mounted) return;
      // Her noktanın zıplamaya başlaması arasına 120 milisaniye gecikme koyuyoruz (Dalga Efekti)
      await Future.delayed(const Duration(milliseconds: 120));
      _animateDot(i);
    }
  }

  void _animateDot(int index) {
    if (!mounted) return;
    // Yukarı zıpla, bitince aşağı in ve bunu sürekli tekrarla (repeat reverse)
    _controllers[index].repeat(reverse: true);
  }

  @override
  void dispose() {
    // Hafıza sızıntısı (Memory Leak) olmaması için tüm controller'ları kapatıyoruz
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A29), // Özel koyu lacivert arka plan tonu
      body: SafeArea(
        child: Stack(
          children: [
            // Merkezdeki Logo, Başlıklar ve Animasyonlu Noktalar Grubu
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Güvenli Resim Yükleme Alanı
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image_rounded, color: Colors.white24, size: 50);
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 35),

                  // Ana Başlık
                  const Text(
                    "Lisansa Giden Yolun",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 8),

                  // Alt Başlık
                  Text(
                    "Akıllı DGS Çalışma Asistanı",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(height: 65), // Noktaların zıplama payı için boşluk biraz artırıldı

                  // YENİLENDİ: Sırayla Zıplayan Üç Nokta Efekti
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _animations[index],
                        builder: (context, child) {
                          return Transform.translate(
                            // _animations y ekseninde (dikeyde) 0 ile -10 arası hareket ettirir
                            offset: Offset(0, _animations[index].value),
                            child: child,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4), // Noktalar arası mesafe
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // En Altta Sabit Duran Sürüm Numarası
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  "v1.0.4",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}