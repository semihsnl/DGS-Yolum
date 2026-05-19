import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'net_calculation_page.dart';

class CustomModeScreen extends StatefulWidget {
  const CustomModeScreen({super.key});

  @override
  State<CustomModeScreen> createState() => _CustomModeScreenState();
}

class _CustomModeScreenState extends State<CustomModeScreen> {
  // Canlı Mod: Süre paylaşımları tekrar dakika ölçeğine çekildi
  double _mathMinutesAllocated = 75.0; // Varsayılan Matematik süresi (Dakika)
  
  // Saniye cinsinden dinamik kalan süre sayaçları
  int _mathSecsRemaining = 0;
  int _turkishSecsRemaining = 0;

  // Kullanıcının derslerde GERÇEKTE geçirdiği süreyi tutan sayaçlar (Saniye olarak)
  int _mathSecondsSpent = 0;
  int _turkishSecondsSpent = 0;
  
  Timer? _timer;
  bool _isRunning = false;
  
  // 0: Ayarlar Ekranı, 1: Matematik Sayacı, 2: Türkçe Sayacı
  int _currentTab = 0; 
  int _startSubject = 0; // 1: Matematik, 2: Türkçe
  bool _isFirstSubjectFinished = false; // İlk seçilen dersin bitip bitmediğini kontrol eder
  
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E26),
        title: const Text("Sınavdan Çıkılsın mı?", style: TextStyle(color: Colors.white)),
        content: const Text("Sınavdan çıkmak istediğinize emin misiniz? İlerlemeniz kaybolacaktır.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İPTAL", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("ÇIK", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }

  // Akıllı Kronometre Algoritması (Otomatik Geçişli ve Gerçek Zaman Takipli)
  void _startCountdownLogic() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentTab == 1) {
          // --- MATEMATİK SAYIYOR ---
          if (_mathSecsRemaining > 0) {
            _mathSecsRemaining--;
            _mathSecondsSpent++; // Matematik ekranında kalınan her saniye kaydediliyor
          } else {
            // Matematik bitti!
            if (!_isFirstSubjectFinished && _startSubject == 1) {
              _isFirstSubjectFinished = true;
              _currentTab = 2; 
            } else {
              timer.cancel();
              _finishExamSequence();
            }
          }
        } else if (_currentTab == 2) {
          // --- TÜRKÇE SAYIYOR ---
          if (_turkishSecsRemaining > 0) {
            _turkishSecsRemaining--;
            _turkishSecondsSpent++; // Türkçe ekranında kalınan her saniye kaydediliyor
          } else {
            // Türkçe bitti!
            if (!_isFirstSubjectFinished && _startSubject == 2) {
              _isFirstSubjectFinished = true;
              _currentTab = 1;
            } else {
              timer.cancel();
              _finishExamSequence();
            }
          }
        }
      });
    });
  }

  // Kalan süreyi tek bir saniye bile kaybetmeden diğer derse aktarır
  void _switchSubjectAndTransferTime() {
    setState(() {
      if (_currentTab == 1) {
        // Matematik'ten Türkçe'ye geçiliyor
        _turkishSecsRemaining += _mathSecsRemaining;
        _mathSecsRemaining = 0; 
        _currentTab = 2; 
      } else if (_currentTab == 2) {
        // Türkçe'den Matematik'e geçiliyor
        _mathSecsRemaining += _turkishSecsRemaining;
        _turkishSecsRemaining = 0; 
        _currentTab = 1; 
      }
      
      // Kullanıcı manuel geçiş yaptığı için ilk ders döngüsünü tamamlanmış sayıyoruz
      _isFirstSubjectFinished = true; 
    });
  }

  void _finishExamSequence() {
    setState(() => _isRunning = false);
    try {
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _audioPlayer.play(AssetSource('alarm.mp3'));
    } catch (e) { debugPrint(e.toString()); }
    _showFinishDialog();
  }

  void _showFinishDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: AlertDialog(
            backgroundColor: const Color(0xFF1C1E26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF6C63FF), size: 60),
                ),
                const SizedBox(height: 24),
                const Text("Sınav Tamamlandı!", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text("Tüm derslerin süreleri başarıyla tamamlandı. Alarmı durdurup net ekranına geçebilirsiniz.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 30),
                _buildDialogButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogButton() {
    return GestureDetector(
      onTap: () {
        _audioPlayer.stop();
        Navigator.pop(context);

        // Canlı Mod Düzeltmesi: Sayaçların tuttuğu saniyeler tekrar dakikaya çevrilerek yuvarlanıyor
        int finalMathDuration = (_mathSecondsSpent / 60).round();
        int finalTurkishDuration = (_turkishSecondsSpent / 60).round();

        // Küçük yuvarlama emniyet kilitleri (Süre sıfır görünmesin)
        if (finalMathDuration == 0 && _mathSecondsSpent > 0) finalMathDuration = 1;
        if (finalTurkishDuration == 0 && _turkishSecondsSpent > 0) finalTurkishDuration = 1;

        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (context) => NetCalculationPage(
              mathDuration: finalMathDuration, 
              turkishDuration: finalTurkishDuration, 
              isTamSinav: false,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)]), borderRadius: BorderRadius.circular(15)),
        child: const Text("DURDUR VE DEVAM ET", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F111A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(_currentTab == 0 ? "Özel Süre Ayarı" : "Özel Sınav Modu", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) Navigator.pop(context);
            },
          ),
        ),
        body: _currentTab == 0 ? _buildSettingsView() : _buildExamView(),
      ),
    );
  }

  // --- 1. EKRAN: SÜRE BÖLÜŞTÜRME VE AYARLAR EKRANI ---
  Widget _buildSettingsView() {
    int matMin = _mathMinutesAllocated.toInt();
    int turMin = 135 - matMin; // Gerçek DGS Süresi (135 Dakika)

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text("Süre Dağılımı Yap", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text("Toplam 135 dakikayı derslere göre paylaştırın.", style: TextStyle(color: Colors.white38, fontSize: 13)),
          
          const SizedBox(height: 40),

          // Canlı Süre Gösterge Kartları
          Row(
            children: [
              Expanded(child: _buildTimeDisplayCard("Matematik", matMin, Colors.blue)),
              const SizedBox(width: 15),
              Expanded(child: _buildTimeDisplayCard("Türkçe", turMin, Colors.orange)),
            ],
          ),

          const SizedBox(height: 35),

          // Dinamik Süre Ayar Çubuğu (Slider)
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.orange,
              thumbColor: const Color(0xFF6C63FF),
              overlayColor: const Color(0xFF6C63FF).withOpacity(0.2),
              valueIndicatorColor: const Color(0xFF1C1E26),
            ),
            child: Slider(
              value: _mathMinutesAllocated,
              min: 15, 
              max: 120, 
              divisions: 21, 
              label: "Matematik: ${matMin} dk",
              onChanged: (value) {
                setState(() {
                  _mathMinutesAllocated = value;
                });
              },
            ),
          ),

          const SizedBox(height: 45),
          const Text("Başlangıç Dersini Seç", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Başlangıç Dersi Seçim Butonları
          Row(
            children: [
              Expanded(child: _subjectSelectionBtn("Matematik ile Başla", 1, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _subjectSelectionBtn("Türkçe ile Başla", 2, Colors.orange)),
            ],
          ),

          const SizedBox(height: 60),

          // Sınav Başlatma Butonu
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                disabledBackgroundColor: Colors.white10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
              ),
              onPressed: _startSubject == 0 ? null : () {
                setState(() {
                  // Canlı Mod Ayarı: Dakikalar tekrar saniyeye çarpılarak atanıyor (matMin * 60)
                  _mathSecsRemaining = matMin * 60;
                  _turkishSecsRemaining = turMin * 60;
                  _mathSecondsSpent = 0; 
                  _turkishSecondsSpent = 0;
                  _isRunning = true;
                  _isFirstSubjectFinished = false;
                  _currentTab = _startSubject; 
                });
                _startCountdownLogic();
              },
              child: const Text("ÖZEL SINAVI BAŞLAT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplayCard(String title, int minutes, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("$minutes dk", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _subjectSelectionBtn(String label, int val, Color color) {
    bool isSelected = _startSubject == val;
    return InkWell(
      onTap: () => setState(() => _startSubject = val),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : const Color(0xFF1C1E26),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? color : Colors.white.withOpacity(0.05), width: 1.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  // --- 2. EKRAN: SINAV GERİ SAYIM SAYACI EKRANI ---
  Widget _buildExamView() {
    bool isMathActive = _currentTab == 1;
    int currentSecs = isMathActive ? _mathSecsRemaining : _turkishSecsRemaining;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Saat:Dakika:Saniye Formatındaki Büyük Sayaç
            Text(
              _formatLongTime(currentSecs), 
              style: const TextStyle(fontSize: 70, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),

            const SizedBox(height: 60),
            
            // Kontrol Butonları Satırı
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. BUTON: Başlat / Devam Et
                Expanded(
                  child: _actionBtn(
                    _isRunning ? null : () { setState(() => _isRunning = true); _startCountdownLogic(); }, 
                    "Devam", 
                    Colors.green
                  ),
                ),
                const SizedBox(width: 10),
                
                // 2. BUTON: Durdur
                Expanded(
                  child: _actionBtn(
                    _isRunning ? () { _timer?.cancel(); setState(() => _isRunning = false); } : null, 
                    "Durdur", 
                    Colors.red
                  ),
                ),
                const SizedBox(width: 10),

                // 3. BUTON: Süre Aktararak Diğer Derse Geçiş Butonu
                Expanded(
                  child: _actionBtn(
                    () => _switchSubjectAndTransferTime(), 
                    isMathActive ? "Türkçe'ye Geç" : "Matematik'e Geç", 
                    isMathActive ? Colors.orange : Colors.blue
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatLongTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    String hoursStr = hours.toString().padLeft(2, '0');
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = seconds.toString().padLeft(2, '0');

    return "$hoursStr:$minutesStr:$secondsStr";
  }

  Widget _actionBtn(VoidCallback? on, String l, Color c) => ElevatedButton(
    onPressed: on, 
    style: ElevatedButton.styleFrom(
      backgroundColor: c, 
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ), 
    child: Text(
      l, 
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
    ),
  );
}