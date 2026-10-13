import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/question_provider.dart';
import '../../models/question_model.dart';
import '../../core/constants.dart';
import '../../widgets/full_screen_image_viewer.dart';
import '../../services/pdf_service.dart';
import '../../services/stats_service.dart';
import 'pdf_reorder_page.dart';

class AllQuestionsPage extends StatefulWidget {
  final bool startInSelectionMode;

  const AllQuestionsPage({super.key, this.startInSelectionMode = false});

  @override
  State<AllQuestionsPage> createState() => _AllQuestionsPageState();
}

class _AllQuestionsPageState extends State<AllQuestionsPage> {
  bool _isSelectionMode = false;
  List<Question> _selectedQuestions = [];

  @override
  void initState() {
    super.initState();
    _isSelectionMode = widget.startInSelectionMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestionProvider>().loadAllQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedQuestions.length} Soru Seçildi' : 'Tüm Sorularım'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedQuestions.clear();
                  });
                },
              )
            : null,
        actions: [
          if (!_isSelectionMode)
            TextButton.icon(
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text("PDF Oluştur", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isSelectionMode = true;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            )
          else
            TextButton(
              onPressed: () {
                final provider = context.read<QuestionProvider>();
                setState(() {
                  // Ekranda görünen filtrelenmiş listeyi toptan seç
                  if (_selectedQuestions.length == provider.filteredQuestions.length) {
                    _selectedQuestions.clear();
                  } else {
                    _selectedQuestions = List.from(provider.filteredQuestions);
                  }
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text("Tümünü Seç", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Consumer<QuestionProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.allQuestions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_outlined, size: 80, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8)),
                    const SizedBox(height: 24),
                    const Text(
                      "Kütüphane Boş",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Henüz hiçbir soru eklemediniz.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16),
                    ),
                  ],
                ),
              );
            }
            final subjects = provider.filterSubjects;
            final questions = provider.filteredQuestions;
            final categories = ['Tümü', ...provider.uniqueCategories];

            return Column(
              children: [
                // Yatay Kaydırılabilir ChoiceChip (Ders Filtresi)
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      final isSelected = subject == provider.selectedSubject;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0, top: 12, bottom: 12),
                        child: ChoiceChip(
                          label: Text(subject),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) provider.setFilter(subject);
                          },
                          labelStyle: TextStyle(
                            color: isSelected ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          selectedColor: Theme.of(context).colorScheme.onSurface,
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          showCheckmark: false, // Zen için temiz bir görünüm
                        ),
                      );
                    },
                  ),
                ),
                // Kategori Filtresi (Etiketler)
                if (categories.length > 1) 
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = category == provider.selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0, top: 4, bottom: 8),
                          child: ChoiceChip(
                            label: Text(category, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) provider.setCategoryFilter(category);
                            },
                            labelStyle: TextStyle(
                              color: isSelected ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            selectedColor: Theme.of(context).colorScheme.primary,
                            backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      },
                    ),
                  ),
                // GridView Alanı
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75, // Dikdörtgen Pinterest görünümü
                    ),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      return _buildQuestionCard(context, questions[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _isSelectionMode && _selectedQuestions.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                HapticFeedback.lightImpact();
                final reorderedList = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfReorderPage(selectedQuestions: _selectedQuestions),
                  ),
                );

                if (reorderedList != null && reorderedList is List<Question>) {
                  _showLayoutSelectionSheet(context, reorderedList);
                }
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).scaffoldBackgroundColor,
              icon: const Icon(Icons.picture_as_pdf),
              label: Text('Özel Deneme Oluştur (${_selectedQuestions.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  void _showLayoutSelectionSheet(BuildContext context, List<Question> finalQuestions) {
    final TextEditingController titleController = TextEditingController();
    bool leaveSpaceForSolution = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bottomSheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sayfa Düzeni ve Sınav Başlığı',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: "Sınav Başlığı (İsteğe Bağlı)",
                          hintText: "Örn: TYT Matematik Zor Sorular",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Çözüm için boşluk bırak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Sorunun altına işlem yapabilmen için soluk çizgili bir alan ekler.', style: TextStyle(fontSize: 11)),
                        value: leaveSpaceForSolution,
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                        onChanged: (bool value) {
                          setModalState(() {
                            leaveSpaceForSolution = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildLayoutOption(
                        context: bottomSheetContext,
                        title: 'Sayfada 1 Soru (Büyük)',
                        icon: Icons.crop_square,
                        pdfValue: 1,
                        titleController: titleController,
                        leaveSpaceForSolution: leaveSpaceForSolution,
                        finalQuestions: finalQuestions,
                      ),
                      _buildLayoutOption(
                        context: bottomSheetContext,
                        title: 'Sayfada 2 Soru',
                        icon: Icons.view_agenda_outlined,
                        pdfValue: 2,
                        titleController: titleController,
                        leaveSpaceForSolution: leaveSpaceForSolution,
                        finalQuestions: finalQuestions,
                      ),
                      _buildLayoutOption(
                        context: bottomSheetContext,
                        title: 'Sayfada 3 Soru',
                        icon: Icons.view_list_outlined,
                        pdfValue: 3,
                        titleController: titleController,
                        leaveSpaceForSolution: leaveSpaceForSolution,
                        finalQuestions: finalQuestions,
                      ),
                      _buildLayoutOption(
                        context: bottomSheetContext,
                        title: 'Sayfada 4 Soru (Izgara/Küçük)',
                        icon: Icons.grid_view,
                        pdfValue: 4,
                        titleController: titleController,
                        leaveSpaceForSolution: leaveSpaceForSolution,
                        finalQuestions: finalQuestions,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLayoutOption({required BuildContext context, required String title, required IconData icon, required int pdfValue, required TextEditingController titleController, required bool leaveSpaceForSolution, required List<Question> finalQuestions}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () {
        final customTitle = titleController.text.trim();
        Navigator.pop(context); // bottom sheet'i kapat
        _generatePDF(pdfValue, customTitle, leaveSpaceForSolution, finalQuestions);
      },
    );
  }

  Future<void> _generatePDF(int questionsPerPage, String customTitle, bool leaveSpaceForSolution, List<Question> finalQuestions) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 20),
                const Text("PDF Oluşturuluyor..."),
              ],
            ),
          ),
        );
      },
    );
    try {
      await PdfService.generateAndPrintExam(finalQuestions, questionsPerPage: questionsPerPage, customTitle: customTitle, leaveSpaceForSolution: leaveSpaceForSolution, context: context);
                  
      if (mounted) {
        HapticFeedback.mediumImpact();
        StatsService.instance.incrementPdfCount();
        setState(() {
          _isSelectionMode = false;
          _selectedQuestions.clear();
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Sonsuz Loading ekranını her şartta yok et (Kritik)
      }
    }
  }

  void _toggleSelection(Question question) {
    setState(() {
      if (_selectedQuestions.contains(question)) {
        _selectedQuestions.remove(question);
        if (_selectedQuestions.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedQuestions.add(question);
      }
    });
  }

  Widget _buildQuestionCard(BuildContext context, Question question) {
    final bool isSelected = _selectedQuestions.contains(question);

    return GestureDetector(
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedQuestions.add(question);
          });
        }
      },
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(question);
        } else {
          _showFullScreenImage(context, question);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isSelected 
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), // Zen soft shadow
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Üst Resim Alanı
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'library_image_${question.id}',
                        child: Image.file(
                          File(question.imagePath),
                          fit: BoxFit.cover,
                          cacheWidth: 400, // RAM Optimizasyonu
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.check_circle, color: Theme.of(context).scaffoldBackgroundColor, size: 28),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Alt Yazı Alanı
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  color: Theme.of(context).cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 14, 
                          color: Theme.of(context).colorScheme.primary, // Tematik Vurgu rengi
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        question.topic,
                        maxLines: 1, // Kırpmayı önlemek için tek satır
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12, 
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Tarih Zaman Damgası
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 10, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd.MM.yyyy - HH:mm').format(question.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildTimeRemainingWidget(question.nextReviewDate),
                    ],
                  ),
                ),
              ],
            ),
            // Güvenli Silme İkonu (Sağ üst - Seçim modunda değilse)
            if (!_isSelectionMode)
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => _handleSoftDelete(context, question),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
            // Soru Kategorisi Rozeti (Etiket/Pill)
            if (question.category?.trim().isNotEmpty == true)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label_outline, size: 12, color: Theme.of(context).scaffoldBackgroundColor),
                      const SizedBox(width: 4),
                      Text(
                        question.category!,
                        style: TextStyle(
                          fontSize: 10, 
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
      ),
    );
  }

  Widget _buildTimeRemainingWidget(String nextReviewDateStr) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final reviewDate = DateTime.parse(nextReviewDateStr);
    final reviewDay = DateTime(reviewDate.year, reviewDate.month, reviewDate.day);
    
    final diff = reviewDay.difference(today).inDays;
    
    String text;
    Color color;
    
    if (diff <= 0) {
      text = "Bugün";
      color = AppConstants.hardColor; // Terracotta / Kiremit (Silme but. gibi uyarı rengi sabit kalabilir)
    } else if (diff == 1) {
      text = "Yarın";
      color = Theme.of(context).colorScheme.secondary; // Adaçayı Yeşili dengi
    } else {
      text = "$diff gün sonra";
      color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6); // Muted Kahve / Gri dengi
    }

    return Row(
      children: [
        Icon(Icons.access_time, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _handleSoftDelete(BuildContext context, Question question) {
    final provider = context.read<QuestionProvider>();
    provider.softDeleteQuestion(question);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final snackBarController = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Soru silindi.', style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'GERİ AL',
          textColor: AppConstants.hardColor,
          onPressed: () {
            provider.undoDelete();
          },
        ),
      ),
    );

    // Kimi platformlarda (Örn: Windows Desktop) erişilebilirlik gereği
    // action barındıran SnackBar'lar otomatik kapanmaz. Bunu 4 saniye sonra acımasızca zorluyoruz:
    Timer(const Duration(seconds: 4), () {
      snackBarController.close();
    });

    snackBarController.closed.then((reason) {
      if (reason != SnackBarClosedReason.action) {
        provider.hardDeleteQuestion(question.id!, question.imagePath);
      }
    });
  }

  void _showFullScreenImage(BuildContext context, Question question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imagePath: question.imagePath,
          heroTag: 'library_image_${question.id}',
        ),
      ),
    );
  }
}
