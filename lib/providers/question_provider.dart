import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../models/question_model.dart';
import '../../data/local/database_helper.dart';
import '../../services/notification_service.dart';
import '../../services/garbage_collector_service.dart';

class QuestionProvider with ChangeNotifier {
  List<Question> _dueQuestions = [];
  List<Question> _allQuestions = [];
  bool _isLoading = false;

  List<Question> get dueQuestions {
    if (_selectedExam == null) return _dueQuestions;
    return _dueQuestions.where((q) => q.exam == _selectedExam || q.exam == 'Genel').toList();
  }

  List<Question> get allQuestions {
    if (_selectedExam == null) return _allQuestions;
    return _allQuestions.where((q) => q.exam == _selectedExam || q.exam == 'Genel').toList();
  }

  bool get isLoading => _isLoading;

  // Onboarding / Sınav Seçimi
  String? _selectedExam;
  String? get selectedExam => _selectedExam;

  List<String> get currentSubjects {
    if (_selectedExam != null && AppConstants.examSubjects.containsKey(_selectedExam)) {
      return AppConstants.examSubjects[_selectedExam]!;
    }
    return AppConstants.examSubjects['Diğer']!;
  }

  Future<void> loadUserExam() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedExam = prefs.getString('selectedExam');
    } catch (e) {
      debugPrint("Sınav tercihi okuma hatası: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveUserExam(String exam) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedExam', exam);
      _selectedExam = exam;
      _selectedSubject = 'Tümü'; // Yeni sınava geçince filtre sıfırlansın
      await loadDueQuestions();
      await loadAllQuestions();
    } catch (e) {
      debugPrint("Sınav tercihi kaydetme hatası: $e");
    } finally {
      notifyListeners();
    }
  }

  // Filtreleme State'leri
  String _selectedSubject = 'Tümü';
  String get selectedSubject => _selectedSubject;
  String _selectedCategory = 'Tümü';
  String get selectedCategory => _selectedCategory;

  void setFilter(String subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Menü için Ders Listesi
  List<String> get filterSubjects {
    final Set<String> subjects = {'Tümü'};
    for (var q in allQuestions) {
      subjects.add(q.subject);
    }
    return subjects.toList();
  }

  // Seçili derse ve kategoriye göre filtrelenmiş veriler
  List<Question> get filteredQuestions {
    List<Question> result = allQuestions;
    
    if (_selectedSubject != 'Tümü') {
      result = result.where((q) => q.subject == _selectedSubject).toList();
    }
    
    if (_selectedCategory != 'Tümü') {
      result = result.where((q) => q.category == _selectedCategory).toList();
    }
    
    return result;
  }

  // Belirli bir ders için daha önce girilen benzersiz (unique) konular
  List<String> getUniqueTopicsForSubject(String subject) {
    final Set<String> topics = {};
    for (var q in allQuestions) {
      if (q.subject == subject) {
        topics.add(q.topic);
      }
    }
    return topics.toList()..sort();
  }

  // Seçili sınav için (veya genel) benzersiz kategorileri döndürür
  List<String> get uniqueCategories {
    final Set<String> categories = {};
    for (var q in allQuestions) {
      if (q.category != null && q.category!.trim().isNotEmpty) {
        categories.add(q.category!.trim());
      }
    }
    return categories.toList()..sort();
  }

  Future<void> loadDueQuestions() async {
    _isLoading = true;
    notifyListeners();

    List<Question> rawQuestions = await DatabaseHelper.instance.getDueQuestions();
    final directory = await getApplicationDocumentsDirectory();
    final String basePath = directory.path;

    _dueQuestions = rawQuestions.map((q) {
      String renderPath = q.imagePath;
      if (!renderPath.contains('/') && !renderPath.contains('\\')) {
        renderPath = '$basePath/$renderPath';
      }
      return q.copyWith(imagePath: renderPath);
    }).toList();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllQuestions() async {
    _isLoading = true;
    notifyListeners();

    List<Question> rawQuestions = await DatabaseHelper.instance.getAllQuestions();
    final directory = await getApplicationDocumentsDirectory();
    final String basePath = directory.path;

    _allQuestions = rawQuestions.map((q) {
      String renderPath = q.imagePath;
      if (!renderPath.contains('/') && !renderPath.contains('\\')) {
        renderPath = '$basePath/$renderPath';
      }
      return q.copyWith(imagePath: renderPath);
    }).toList();
    
    _isLoading = false;
    notifyListeners();
    
    // Veritabanı okunduğunda/değiştiğinde bildirim saatlerini yeni tabloya göre kur.
    final time = await NotificationService.instance.getNotificationTime();
    NotificationService.instance.scheduleDailyNotification(time.hour, time.minute);

    // Açılış süresini yavaşlatmamak için (Fire and Forget) arka planda sessiz çalışacak şekilde çöpleri temizle
    GarbageCollectorService.cleanOrphanedImages(_allQuestions);
  }

  Future<void> addQuestion({
    required String imagePath,
    required String subject,
    required String topic,
    String? note,
    String? category, // İsteğe bağlı
  }) async {
    final now = DateTime.now();
    // Path üzerinden sadece dosya ismini izole et (Göreli/Relative) 
    final String safeImagePath = imagePath.split('/').last.split('\\').last;
    
    // İlk eklemede direkt review için hazır olsun diye bugünü veriyoruz.
    final newQuestion = Question(
      imagePath: safeImagePath,
      subject: subject,
      topic: topic,
      exam: _selectedExam ?? 'Diğer',
      note: note,
      category: category,
      nextReviewDate: now.toIso8601String(),
      createdAt: now,
    );

    await DatabaseHelper.instance.insertQuestion(newQuestion);
    await loadDueQuestions();
    await loadAllQuestions();
  }

  // Zorluk: { 0: Zordu, 1: Orta, 2: Kolaydı }
  Future<void> reviewQuestion(Question question, int difficultyOption) async {
    DateTime nextDate = DateTime.parse(question.nextReviewDate);
    
    int newInterval = question.interval;
    double newEaseFactor = question.easeFactor;
    int isLearned = question.isLearned;

    if (difficultyOption == 0) { // Zordu
      newInterval = 1; 
      newEaseFactor = (newEaseFactor - 0.2).clamp(1.3, 5.0);
    } else if (difficultyOption == 1) { // Orta
      newInterval = 3; 
    } else { // Kolaydı
      newInterval = 7; 
    }

    nextDate = DateTime.now().add(Duration(days: newInterval));
    
    final updatedQuestion = question.copyWith(
      nextReviewDate: nextDate.toIso8601String(),
      interval: newInterval,
      easeFactor: newEaseFactor,
      reviewCount: question.reviewCount + 1,
      isLearned: isLearned,
    );

    await DatabaseHelper.instance.updateQuestion(updatedQuestion);
    
    // Gözden geçirilmiş soruyu bugünkü listeden çıkar
    _dueQuestions.removeWhere((q) => q.id == question.id);
    
    // Tüm sorular listesinde de eskisini bulup yeni haliyle değiştiriyoruz
    final index = _allQuestions.indexWhere((q) => q.id == question.id);
    if (index != -1) {
      _allQuestions[index] = updatedQuestion;
    }
    
    notifyListeners();
    final time = await NotificationService.instance.getNotificationTime();
    NotificationService.instance.scheduleDailyNotification(time.hour, time.minute);
  }

  Question? _tempDeletedQuestion;
  int? _tempDeletedIndex;

  void softDeleteQuestion(Question question) {
    _tempDeletedQuestion = question;
    _tempDeletedIndex = _allQuestions.indexWhere((q) => q.id == question.id);
    if (_tempDeletedIndex == -1) _tempDeletedIndex = null;
    
    _allQuestions.removeWhere((q) => q.id == question.id);
    _dueQuestions.removeWhere((q) => q.id == question.id);
    notifyListeners();
  }

  void undoDelete() {
    if (_tempDeletedQuestion != null) {
      if (_tempDeletedIndex != null && _tempDeletedIndex! >= 0 && _tempDeletedIndex! <= _allQuestions.length) {
        _allQuestions.insert(_tempDeletedIndex!, _tempDeletedQuestion!);
      } else {
        _allQuestions.add(_tempDeletedQuestion!);
      }
      
      loadDueQuestions(); // Veritabanından sıfırlanıp dueList'e de düşmesini garantileriz
      notifyListeners();
      
      _tempDeletedQuestion = null;
      _tempDeletedIndex = null;
    }
  }

  Future<void> hardDeleteQuestion(int id, String imagePath) async {
    // 1. Veritabanından kalıcı sil
    await DatabaseHelper.instance.deleteQuestion(id);
    
    // 2. Fiziksel sızıntıyı önle
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Fiziksel dosya silinirken uyarı alındı: $e");
    }

    if (_tempDeletedQuestion?.id == id) {
      _tempDeletedQuestion = null;
      _tempDeletedIndex = null;
    }

    final time = await NotificationService.instance.getNotificationTime();
    NotificationService.instance.scheduleDailyNotification(time.hour, time.minute);
  }

  // --- OLUŞTURULAN TOPLU (BATCH) I/O İŞLEYİCİLER (Listeler sadece 1 kez rebuild edilir) ---
  
  /// Binlerce dosyayı bile UI'ı dondurmadan (Janksiz) diski yormadan tamamen siler
  Future<void> hardDeleteQuestionsBatch(List<Question> questionsToDelete) async {
    if (questionsToDelete.isEmpty) return;

    // 1. Veritabanından (SQLite) Toplu Sil (DB.Batch)
    final List<int> idsToDelete = questionsToDelete.map((q) => q.id!).toList();
    await DatabaseHelper.instance.deleteQuestionsBatch(idsToDelete);

    // 2. RAM Düzeltmesi (Provider listelerini temizle) - BURADA DÖNGÜDE notifyListeners YASAK!
    for (final q in questionsToDelete) {
      _allQuestions.removeWhere((item) => item.id == q.id);
      _dueQuestions.removeWhere((item) => item.id == q.id);
      
      // Fiziksel medyayı (Resimleri) sessizce arka planda siliver
      try {
        final file = File(q.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    // 3. Ekrana BİR KERE güncelleme gönderilir (Frame-drop koruması)
    notifyListeners();
  }

  /// Çoklu işlemleri arka arkaya veritabanına sokmadan (Bulk execution) temizler
  Future<void> updateQuestionsBatch(List<Question> updatedQuestions) async {
    if (updatedQuestions.isEmpty) return;

    // 1. Veritabanında (SQLite) topluca güncelle
    await DatabaseHelper.instance.updateQuestionsBatch(updatedQuestions);

    // 2. RAM Listelerinde Düzelt
    for (final q in updatedQuestions) {
      final allIndex = _allQuestions.indexWhere((item) => item.id == q.id);
      if (allIndex != -1) _allQuestions[allIndex] = q;

      final dueIndex = _dueQuestions.indexWhere((item) => item.id == q.id);
      if (dueIndex != -1) {
        _dueQuestions[dueIndex] = q;
      }
    }

    // 3. Tüm süreç tamamlanınca YALNIZCA BİR KERE state tetiklenir
    notifyListeners();
  }
}
