import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/exam_result.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final ExamResultStorage _storage = ExamResultStorage();
  List<ExamResult> _results = [];
  bool _isLoading = true;
  
  // Hedef değerleri için değişkenler
  double _mathTarget = 0.0;
  double _turkishTarget = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await _storage.loadExamResults();
    final targets = await _storage.loadTargetNets(); // Hedefleri yükle
    results.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    setState(() {
      _results = results;
      _mathTarget = targets['math']!;
      _turkishTarget = targets['turkish']!;
      _isLoading = false;
    });
  }

  // Hedef belirleme diyaloğu
  void _showTargetDialog() {
    TextEditingController mController = TextEditingController(text: _mathTarget > 0 ? _mathTarget.toString() : "");
    TextEditingController tController = TextEditingController(text: _turkishTarget > 0 ? _turkishTarget.toString() : "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E3F),
        title: const Text("Hedef Netlerini Belirle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTargetInput(mController, "Matematik Hedefi", Colors.blueAccent),
            const SizedBox(height: 16),
            _buildTargetInput(tController, "Türkçe Hedefi", Colors.orangeAccent),
            const SizedBox(height: 12),
            const Text("Sıfırlamak için 0 yazın veya boş bırakın.", style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D26A)),
            onPressed: () async {
              double m = double.tryParse(mController.text) ?? 0.0;
              double t = double.tryParse(tController.text) ?? 0.0;
              await _storage.saveTargetNets(m, t);
              Navigator.pop(context);
              _loadData(); // Verileri ve grafiği tazele
            },
            child: const Text("Kaydet", style: TextStyle(color: Color(0xFF0A0E27), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetInput(TextEditingController controller, String label, Color color) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: color.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: color, width: 2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showTargetDialog, 
            icon: const Icon(Icons.track_changes, color: Color(0xFF00D26A)) // Hedef Butonu
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D26A)))
          : _results.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(), 
                        const SizedBox(height: 32),
                        const Text(
                          "Genel Net Gelişimi",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildMainChart(),
                        const SizedBox(height: 40),
                        const Text(
                          "Ders Bazlı Karşılaştırma",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildSubjectCompareChart(),
                        const SizedBox(height: 16),
                        _buildLegend(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    if (_results.isEmpty) return const SizedBox();

    double totalNetAvg = _results.map((e) => e.mathNet + e.turkishNet).reduce((a, b) => a + b) / _results.length;
    double mathNetAvg = _results.map((e) => e.mathNet).reduce((a, b) => a + b) / _results.length;
    double turkishNetAvg = _results.map((e) => e.turkishNet).reduce((a, b) => a + b) / _results.length;

    return Column(
      children: [
        Row(
          children: [
            _buildStatCard("Ortalama Toplam Net", totalNetAvg.toStringAsFixed(2), const Color(0xFF9F43FF)),
            const SizedBox(width: 12),
            _buildStatCard("Sınav Sayısı", _results.length.toString(), const Color(0xFF00D26A)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard("Ort. Matematik", mathNetAvg.toStringAsFixed(2), Colors.blueAccent),
            const SizedBox(width: 12),
            _buildStatCard("Ort. Türkçe", turkishNetAvg.toStringAsFixed(2), Colors.orangeAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E3F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              title, 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 11),
            ),
            const SizedBox(height: 6),
            Text(
              value, 
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem("Matematik", Colors.blueAccent),
        const SizedBox(width: 24),
        _legendItem("Türkçe", Colors.orangeAccent),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Henüz veri yok. Sınav çözerek başlayın!',
        style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 16),
      ),
    );
  }

  LineTouchData _getTouchData() {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchedSpot) => const Color(0xFF1E1E3F),
        tooltipRoundedRadius: 8,
        getTooltipItems: (List<LineBarSpot> touchedSpots) {
          return touchedSpots.map((LineBarSpot touchedSpot) {
            final result = _results[touchedSpot.x.toInt()];
            final dateStr = "${result.dateTime.day}/${result.dateTime.month}/${result.dateTime.year}";
            
            return LineTooltipItem(
              "${result.name ?? 'Sınav'}\n",
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              children: [
                TextSpan(
                  text: "$dateStr\n",
                  style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 10),
                ),
                TextSpan(
                  text: "Net: ${touchedSpot.y.toStringAsFixed(2)}",
                  style: TextStyle(color: touchedSpot.bar.color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildMainChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 16, top: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: _getTouchData(),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _results.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), (e.value.mathNet + e.value.turkishNet));
              }).toList(),
              isCurved: true,
              color: const Color(0xFF9F43FF),
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: const Color(0xFF9F43FF).withOpacity(0.15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCompareChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 16, top: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: _getTouchData(),
          // HEDEF ÇİZGİLERİ BURAYA EKLENDİ
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (_mathTarget > 0)
                HorizontalLine(
                  y: _mathTarget,
                  color: Colors.blueAccent.withOpacity(0.6),
                  strokeWidth: 2,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    labelResolver: (_) => 'Hedef Mat: $_mathTarget',
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              if (_turkishTarget > 0)
                HorizontalLine(
                  y: _turkishTarget,
                  color: Colors.orangeAccent.withOpacity(0.6),
                  strokeWidth: 2,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.bottomRight,
                    labelResolver: (_) => 'Hedef Tür: $_turkishTarget',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _results.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.mathNet)).toList(),
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
            LineChartBarData(
              spots: _results.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.turkishNet)).toList(),
              isCurved: true,
              color: Colors.orangeAccent,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}