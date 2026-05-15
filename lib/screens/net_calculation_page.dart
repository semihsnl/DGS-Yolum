import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../models/exam_result.dart';

class NetCalculationPage extends StatefulWidget {
  final int mathDuration;
  final int turkishDuration;
  final bool isTamSinav;
  final String? examName; 
  final ExamResult? existingResult; 

  const NetCalculationPage({
    super.key,
    required this.mathDuration,
    required this.turkishDuration,
    required this.isTamSinav,
    this.examName,
    this.existingResult,
  });

  @override
  State<NetCalculationPage> createState() => _NetCalculationPageState();
}

class _NetCalculationPageState extends State<NetCalculationPage> {
  late TextEditingController _mathCorrectController;
  late TextEditingController _mathWrongController;
  late TextEditingController _mathEmptyController; // Boş sorular için yeni controller
  late TextEditingController _turkishCorrectController;
  late TextEditingController _turkishWrongController;
  late TextEditingController _turkishEmptyController; // Boş sorular için yeni controller
  late TextEditingController _nameController; 

  double _mathNet = 0;
  double _turkishNet = 0;

  final ExamResultStorage _storage = ExamResultStorage(); 

  @override
  void initState() {
    super.initState();
    _mathCorrectController = TextEditingController();
    _mathWrongController = TextEditingController();
    _mathEmptyController = TextEditingController(); // Başlatıldı
    _turkishCorrectController = TextEditingController();
    _turkishWrongController = TextEditingController();
    _turkishEmptyController = TextEditingController(); // Başlatıldı
    _nameController = TextEditingController(); 
    
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (widget.existingResult != null) {
      _nameController.text = widget.existingResult!.name ?? "";
      _mathCorrectController.text = widget.existingResult!.mathCorrect.toString();
      _mathWrongController.text = widget.existingResult!.mathWrong.toString();
      // Not: Modelde mathEmpty alanı varsa buraya ekleme yapılabilir.
      _turkishCorrectController.text = widget.existingResult!.turkishCorrect.toString();
      _turkishWrongController.text = widget.existingResult!.turkishWrong.toString();
      _calculateNets();
    } else {
      List<ExamResult> existingResults = await _storage.loadExamResults();
      setState(() {
        _nameController.text = "Deneme Sınavı ${existingResults.length + 1}";
      });
    }
  }

  @override
  void dispose() {
    _mathCorrectController.dispose();
    _mathWrongController.dispose();
    _mathEmptyController.dispose();
    _turkishCorrectController.dispose();
    _turkishWrongController.dispose();
    _turkishEmptyController.dispose();
    _nameController.dispose(); 
    super.dispose();
  }

  void _calculateNets() {
    int mathCorrect = int.tryParse(_mathCorrectController.text) ?? 0;
    int mathWrong = int.tryParse(_mathWrongController.text) ?? 0;
    int turkishCorrect = int.tryParse(_turkishCorrectController.text) ?? 0;
    int turkishWrong = int.tryParse(_turkishWrongController.text) ?? 0;

    _mathNet = mathCorrect - (mathWrong * 0.25);
    _turkishNet = turkishCorrect - (turkishWrong * 0.25);

    _mathNet = _mathNet < 0 ? 0 : _mathNet;
    _turkishNet = _turkishNet < 0 ? 0 : _turkishNet;

    setState(() {});
  }

  void _saveExamResult() async {
    final examResult = ExamResult(
      mode: widget.isTamSinav ? 'tam' : 'ozel',
      mathDuration: widget.mathDuration,
      turkishDuration: widget.turkishDuration,
      mathNet: _mathNet,
      turkishNet: _turkishNet,
      mathCorrect: _mathCorrectController.text.isEmpty ? 0 : int.parse(_mathCorrectController.text),
      mathWrong: _mathWrongController.text.isEmpty ? 0 : int.parse(_mathWrongController.text),
      turkishCorrect: _turkishCorrectController.text.isEmpty ? 0 : int.parse(_turkishCorrectController.text),
      turkishWrong: _turkishWrongController.text.isEmpty ? 0 : int.parse(_turkishWrongController.text),
      dateTime: DateTime.now(),
      name: _nameController.text, 
    );

    List<ExamResult> existingResults = await _storage.loadExamResults();
    
    if (widget.existingResult != null) {
      // Düzenleme modundaysak eski kaydı bulup güncelle
      int index = existingResults.indexWhere((res) => res.dateTime == widget.existingResult!.dateTime);
      if (index != -1) existingResults[index] = examResult;
    } else {
      existingResults.add(examResult);
    }
    
    await _storage.saveExamResults(existingResults);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.existingResult != null ? 'Sonuç başarıyla güncellendi!' : 'Sonuç başarıyla kaydedildi!'),
        backgroundColor: const Color(0xFF00D26A),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        title: Text(
          widget.existingResult != null ? 'Sonuç Düzenle' : 'Sınav Sonucu',
          style: const TextStyle(color: Color(0xFF00D26A), fontWeight: FontWeight.bold), // BAŞLIK YEŞİL YAPILDI
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sınav Adı',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E1E3F),
                  hintText: 'Sınav adını giriniz...',
                  hintStyle: const TextStyle(color: Color(0xFF757575)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Süreleriniz',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
              const SizedBox(height: 16),
              if (widget.isTamSinav)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E3F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF6C63FF), width: 2),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Toplam Sınav Süresi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '135 Dakika',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E3F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6C63FF), width: 2),
                        ),
                        child: Column(
                          children: [
                            const Text('Matematik', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF))),
                            const SizedBox(height: 8),
                            Text('${widget.mathDuration} dk', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E3F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF9F43), width: 2),
                        ),
                        child: Column(
                          children: [
                            const Text('Türkçe', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF))),
                            const SizedBox(height: 8),
                            Text('${widget.turkishDuration} dk', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF9F43))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              const Text(
                'Doğru-Yanlış-Boş Girin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
              const SizedBox(height: 16),
              // Matematik - BOŞ SORU EKLENDİ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E3F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6C63FF), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Matematik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(_mathCorrectController, 'Doğru', const Color(0xFF6C63FF))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildInputField(_mathWrongController, 'Yanlış', const Color(0xFF6C63FF))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildInputField(_mathEmptyController, 'Boş', const Color(0xFF6C63FF))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Net: ${_mathNet.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Türkçe - BOŞ SORU EKLENDİ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E3F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF9F43), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Türkçe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF9F43))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(_turkishCorrectController, 'Doğru', const Color(0xFFFF9F43))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildInputField(_turkishWrongController, 'Yanlış', const Color(0xFFFF9F43))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildInputField(_turkishEmptyController, 'Boş', const Color(0xFFFF9F43))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Net: ${_turkishNet.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF9F43))),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF757575),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('İptal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveExamResult,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D26A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A0E27))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Input Field Yardımcı Widget
  Widget _buildInputField(TextEditingController controller, String hint, Color color) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF757575), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF0A0E27),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      onChanged: (_) => _calculateNets(),
    );
  }
}