import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import '../../core/constants.dart';

class ImageEditPage extends StatefulWidget {
  final File imageFile;

  const ImageEditPage({super.key, required this.imageFile});

  @override
  State<ImageEditPage> createState() => _ImageEditPageState();
}

class _ImageEditPageState extends State<ImageEditPage> {
  final ImagePainterController _painterController = ImagePainterController();

  Future<void> _saveAndReturn() async {
    try {
      final Uint8List? imageBytes = await _painterController.exportImage();
      if (imageBytes != null) {
        final docDir = await getApplicationDocumentsDirectory();
        final tempFile = await File('${docDir.path}/painted_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await tempFile.writeAsBytes(imageBytes);
        if (mounted) Navigator.pop(context, tempFile.path);
      } else {
        if (mounted) Navigator.pop(context, widget.imageFile.path); 
      }
    } catch (e) {
      if (mounted) Navigator.pop(context, widget.imageFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundZen,
      appBar: AppBar(
        title: const Text('Düzenle ve Çiz'),
        backgroundColor: AppConstants.backgroundZen,
        foregroundColor: AppConstants.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppConstants.primaryAccent),
            onPressed: _saveAndReturn,
          ),
        ],
      ),
      body: ImagePainter.file(
        widget.imageFile,
        controller: _painterController,
        scalable: true,
        controlsAtTop: false,
        colors: const [
          Colors.black,
          Colors.white,
          Colors.red,
          Colors.blue,
          Colors.yellowAccent,
          AppConstants.primaryAccent,
        ],
      ),
    );
  }
}
