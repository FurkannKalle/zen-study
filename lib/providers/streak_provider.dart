import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';

class StreakProvider with ChangeNotifier {
  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  // Streak mantığı kontrol edilir. Eğer streak 1 arttıysa true, yoksa false döner (Tebrik SnackBar'ı göstermek için).
  Future<bool> checkStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginStr = prefs.getString('lastLoginDate');
    final currentStreakVal = prefs.getInt('currentStreak') ?? 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool didIncrease = false;

    if (lastLoginStr == null) {
      // İlk giriş: Seriyi başlat
      _currentStreak = 1;
      await prefs.setString('lastLoginDate', today.toIso8601String());
      await prefs.setInt('currentStreak', _currentStreak);
    } else {
      final lastLogin = DateTime.parse(lastLoginStr);
      final difference = today.difference(lastLogin).inDays;

      if (difference == 0) {
        // Bugün zaten girilmiş (Seri aynı ve korundu)
        _currentStreak = currentStreakVal;
      } else if (difference == 1) {
        // Dün girilmiş, seriyi 1 arttır
        _currentStreak = currentStreakVal + 1;
        await prefs.setString('lastLoginDate', today.toIso8601String());
        await prefs.setInt('currentStreak', _currentStreak);
        didIncrease = true;
      } else {
        // Dünden daha eski, seriyi boz 1'den başlat
        _currentStreak = 1;
        await prefs.setString('lastLoginDate', today.toIso8601String());
        await prefs.setInt('currentStreak', _currentStreak);
      }
    }
    
    await _updateHomeWidget();
    notifyListeners();
    return didIncrease;
  }

  Future<void> incrementDailyReview() async {
    final prefs = await SharedPreferences.getInstance();
    final String todayDate = DateTime.now().toIso8601String().substring(0, 10);
    
    final dailyReviewsStr = prefs.getString('dailyReviews');
    Map<String, dynamic> dailyReviews = {};
    if (dailyReviewsStr != null) {
      dailyReviews = json.decode(dailyReviewsStr);
    }
    
    dailyReviews[todayDate] = (dailyReviews[todayDate] as int? ?? 0) + 1;
    await prefs.setString('dailyReviews', json.encode(dailyReviews));
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getWeeklyActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyReviewsStr = prefs.getString('dailyReviews');
    Map<String, dynamic> dailyReviews = {};
    if (dailyReviewsStr != null) {
      dailyReviews = json.decode(dailyReviewsStr);
    }

    List<Map<String, dynamic>> weeklyData = [];
    final now = DateTime.now();
    
    // Dart'ta DateTime.weekday: 1=Pzt, 7=Paz
    int daysSinceMonday = now.weekday - 1;
    final monday = now.subtract(Duration(days: daysSinceMonday));

    final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    for (int i = 0; i < 7; i++) {
        final currentDay = monday.add(Duration(days: i));
        final dateString = currentDay.toIso8601String().substring(0, 10);
        
        weeklyData.add({
            'date': dateString,
            'dayName': dayNames[i],
            'count': dailyReviews[dateString] ?? 0,
            'isToday': dateString == now.toIso8601String().substring(0, 10),
        });
    }

    return weeklyData;
  }

  Future<void> _updateHomeWidget() async {
    try {
      final List<Map<String, dynamic>> weekData = await getWeeklyActivity();
      final Map<String, int> daysMap = {};
      
      for (var day in weekData) {
        daysMap[day['dayName'] as String] = day['count'] as int;
      }
      
      final String jsonPayload = json.encode({
        'streak': _currentStreak,
        'days': daysMap
      });
      
      await HomeWidget.saveWidgetData<String>('weekly_stats', jsonPayload);
      await HomeWidget.updateWidget(name: 'ZenWidgetProvider', iOSName: 'ZenWidget');
    } catch (e) {
      debugPrint('Home Widget Error: $e');
    }
  }
}
