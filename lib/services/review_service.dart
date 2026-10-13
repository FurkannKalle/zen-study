import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

class ReviewService {
  static final ReviewService instance = ReviewService._internal();

  ReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;
  static const String _reviewPrefKey = 'has_asked_for_review';

  /// Kullanıcıya uygulamayı oylaması için sadece BİR KERE istek gönderir.
  Future<void> askForReview(BuildContext? context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAsked = prefs.getBool(_reviewPrefKey) ?? false;

      if (hasAsked) {
        return; // Spamlememek için eğer daha önce sorulduysa hiçbir şey yapma.
      }

      bool isAvailable = await _inAppReview.isAvailable();
      
      if (isAvailable) {
        await Future.delayed(const Duration(seconds: 1)); // Akışı zedelememek için minik bir bekleme (opsiyonel)
        
        await _inAppReview.requestReview();
        
        // Kullanıcı reddetse dahi tekrar rahatsız edilmesin.
        await prefs.setBool(_reviewPrefKey, true);
        debugPrint("Review in-app dialog requested successfully.");
      }
    } catch (e) {
      debugPrint("Review Service Error: $e");
    }
  }
}
