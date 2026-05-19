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

  // --- ANA SAYFA EKRANI (TEMİZLENDİ & ODAKLANDI) ---
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
                const SizedBox(height: 25),
                _buildOsymTimeline(),
                const SizedBox(height: 25),
                _buildNetGraphSection(),
                const SizedBox(height: 30), // Alt boşluk dengelendi
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- YENİ KATEGORİLER EKRANI (MUAZZAM GRUPLAMA) ---
  Widget _buildCategoriesScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            
            // GRUP 1: REHBER VE HESAPLAMA
            _buildSectionTitle("REHBER VE HESAPLAMA"),
            const SizedBox(height: 12),
            _buildMainButton(
              title: "Taban Sıralamalar ve Puanlar",
              subtitle: "Son 5 yılın üniversite ve bölüm verileri",
              icon: Icons.account_balance_rounded,
              color: const Color(0xFF00D26A), // Yeşil
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BasePointsPage())),
            ),
            const SizedBox(height: 12),
            _buildMainButton(
              title: "Puan Hesapla",
              subtitle: "DGS puanını anında öğren",
              icon: Icons.calculate_rounded,
              color: const Color(0xFF6C63FF), // Mor
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PuanHesaplamaPage())),
            ),
            
            const SizedBox(height: 28),
            
            // GRUP 2: SINAV MODLARI
            _buildSectionTitle("SINAV MODLARI"),
            const SizedBox(height: 12),
            _buildMainButton(
              title: "Tam Sınav",
              subtitle: "135 dk GERÇEK SINAV PROVASI",
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
            
            const SizedBox(height: 28),
            
            // GRUP 3: ARŞİV VE FAVORİLER
            _buildSectionTitle("ARŞİV VE FAVORİLER"),
            const SizedBox(height: 12),
            _buildMainButton(
              title: "Tercih Listem",
              subtitle: "Favori bölümlerini yönet",
              icon: Icons.format_list_numbered_rounded,
              color: Colors.amber, // Sarı
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PreferredListPage())),
            ),
            const SizedBox(height: 12),
            _buildMainButton(
              title: "Geçmiş Sınavlarım",
              subtitle: "Eski sonuçlarını ve gelişimini gör",
              icon: Icons.history_rounded,
              color: const Color(0xFF9F43FF), // Açık Mor
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExamHistoryPage())),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- ÖSYM TARİH ŞERİDİ ---
  Widget _buildOsymTimeline() {
    final now = DateTime.now();
    final DateTime appStart = DateTime(2026, 5, 15, 10, 0);
    final DateTime appEnd = DateTime(2026, 6, 2, 23, 59);
    final DateTime lateAppStart = DateTime(2026, 6, 2, 23, 59);
    final DateTime lateAppEnd = DateTime(2026, 6, 11, 23, 59);
    final DateTime examTime = DateTime(2026, 7, 19, 10, 15);
    final DateTime resultTime = DateTime(2026, 8, 13, 10, 0);

    bool isInAppPeriod = now.isAfter(appStart) && now.isBefore(appEnd);
    bool isInLateAppPeriod = now.isAfter(lateAppStart) && now.isBefore(lateAppEnd);
    bool anyActive = isInAppPeriod || isInLateAppPeriod;

    bool isNextApp = !anyActive && now.isBefore(appStart);
    bool isNextLateApp = !anyActive && now.isAfter(appEnd) && now.isBefore(lateAppStart);
    bool isNextExam = !anyActive && now.isAfter(lateAppEnd) && now.isBefore(examTime);
    bool isNextResult = !anyActive && now.isAfter(examTime) && now.isBefore(resultTime);

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
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: Color(0xFF6C63FF), size: 20),
              const SizedBox(width: 8),
              const Text("ÖSYM Sınav Takvimi", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 25),
          _buildTimelineItem(
            title: "DGS Başvuru Dönemi",
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateLabel("Başlangıç:", "15 Mayıs 2026 - 10:00", isInAppPeriod, isNextApp),
                const SizedBox(height: 4),
                _buildDateLabel("Bitiş:", "02 Haziran 2026 - 23:59", isInAppPeriod, isNextApp),
              ],
            ),
            isCurrentActive: isInAppPeriod,
            isNextTarget: isNextApp,
            isLast: false,
          ),
          _buildTimelineItem(
            title: "Geç Başvuru Günü",
            content: _buildDateLabel("Süre:", "11 Haziran 2026 (00:00 - 23:59)", isInLateAppPeriod, isNextLateApp),
            isCurrentActive: isInLateAppPeriod,
            isNextTarget: isNextLateApp,
            isLast: false,
          ),
          _buildTimelineItem(
            title: "DGS 2026 Sınav Günü",
            content: Text(
              "19 Temmuz 2026 - Saat 10:15",
              style: TextStyle(
                color: isInAppPeriod || isInLateAppPeriod || isNextExam ? const Color(0xFF6DC4A7) : Colors.white.withOpacity(0.12),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            isCurrentActive: false,
            isNextTarget: isNextExam,
            isLast: false,
          ),
          _buildTimelineItem(
            title: "Sonuç Açıklama Tarihi",
            content: _buildDateLabel("Tarih:", "13 Ağustos 2026", false, isNextResult),
            isCurrentActive: false,
            isNextTarget: isNextResult,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({required String title, required Widget content, required bool isCurrentActive, required bool isNextTarget, required bool isLast}) {
    Color dotColor;
    if (isCurrentActive) {
      dotColor = const Color(0xFF00D26A);
    } else if (isNextTarget) {
      dotColor = const Color(0xFF6C63FF);
    } else {
      dotColor = Colors.white.withOpacity(0.05);
    }
    Color titleColor = (isCurrentActive || isNextTarget) ? Colors.white : Colors.white.withOpacity(0.3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 4),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: (isCurrentActive || isNextTarget) ? Colors.white.withOpacity(0.15) : Colors.transparent, width: 2),
                boxShadow: isCurrentActive 
                    ? [BoxShadow(color: const Color(0xFF00D26A).withOpacity(0.3), blurRadius: 8, spreadRadius: 2)]
                    : (isNextTarget ? [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 8, spreadRadius: 2)] : []),
              ),
            ),
            if (!isLast) Container(width: 2, height: 55, color: dotColor.withOpacity(0.2)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: titleColor, fontSize: 14, fontWeight: (isCurrentActive || isNextTarget) ? FontWeight.bold : FontWeight.w600)),
              const SizedBox(height: 6),
              content,
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateLabel(String prefix, String dateText, bool isCurrentActive, bool isNextTarget) {
    bool isVisible = isCurrentActive || isNextTarget;
    Color textColor = isCurrentActive ? const Color(0xFF6DC4A7) : (isNextTarget ? Colors.white70 : Colors.white.withOpacity(0.12));
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 12, fontFamily: 'Segoe UI', color: isVisible ? Colors.white60 : Colors.white.withOpacity(0.12)),
        children: [
          TextSpan(text: "$prefix ", style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: dateText, style: TextStyle(color: textColor)),
        ],
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
          if (_recentExams.isEmpty) _buildEmptyGraphState() else SizedBox(height: 160, child: LineChart(_mainChartData())),
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
          const Text("Henüz deneme çözmedin.\nNet takibi için sınavlara başla!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
          TextButton(onPressed: () => setState(() => _selectedIndex = 1), child: const Text("Sınav Modlarını Gör", style: TextStyle(color: Color(0xFF6C63FF))))
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1E26),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
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
    return Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5));
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(25, 0, 25, 15),
      height: 60, 
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E26),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

  Widget _buildNavItem(int index, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() { _selectedIndex = index; });
        _loadData();
      },
      child: Container(
        width: 60,
        height: 60,
        color: Colors.transparent,
        child: Icon(icon, size: isSelected ? 30 : 26, color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withOpacity(0.3)),
      ),
    );
  }
}