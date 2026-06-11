import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Rakam filtrelemesi için eklendi
import '../models/exam_result.dart';
import 'net_calculation_page.dart';

class ExamHistoryPage extends StatefulWidget {
  const ExamHistoryPage({super.key});

  @override
  State<ExamHistoryPage> createState() => _ExamHistoryPageState();
}

class _ExamHistoryPageState extends State<ExamHistoryPage> {
  List<ExamResult> _results = [];
  final ExamResultStorage _storage = ExamResultStorage();

  @override
  void initState() {
    super.initState();
    _loadExamResults();
  }

  Future<void> _loadExamResults() async {
    _results = await _storage.loadExamResults();
    setState(() {
      _results.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    });
  }

  // Detaylı net düzenleme sayfasına yönlendirme (HIZLI GEÇİŞ)
  void _navigateToDetailEdit(int index) {
    final result = _results[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NetCalculationPage(
          mathDuration: result.mathDuration,
          turkishDuration: result.turkishDuration,
          isTamSinav: result.mode == 'tam',
          existingResult: result,
        ),
      ),
    ).then((_) => _loadExamResults());
  }

  // 🎯 YENİ: Süre Değiştirme Diyaloğu (Tıklandığında Açılan Dinamik Sayı Seçici)
  void _showDurationEditDialog(int index, bool isMath) {
    final result = _results[index];
    // Mevcut dakikayı controller'a başlangıç değeri yapıyoruz
    final durationController = TextEditingController(
      text: (isMath ? result.mathDuration : result.turkishDuration).toString()
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E3F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isMath ? 'Matematik Süresini Düzenle' : 'Türkçe Süresini Düzenle',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: durationController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Sadece tam sayı izni
            decoration: InputDecoration(
              suffixText: "Dakika",
              suffixStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF0A0E27),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                int? newDuration = int.tryParse(durationController.text);
                if (newDuration != null && newDuration > 0) {
                  setState(() {
                    if (isMath) {
                      result.mathNet = result.mathCorrect - (result.mathWrong * 0.25); // Neti koru/güncelle
                      // Hafızadaki objenin süresini doğrudan mutasyona uğratıyoruz
                      _results[index] = ExamResult(
                        mode: result.mode,
                        mathDuration: newDuration, // Yeni değer atandı
                        turkishDuration: result.turkishDuration,
                        mathNet: result.mathNet,
                        turkishNet: result.turkishNet,
                        mathCorrect: result.mathCorrect,
                        mathWrong: result.mathWrong,
                        turkishCorrect: result.turkishCorrect,
                        turkishWrong: result.turkishWrong,
                        dateTime: result.dateTime,
                        name: result.name,
                      );
                    } else {
                      _results[index] = ExamResult(
                        mode: result.mode,
                        mathDuration: result.mathDuration,
                        turkishDuration: newDuration, // Yeni değer atandı
                        mathNet: result.mathNet,
                        turkishNet: result.turkishNet,
                        mathCorrect: result.mathCorrect,
                        mathWrong: result.mathWrong,
                        turkishCorrect: result.turkishCorrect,
                        turkishWrong: result.turkishWrong,
                        dateTime: result.dateTime,
                        name: result.name,
                      );
                    }
                  });
                  // Değişikliği kalıcı olarak SharedPreferences'a yazıyoruz
                  await _storage.saveExamResults(_results);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Güncelle', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Orijinal Silme Diyaloğu
  Future<void> _showDeleteDialog(int index) async {
    final result = _results[index];
    final String examName = result.name ?? (result.mode == 'tam' ? 'Tam Sınav' : 'Özel Mod');

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E3F),
          title: const Text(
            'Sınavı Sil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  '"$examName" adındaki denemeyi silmek istediğinizden emin misiniz?',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Vazgeç', style: TextStyle(color: Color(0xFFB0B0B0))),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Sil', style: TextStyle(color: Color(0xFFFF6B6B))),
              onPressed: () {
                setState(() {
                  _results.removeAt(index);
                  _storage.saveExamResults(_results);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Basılı tutunca altta çıkan seçenekler
  void _showOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E3F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF6C63FF)),
                title: const Text('Düzenle', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context); // Menüyü kapat
                  _navigateToDetailEdit(index); // SORU SORMADAN DİREKT SAYFAYA GİT
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFFF6B6B)),
                title: const Text('Sil', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        title: const Text('Geçmiş Sınavlarım'),
        centerTitle: true,
      ),
      body: _results.isEmpty
          ? const Center(
              child: Text(
                'Henüz sınav sonucu kaydedilmedi',
                style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                return GestureDetector(
                  onLongPress: () => _showOptions(context, index), 
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E3F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: result.mode == 'tam' ? const Color(0xFF6C63FF) : const Color(0xFFFF9F43),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center, 
                      children: [
                        Text(
                          result.name != null && result.name!.isNotEmpty
                              ? result.name!
                              : (result.mode == 'tam' ? 'Tam Sınav' : 'Özel Mod'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: result.mode == 'tam' ? const Color(0xFF8E86FF) : const Color(0xFFFFB366),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              result.mode == 'tam' ? 'Tam Sınav' : 'Özel Mod',
                              style: TextStyle(
                                fontSize: 13,
                                color: result.mode == 'tam' ? const Color(0xFF6C63FF) : const Color(0xFFFF9F43),
                              ),
                            ),
                            Text(
                              '${result.dateTime.day}/${result.dateTime.month}/${result.dateTime.year} ${result.dateTime.hour}:${result.dateTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFB0B0B0)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // 🎯 GÜNCELLEME: Taşma hatasını önlemek için Row içi Expanded yapıldı ve InkWell'ler kaldırıldı!
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Matematik', style: TextStyle(fontSize: 12, color: Color(0xFFB0B0B0))),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${result.mathDuration} dk - ${result.mathNet.toStringAsFixed(2)} net',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10), // Araya güvenli bir boşluk
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Türkçe', style: TextStyle(fontSize: 12, color: Color(0xFFB0B0B0))),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${result.turkishDuration} dk - ${result.turkishNet.toStringAsFixed(2)} net',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0E27),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  const Text('Toplam Net', style: TextStyle(fontSize: 11, color: Color(0xFFB0B0B0))),
                                  const SizedBox(height: 4),
                                  Text(
                                    (result.mathNet + result.turkishNet).toStringAsFixed(2),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9F43FF)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Spacer(),
                            Text(
                              'Basılı tut: Seçenekler',
                              style: TextStyle(fontSize: 10, color: Color(0xFF757575), fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}