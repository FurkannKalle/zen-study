import 'dart:io';
import 'dart:isolate';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class CompressService {
  CompressService._();

  /// Sıkıştırma işlemi yapar ve sıkıştırılmış dosyanın kendisini (File) döner.
  /// İşlem bitince RAM ve depolama dolmaması için dönümlük (geçici) orjinal dosyayı silmezsek de,
  /// geçici klasöre kaydedeceğimiz için sorun olmaz. Lakin biz bu servisi
  /// AddQuestionPage'de kalıcı dizine kaydetmeden önce araya sokacağız.
  static Future<File?> compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      
      // Geçici dosya adı
      final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80, // Okunabilirliği düşürmeden %80 kalite
        format: CompressFormat.jpeg,
      );
      
      if (result != null) {
        return File(result.path);
      }
      return null;
    } catch (e) {
      print("Görsel sıkıştırma hatası: $e");
      return null; // Hata olursa null dön, sistemi çökertme
    }
  }

  /// Disk G/Ç (I/O) işlemlerinin Main Thread'i (Arayüzü) dondurmaması için kopyalama ve temizlik
  /// adımları tamamen arka plandaki bir Isolate aracılığıyla gerçekleşir.
  static Future<String> saveAndCleanImage(String sourcePath, String targetPath, String? compressPath) async {
    return await Isolate.run(() async {
      final fileToSave = File(sourcePath);
      
      // I/O yoğun kopyalama
      final savedImage = await fileToSave.copy(targetPath);
      
      // I/O yoğun temizlik (temp dosyalar)
      if (compressPath != null) {
        final cFile = File(compressPath);
        if (cFile.existsSync()) cFile.deleteSync();
      }
      // Orijinal geçici resmi de sil (zaten kopyalandı)
      final tempOrig = File(sourcePath);
      if (tempOrig.existsSync()) tempOrig.deleteSync();
      
      return savedImage.path;
    });
  }
}
