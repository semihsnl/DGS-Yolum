import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'net_calculation_page.dart';

class FullExamPage extends StatefulWidget {
  const FullExamPage({super.key});

  @override
  State<FullExamPage> createState() => _FullExamPageState();
}

class _FullExamPageState extends State<FullExamPage> {
  Timer? _timer;
  int _secondsRemaining = 10; // TEST SÜRESİ
  bool _isRunning = false;
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

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _isRunning = false);
        _playFinalAlarm();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  Future<void> _playFinalAlarm() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('alarm.mp3'));
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
                  child: const Icon(Icons.alarm_on_rounded, color: Color(0xFF6C63FF), size: 60),
                ),
                const SizedBox(height: 24),
                const Text("Süre Tamamlandı!", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text("Sınav süresi sona erdi. Devam etmek için alarmı durdur.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NetCalculationPage(mathDuration: 135, turkishDuration: 135, isTamSinav: true)));
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) Navigator.pop(context);
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}", 
                   style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 50),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _actionBtn(_isRunning ? null : _startTimer, "Başlat", Colors.green),
                const SizedBox(width: 20),
                _actionBtn(_isRunning ? _pauseTimer : null, "Durdur", Colors.red),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(VoidCallback? on, String l, Color c) => ElevatedButton(
    onPressed: on, 
    style: ElevatedButton.styleFrom(backgroundColor: c, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
    child: Text(l, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  );
}