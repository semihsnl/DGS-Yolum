import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _obpController = TextEditingController();
  final _uniController = TextEditingController();
  final _bolumController = TextEditingController();
  bool _isYerlesti = false;

  List<String> _uniList = [];
  List<String> _bolumList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadJsonData();
    await _loadSettings();
    setState(() => _isLoading = false);
  }

  // JSON dosyasından üniversite ve bölüm listesini çek
  Future<void> _loadJsonData() async {
    try {
      final String response = await rootBundle.loadString('assets/data.json');
      final List<dynamic> data = json.decode(response);
      
      Set<String> unis = {};
      Set<String> bolums = {};

      for (var item in data) {
        if (item['uni'] != null) unis.add(item['uni'].toString());
        if (item['bolum'] != null) bolums.add(item['bolum'].toString());
      }

      _uniList = unis.toList()..sort();
      _bolumList = bolums.toList()..sort();
    } catch (e) {
      debugPrint("JSON yükleme hatası: $e");
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _obpController.text = prefs.getString('saved_obp') ?? "40";
      _uniController.text = prefs.getString('saved_uni') ?? "";
      _bolumController.text = prefs.getString('saved_bolum') ?? "";
      _isYerlesti = prefs.getBool('saved_yerlesti') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    double obp = double.tryParse(_obpController.text) ?? 40;
    if (obp < 40) obp = 40;
    if (obp > 80) obp = 80;

    await prefs.setString('saved_obp', obp.toString());
    await prefs.setString('saved_uni', _uniController.text);
    await prefs.setString('saved_bolum', _bolumController.text);
    await prefs.setBool('saved_yerlesti', _isYerlesti);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ayarlar kaydedildi!"), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Profil Bilgileri", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Eğitim Bilgileri"),
                _buildSettingsCard(
                  children: [
                    _buildInputField("Sabit ÖBP Puanı (40-80)", _obpController, isNumber: true),
                    CheckboxListTile(
                      title: const Text("Önceki yıl yerleştim", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      value: _isYerlesti,
                      activeColor: const Color(0xFF6C63FF),
                      onChanged: (val) => setState(() => _isYerlesti = val!),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                _buildSectionTitle("Hedef Bilgileri"),
                _buildSettingsCard(
                  children: [
                    _buildAutocompleteField("Hedef Üniversite", _uniController, _uniList),
                    const SizedBox(height: 15),
                    _buildAutocompleteField("Hedef Bölüm", _bolumController, _bolumList),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _saveSettings,
                    child: const Text("AYARLARI KAYDET", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildAutocompleteField(String label, TextEditingController controller, List<String> options) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') return const Iterable<String>.empty();
        return options.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) => controller.text = selection,
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        // SharedPreferences'tan gelen değeri fieldController'a aktar
        if (fieldController.text != controller.text && controller.text.isNotEmpty) {
           fieldController.text = controller.text;
        }
        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          onChanged: (val) => controller.text = val,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6C63FF))),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width - 80,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1E26),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    title: Text(option, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6C63FF))),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(title, style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1C1E26), borderRadius: BorderRadius.circular(20)),
      child: Column(children: children),
    );
  }
}