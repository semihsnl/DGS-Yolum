import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'puan_hesaplama_page.dart';
import 'full_exam_page.dart';
import 'custom_mode_screen.dart';
import 'exam_history_page.dart';
import 'statistics_page.dart';
import 'base_points_page.dart';
import 'settings_page.dart';
import 'preferred_list_page.dart'; // Tercih listesi importu
import '../models/exam_result.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<ExamResult> _recentExams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_recentExams.isEmpty) setState(() => _isLoading = true);
    final results = await ExamResultStorage().loadExamResults();
    results.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    if (mounted) {
      setState(() {
        _recentExams = results.length > 5 ? results.sublist(results.length - 5) : results;
        _isLoading = false;
      });
    }
  }

  int get _daysRemaining {
    final now = DateTime.now();
    final examDate = DateTime(2026, 7, 19);
    return examDate.difference(now).inDays;
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0: return _buildHomeScreen();
      case 1: return _buildCategoriesScreen();
      case 2: return const StatisticsPage();
      case 3: return const SettingsPage();
      default: return _buildHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F111A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- ANA SAYFA EKRANI ---
  Widget _buildHomeScreen() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF6C63FF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                _buildDgsCountdown(),
                const SizedBox(height: 30),
                _buildNetGraphSection(),
                const SizedBox(height: 24),
                
                // --- ANA BUTONLAR ---
                _buildMainButton(
                  title: "Puan Hesapla",
                  subtitle: "DGS puanını anında öğren",
                  icon: Icons.calculate_rounded,
                  color: const Color(0xFF6C63FF),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PuanHesaplamaPage())),
                ),
                const SizedBox(height: 12),
                _buildMainButton(
                  title: "Taban Sıralamalar ve Puanlar",
                  subtitle: "Son 5 yılın üniversite ve bölüm verileri",
                  icon: Icons.account_balance_rounded,
                  color: const Color(0xFF00D26A),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BasePointsPage())),
                ),
                const SizedBox(height: 12),
                _buildMainButton(
                  title: "Tercih Listem",
                  subtitle: "Favori bölümlerini yönet",
                  icon: Icons.format_list_numbered_rounded,
                  color: Colors.amber,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PreferredListPage())),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetGraphSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E26),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Gelişim Analizi", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 25),
          if (_recentExams.isEmpty)
            _buildEmptyGraphState()
          else
            SizedBox(height: 160, child: LineChart(_mainChartData())),
        ],
      ),
    );
  }

  Widget _buildEmptyGraphState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, color: Colors.white.withOpacity(0.1), size: 50),
          const SizedBox(height: 10),
          const Text(
            "Henüz deneme çözmedin.\nNet takibi için sınavlara başla!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
          TextButton(
            onPressed: () => setState(() => _selectedIndex = 1),
            child: const Text("Sınav Modlarını Gör", style: TextStyle(color: Color(0xFF6C63FF))),
          )
        ],
      ),
    );
  }

  LineChartData _mainChartData() {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: _recentExams.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.mathNet + e.value.turkishNet)).toList(),
          isCurved: true,
          color: const Color(0xFF6C63FF),
          barWidth: 4,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: const Color(0xFF6C63FF).withOpacity(0.1)),
        ),
      ],
    );
  }

  Widget _buildCategoriesScreen() {
  return SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          const SizedBox(height: 24),
          _buildSectionTitle("SINAV MODLARI"),
          const SizedBox(height: 12),
          _buildMainButton(
            title: "Tam Sınav",
            subtitle: "135 dk gerçek sınav provası",
            icon: Icons.timer_outlined,
            color: const Color(0xFF6C63FF), // Mor
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FullExamPage())),
          ),
          const SizedBox(height: 12),
          _buildMainButton(
            title: "Özel Mod",
            subtitle: "Süreleri kendine göre ayarla",
            icon: Icons.tune_rounded,
            color: const Color(0xFFFF9F43), // Turuncu
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomModeScreen())),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle("ARŞİV"),
          const SizedBox(height: 12),
          _buildMainButton(
            title: "Geçmiş Sınavlarım",
            subtitle: "Eski sonuçlarını ve gelişimini gör",
            icon: Icons.history_rounded,
            color: const Color(0xFF9F43FF), // Açık Mor
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExamHistoryPage())),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDgsCountdown() {
    return Column(
      children: [
        const Text("DGS'YE KALAN SÜRE", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Text("$_daysRemaining Gün", style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        const Text("19 Temmuz 2026", style: TextStyle(color: Color(0xFF6DC4A7), fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMainButton({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20), // Yükseklik dengelendi
        decoration: BoxDecoration(
          color: const Color(0xFF1C1E26),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.2)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5));
  }

  Widget _buildMenuCard({required String title, required String subtitle, required IconData icon, required Color iconColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1C1E26), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 24)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
  return Container(
    // Barın konumu ve dış boşlukları
    margin: const EdgeInsets.fromLTRB(25, 0, 25, 15),
    // Yüksekliği tam ikonlara göre daralttık
    height: 60, 
    decoration: BoxDecoration(
      color: const Color(0xFF1C1E26),
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(
        color: Colors.white.withOpacity(0.08),
        width: 1,
      ),
    ),
    child: Row(
      // İkonları yatayda eşit aralıklarla dağıtır
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      // İkonları dikeyde TAM MERKEZLER
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildNavItem(0, Icons.home_filled),
        _buildNavItem(1, Icons.grid_view_rounded),
        _buildNavItem(2, Icons.analytics_rounded),
        _buildNavItem(3, Icons.settings_rounded),
      ],
    ),
  );
}

// İkon butonlarını oluşturan yardımcı fonksiyon
Widget _buildNavItem(int index, IconData icon) {
  bool isSelected = _selectedIndex == index;
  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedIndex = index;
      });
      _loadData();
    },
    // Tıklama alanını genişletmek için boş bir container ile sarıyoruz
    child: Container(
      width: 60,
      height: 60,
      color: Colors.transparent, // Tıklama alanı için şart
      child: Icon(
        icon,
        // İKON BOYUTLARINI BURADAN BÜYÜTTÜM
        size: isSelected ? 30 : 26, 
        color: isSelected 
            ? const Color(0xFF6C63FF) 
            : Colors.white.withOpacity(0.3),
      ),
    ),
  );
}
}