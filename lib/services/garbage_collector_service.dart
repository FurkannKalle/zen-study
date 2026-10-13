import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/question_model.dart';

class GarbageCollectorService {
  GarbageCollectorService._();

  /// Veritabanında (db) karşılığı olmayan hayalet/kimsesiz (orphaned) kalmış imajları disk üzerinden sessizce siler.
  /// Storage leak (Hafıza sızıntısı) sorunlarını kökten engeller.
  static Future<void> cleanOrphanedImages(List<Question> allQuestions) async {
    try {
      // 1. Mükemmel hız (O(1) karmaşıklığı) için kayıtlı olan tüm yolları bir Set'e at
      final Set<String> validImagePaths = allQuestions.map((q) => q.imagePath).toSet();

      // 2. Uygulamanın kayıt dizini (Resimlerin atıldığı yer)
      final Directory appDir = await getApplicationDocumentsDirectory();

      // 3. Dizindeki tüm dosyaları sessizce tara (Sadece fotoğraf uzantılarını)
      final List<FileSystemEntity> files = appDir.listSync();

      int deletedOrphans = 0;
      for (final FileSystemEntity entity in files) {
        if (entity is File) {
          final String path = entity.path;
          
          if (path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png')) {
            // Eğer resim veritabanındaki valid Set içerisinde YOKSA, o dosya çöp olmuştur
            if (!validImagePaths.contains(path)) {
              try {
                await entity.delete();
                deletedOrphans++;
              } catch (_) {
                // Silme başarısız olsa bile sistemi çökertme (Sessiz devam)
              }
            }
          }
        }
      }

      if (deletedOrphans > 0) {
        debugPrint("Garbage Collector: $deletedOrphans hayalet (orphaned) dosya diskten imha edildi.");
      }
    } catch (e) {
      debugPrint("Garbage Collector Motor Hatası (Zararsız): $e");
    }
  }
}
