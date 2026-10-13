import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'stats_service.dart';

class FocusService extends ChangeNotifier with WidgetsBindingObserver {
  static final FocusService _instance = FocusService._internal();

  static FocusService get instance => _instance;

  int _selectedMinutes = 25;
  int get selectedMinutes => _selectedMinutes;

  final ValueNotifier<int> remainingSecondsNotifier = ValueNotifier<int>(25 * 60);
  int get remainingSeconds => remainingSecondsNotifier.value;
  set remainingSeconds(int value) => remainingSecondsNotifier.value = value;

  bool isRunning = false;
  bool isFailed = false;
  bool isCompleted = false;
  bool isBreakTime = false; // Mola modunda mı?
  bool hasFailedFocus = false; // Kullanıcı 10 saniyelik toleransı aştı mı?
  Timer? _penaltyTimer;

  void setDuration(int minutes) {
    if (!isRunning) {
      _selectedMinutes = minutes;
      remainingSeconds = minutes * 60;
      notifyListeners();
    }
  }

  IconData get plantIcon {
    if (_selectedMinutes <= 15) return Icons.local_florist;
    if (_selectedMinutes <= 30) return Icons.eco;
    if (_selectedMinutes <= 50) return Icons.park;
    return Icons.forest;
  }

  String get plantName {
    if (_selectedMinutes <= 15) return 'Küçük Kaktüs 🌵';
    if (_selectedMinutes <= 30) return 'Genç Fidan 🌱';
    if (_selectedMinutes <= 50) return 'Büyük Ağaç 🌳';
    return 'Ulu Orman 🌲';
  }

  String? _selectedSubject;
  String? get selectedSubject => _selectedSubject;

  void setSubject(String? subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  String _selectedSound = 'sessiz';
  
  String get selectedSound => _selectedSound;

  void setSelectedSound(String sound) {
    _selectedSound = sound;
    if (isRunning) {
      _playAmbientSound();
    }
    notifyListeners();
  }

  Timer? _timer;

  FocusService._internal() {
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    WidgetsBinding.instance.addObserver(this);
  }

  void _playAmbientSound() async {
    if (_selectedSound != 'sessiz') {
      await _audioPlayer.play(AssetSource('sounds/$_selectedSound.mp3'));
    } else {
      await _audioPlayer.stop();
    }
  }

  void _stopAmbientSound() async {
    await _audioPlayer.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isRunning && !isBreakTime && !hasFailedFocus) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        // Cihaz kilitlendiğinde veya başka uygulamaya geçildiğinde hemen silmek yerine 10 sn şans ver
        _penaltyTimer?.cancel();
        _penaltyTimer = Timer(const Duration(seconds: 10), () {
          // 10 saniye sonunda kullanıcı sisteme dönmediyse sayacı tamamen öldür
          hasFailedFocus = true;
          failTimer();
          notifyListeners();
        });
      } else if (state == AppLifecycleState.resumed) {
        // Kullanıcı 10 saniye dolmadan geri döndü, affet ve cezayı iptal et
        _penaltyTimer?.cancel();
      }
    }
  }

  void startTimer() {
    isRunning = true;
    isFailed = false;
    isCompleted = false;
    hasFailedFocus = false;
    _penaltyTimer?.cancel();
    WakelockPlus.enable(); // Ekranın donanım uyku moduna geçmesini engeller
    
    // Eğer mola modundaysak, süreyi kesin olarak 5 dakika (300 sn) başlat. Yoksa kullanıcının seçtiği odak süresiyle başlat.
    remainingSeconds = isBreakTime ? (5 * 60) : (_selectedMinutes * 60);
    _playAmbientSound();
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        // CPU Pil Optimizasyonu: Her saniye tüm sayfayı çizen notifyListeners() kaldırıldı!
        // Sadece ValueNotifier dinleyicileri uyarılacak.
      } else {
        _timer?.cancel();
        isRunning = false;
        WakelockPlus.disable(); // Pili korumak için ekran kilidi motorunu durdur
        
        HapticFeedback.mediumImpact();
        
        if (!isBreakTime) {
          // Odak süresi bitti, ağaç yetiştirdi ve molaya geçiş hazırlığı
          isCompleted = true;
          // İstatistiği kaydet (Başarılı)
          StatsService.instance.addSession(_selectedMinutes, _selectedSubject, true);
          
          isBreakTime = true;
          remainingSeconds = 5 * 60; // 5 dakika mola
        } else {
          // Mola bitti, normal duruma dönüş
          isBreakTime = false;
          isCompleted = false; 
          remainingSeconds = _selectedMinutes * 60;
        }
        
        _stopAmbientSound();
        notifyListeners();
      }
    });
  }

  void stopTimer() {
    failTimer();
  }

  void failTimer() {
    _timer?.cancel();
    _stopAmbientSound();
    WakelockPlus.disable();
    
    // Eğer gerçekten sayaç işliyordu da fail edildiyse başarısızlığa yaz.
    if (isRunning) {
       StatsService.instance.addSession(_selectedMinutes, _selectedSubject, false);
    }
    
    isRunning = false;
    isFailed = true;
    isBreakTime = false;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _stopAmbientSound();
    WakelockPlus.disable();
    isRunning = false;
    isFailed = false;
    isCompleted = false;
    isBreakTime = false;
    _selectedSubject = null;
    remainingSeconds = _selectedMinutes * 60;
    notifyListeners();
  }

  String get formattedTime {
    int m = remainingSeconds ~/ 60;
    int s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _penaltyTimer?.cancel();
    WakelockPlus.disable();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  void resetPenalty() {
    hasFailedFocus = false;
    notifyListeners();
  }
}
