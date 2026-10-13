import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/question_provider.dart';
import '../../services/focus_service.dart';
import '../../widgets/scratchpad_overlay.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;
  bool _isBreathing = false;
  bool isScratchpadActive = false;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _breatheAnimation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breatheController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      if (_breatheController.isAnimating) {
        _breatheController.stop(); // Pil tasarrufu: Arka planda animasyon dondur
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isBreathing && !_breatheController.isAnimating) {
        _breatheController.repeat(reverse: true); // Geri gelindiğinde devam et
      }
    }
  }

  void _startFocusWithBreathing(FocusService focusService) {
    if (_isBreathing) return;
    
    setState(() {
      _isBreathing = true;
    });
    
    _breatheController.repeat(reverse: true);
    
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      _breatheController.stop();
      setState(() {
        _isBreathing = false;
      });
      focusService.startTimer();
    });
  }

  double _getTreeSize(FocusService focusService) {
    if (focusService.isFailed) return 100.0;
    if (focusService.isCompleted) return 180.0;
    
    double progress = 1 - (focusService.remainingSeconds / (focusService.selectedMinutes * 60));
    return 100.0 + (progress * 80.0);
  }

  Color _getTreeColor(FocusService focusService, BuildContext context) {
    if (focusService.isFailed) return Colors.grey.shade500;
    if (focusService.isCompleted) return Theme.of(context).colorScheme.primary;
    return Theme.of(context).colorScheme.primary; 
  }

  void _showSubjectPicker(BuildContext context, FocusService focusService) {
    final provider = context.read<QuestionProvider>();
    final List<String> subjects = ['Genel', ...provider.currentSubjects];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hangi derse odaklanıyorsun?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              if (focusService.selectedSubject != null)
                TextButton.icon(
                  onPressed: () {
                    focusService.setSubject(null);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.clear, color: Colors.red),
                  label: const Text('Etiketi Temizle (Vazgeç)', style: TextStyle(color: Colors.red)),
                ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    final isSelected = focusService.selectedSubject == subject;

                    return ListTile(
                      title: Text(
                        subject,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                      onTap: () {
                        focusService.setSubject(subject);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSoundChipsRow(BuildContext context, FocusService focusService) {
    final Map<String, String> sounds = {
      'sessiz': 'Sessiz 🤫',
      'yagmur': 'Yağmur 🌧️',
      'orman': 'Orman 🌲',
      'somine': 'Şömine 🔥'
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: sounds.entries.map((entry) {
          final isSelected = focusService.selectedSound == entry.key;
          final primaryColor = Theme.of(context).colorScheme.primary; 
          final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
          final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                focusService.setSelectedSound(entry.key);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? primaryColor : onSurfaceColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? onPrimaryColor : onSurfaceColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FocusService.instance,
      builder: (context, child) {
        final focusService = FocusService.instance;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        // --- KATI MOD (PENALTY) ARAYÜZÜ ---
        if (focusService.hasFailedFocus) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFF2A2E2A),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.heart_broken, size: 100, color: Colors.grey),
                    const SizedBox(height: 24),
                    const Text(
                      "Odağın Bozuldu.",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Dış dünyadaki gürültüye yenik düştün. Hazır olduğunda derin bir nefes al ve tekrar başla.",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A3626), // Koyu Orman Yeşili
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        focusService.resetPenalty();
                        focusService.resetTimer();
                      },
                      child: const Text("Yeniden Başla", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // --- Dinamik Mola Renkleri (Okyanus Mavisi) ---
        final Color bgColor = focusService.isBreakTime 
            ? (isDark ? const Color(0xFF0D47A1) : const Color(0xFFE3F2FD)) // Lacivert / Açık Mavi
            : Theme.of(context).scaffoldBackgroundColor;
            
        final Color primaryColor = focusService.isBreakTime 
            ? (isDark ? const Color(0xFF81D4FA) : const Color(0xFF0277BD)) // Parlak Mavi / Deniz Mavisi
            : Theme.of(context).colorScheme.primary;

        final Color textColor = focusService.isBreakTime
            ? (isDark ? Colors.white : const Color(0xFF01579B))
            : Theme.of(context).colorScheme.onSurface;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
            title: Text(
              focusService.isBreakTime ? 'Mola Vakti' : 'Zen Odak Modu', 
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.draw),
                tooltip: 'Dijital Karalama Kağıdı',
                onPressed: () {
                  setState(() {
                    isScratchpadActive = !isScratchpadActive;
                  });
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isBreathing)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _breatheAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _breatheAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 60),
                      Text(
                        "Derin bir nefes al...\nVe odaklanmaya başla.",
                        style: TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else ...[
                  if (focusService.isFailed)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Text(
                        'Odaklanmanı bozdun, fidanın kurudu 🥀',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (focusService.isCompleted && !focusService.isBreakTime)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        'Harika! Bir ağaç yetiştirdin 🌳',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (focusService.isRunning)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        focusService.isBreakTime 
                            ? 'Harika iş çıkardın! Şimdi gözlerini ekrandan ayır ve dinlen.'
                            : 'Dış dünyayla bağlantını kes ve hedefine odaklan!',
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: textColor),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                         focusService.isBreakTime 
                            ? 'Mola Vakti Geldi, Dinlenmeye Hazır Mısın?' 
                            : 'Odaklanmaya hazır mısın?',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                        textAlign: TextAlign.center,
                      ),
                    ),

                ValueListenableBuilder<int>(
                  valueListenable: focusService.remainingSecondsNotifier,
                  builder: (context, remainingSecs, child) {
                    return Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeInOut,
                          child: Icon(
                            focusService.isBreakTime ? Icons.coffee : focusService.plantIcon,
                            size: _getTreeSize(focusService), // Bu metod artık remainingSecs veya get remainingSeconds üzerinden anlık değerle döner.
                            color: focusService.isBreakTime 
                                   ? (isDark ? const Color(0xFFB3E5FC) : const Color(0xFF0288D1))
                                   : _getTreeColor(focusService, context),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          focusService.formattedTime, // get metodu anlık notifer değerini okuduğu için güncel değer yansır.
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w300,
                            color: textColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),
                
                if (!focusService.isRunning && !focusService.isBreakTime)
                  Column(
                    children: [
                      Text(
                        "Hedef Süre: ${focusService.selectedMinutes} Dakika (${focusService.plantName})",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Slider(
                        value: focusService.selectedMinutes.toDouble(),
                        min: 10,
                        max: 120,
                        divisions: 22,
                        activeColor: primaryColor,
                        inactiveColor: textColor.withValues(alpha: 0.2),
                        onChanged: (val) {
                          focusService.setDuration(val.toInt());
                        },
                      ),
                    ],
                  ),
                if (!focusService.isRunning && focusService.isBreakTime)
                   Text(
                        "Mola Süresi: 5 Dakika",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),

                if (!focusService.isRunning) const SizedBox(height: 16),
                
                // Müzik / Ses Seçim Yatay Çubuğu
                _buildSoundChipsRow(context, focusService),
                
                const SizedBox(height: 32),

                if (!focusService.isRunning && !focusService.isBreakTime)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ActionChip(
                      backgroundColor: focusService.selectedSubject != null ? primaryColor : Colors.transparent,
                      side: BorderSide(color: textColor.withValues(alpha: 0.5)),
                      label: Text(
                        focusService.selectedSubject == null 
                            ? 'Ders Etiketle (İsteğe Bağlı)' 
                            : 'Ders: ${focusService.selectedSubject}',
                        style: TextStyle(
                          color: focusService.selectedSubject != null ? (isDark ? Colors.black : Colors.white) : textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      avatar: Icon(
                        Icons.label_outline, 
                        color: focusService.selectedSubject != null ? (isDark ? Colors.black : Colors.white) : textColor
                      ),
                      onPressed: () => _showSubjectPicker(context, focusService),
                    ),
                  ),

                if (!focusService.isRunning)
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (focusService.isBreakTime) {
                        focusService.startTimer(); // Direkt başlat (Breathe pass)
                      } else {
                        _startFocusWithBreathing(focusService);
                      }
                    },
                    icon: Icon(focusService.isBreakTime ? Icons.free_breakfast : Icons.play_arrow),
                    label: Text(
                      focusService.isBreakTime 
                          ? 'Molaya Başla' 
                          : (focusService.isFailed || focusService.isCompleted ? 'Yeniden Başla' : 'Odaklanmaya Başla'), 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, 
                      foregroundColor: isDark ? Colors.black : Colors.white, 
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      focusService.stopTimer();
                    },
                    icon: const Icon(Icons.close),
                    label: Text(focusService.isBreakTime ? 'Molayı Bitir' : 'Pes Et', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                  ),
                ], // end of else ...[
              ], // end of children
            ),
          ),
          
          ScratchpadOverlay(
            isVisible: isScratchpadActive,
            onClose: () {
              setState(() {
                isScratchpadActive = false;
              });
            },
          ),
        ],
      ),
    );
      },
    );
  }
}

