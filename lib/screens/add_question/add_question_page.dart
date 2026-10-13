import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image_cropper/image_cropper.dart';
import 'image_edit_page.dart';
import '../../providers/question_provider.dart';
import '../../core/constants.dart';
import '../../services/compress_service.dart';

class AddQuestionPage extends StatefulWidget {
  const AddQuestionPage({super.key});

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  
  String? _selectedSubject;
  String _topic = '';
  String? _category;
  String? _note;

  // Türkçe "i/ı" harflerinde boş eşleşmeyi önleyen kalkan
  String normalizeTurkish(String text) {
    return text
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase();
  }

  void _onSelectImageSource(ImageSource source) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context); 
    }
    _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (pickedFile == null) return;

      if (!mounted) return;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Soruyu Kırp',
              toolbarColor: const Color(0xFF1A3626),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(title: 'Soruyu Kırp'),
        ],
      );

      if (croppedFile == null) return;

      if (mounted) {
        setState(() {
          _selectedImage = File(croppedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem hatası: $e')),
        );
      }
    }
  }

  Future<void> _openPainter() async {
    if (_selectedImage == null) return;

    try {
      final String? editedImagePath = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditPage(imageFile: _selectedImage!),
        ),
      );

      if (editedImagePath != null && mounted) {
        setState(() {
          _selectedImage = File(editedImagePath);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çizim sayfası açılamadı: $e')),
        );
      }
    }
  }

  Future<void> _saveQuestion() async {
    if (_selectedImage == null || _selectedSubject == null || _topic.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }

    try {
      // 1. Önce sıkıştırma yap
      File? compressedFile = await CompressService.compressImage(_selectedImage!);
      File fileToSave = compressedFile ?? _selectedImage!;

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String targetPath = p.join(appDir.path, fileName);
      
      // I/O işlemlerini Isolate ile arka planda çalıştır! UI donması engellendi.
      final String finalImagePath = await CompressService.saveAndCleanImage(
        fileToSave.path, 
        targetPath, 
        compressedFile?.path,
      );

      await context.read<QuestionProvider>().addQuestion(
        imagePath: finalImagePath,
        subject: _selectedSubject!,
        topic: _topic.trim(), // Sadece boşluklardan oluşan konu isimlerini temizledik
        note: _note?.trim().isNotEmpty == true ? _note?.trim() : null,

        category: _category?.trim().isNotEmpty == true ? _category?.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Soru başarıyla kaydedildi 🌿', style: TextStyle(color: AppConstants.backgroundZen, fontWeight: FontWeight.bold)),
            backgroundColor: AppConstants.primaryAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zihnine Not Düş')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
                            title: Text('Kamerayla Çek', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                            onTap: () => _onSelectImageSource(ImageSource.camera),
                          ),
                          ListTile(
                            leading: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.secondary),
                            title: Text('Galeriden Seç', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                            onTap: () => _onSelectImageSource(ImageSource.gallery),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04), // soft shadow
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.file(
                              _selectedImage!, 
                              fit: BoxFit.cover,
                              cacheWidth: 400,
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: InkWell(
                              onTap: _openPainter,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A3626).withValues(alpha: 0.85), // Yarı saydam Orman Yeşili
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.brush, color: Theme.of(context).colorScheme.onPrimary, size: 24),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 64, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(height: 16),
                          Text('Soru Fotoğrafı Eklemek İçin Dokunun', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
            Builder(
              builder: (context) {
                final currentSubjects = context.read<QuestionProvider>().currentSubjects;
                // Daha önceki bir seçim yeni listede kalmamışsa Dropdown hata fırlatır, kontrol edelim.
                if (_selectedSubject != null && !currentSubjects.contains(_selectedSubject)) {
                  _selectedSubject = null;
                }
                
                return DropdownButtonFormField<String>(
                  dropdownColor: Theme.of(context).cardColor,
                  decoration: const InputDecoration(labelText: 'Ders'),
                  initialValue: _selectedSubject,
                  items: currentSubjects.map((subject) {
                    return DropdownMenuItem(value: subject, child: Text(subject, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedSubject = value),
                );
              },
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty || _selectedSubject == null) {
                  return const Iterable<String>.empty();
                }
                final uniqueTopics = context.read<QuestionProvider>().getUniqueTopicsForSubject(_selectedSubject!);
                return uniqueTopics.where((String option) {
                  return normalizeTurkish(option).contains(normalizeTurkish(textEditingValue.text));
                });
              },
              onSelected: (String selection) {
                _topic = selection;
              },
              fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  maxLength: 50, // Kullanıcının UI'ı patlatmasını engellemek için sınır
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Konu',
                    hintText: 'Örn: Asal Sayılar',
                  ),
                  onChanged: (value) => _topic = value, // Kendisi manuel de girebilir
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).cardColor,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200, 
                        maxWidth: MediaQuery.of(context).size.width - 48, // Ekran genişliği paddinglerden kurtulmuş şekilde
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () {
                              onSelected(option);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                option,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              maxLines: 3,
              minLines: 1,
              maxLength: 300,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Not (İsteğe Bağlı)',
                hintText: 'Bu soruyla ilgili hatırlamak istediklerin veya kaçırdığın detaylar...',
                prefixIcon: Icon(Icons.edit_note, color: Theme.of(context).colorScheme.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
              ),
              onChanged: (value) => _note = value,
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                final uniqueCategories = context.read<QuestionProvider>().uniqueCategories;
                return uniqueCategories.where((String option) {
                  return normalizeTurkish(option).contains(normalizeTurkish(textEditingValue.text));
                });
              },
              onSelected: (String selection) {
                _category = selection;
              },
              fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  maxLength: 30,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Kategori / Etiket (İsteğe Bağlı)',
                    hintText: 'Örn: Deneme 1, Çıkmış Sorular',
                    prefixIcon: Icon(Icons.label_outline, color: Theme.of(context).colorScheme.secondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  onChanged: (value) => _category = value, 
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).cardColor,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 48),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(option, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _saveQuestion,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              child: const Text('Ajandaya Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
