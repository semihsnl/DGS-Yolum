import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExamResult {
  final String mode;
  final int mathDuration;
  final int turkishDuration;
  double mathNet;
  double turkishNet;
  int mathCorrect;
  int mathWrong;
  int turkishCorrect;
  int turkishWrong;
  final DateTime dateTime;
  String? name;

  ExamResult({
    required this.mode,
    required this.mathDuration,
    required this.turkishDuration,
    required this.mathNet,
    required this.turkishNet,
    this.mathCorrect = 0,
    this.mathWrong = 0,
    this.turkishCorrect = 0,
    this.turkishWrong = 0,
    required this.dateTime,
    this.name,
  });

  // JSON formatına dönüştürme (Hafızaya kaydetmek için)
  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'mathDuration': mathDuration,
      'turkishDuration': turkishDuration,
      'mathNet': mathNet,
      'turkishNet': turkishNet,
      'mathCorrect': mathCorrect,
      'mathWrong': mathWrong,
      'turkishCorrect': turkishCorrect,
      'turkishWrong': turkishWrong,
      'dateTime': dateTime.toIso8601String(),
      'name': name,
    };
  }

  // JSON'dan nesneye dönüştürme (Hafızadan okumak için)
  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      mode: json['mode'],
      mathDuration: json['mathDuration'],
      turkishDuration: json['turkishDuration'],
      mathNet: (json['mathNet'] as num).toDouble(),
      turkishNet: (json['turkishNet'] as num).toDouble(),
      mathCorrect: json['mathCorrect'] ?? 0,
      mathWrong: json['mathWrong'] ?? 0,
      turkishCorrect: json['turkishCorrect'] ?? 0,
      turkishWrong: json['turkishWrong'] ?? 0,
      dateTime: DateTime.parse(json['dateTime']),
      name: json['name'],
    );
  }
}

class ExamResultStorage {
  static const _key = 'examResults';
  static const _mathTargetKey = 'mathTarget';
  static const _turkishTargetKey = 'turkishTarget';
  static const _favoritesKey = 'favoriteUnits';

  // Tüm sınav sonuçlarını listele
  Future<List<ExamResult>> loadExamResults() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? resultsJson = prefs.getStringList(_key);
    if (resultsJson == null) return [];
    return resultsJson.map((jsonString) => ExamResult.fromJson(jsonDecode(jsonString))).toList();
  }

  // Sınav sonuçlarını kaydet
  Future<void> saveExamResults(List<ExamResult> results) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> resultsJson = results.map((result) => jsonEncode(result.toJson())).toList();
    await prefs.setStringList(_key, resultsJson);
  }

  // Tek bir sınav sonucu ekle (Pratik kullanım için)
  Future<void> addExamResult(ExamResult result) async {
    final results = await loadExamResults();
    results.add(result);
    await saveExamResults(results);
  }

  // --- Tercih Listesi İşlemleri ---
  Future<void> saveFavorites(List<dynamic> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoritesKey, jsonEncode(favorites));
  }

  Future<List<dynamic>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favsJson = prefs.getString(_favoritesKey);
    if (favsJson == null) return [];
    return jsonDecode(favsJson);
  }

  // --- Hedef Net İşlemleri ---
  Future<void> saveTargetNets(double mathTarget, double turkishTarget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_mathTargetKey, mathTarget);
    await prefs.setDouble(_turkishTargetKey, turkishTarget);
  }

  Future<Map<String, double>> loadTargetNets() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'math': prefs.getDouble(_mathTargetKey) ?? 0.0,
      'turkish': prefs.getDouble(_turkishTargetKey) ?? 0.0,
    };
  }
}