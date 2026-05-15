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
  int _mathMinutes = 75;
  late int _turkishMinutes;
  Timer? _currentTimer;
  int _mathSecs = 10; // TEST SÜRESİ
  int _turkishSecs = 10; // TEST SÜRESİ
  bool _isRunning = false;
  int _currentTab = 0; 
  int _startSubject = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _turkishMinutes = 135 - _mathMinutes;
  }

  @override
  void dispose() {
    _currentTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E26),
        title: const Text("Sınavdan Çıkılsın mı?", style: TextStyle(color: Colors.white)),
        content: const Text("Sınavdan çıkmak istediğinize emin misiniz?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İPTAL", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("ÇIK", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }

  void _runLogic() {
    _currentTimer?.cancel();
    _currentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentTab == 1) {
          if (_mathSecs > 0) { _mathSecs--; } 
          else { if (_startSubject == 1) { _currentTab = 2; } else { timer.cancel(); _playAlarm(); } }
        } else {
          if (_turkishSecs > 0) { _turkishSecs--; } 
          else { if (_startSubject == 2) { _currentTab = 1; } else { timer.cancel(); _playAlarm(); } }
        }
      });
    });
  }

  void _playAlarm() {
    setState(() => _isRunning = false);
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.play(AssetSource('alarm.mp3'));
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
                const Text("Özel mod süresi sona erdi. Devam etmek için alarmı durdur.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NetCalculationPage(mathDuration: _mathMinutes, turkishDuration: _turkishMinutes, isTamSinav: false)));
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
        body: _currentTab == 0 ? _buildSettings() : _buildExamView(),
      ),
    );
  }

  Widget _buildSettings() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text("Başlangıç Dersi Seç:", style: TextStyle(color: Colors.white, fontSize: 18)),
      const SizedBox(height: 30),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _modeBtn("Matematik", 1),
        const SizedBox(width: 10),
        _modeBtn("Türkçe", 2),
      ]),
      const SizedBox(height: 40),
      ElevatedButton(
        onPressed: _startSubject == 0 ? null : () { setState(() { _isRunning = true; _currentTab = _startSubject; }); _runLogic(); },
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
        child: const Text("BAŞLAT"),
      )
    ]));
  }

  Widget _modeBtn(String t, int v) => ElevatedButton(
    onPressed: () => setState(() => _startSubject = v),
    style: ElevatedButton.styleFrom(backgroundColor: _startSubject == v ? Colors.green : const Color(0xFF1C1E26)),
    child: Text(t),
  );

  Widget _buildExamView() {
    bool isMath = _currentTab == 1;
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(isMath ? "Matematik" : "Türkçe", style: TextStyle(fontSize: 32, color: isMath ? Colors.blue : Colors.orange, fontWeight: FontWeight.bold)),
      const SizedBox(height: 30),
      Text(isMath ? _format(_mathSecs) : _format(_turkishSecs), style: const TextStyle(fontSize: 80, color: Colors.white, fontWeight: FontWeight.bold)),
      const SizedBox(height: 50),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _actionBtn(_isRunning ? null : () { setState(() => _isRunning = true); _runLogic(); }, "Devam", Colors.green),
        const SizedBox(width: 20),
        _actionBtn(_isRunning ? () { _currentTimer?.cancel(); setState(() => _isRunning = false); } : null, "Durdur", Colors.red),
      ]),
    ]));
  }

  String _format(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  Widget _actionBtn(VoidCallback? on, String l, Color c) => ElevatedButton(onPressed: on, style: ElevatedButton.styleFrom(backgroundColor: c, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)), child: Text(l));
}