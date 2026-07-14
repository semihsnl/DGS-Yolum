import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // AdMob kütüphanesi
import '../models/exam_result.dart';
import 'preferred_list_page.dart';
import '../ad_helper.dart';

class BasePointsPage extends StatefulWidget {
  const BasePointsPage({super.key});

  @override
  State<BasePointsPage> createState() => _BasePointsPageState();
}

enum SortType { none, ascending, descending }

class SearchItem {
  final String name;
  final bool isUniversity;
  final bool isCity;
  SearchItem(this.name, {this.isUniversity = false, this.isCity = false});
}

class _BasePointsPageState extends State<BasePointsPage> {
  List<dynamic> _allData = [];
  List<dynamic> _filteredData = [];
  List<dynamic> _favorites = [];
  bool _isLoading = true;
  
  final List<SearchItem> _selectedFilters = []; 
  List<String> _uniSuggestions = [];
  List<String> _bolumSuggestions = [];
  List<String> _cities = [];

  List<String> _selectedMainTypes = ["Tümü"]; 
  final List<String> _selectedVakifSubTypes = ["Burslu", "%50", "%25", "Ücretli"];
  final List<String> _selectedLanguages = ["Türkçe", "İngilizce"];

  SortType _puanSort = SortType.none;
  SortType _siraSort = SortType.none;
  final TextEditingController _searchController = TextEditingController();

