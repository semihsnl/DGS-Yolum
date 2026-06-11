import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PuanHesaplamaPage extends StatefulWidget {
  const PuanHesaplamaPage({super.key});

  @override
  State<PuanHesaplamaPage> createState() => _PuanHesaplamaPageState();
}

class _PuanHesaplamaPageState extends State<PuanHesaplamaPage> {
  final _matDogru = TextEditingController(text: "0");
  final _matYanlis = TextEditingController(text: "0");
  final _sozDogru = TextEditingController(text: "0");
  final _sozYanlis = TextEditingController(text: "0");
  
  // ÖBP için controller (Ayarlar'dan gelecek)
  final _obpPuanController = TextEditingController(); 

  bool _isYerlesti = false; 

  double _sayNet = 0, _sozNet = 0;
  double _sayPuan = 0, _sozPuan = 0, _eaPuan = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedProfileSettings(); // Sayfa açılırken Ayarlar verilerini çek
  }

  // AYARLAR sekmesinden verileri çeken fonksiyon
  Future<void> _loadSavedProfileSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Ayarlar sayfasında kullanılan 'saved_obp' anahtarını okuyoruz
      // Eğer henüz ayar yapılmamışsa varsayılan olarak "40" getirir
      _obpPuanController.text = prefs.getString('saved_obp') ?? "40";
      
      // Ayarlar sayfasında kullanılan 'saved_yerlesti' anahtarını okuyoruz
      _isYerlesti = prefs.getBool('saved_yerlesti') ?? false;
    });
  }

  // ÖBP Puanını anlık olarak hafızaya kaydetme fonksiyonu
  Future<void> _saveObpOnly() async {
    final prefs = await SharedPreferences.getInstance();
    double? obpVal = double.tryParse(_obpPuanController.text);
    
    if (obpVal != null) {
      // Sınır kontrollerini güvene alalım
      if (obpVal < 40) obpVal = 40;
      if (obpVal > 80) obpVal = 80;
      
      String targetObp = obpVal.toStringAsFixed(1);
      _obpPuanController.text = targetObp;
      
      // Ortak anahtara ('saved_obp') yazıyoruz
      await prefs.setString('saved_obp', targetObp);
      await prefs.setBool('saved_yerlesti', _isYerlesti);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ÖBP Puanınız profilinize kaydedildi!")),
        );
      }
    } else {
      // Eğer alan boş bırakıldıysa veya geçersizse varsayılan alt sınırı ata ve kaydet
      _obpPuanController.text = "40.0";
      await prefs.setString('saved_obp', "40.0");
      await prefs.setBool('saved_yerlesti', _isYerlesti);
    }
  }

  void _hesapla() {
    setState(() {
      int matD = int.tryParse(_matDogru.text) ?? 0;
      int matY = int.tryParse(_matYanlis.text) ?? 0;
      int sozD = int.tryParse(_sozDogru.text) ?? 0;
      int sozY = int.tryParse(_sozYanlis.text) ?? 0;
      
      double obpVal = double.tryParse(_obpPuanController.text) ?? 40.0;

      // Toplam 50 Sınırı Kontrolü
      if (matD + matY > 50) {
        matD = 0; matY = 0;
        _matDogru.text = "0"; _matYanlis.text = "0";
      }
      if (sozD + sozY > 50) {
        sozD = 0; sozY = 0;
        _sozDogru.text = "0"; _sozYanlis.text = "0";
      }

      // ÖBP Sınır Kontrolü (40-80)
      if (obpVal < 40) {
        obpVal = 40;
        _obpPuanController.text = "40";
      } else if (obpVal > 80) {
        obpVal = 80;
        _obpPuanController.text = "80";
      }

      // Net Hesaplama (4 yanlış 1 doğru)
      _sayNet = matD - (matY * 0.25);
      _sozNet = sozD - (sozY * 0.25);

      if (_sayNet < 0) _sayNet = 0;
      if (_sozNet < 0) _sozNet = 0;

      // ÖBP Katsayısı (Yerleşme durumuna göre %25 kırılma: 0.6 -> 0.45)
      double obpKatsayisi = _isYerlesti ? 0.45 : 0.6;
      double obpEtkisi = obpVal * obpKatsayisi;

      // Güncel Katsayılar ve Taban Puanlar
      _sayPuan = (_sayNet * 3.431) + (_sozNet * 0.584) + obpEtkisi + 144.017;
      _sozPuan = (_sayNet * 0.677) + (_sozNet * 2.932) + obpEtkisi + 126.070;
      _eaPuan = (_sayNet * 2.054) + (_sozNet * 1.758) + obpEtkisi + 135.044;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("DGS Puan Hesaplama", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSectionCard("Sayısal Bölüm (Matematik)", _matDogru, _matYanlis, Colors.blueAccent),
                  const SizedBox(height: 16),
                  _buildSectionCard("Sözel Bölüm (Türkçe)", _sozDogru, _sozYanlis, Colors.orangeAccent),
                  const SizedBox(height: 16),
                  _buildObpCard(),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _hesapla,
                      child: const Text("HESAPLA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  if (_sayPuan > 140) _buildResultCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, TextEditingController d, TextEditingController y, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInputField("Doğru", d, isObp: false)),
              const SizedBox(width: 15),
              Expanded(child: _buildInputField("Yanlış", y, isObp: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {required bool isObp}) {
    return TextField(
      controller: controller,
      // 🎯 ÖBP alanıysa ondalıklı klavye, değilse sadece tam sayı klavyesi açılır
      keyboardType: isObp ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
      style: const TextStyle(color: Colors.white),
      // 🎯 Sadece rakamları ve noktayı kabul eden filtreleme mimarisi
      inputFormatters: [
        isObp 
          ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')) // ÖBP için rakam ve nokta izni
          : FilteringTextInputFormatter.digitsOnly,             // Doğru/Yanlış için sadece tam sayı
      ],
      onChanged: (value) {
        if (isObp && value.isNotEmpty) {
          double? currentVal = double.tryParse(value);
          // Kullanıcı anlık olarak 80'den büyük yazarsa otomatik 80'e çeker
          if (currentVal != null && currentVal > 80) {
            controller.text = "80";
            controller.selection = TextSelection.fromPosition(const TextPosition(offset: 2));
          }
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
        filled: true,
        fillColor: Colors.black26,
      ),
    );
  }

  Widget _buildObpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _buildInputField("ÖBP Puanı (40 - 80)", _obpPuanController, isObp: true)),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D26A).withOpacity(0.15),
                  foregroundColor: const Color(0xFF00D26A),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: const Color(0xFF00D26A).withOpacity(0.3)),
                ),
                onPressed: _saveObpOnly,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text("ÖBP'mi Kaydet", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text("Önceki yıl yerleştim", style: TextStyle(color: Colors.white70, fontSize: 13)),
            value: _isYerlesti,
            activeColor: const Color(0xFF6C63FF),
            onChanged: (val) => setState(() => _isYerlesti = val!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2E335A), Color(0xFF1C1E26)]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Text("Sonuçlar", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white10, height: 30),
          _resultRow("Sayısal Puan:", _sayPuan, Colors.greenAccent, isPoint: true),
          _resultRow("Sözel Puan:", _sozPuan, Colors.orangeAccent, isPoint: true),
          _resultRow("Eşit Ağırlık Puan:", _eaPuan, Colors.blueAccent, isPoint: true),
          const Divider(color: Colors.white10, height: 30),
          _resultRow("Sayısal Net:", _sayNet, Colors.white70, isPoint: false),
          _resultRow("Sözel Net:", _sozNet, Colors.white70, isPoint: false),
        ],
      ),
    );
  }

  Widget _resultRow(String label, double value, Color color, {required bool isPoint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          Text(
            value.toStringAsFixed(isPoint ? 3 : 2), 
            style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}