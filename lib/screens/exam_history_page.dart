import 'package:flutter/material.dart';
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Matematik', style: TextStyle(fontSize: 12, color: Color(0xFFB0B0B0))),
                                const SizedBox(height: 4),
                                Text(
                                  '${result.mathDuration} dk - ${result.mathNet.toStringAsFixed(2)} net',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Türkçe', style: TextStyle(fontSize: 12, color: Color(0xFFB0B0B0))),
                                const SizedBox(height: 4),
                                Text(
                                  '${result.turkishDuration} dk - ${result.turkishNet.toStringAsFixed(2)} net',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
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
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Basılı tut: Seçenekler',
                            style: TextStyle(fontSize: 10, color: Color(0xFF757575), fontStyle: FontStyle.italic),
                          ),
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