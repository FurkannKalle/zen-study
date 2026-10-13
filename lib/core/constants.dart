import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Soru Takip Zen';

  // Zen Theme Colors
  static const Color backgroundZen = Color(0xFFF9F6F0); // Warm Oat / Beige
  static const Color cardColor = Color(0xFFFFFFFF); // Off-white / Pure white for cards
  
  // Accents (Nature & Coffee Shop)
  static const Color primaryAccent = Color(0xFF2E5C40); // Forest Green
  static const Color secondaryAccent = Color(0xFF8A9A5B); // Sage Green
  
  // Feedback Colors (Swipe logic - Organic)
  static const Color easyColor = Color(0xFF5E8C61); // Leaf Green (Right swipe - Kolay)
  static const Color mediumColor = Color(0xFFC69C6D); // Earth / Mustard (Up swipe - Orta)
  static const Color hardColor = Color(0xFFD96C4A); // Terracotta (Left swipe - Zor)

  // Typography Base
  static const Color textPrimary = Color(0xFF1A3626); // Very Dark Forest Green
  static const Color textSecondary = Color(0xFF3E2723); // Dark Brown

  // Zen Layout Constants
  static const double borderRadiusLg = 24.0;
  static const double borderRadiusMd = 16.0;

  // Tüm Türkiye Sınav ve Ders Hiyerarşisi
  static const Map<String, List<String>> examSubjects = {
    'YKS': ['Türkçe', 'Matematik', 'Geometri', 'Fizik', 'Kimya', 'Biyoloji', 'Tarih', 'Coğrafya', 'Felsefe', 'Din Kültürü', 'Yabancı Dil'],
    'LGS': ['Türkçe', 'Matematik', 'Fen Bilimleri', 'İnkılap Tarihi', 'İngilizce', 'Din Kültürü'],
    'KPSS': ['Türkçe', 'Matematik', 'Tarih', 'Coğrafya', 'Vatandaşlık', 'Eğitim Bilimleri', 'ÖABT (Alan Bilgisi)'],
    'AGS': ['Sözel Yetenek', 'Sayısal Yetenek', 'Eğitim Bilimleri', 'Alan Eğitimi'],
    'ALES': ['Türkçe (Sözel)', 'Matematik (Sayısal)', 'Sözel Mantık', 'Sayısal Mantık'],
    'YDS': ['Kelime Bilgisi', 'Gramer', 'Cümle Tamamlama', 'Çeviri', 'Paragraf', 'Diyalog'],
    'TUS': ['Anatomi', 'Fizyoloji-Histoloji', 'Biyokimya', 'Mikrobiyoloji', 'Patoloji', 'Farmakoloji', 'Dahiliye', 'Pediatri', 'Cerrahi', 'Kadın Doğum', 'Küçük Stajlar'],
    'DUS': ['Temel Bilimler', 'Protetik Diş', 'Restoratif Diş', 'Ağız ve Çene Cerrahisi', 'Ortodonti', 'Endodonti', 'Periodontoloji', 'Pedodonti', 'Ağız ve Çene Radyolojisi'],
    'Diğer': ['Genel Yetenek', 'Genel Kültür', 'Yabancı Dil', 'Alan Bilgisi']
  };
  
  // Sınav Tahmini Tarihleri (2027)
  static final Map<String, DateTime?> examDates = {
    'YKS': DateTime(2027, 6, 19),
    'LGS': DateTime(2027, 6, 6),
    'KPSS': DateTime(2027, 7, 18),
    'AGS': DateTime(2027, 5, 15),
    'ALES': DateTime(2027, 4, 18),
    'YDS': DateTime(2027, 4, 10),
    'TUS': DateTime(2027, 3, 22),
    'DUS': DateTime(2027, 5, 20),
    'DGS': DateTime(2027, 6, 30),
    'Diğer': null,
  };

  // Günlük Stoacı/Zen Motivasyon Sözleri
  static const List<String> stoicQuotes = [
    '"Zamanın değerini bil; kontrol edemeyeceğin şeyleri bırak, sadece bugünkü çabana odaklan." - Epiktetos',
    '"Başarının sırrı, ne kadar zamanın kaldığında değil, şu anki zamanı nasıl kullandığındadır." - Marcus Aurelius',
    '"Telaş etmek hiçbir şeyi hızlandırmaz. Sakin ol ve sadece sıradaki adıma odaklan." - Zen Felsefesi',
    '"Bugün yapacağın küçük bir çalışma, yarınki büyük bir başarının temelidir." - Seneca',
    '"Unutma; bugün, dünün endişe ettiği yarındır. Odaklan ve anı yaşa." - Stoacı Metin',
    '"Bizi kortukan şeylerin büyük bir kısmı sadece kendi zihnimizdedir." - Seneca',
    '"Bir hedefe doğru ilerleyen karınca bile, sabit duran aslandan daha çok mesafe kat eder." - Doğu Atasözü',
    '"Dış dünyadaki gürültüyü kapat. En güçlü silahın sarsılmaz odaklanmandır." - Marcus Aurelius',
    '"Her gün kendine bir görev ver ve o küçük adımı inançla at." - Epiktetos',
    '"Zorluklardan kaçma, çünkü seni saf altın gibi işleyen şey onlardır." - Seneca',
  ];
}