  // AdMob Reklam Değişkenleri
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDataFromAssets();
    _loadFavorites();
    _loadTestBannerAd(); // Sayfa açılır açılmaz emülatör için test reklamını yükler
  }

  // Güvenli AdMob Test Reklamı Yükleme Fonksiyonu
  void _loadTestBannerAd() {
    BannerAd(
      adUnitId: AdHelper.universityBannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() { 
            _bannerAd = ad as BannerAd;
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Test Banner yüklenemedi: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // Sayfa kapatıldığında belleği temizler
    super.dispose();
  }

  // Türkçe karakter duyarlı küçük harfe çevirme fonksiyonu
  String _toTurkishLower(String text) {
    return text
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ü', 'ü')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ç', 'ç')
        .toLowerCase();
  }

  Future<void> _loadFavorites() async {
    var favs = await ExamResultStorage().loadFavorites();
    setState(() { _favorites = favs; });
  }

  Future<void> _loadDataFromAssets() async {
    try {
      final String response = await rootBundle.loadString('assets/data.json');
      final data = await json.decode(response);
      setState(() {
        _allData = data;
        Set<String> citySet = {};
        Set<String> uniSet = {};
        Set<String> bolumSet = {};
        for (var item in data) {
          if (item['sehir'] != null) citySet.add(item['sehir']);
          if (item['uni'] != null) uniSet.add(item['uni']);
          if (item['bolum'] != null) {
            String bName = item['bolum'].toString();
            String cleanedName = bName.contains('(') ? bName.split('(')[0].trim() : bName.trim();
            bolumSet.add(cleanedName);
          }
        }
        _cities = citySet.toList()..sort();
        _uniSuggestions = uniSet.toList()..sort();
        _bolumSuggestions = bolumSet.toList()..sort();
        _isLoading = false;
      });
      _filterAndSortData();
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }

  void _toggleFavorite(dynamic item) async {
    setState(() {
      int index = _favorites.indexWhere((f) => f['bolum'] == item['bolum'] && f['uni'] == item['uni']);
      if (index > -1) {
        _favorites.removeAt(index);
      } else {
        if (_favorites.length < 30) {
          _favorites.add(item);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("En fazla 30 tercih yapabilirsiniz!")));
        }
      }
    });
    await ExamResultStorage().saveFavorites(_favorites);
  }

  void _filterAndSortData() {
    setState(() {
      _filteredData = _allData.where((item) {
        // --- 1. Arama (Şehir, Üni, Bölüm) Filtreleri ---
        var selectedCities = _selectedFilters.where((f) => f.isCity).map((f) => _toTurkishLower(f.name)).toList();
        var selectedUnis = _selectedFilters.where((f) => f.isUniversity).map((f) => _toTurkishLower(f.name)).toList();
        var selectedBolums = _selectedFilters.where((f) => !f.isUniversity && !f.isCity).map((f) => _toTurkishLower(f.name)).toList();

        bool cityMatch = selectedCities.isEmpty || selectedCities.contains(_toTurkishLower(item['sehir']));
        bool uniMatch = selectedUnis.isEmpty || selectedUnis.contains(_toTurkishLower(item['uni']));
        bool bolumMatch = selectedBolums.isEmpty || selectedBolums.any((sb) => _toTurkishLower(item['bolum'].toString()).contains(sb));

        // --- 2. Üniversite Türü (Devlet / Vakıf) ve Burs Filtresi ---
        bool typeMatch = false;
        String itemType = item['uni_turu'].toString();
        String bolumName = item['bolum'].toString();

        if (_selectedMainTypes.contains("Tümü")) {
          typeMatch = true;
        } else {
          bool isDevletSelected = _selectedMainTypes.contains("Devlet");
          bool isVakifSelected = _selectedMainTypes.contains("Vakıf");

          if (isDevletSelected && itemType == "Devlet") {
            typeMatch = true;
          } 
          
          if (isVakifSelected && itemType == "Vakıf") {
             bool bursMatch = _selectedVakifSubTypes.any((sub) => bolumName.contains(sub));
             if (bursMatch) typeMatch = true;
          }
        }

        // --- 3. Dil Filtresi ---
        bool isEnglish = bolumName.contains("(İngilizce)");
        bool matchesLang = (_selectedLanguages.contains("Türkçe") && !isEnglish) || 
                          (_selectedLanguages.contains("İngilizce") && isEnglish);

        return cityMatch && uniMatch && bolumMatch && typeMatch && matchesLang;
      }).toList();

      // --- 4. Sıralama ---
      if (_puanSort != SortType.none) {
        _filteredData.sort((a, b) {
          double vA = double.tryParse(a['puanlar'].toString().split(' ')[0].replaceAll(',', '.')) ?? 0.0;
          double vB = double.tryParse(b['puanlar'].toString().split(' ')[0].replaceAll(',', '.')) ?? 0.0;
          return _puanSort == SortType.descending ? vB.compareTo(vA) : vA.compareTo(vB);
        });
      }

      if (_siraSort != SortType.none) {
        _filteredData.sort((a, b) {
          int vA = int.tryParse(a['siralamalar'].toString().split(' ')[0].replaceAll('.', '').trim()) ?? 9999999;
          int vB = int.tryParse(b['siralamalar'].toString().split(' ')[0].replaceAll('.', '').trim()) ?? 9999999;
          return _siraSort == SortType.ascending ? vA.compareTo(vB) : vB.compareTo(vA);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F111A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F111A),
          elevation: 0,
          toolbarHeight: 45,
          title: const Text("Taban Sıralama ve Puanlar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.format_list_numbered, color: Colors.amber, size: 20),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const PreferredListPage()));
                _loadFavorites();
              },
            )
          ],
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D26A)))
          : Column(
              children: [
                _buildAutocompleteSearch(),
                _buildSelectedChips(),
                
                // 🎯 1. Satır: Üniversite Türü Filtresi (Tümü, Devlet, Vakıf)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: _buildFilterArea(),
                  ),
                ),
  
                // 🎯 2. Satır: Dil Filtresi (Türkçe, İngilizce)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: _buildLanguageFilters(),
                  ),
                ),
                
                _buildSortingBar(),
                _buildInfoBanner(),
                Expanded(
                  child: _filteredData.isEmpty 
                  ? const Center(child: Text("Sonuç bulunamadı.", style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: _filteredData.length,
                      itemBuilder: (context, index) => _buildUniDetailCard(_filteredData[index]),
                    ),
                ),
              ],
            ),
        // 🟢 REKLAM BURADA SABİT: Liste ne kadar kayarsa kaysın, reklam hep en altta çakılı durur.
        bottomNavigationBar: _isBannerAdLoaded && _bannerAd != null
            ? SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildUniDetailCard(Map<String, dynamic> data) {
    bool isFav = _favorites.any((f) => f['bolum'] == data['bolum'] && f['uni'] == data['uni']);
    List<String> y = data['yillar'].toString().split(' ');
    List<String> k = data['kontlar'].toString().split(' ');
    List<String> p = data['puanlar'].toString().split(' ');
    List<String> s = data['siralamalar'].toString().split(' ');
    
    Color typeColor = data['tur'].toString().contains("SAY") ? Colors.blueAccent : (data['tur'].toString().contains("SÖZ") ? Colors.orangeAccent : Colors.teal);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: const Color(0xFF1C1E26), borderRadius: BorderRadius.circular(15)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 32,
              decoration: BoxDecoration(color: typeColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15))),
              child: Center(child: RotatedBox(quarterTurns: 3, child: Text(data['tur'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['sehir'].toString().toUpperCase(), style: const TextStyle(color: Color(0xFF9E86FF), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                              const SizedBox(height: 2),
                              Text(data['uni'], style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w400, height: 1.2), softWrap: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(onTap: () => _toggleFavorite(data), child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 20)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(data['bolum'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.2), softWrap: true),
                    const SizedBox(height: 4),
                    Text("${data['uni_turu']} | ${data['fak'] ?? ''}", style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            
            Container(
              width: 165, 
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: const BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(y.length > 4 ? 4 : y.length, (i) {
                  if (int.tryParse(y[i]) != null && int.parse(y[i]) > 2026) {
                    return const SizedBox.shrink();
                  }
                  bool isNewest = i == 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(y[i], style: TextStyle(color: isNewest ? Colors.white70 : Colors.grey, fontSize: 9, fontWeight: isNewest ? FontWeight.bold : FontWeight.normal)),
                        SizedBox(width: 28, child: Text("K:${k[i]}", style: TextStyle(color: isNewest ? Colors.white54 : Colors.white24, fontSize: 9), textAlign: TextAlign.center)),
                        Text(p[i].contains(',') ? p[i].split(',')[0] : p[i], style: TextStyle(color: isNewest ? const Color(0xFF00D26A) : Colors.green.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w900)),
                        Text(s[i], style: TextStyle(color: isNewest ? Colors.orangeAccent : Colors.orange.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutocompleteSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Autocomplete<String>(
              optionsBuilder: (v) {
                if (v.text.isEmpty) return const Iterable<String>.empty();
                String input = _toTurkishLower(v.text);
                return [..._uniSuggestions, ..._bolumSuggestions].where((o) => _toTurkishLower(o).contains(input));
              },
              onSelected: (selection) {
                setState(() {
                  bool isUni = _uniSuggestions.contains(selection);
                  if (!_selectedFilters.any((f) => f.name == selection)) {
                    _selectedFilters.add(SearchItem(selection, isUniversity: isUni));
                  }
                  _searchController.clear();
                });
                _filterAndSortData();
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 80,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(color: const Color(0xFF1C1E26), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, index) {
                          final String option = options.elementAt(index);
                          final bool isUni = _uniSuggestions.contains(option);
                          return ListTile(
                            leading: Icon(isUni ? Icons.school : Icons.description, color: isUni ? Colors.blueAccent : Colors.greenAccent, size: 18),
                            title: Text(option, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              fieldViewBuilder: (context, controller, node, onSubmitted) {
                return TextField(
                  controller: controller, focusNode: node,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    hintText: "Bölüm veya üniversite yazın...",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                    filled: true, fillColor: const Color(0xFF1C1E26),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                );
              },
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _showCityPicker, 
            icon: const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20)
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChips() {
    if (_selectedFilters.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      width: double.infinity,
      child: Wrap(
        spacing: 4,
        runSpacing: 2,
        children: [
          ..._selectedFilters.map((f) => Chip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
            backgroundColor: f.isCity ? Colors.purple.withOpacity(0.2) : (f.isUniversity ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2)),
            label: Text(f.name, style: const TextStyle(color: Colors.white, fontSize: 9)),
            onDeleted: () { setState(() => _selectedFilters.remove(f)); _filterAndSortData(); },
          )),
        ],
      ),
    );
  }

  Widget _buildFilterArea() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMainTypeChip("Tümü"),
          _buildMainTypeChip("Devlet"),
          _buildMainTypeChip("Vakıf"),
          if (_selectedMainTypes.contains("Vakıf")) ...["Burslu", "%50", "%25", "Ücretli"].map((s) => _buildVakifSubChip(s)),
        ],
      ),
    );
  }

  Widget _buildMainTypeChip(String label) {
    bool isSelected = _selectedMainTypes.contains(label);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        label: Text(label, style: const TextStyle(fontSize: 10)),
        selected: isSelected,
        onSelected: (val) {
          setState(() {
            if (label == "Tümü") { _selectedMainTypes = ["Tümü"]; } 
            else { 
              _selectedMainTypes.remove("Tümü");
              val ? _selectedMainTypes.add(label) : _selectedMainTypes.remove(label);
              if (_selectedMainTypes.isEmpty) _selectedMainTypes.add("Tümü");
            }
          });
          _filterAndSortData();
        },
        selectedColor: const Color(0xFF00D26A),
        backgroundColor: const Color(0xFF1C1E26),
        labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildVakifSubChip(String label) {
    bool isSelected = _selectedVakifSubTypes.contains(label);
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: FilterChip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        label: Text(label, style: const TextStyle(fontSize: 9)),
        selected: isSelected,
        onSelected: (v) { setState(() { v ? _selectedVakifSubTypes.add(label) : _selectedVakifSubTypes.remove(label); }); _filterAndSortData(); },
        selectedColor: Colors.amber,
        backgroundColor: const Color(0xFF1C1E26),
        labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.amber),
      ),
    );
  }

  Widget _buildLanguageFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ["Türkçe", "İngilizce"].map((l) => Padding(
          padding: const EdgeInsets.only(right: 4),
          child: FilterChip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            label: Text(l, style: const TextStyle(fontSize: 10)),
            selected: _selectedLanguages.contains(l),
            onSelected: (v) { setState(() => v ? _selectedLanguages.add(l) : _selectedLanguages.remove(l)); _filterAndSortData(); },
            selectedColor: Colors.blueAccent,
            backgroundColor: const Color(0xFF1C1E26),
            labelStyle: TextStyle(color: _selectedLanguages.contains(l) ? Colors.black : Colors.grey, fontWeight: FontWeight.bold),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSortingBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      height: 30,
      decoration: BoxDecoration(color: const Color(0xFF1C1E26), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          _buildSortButton("PUAN", _puanSort, () => _toggleSort("puan")),
          _buildSortButton("SIRA", _siraSort, () => _toggleSort("sira")),
        ],
      ),
    );
  }

  Widget _buildSortButton(String l, SortType s, VoidCallback t) {
    return Expanded(
      child: InkWell(
        onTap: t, 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Text(l, style: TextStyle(color: s == SortType.none ? Colors.grey : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)), 
            Icon(s == SortType.descending ? Icons.arrow_drop_down : s == SortType.ascending ? Icons.arrow_drop_up : Icons.unfold_more, size: 14, color: s == SortType.none ? Colors.grey : Colors.green)
          ]
        )
      )
    );
  }

  Widget _buildInfoBanner() => const Padding(padding: EdgeInsets.only(right: 20, bottom: 2), child: Align(alignment: Alignment.centerRight, child: Text("Yıl | Kont. | Puan | Sıra", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold))));

  void _toggleSort(String f) {
    setState(() {
      if (f == "puan") { _siraSort = SortType.none; _puanSort = _getNextSortType(_puanSort); }
      else { _puanSort = SortType.none; _siraSort = _getNextSortType(_siraSort); }
      _filterAndSortData();
    });
  }

  SortType _getNextSortType(SortType c) => c == SortType.none ? SortType.descending : (c == SortType.descending ? SortType.ascending : SortType.none);

  void _showCityPicker() {
    String citySearchQuery = "";
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1C1E26), isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (context) {
      return StatefulBuilder(builder: (context, setModalState) {
        List<String> displayCities = _cities.where((c) => _toTurkishLower(c).contains(_toTurkishLower(citySearchQuery))).toList();
        return DraggableScrollableSheet(initialChildSize: 0.7, expand: false, builder: (context, scrollController) {
          return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            TextField(onChanged: (v) => setModalState(() => citySearchQuery = v), style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Şehir ara...", hintStyle: const TextStyle(color: Colors.grey), prefixIcon: const Icon(Icons.search, color: Colors.grey), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Şehirler", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), TextButton(onPressed: () { setState(() => _selectedFilters.removeWhere((f) => f.isCity)); _filterAndSortData(); setModalState(() {}); }, child: const Text("Sıfırla"))]),
            Expanded(child: ListView.builder(controller: scrollController, itemCount: displayCities.length, itemBuilder: (context, index) {
              final c = displayCities[index]; bool isSel = _selectedFilters.any((f) => f.isCity && f.name == c);
              return CheckboxListTile(title: Text(c, style: TextStyle(color: isSel ? const Color(0xFF00D26A) : Colors.white70)), value: isSel, onChanged: (v) { setState(() { v! ? _selectedFilters.add(SearchItem(c, isCity: true)) : _selectedFilters.removeWhere((f) => f.isCity && f.name == c); }); setModalState(() {}); _filterAndSortData(); });
            }))]));
        });
      });
    });
  }
}