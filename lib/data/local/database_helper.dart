import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/question_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('questions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imagePath TEXT NOT NULL,
        subject TEXT NOT NULL,
        topic TEXT NOT NULL,
        exam TEXT NOT NULL,
        note TEXT,
        category TEXT,
        nextReviewDate TEXT NOT NULL,
        isLearned INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        interval INTEGER NOT NULL,
        easeFactor REAL NOT NULL,
        reviewCount INTEGER NOT NULL
      )
    ''');

    // Performans için indekslemeler (Binlerce kayıtta anlık arama / filtreleme)
    await db.execute('CREATE INDEX IF NOT EXISTS idx_exam ON questions (exam)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_category ON questions (category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_created_at ON questions (createdAt)');
    // Günü gelen sorular (dueQuestions) için compound (bileşik) indeks
    await db.execute('CREATE INDEX IF NOT EXISTS idx_due_questions ON questions (nextReviewDate, isLearned)');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE questions ADD COLUMN exam TEXT DEFAULT 'Genel'");
      } catch (e) {
        // Kolon zaten eklenmişse hata yoksayılır
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute("ALTER TABLE questions ADD COLUMN note TEXT");
      } catch (e) {
        // Kolon zaten eklenmişse hata yoksayılır
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE questions ADD COLUMN category TEXT");
      } catch (e) {
        // Kolon zaten eklenmişse hata yoksayılır
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute("ALTER TABLE questions ADD COLUMN createdAt TEXT");
      } catch (e) {
        // Kolon zaten eklenmişse hata yoksayılır
      }
    }
    if (oldVersion < 6) {
      try {
        // Eski kullanıcılardan veri kaybetmemek için toplu indeks göçü (Batch Migration)
        final batch = db.batch();
        batch.execute('CREATE INDEX IF NOT EXISTS idx_exam ON questions (exam)');
        batch.execute('CREATE INDEX IF NOT EXISTS idx_category ON questions (category)');
        batch.execute('CREATE INDEX IF NOT EXISTS idx_created_at ON questions (createdAt)');
        batch.execute('CREATE INDEX IF NOT EXISTS idx_due_questions ON questions (nextReviewDate, isLearned)');
        await batch.commit();
      } catch (e) {
        // İndeksler oluşturulamazsa tablo silinmesin diye fail-safe
      }
    }
    if (oldVersion < 7) {
      try {
        // Göreli (Relative) Dosya Yolu göçü: Absolute path'leri sadece dosya ismine daraltma
        final batch = db.batch();
        final List<Map<String, dynamic>> questions = await db.query('questions');
        for (var q in questions) {
          String imagePath = q['imagePath'] as String;
          if (imagePath.contains('/') || imagePath.contains('\\')) {
            // Sadece dosya ismini alma algoritması (Örn. my_image.jpg)
            String newPath = imagePath.split('/').last.split('\\').last;
            batch.update(
              'questions',
              {'imagePath': newPath},
              where: 'id = ?',
              whereArgs: [q['id']],
            );
          }
        }
        await batch.commit(noResult: true);
      } catch (e) {
        // fail-safe
      }
    }
  }

  Future<int> insertQuestion(Question question) async {
    final db = await instance.database;
    return await db.insert('questions', question.toMap());
  }
  
  Future<List<Question>> getDueQuestions() async {
    final db = await instance.database;
    final String nowStr = DateTime.now().toIso8601String();
    
    final maps = await db.query(
      'questions',
      where: 'nextReviewDate <= ? AND isLearned = ?',
      whereArgs: [nowStr, 0],
      orderBy: 'nextReviewDate ASC',
    );

    if (maps.isNotEmpty) {
      return maps.map((map) => Question.fromMap(map)).toList();
    } else {
      return [];
    }
  }

  Future<List<Question>> getAllQuestions() async {
    final db = await instance.database;
    // En son eklenen soru en üstte çıksın diye createdAt DESC yaptık
    final maps = await db.query(
      'questions',
      orderBy: 'createdAt DESC',
    );

    if (maps.isNotEmpty) {
      return maps.map((map) => Question.fromMap(map)).toList();
    } else {
      return [];
    }
  }

  Future<int> updateQuestion(Question question) async {
    final db = await instance.database;
    return await db.update(
      'questions',
      question.toMap(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }
  
  Future<int> deleteQuestion(int id) async {
    final db = await instance.database;
    return await db.delete(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- TOPLU (BATCH) I/O İŞLEMLERİ (Performans İyileştirmesi) ---

  Future<void> deleteQuestionsBatch(List<int> ids) async {
    final db = await instance.database;
    try {
      final batch = db.batch();
      for (final id in ids) {
        batch.delete(
          'questions',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      await batch.commit(noResult: true); // noResult: true, dönüş ID'lerini umursamadığı için hızı 10x artırır
    } catch (e) {
      // Hata durumunda batch işlemi çöpe gider
    }
  }

  Future<void> updateQuestionsBatch(List<Question> questions) async {
    final db = await instance.database;
    try {
      final batch = db.batch();
      for (final q in questions) {
        batch.update(
          'questions',
          q.toMap(),
          where: 'id = ?',
          whereArgs: [q.id],
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      // Sessiz başarısızlık
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
