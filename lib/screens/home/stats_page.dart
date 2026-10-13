import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../../services/stats_service.dart';
import '../../providers/question_provider.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late ConfettiController _confettiController;
  bool _hasPlayedConfetti = false;

  final List<Color> _zenColors = const [
    Color(0xFF6B9A7B), // Pastel yeşil
    Color(0xFF8A9A5B), // Adaçayı
    Color(0xFF4A7C59), // Orman
    Color(0xFF385741), // Koyu orman
    Color(0xFFA5C1A0), // Açık yeşil
    Color(0xFFC3A38A), // Toprak tonu
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _checkGoalAndPlayConfetti(double progress) {
    if (progress >= 1.0 && !_hasPlayedConfetti) {
      _hasPlayedConfetti = true;
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: kToolbarHeight, // Normal app bar high
          title: Text(
            'Kişisel Ormanım',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.spa), text: 'Zen Odak'),
              Tab(icon: Icon(Icons.library_books), text: 'Kütüphane'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildZenFocusTab(context),
            _buildLibraryTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildZenFocusTab(BuildContext context) {
    return Stack(
      children: [
        ListenableBuilder(
          listenable: StatsService.instance,
          builder: (context, child) {
            final stats = StatsService.instance;
            
            double progress = stats.currentWeekFocusMinutes / stats.weeklyGoalMinutes;
            WidgetsBinding.instance.addPostFrameCallback((_) {
               _checkGoalAndPlayConfetti(progress);
            });

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildZenRank(context, stats),
                  const SizedBox(height: 24),
                  _buildWeeklyGoalCard(context, stats, progress),
                  const SizedBox(height: 32),
                  _buildSummaryCards(context, stats),
                  const SizedBox(height: 32),
                  _buildSubjectChart(context, stats),
                  const SizedBox(height: 32),
                  _buildDailyBarChart(context, stats),
                  const SizedBox(height: 32),
                  _buildPersonalForest(context, stats),
                  const SizedBox(height: 32),
                  _buildSmartInsight(context, stats),
                  const SizedBox(height: 48),
                ],
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.lightGreen, Colors.amber, Colors.orange, Color(0xFF6B9A7B)],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyGoalCard(BuildContext context, StatsService stats, double progress) {
    final double clampedProgress = progress.clamp(0.0, 1.0);
    final isCompleted = clampedProgress >= 1.0;
    
    // Converting minutes to hours formatting
    String formatMinutesToHours(int totalMins) {
      double hours = totalMins / 60;
      if (hours.truncateToDouble() == hours) {
        return "${hours.toInt()} Saat";
      }
      return "${hours.toStringAsFixed(1)} Saat";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isCompleted ? Colors.amber.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Haftalık Hedef: ${formatMinutesToHours(stats.weeklyGoalMinutes)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${formatMinutesToHours(stats.currentWeekFocusMinutes)} / ${formatMinutesToHours(stats.weeklyGoalMinutes)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.amber.shade700 : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: clampedProgress,
              minHeight: 12,
              backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.amber : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (isCompleted) ...[
            const SizedBox(height: 16),
            const Text(
              "Tebrikler! Haftalık hedefini tamamladın 🏆",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, StatsService stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSingleCard(
          context: context,
          title: 'Toplam Süre',
          value: '${stats.totalFocusMinutes} Dk',
          icon: Icons.timer,
          iconColor: Theme.of(context).colorScheme.primary,
        ),
        _buildSingleCard(
          context: context,
          title: 'Büyüyen Ağaç',
          value: '${stats.successfulTreesCount}',
          icon: Icons.park,
          iconColor: const Color(0xFF4A7C59),
        ),
        _buildSingleCard(
          context: context,
          title: 'Kuruyan Fidan',
          value: '${stats.failedTreesCount}',
          icon: Icons.local_florist,
          iconColor: Colors.grey.shade500,
        ),
      ],
    );
  }

  Widget _buildSingleCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectChart(BuildContext context, StatsService stats) {
    final distribution = stats.subjectDistribution;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ders Dağılımı (Tüm Zamanlar)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          if (distribution.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Henüz veri yok...\nDers etiketleyerek odaklanmayı dene.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 50,
                  sections: _generateSections(context, distribution),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _generateLegends(context, distribution),
            ),
          ]
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(BuildContext context, Map<String, int> distribution) {
    final List<PieChartSectionData> sections = [];
    int i = 0;
    
    distribution.forEach((subject, minutes) {
      final color = _zenColors[i % _zenColors.length];
      sections.add(
        PieChartSectionData(
          color: color,
          value: minutes.toDouble(),
          title: '$minutes dk',
          radius: 40,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      i++;
    });

    return sections;
  }

  List<Widget> _generateLegends(BuildContext context, Map<String, int> distribution) {
    final List<Widget> legends = [];
    int i = 0;
    
    distribution.forEach((subject, minutes) {
      final color = _zenColors[i % _zenColors.length];
      legends.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              subject,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
      i++;
    });

    return legends;
  }

  Widget _buildDailyBarChart(BuildContext context, StatsService stats) {
    final dailyMinutes = stats.currentWeekDailyMinutes;
    double maxMinutes = 0;
    for (var m in dailyMinutes) {
      if (m > maxMinutes) maxMinutes = m;
    }

    // Y ekseninde güzel durması için maxMinutes'u biraz yuvarlayalım (örneğin %20 boşluk bırakalım üstten)
    final maxY = maxMinutes == 0 ? 60.0 : maxMinutes * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Günlük Odak Analizi (Bu Hafta)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Theme.of(context).colorScheme.surface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} dk',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Y eksenini gizliyoruz (grid gibi)
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                        if (value >= 0 && value < 7) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: false, // Arka plan çizgilerini gizle
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final minutes = dailyMinutes[index];
                  final isMax = minutes == maxMinutes && maxMinutes > 0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: minutes,
                        color: isMax 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalForest(BuildContext context, StatsService stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Benim Ormanım',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (stats.sessions.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _showClearDataDialog(context, stats);
                  },
                  child: Text('Temizle', style: TextStyle(color: Colors.red.shade400)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (stats.sessions.isEmpty)
             Text(
              'Ormanın çok ıssız... Odaklanmaya başla ve ağaçlarını yeşert!',
              style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats.sessions.map((session) {
                if (session.isSuccess) {
                  return const Icon(Icons.park, color: Color(0xFF4A7C59), size: 32);
                } else {
                  return Icon(Icons.local_florist, color: Colors.grey.shade400, size: 28);
                }
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, StatsService stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ormanı Temizle'),
        content: const Text('Tüm odaklanma istatistiklerini (ağaçlarını) silmek istediğinden emin misin? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              stats.clearAllStats();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );
  }

  Widget _buildZenRank(BuildContext context, StatsService stats) {
    return Column(
      children: [
        Text(
          stats.currentRank,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Toplam Odaklanma: ${stats.totalFocusHours.toStringAsFixed(1)} Saat',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSmartInsight(BuildContext context, StatsService stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: Colors.amber.shade700, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              stats.smartInsight,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTab(BuildContext context) {
    return Consumer<QuestionProvider>(
      builder: (context, provider, child) {
        final allQuestions = provider.allQuestions;
        final int totalCount = allQuestions.length;
        
        final now = DateTime.now();
        final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        final int weeklyCount = allQuestions.where((q) => q.createdAt.isAfter(startOfWeek)).length;
        
        final Map<String, int> distribution = {};
        for (var q in allQuestions) {
          distribution[q.subject] = (distribution[q.subject] ?? 0) + 1;
        }

        return ListenableBuilder(
          listenable: StatsService.instance,
          builder: (context, child) {
            final stats = StatsService.instance;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Üretim Panosu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSingleCard(
                        context: context,
                        title: 'Toplam Soru',
                        value: '$totalCount',
                        icon: Icons.inventory_2,
                        iconColor: Theme.of(context).colorScheme.primary,
                      ),
                      _buildSingleCard(
                        context: context,
                        title: 'Eklenen (Bu Hafta)',
                        value: '+$weeklyCount',
                        icon: Icons.moving_outlined,
                        iconColor: Colors.amber.shade600,
                      ),
                      _buildSingleCard(
                        context: context,
                        title: 'Üretilen PDF',
                        value: '${stats.generatedPdfCount}',
                        icon: Icons.picture_as_pdf,
                        iconColor: Colors.red.shade400,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Kütüphane Dağılımı (Donut Chart)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest ?? Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kütüphane Dağılımı',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (distribution.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                'Kütüphanen henüz bomboş...\nHemen birkaç soru ekle!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          )
                        else ...[
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 60, // Donut mantığı için radius büyütüldü
                                sections: _generateLibrarySections(context, distribution),
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: _generateLibraryLegends(context, distribution),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Çapraz Yapay Zeka Asistanı
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            stats.getLibrarySmartInsight(distribution),
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            );
          }
        );
      },
    );
  }

  List<PieChartSectionData> _generateLibrarySections(BuildContext context, Map<String, int> distribution) {
    final List<PieChartSectionData> sections = [];
    int i = 0;
    
    distribution.forEach((subject, count) {
      final color = _zenColors[i % _zenColors.length];
      sections.add(
        PieChartSectionData(
          color: color,
          value: count.toDouble(),
          title: '$count',
          radius: 40,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      i++;
    });

    return sections;
  }

  List<Widget> _generateLibraryLegends(BuildContext context, Map<String, int> distribution) {
    final List<Widget> legends = [];
    int i = 0;
    
    distribution.forEach((subject, count) {
      final color = _zenColors[i % _zenColors.length];
      legends.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              '$subject ($count)',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
      i++;
    });

    return legends;
  }
}
