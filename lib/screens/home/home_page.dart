import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/question_provider.dart';
import '../../core/constants.dart';
import '../add_question/add_question_page.dart';
import '../review/review_page.dart';
import '../all_questions/all_questions_page.dart';
import '../../providers/theme_provider.dart';
import '../../providers/streak_provider.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final streakProvider = context.read<StreakProvider>();
      final didIncrease = await streakProvider.checkStreak();
      
      if (didIncrease && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Harika! Serin ${streakProvider.currentStreak} güne ulaştı! 🔥', 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
              ],
            ),
            backgroundColor: Theme.of(context).cardColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          )
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<QuestionProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
            }
            return CustomScrollView(
              slivers: [
                _buildAppBar(context, provider.dueQuestions.length),

                // Akıllı Sınav Geri Sayımı ve Felsefi İçgörü
                SliverToBoxAdapter(
                  child: _buildExamMotivationCard(context, provider.selectedExam),
                ),

                // Günlük Motivasyon ve Seri Paneli
                SliverToBoxAdapter(
                  child: _buildMotivationCard(context),
                ),

                // Kendi Denemeni Yarat Kartı (AllQuestionsPage - Seçim Modu Yönlendiricisi)
                SliverToBoxAdapter(
                  child: _buildPdfRoutingCard(context),
                ),

                if (provider.dueQuestions.isEmpty)
                  _buildEmptyState(context)
                else
                  _buildDashboardMetrics(context, provider.dueQuestions.length),
                
                if (provider.dueQuestions.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final list = provider.dueQuestions;
                          final q = list[index];
                          return _buildQuestionCard(context, q);
                        },
                        childCount: provider.dueQuestions.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: Theme.of(context).colorScheme.primary, // Tema rengi
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddQuestionPage()),
          );
        },
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 32,
        ),
      ),
    );
  }


  Widget _buildAppBar(BuildContext context, int count) {
    return SliverAppBar(
      expandedHeight: 150.0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floating: true,
      pinned: true,
      elevation: 0,
      actions: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.grid_view_rounded, color: Theme.of(context).colorScheme.primary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllQuestionsPage()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'Kütüphanem',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPdfRoutingCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final provider = context.read<QuestionProvider>();
            if (provider.allQuestions.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Önce kütüphanene birkaç soru eklemelisin 🍃',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary, // Yeşil ton
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  duration: const Duration(seconds: 3),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllQuestionsPage(startInSelectionMode: true)),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary, // Orman Yeşili
              borderRadius: BorderRadius.circular(16), // Yuvarlatılmış köşeler
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.auto_stories, color: Theme.of(context).colorScheme.onPrimary, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kendi Denemeni Yarat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'İstediğin soruları seç ve anında PDF çalışma kağıdına dönüştür.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onPrimary, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamMotivationCard(BuildContext context, String? selectedExam) {
    final DateTime now = DateTime.now();
    int? daysLeft;
    bool showCountdown = false;

    if (selectedExam != null && selectedExam != 'Diğer' && AppConstants.examDates.containsKey(selectedExam)) {
      final examDate = AppConstants.examDates[selectedExam];
      if (examDate != null && examDate.isAfter(now)) {
        daysLeft = examDate.difference(now).inDays;
        showCountdown = true;
      }
    }

    final int quoteIndex = now.day % AppConstants.stoicQuotes.length;
    final String quote = AppConstants.stoicQuotes[quoteIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            if (showCountdown) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_bottom, color: Theme.of(context).colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '$selectedExam için kalan süre: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    '$daysLeft Gün',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
            ],
            Text(
              quote,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationCard(BuildContext context) {
    return Consumer<StreakProvider>(
      builder: (context, streakProvider, child) {
        final int streak = streakProvider.currentStreak;
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest ?? Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Günün kutlu olsun! ✨',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      streak > 0 ? 'Motivasyonunu Koru!' : 'Hadi Başlayalım!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary, // Koyu Orman Yeşili
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '$streak Gün',
                        style: TextStyle(
                          color: Theme.of(context).scaffoldBackgroundColor, // Yulaf
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Haftalık Etkinlik Raporu (Yedi Gün)
            FutureBuilder<List<Map<String, dynamic>>>(
              future: streakProvider.getWeeklyActivity(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final weeklyData = snapshot.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: weeklyData.map((dayData) {
                    final isToday = dayData['isToday'] as bool;
                    final count = dayData['count'] as int;
                    final hasActivity = count > 0;
                    
                    return Column(
                      children: [
                        Text(
                          dayData['dayName'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: isToday ? 1.0 : 0.6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasActivity ? Theme.of(context).colorScheme.primary : Colors.transparent,
                            border: Border.all(
                              color: hasActivity 
                                  ? Theme.of(context).colorScheme.primary 
                                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: hasActivity 
                              ? Icon(Icons.eco, size: 14, color: Theme.of(context).scaffoldBackgroundColor)
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasActivity ? '$count' : '-',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              }
            ),
          ],
        ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardMetrics(BuildContext context, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Odaklanman gereken',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$count Soru',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final dueQuestions = context.read<QuestionProvider>().dueQuestions;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewPage(questions: dueQuestions),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('Başla'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.energy_savings_leaf_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 24),
              Text(
                "Kütüphanen şu an çok huzurlu...\nİlk sorunu ekleyerek serüvene başla.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, dynamic question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // soft shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewPage(questions: [question]),
            ),
          );
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Image.file(
              File(question.imagePath),
              fit: BoxFit.cover,
              cacheWidth: 400, // OOM Koruması
              errorBuilder: (context, error, stackTrace) => Icon(Icons.style, color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ),
        title: Text(
          question.subject,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
        ),
        subtitle: Text(
          question.topic,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ),
    );
  }


}
