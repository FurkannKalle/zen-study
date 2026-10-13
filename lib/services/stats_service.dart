import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class FocusSession {
  final DateTime date;
  final int durationMinutes;
  final String? subject;
  final bool isSuccess;

  FocusSession({
    required this.date,
    required this.durationMinutes,
    this.subject,
    required this.isSuccess,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'subject': subject,
      'isSuccess': isSuccess,
    };
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      date: DateTime.parse(json['date']),
      durationMinutes: json['durationMinutes'],
      subject: json['subject'],
      isSuccess: json['isSuccess'],
    );
  }
}

class StatsService extends ChangeNotifier {
  static final StatsService instance = StatsService._internal();

  StatsService._internal() {
    _loadSessions();
  }

  static const String _statsPrefKey = 'focus_sessions_history';
  static const String _pdfCountKey = 'generated_pdf_count';
  
  List<FocusSession> _sessions = [];
  int _generatedPdfCount = 0;
  String? _selectedExam; // Dinamik Sınav Modülü Seçimi İçi
  
  final int weeklyGoalMinutes = 600;

  List<FocusSession> get sessions => List.unmodifiable(_sessions);
  int get generatedPdfCount => _generatedPdfCount;

  int get currentWeekFocusMinutes {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    
    return _sessions
        .where((s) => s.isSuccess && s.date.isAfter(startOfWeek))
        .fold(0, (total, s) => total + s.durationMinutes);
  }

  List<double> get currentWeekDailyMinutes {
    final List<double> dailyMinutes = List.filled(7, 0.0);
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    for (var s in _sessions) {
      if (s.isSuccess && s.date.isAfter(startOfWeek)) {
        // weekday: 1 (Monday) to 7 (Sunday)
        // index: 0 (Monday) to 6 (Sunday)
        int index = s.date.weekday - 1;
        dailyMinutes[index] += s.durationMinutes.toDouble();
      }
    }
    return dailyMinutes;
  }

  int get totalFocusMinutes {
    return _sessions
        .where((s) => s.isSuccess)
        .fold(0, (total, s) => total + s.durationMinutes);
  }

  double get totalFocusHours => totalFocusMinutes / 60;

  String get currentRank {
    if (totalFocusHours < 5) return "🌱 Çırak (Tohum)";
    if (totalFocusHours < 20) return "🌿 Odak Yolcusu (Fidan)";
    if (totalFocusHours < 50) return "🌳 Zen Ustası (Ağaç)";
    return "🌲 Orman Muhafızı";
  }

  String get smartInsight {
    final dist = subjectDistribution;
    if (dist.isEmpty) {
      return "Henüz analiz yapacak kadar veri yok. Hemen odaklanmaya başla!";
    }

    String maxSub = "";
    int maxMin = -1;

    for (var entry in dist.entries) {
      if (entry.value > maxMin && entry.key != 'Diğer' && entry.key != 'Genel') {
        maxMin = entry.value;
        maxSub = entry.key;
      }
    }

    // Find the least studied (from core subjects based on exam system)
    String minSub = "";
    int minMin = 99999999;
    
    // Core subjects dynamically fetched via selected exam
    List<String> coreSubjects = [];
    if (_selectedExam != null && AppConstants.examSubjects.containsKey(_selectedExam)) {
      coreSubjects = AppConstants.examSubjects[_selectedExam!]!;
    } else {
      coreSubjects = AppConstants.examSubjects['Diğer']!;
    }
    
    for (var sub in coreSubjects) {
      final subTrimmed = sub.trim();
      final subMin = dist[subTrimmed] ?? 0;
      if (subMin < minMin && subTrimmed != maxSub) {
        minMin = subMin;
        minSub = subTrimmed;
      }
    }

    if (maxSub.isEmpty) {
      return "Harika gidiyorsun! Odak serüveninde bir sonraki adımın seni bekliyor.";
    }

    double maxHours = maxMin / 60;
    String hoursStr = maxHours.toStringAsFixed(1).replaceAll('.0', '');
    
    if (minMin == 0) {
      return "Harika gidiyorsun! Son zamanlarda en çok $maxSub ($hoursStr saat) çalıştın ama $minSub defterin henüz açılmamış gibi. Bir sonraki seansını ona ayırabilirsin.";
    } else {
      return "Harika gidiyorsun! Son zamanlarda en çok $maxSub ($hoursStr saat) çalıştın ama $minSub tarafı biraz eksik kalmış gibi. Bir sonraki seansını ona ayırabilirsin.";
    }
  }

