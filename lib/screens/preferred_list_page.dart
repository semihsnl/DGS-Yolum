import 'package:flutter/material.dart';
import '../models/exam_result.dart';

class PreferredListPage extends StatefulWidget {
  const PreferredListPage({super.key});

  @override
  State<PreferredListPage> createState() => _PreferredListPageState();
}

class _PreferredListPageState extends State<PreferredListPage> {
  List<dynamic> _myList = [];

  @override
  void initState() {
    super.initState();
    _loadMyList();
  }

  Future<void> _loadMyList() async {
    var data = await ExamResultStorage().loadFavorites();
    setState(() {
      _myList = data;
    });
  }

  void _removeFromList(int index) async {
    setState(() {
      _myList.removeAt(index);
    });
    await ExamResultStorage().saveFavorites(_myList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tercih Listem",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "${_myList.length}/30 Tercih Hakkı",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: _myList.isEmpty
          ? const Center(
              child: Text(
                "Listeniz henüz boş.\nTaban puanlardan bölümleri ekleyin.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ReorderableListView.builder(
              // Varsayılan sürükleme kollarını kapattık, kendimizinkini aşağıda tanımlayacağız
              buildDefaultDragHandles: false, 
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _myList.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _myList.removeAt(oldIndex);
                  _myList.insert(newIndex, item);
                });
                ExamResultStorage().saveFavorites(_myList);
              },
              itemBuilder: (context, index) {
                final item = _myList[index];
                return _buildModernPreferredCard(item, index, key: ValueKey("${item['uni']}${item['bolum']}"));
              },
            ),
    );
  }

  Widget _buildModernPreferredCard(dynamic data, int index, {required Key key}) {
    return Container(
      key: key, // ReorderableListView için anahtar burada olmalı
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E26),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // SIRA NUMARASI
                Container(
                  width: 35,
                  height: 35,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6C63FF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // BİLGİ ALANI
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${data['uni'].toString().toUpperCase()} - ${data['sehir']}",
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['bolum'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${data['uni_turu']} | ${data['fak'] ?? ''}",
                        style: const TextStyle(
                          color: Color(0xFFFACC15),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // SADECE BU İKON SÜRÜKLEME YAPAR
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 12.0, top: 15.0, bottom: 5.0, right: 5.0), 
                    child: Icon(Icons.drag_handle, color: Colors.white24, size: 32),
                  ),
                ),
              ],
            ),
          ),

          // ÇARPI BUTONU (Sağ Üstte)
          Positioned(
            top: 5,
            right: 5,
            child: InkWell(
              onTap: () => _removeFromList(index),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}