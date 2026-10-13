import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/question_model.dart';

class PdfReorderPage extends StatefulWidget {
  final List<Question> selectedQuestions;

  const PdfReorderPage({super.key, required this.selectedQuestions});

  @override
  State<PdfReorderPage> createState() => _PdfReorderPageState();
}

class _PdfReorderPageState extends State<PdfReorderPage> {
  late List<Question> _currentList;

  @override
  void initState() {
    super.initState();
    _currentList = List.from(widget.selectedQuestions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sıralamayı Ayarla', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.drag_indicator, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Soruları basılı tutup sürükleyerek sınavdaki sıralamalarını değiştirebilirsiniz.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 100), // FAB'in altına girmemesi için alt boşluk
        itemCount: _currentList.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = _currentList.removeAt(oldIndex);
            _currentList.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final question = _currentList[index];
          return Card(
            key: ValueKey(question.id ?? question.imagePath),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(question.imagePath),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  cacheWidth: 150, // Maksimum RAM verimliliği
                ),
              ),
              title: Text(question.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(question.topic),
              trailing: Icon(Icons.drag_handle, color: Theme.of(context).colorScheme.primary),
            ),
          );
        },
      ),
    ),
    ],
    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, _currentList),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Devam Et', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