  String getLibrarySmartInsight(Map<String, int> libraryDistribution) {
    if (libraryDistribution.isEmpty) {
      return "Kütüphanende henüz hiç soru yok. Soru ekleyerek analiz sürecini başlatabilirsin!";
    }

    String maxLibrarySub = "";
    int maxLibraryCount = -1;

    for (var entry in libraryDistribution.entries) {
      final keyTrimmed = entry.key.trim();
      if (entry.value > maxLibraryCount && keyTrimmed != 'Tümü' && keyTrimmed != 'Genel') {
        maxLibraryCount = entry.value;
        maxLibrarySub = keyTrimmed;
      }
    }

    if (maxLibrarySub.isEmpty) return "Soru ekleyerek analiz sürecini başlatabilirsin!";

    final focusDist = subjectDistribution;
    final int focusMinutes = focusDist[maxLibrarySub] ?? 0;

    if (focusMinutes < 60) {
      return "Kütüphanende en çok $maxLibrarySub birikmiş ($maxLibraryCount soru) ancak son zamanlarda ona az odaklanmışsın (Sadece $focusMinutes dk). Sonraki PDF'ini $maxLibrarySub dersinden oluşturabilirsin!";
    } else {
      return "Kütüphanendeki sorularla çalışmaların uyum içinde. $maxLibrarySub testlerini harika bir deneme PDF'ine dönüştürmek için mükemmel bir vakit!";
    }
  }

  int get successfulTreesCount {
    return _sessions.where((s) => s.isSuccess).length;
  }

  int get failedTreesCount {
    return _sessions.where((s) => !s.isSuccess).length;
  }

  Map<String, int> get subjectDistribution {
    final Map<String, int> distribution = {};
    for (var s in _sessions.where((s) => s.isSuccess && s.subject != null)) {
      final sub = s.subject!.trim();
      distribution[sub] = (distribution[sub] ?? 0) + s.durationMinutes;
    }
    return distribution;
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionsJson = prefs.getString(_statsPrefKey);
    _selectedExam = prefs.getString('selectedExam');

    if (sessionsJson != null) {
      final List<dynamic> decodedList = json.decode(sessionsJson);
      _sessions = decodedList.map((json) => FocusSession.fromJson(json)).toList();
      
      // Tarihe göre sırala (en yeniden eskiye)
      _sessions.sort((a, b) => b.date.compareTo(a.date));
    }
    
    _generatedPdfCount = prefs.getInt(_pdfCountKey) ?? 0;
    notifyListeners();
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = _sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_statsPrefKey, json.encode(jsonList));
  }

  void addSession(int minutes, String? subject, bool isSuccess) {
    if (minutes <= 0) return;

    final newSession = FocusSession(
      date: DateTime.now(),
      durationMinutes: minutes,
      subject: subject,
      isSuccess: isSuccess,
    );

    _sessions.insert(0, newSession);
    _saveSessions();
    notifyListeners();
  }
  
  Future<void> incrementPdfCount() async {
    _generatedPdfCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pdfCountKey, _generatedPdfCount);
    notifyListeners();
  }

  void clearAllStats() async {
    _sessions.clear();
    _generatedPdfCount = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pdfCountKey);
    await _saveSessions();
    notifyListeners();
  }
}
