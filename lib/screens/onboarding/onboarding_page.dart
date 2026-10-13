import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants.dart';
import 'exam_selection_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Sorularını Yakala ve Kırp",
      "description": "Yapamadığın soruların fotoğrafını çek, akıllı kırpma aracıyla gereksiz yerleri temizle ve kendi dijital test kitabını oluştur.",
      "icon": Icons.crop,
    },
    {
      "title": "Kütüphaneni Düzenle",
      "description": "Sorularına \"Matematik\", \"Fizik\" veya \"Tekrar Çözülecek\" gibi özel etiketler ata. Aradığın her soruya tek tıkla, anında ulaş.",
      "icon": Icons.style,
    },
    {
      "title": "Zen Odak Modu",
      "description": "Sınav sürene göre sayacını kur, dış dünyayla bağlantını kes ve derin çalışmanın keyfine var. Odaklandıkça istatistiklerin büyüsün.",
      "icon": Icons.spa,
    },
    {
      "title": "Serini Koru",
      "description": "Her gün en az bir odak seansını tamamla, ateşini canlandır. Motivasyonunu kaybetmeden hedefine doğru emin adımlarla ilerle.",
      "icon": Icons.local_fire_department,
    },
  ];

  void _completeOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ExamSelectionPage()),
    );
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tema moduna göre arka plan (Light: krem, Dark: Surface/Antrasit uyumu)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Theme.of(context).colorScheme.surface : AppConstants.backgroundZen;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // İkon Bölümü
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _onboardingData[index]['icon'],
                            size: 100,
                            color: AppConstants.primaryAccent, // Orman Yeşili
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Başlık Bölümü
                        Text(
                          _onboardingData[index]['title'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Açıklama Bölümü
                        Text(
                          _onboardingData[index]['description'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Alt Navigasyon (SmoothPageIndicator ve Butonlar)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sol: "Geç" Butonu
                  _currentPage == _onboardingData.length - 1
                      ? const SizedBox(width: 60)
                      : TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(
                            "Geç",
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                  
                  // Orta: SmoothPageIndicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _onboardingData.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppConstants.primaryAccent,
                      dotColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),

                  // Sağ: "İleri" veya "Başla" Butonu
                  _currentPage == _onboardingData.length - 1
                      ? ElevatedButton(
                          onPressed: _completeOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text(
                            "Başla",
                            style: TextStyle(
                              color: AppConstants.backgroundZen,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _nextPage,
                          icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppConstants.primaryAccent),
                          label: const Text(
                            "İleri",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppConstants.primaryAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
