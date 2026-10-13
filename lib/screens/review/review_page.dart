import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../models/question_model.dart';
import '../../providers/question_provider.dart';
import '../../providers/streak_provider.dart';
import '../../core/constants.dart';
import '../../widgets/full_screen_image_viewer.dart';
import '../../widgets/scratchpad_overlay.dart';

class ReviewPage extends StatefulWidget {
  final List<Question> questions;

  const ReviewPage({super.key, required this.questions});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final CardSwiperController controller = CardSwiperController();
  late List<Question> _deck;
  int _currentIndex = 0;
  bool isScratchpadActive = false;

  @override
  void initState() {
    super.initState();
    _deck = List.from(widget.questions);
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (_deck.isEmpty || previousIndex >= _deck.length) return false;
    
    final question = _deck[previousIndex];
    int difficulty = 1; 
    
    if (direction == CardSwiperDirection.right) {
      difficulty = 2; 
    } else if (direction == CardSwiperDirection.left) {
      difficulty = 0; 
    } else if (direction == CardSwiperDirection.bottom) {
      return false; 
    }

    context.read<QuestionProvider>().reviewQuestion(question, difficulty);
    context.read<StreakProvider>().incrementDailyReview();
    
    // Kütüphanenin (flutter_card_swiper) çökmesini engellemek için mevcut durumu takip ediyoruz
    setState(() {
      _currentIndex = previousIndex + 1;
    });

    return true; 
  }

  @override
  Widget build(BuildContext context) {
    // Kütüphane kalan kart sayısından fazla gösterim isterse assert fırlattığı için dinamik tutuyoruz.
    int remaining = _deck.length - _currentIndex;
    int displayCount = remaining > 3 ? 3 : (remaining <= 0 ? 1 : remaining);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Odak Modu'),
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
          SafeArea(
            child: _deck.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.spa_outlined, size: 64, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(height: 16),
                    Text(
                      "Sorun Yok...\nTüm soruları tamamladın.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: CardSwiper(
                      controller: controller,
                      cardsCount: _deck.length,
                      onSwipe: _onSwipe,
                      numberOfCardsDisplayed: displayCount,
                      onEnd: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Bu oturumdaki tüm soruları tamamladın!"),
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                          )
                        );
                        Navigator.pop(context);
                      },
                      backCardOffset: const Offset(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                        return _buildCardWidget(_deck[index]);
                      },
                    ),
                  ),
                  _buildLegend(),
                ],
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
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0, top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(Icons.energy_savings_leaf_outlined, AppConstants.hardColor, "Zor\n(Sola)"),
          _buildLegendItem(Icons.water_drop_outlined, AppConstants.mediumColor, "Orta\n(Yukarı)"),
          _buildLegendItem(Icons.eco_rounded, AppConstants.easyColor, "Kolay\n(Sağa)"),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String text) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCardWidget(Question question) {
    return Container(
      // Key ile sarmak, swiper'ın kartları birbirinden net olarak ayırmasını sağlar. 
      key: ValueKey(question.id),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Theme.of(context).cardColor),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageViewer(
                      imagePath: question.imagePath,
                      heroTag: 'review_image_${question.id}',
                    ),
                  ),
                );
              },
              child: Hero(
                tag: 'review_image_${question.id}',
                child: Image.file(
                  File(question.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.style, size: 64, color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
              ),
            ),
            // Kategori Etiketi
            if (question.category?.trim().isNotEmpty == true)
              Positioned(
                top: 24,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3)),
                    ]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label_outline, size: 14, color: Theme.of(context).scaffoldBackgroundColor),
                      const SizedBox(width: 4),
                      Text(
                        question.category!,
                        style: TextStyle(
                          fontSize: 12, 
                          color: Theme.of(context).scaffoldBackgroundColor, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Alt Bilgi Şeridi
        Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        question.subject, 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      question.topic, 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    // Tarih Zaman Damgası
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd.MM.yyyy - HH:mm').format(question.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    if (question.note?.trim().isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8).copyWith(topLeft: Radius.zero, bottomLeft: Radius.zero),
                            border: Border(
                              left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.secondary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  question.note!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    height: 1.4,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // Soru Etiketleri bitişi
          ],
        ),
      ),
    );
  }
}
