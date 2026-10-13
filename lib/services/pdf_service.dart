import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../services/review_service.dart';
import '../models/question_model.dart';
import 'package:flutter/services.dart' show rootBundle;


import 'package:flutter/material.dart';

class PdfService {
  static Future<void> generateAndPrintExam(List<Question> selectedQuestions, {int questionsPerPage = 2, String? customTitle, bool leaveSpaceForSolution = false, BuildContext? context}) async {
    final dateString = DateFormat('dd.MM.yyyy - HH:mm').format(DateTime.now());
    final String examTitle = (customTitle != null && customTitle.trim().isNotEmpty) ? customTitle.trim() : 'Özel Deneme Sınavı';

    final rawQuestions = selectedQuestions.map((q) => {
      'subject': q.subject,
      'topic': q.topic,
      'category': q.category,
      'note': q.note,
      'imagePath': q.imagePath,
    }).toList();

    // Offline Fontları Kök üzerinden yükle 
    final ByteData regularFontData = await rootBundle.load('assets/fonts/Quicksand-Regular.ttf');
    final ByteData boldFontData = await rootBundle.load('assets/fonts/Quicksand-Bold.ttf');
    final Uint8List regularBytes = regularFontData.buffer.asUint8List();
    final Uint8List boldBytes = boldFontData.buffer.asUint8List();

    final Map<String, dynamic> isolateData = {
      'questions': rawQuestions,
      'questionsPerPage': questionsPerPage,
      'examTitle': examTitle,
      'leaveSpaceForSolution': leaveSpaceForSolution,
      'dateString': dateString,
      'fontRegularBytes': regularBytes,
      'fontBoldBytes': boldBytes,
    };

    // CPU Yoğun işlemi arka plana (Isolate) devret (Flutter 3.7+ Isolate.run)
    final Uint8List pdfBytes = await Isolate.run(() => _buildPdfIsolate(isolateData));

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Kendi_Denemem.pdf',
    );

    // Asenkron işlemlerden (Printing.sharePdf) sonra context hayatta mı (mounted) kontrol et
    if (context != null && !context.mounted) return;

    // Kendi denemesini başarıyla oluşturan kullanıcıya mağaza puanlaması sor
    ReviewService.instance.askForReview(context);
  }

  static Future<Uint8List> _buildPdfIsolate(Map<String, dynamic> data) async {
    final List<dynamic> questions = data['questions'];
    final int questionsPerPage = data['questionsPerPage'];
    final String examTitle = data['examTitle'];
    final bool leaveSpaceForSolution = data['leaveSpaceForSolution'];
    final String dateString = data['dateString'];
    final Uint8List fontRegularBytes = data['fontRegularBytes'];
    final Uint8List fontBoldBytes = data['fontBoldBytes'];

    // Platform Channels (Offline TTF)
    final fontRegular = pw.Font.ttf(fontRegularBytes.buffer.asByteData());
    final fontBold = pw.Font.ttf(fontBoldBytes.buffer.asByteData());

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
        fontFallback: [fontRegular],
      ),
    );

    List<List<dynamic>> chunks = [];
    for (var i = 0; i < questions.length; i += questionsPerPage) {
      int end = (i + questionsPerPage < questions.length) ? i + questionsPerPage : questions.length;
      chunks.add(questions.sublist(i, end));
    }
    
    int globalQuestionIndex = 0;

    for (int chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
      final chunk = chunks[chunkIndex];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
            fontFallback: [fontRegular],
          ),
          build: (pw.Context context) {
            pw.Widget header = pw.SizedBox();
            if (chunkIndex == 0) {
              header = pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        examTitle,
                        style: pw.TextStyle(font: fontBold, fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                      ),
                      pw.Text(
                        dateString,
                        style: pw.TextStyle(font: fontRegular, fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 2, color: PdfColors.teal900),
                  pw.SizedBox(height: 16),
                ],
              );
            }

            final footer = pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10.0),
              child: pw.Text(
                'Sayfa ${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(font: fontRegular, color: PdfColors.grey),
              ),
            );

            List<pw.Widget> builtQuestions = [];
            for (int i = 0; i < chunk.length; i++) {
              final question = chunk[i];
              final imageBytes = File(question['imagePath']).readAsBytesSync();
              final image = pw.MemoryImage(imageBytes);
              
              globalQuestionIndex++;
              
              final questionCard = pw.Container(
                margin: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Soru $globalQuestionIndex - ${question['subject']} > ${question['topic']}',
                      style: pw.TextStyle(font: fontBold, fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    if (question['category'] != null && question['category'].toString().trim().isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Kategori: ${question['category']}',
                        style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                    pw.SizedBox(height: 8),
                    if (leaveSpaceForSolution) ...[
                      pw.Expanded(
                        flex: 3,
                        child: pw.Center(
                          child: pw.Image(image, fit: pw.BoxFit.contain),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                            children: List.generate(5, (index) => pw.Divider(color: PdfColors.grey200, thickness: 0.5)),
                          ),
                        ),
                      ),
                    ] else ...[
                      pw.Expanded(
                        child: pw.Center(
                          child: pw.Image(image, fit: pw.BoxFit.contain),
                        ),
                      ),
                    ],
                  ],
                ),
              );
              builtQuestions.add(questionCard);
            }

            pw.Widget content = pw.SizedBox();
            if (questionsPerPage == 4 && chunk.length > 2) {
              pw.Widget topRow = pw.Expanded(
                child: pw.Row(
                  children: [
                    if (builtQuestions.isNotEmpty) pw.Expanded(child: builtQuestions[0]),
                    if (builtQuestions.length > 1) pw.Expanded(child: builtQuestions[1]) else pw.Expanded(child: pw.SizedBox()),
                  ]
                )
              );
              pw.Widget bottomRow = pw.Expanded(
                child: pw.Row(
                  children: [
                    if (builtQuestions.length > 2) pw.Expanded(child: builtQuestions[2]) else pw.Expanded(child: pw.SizedBox()),
                    if (builtQuestions.length > 3) pw.Expanded(child: builtQuestions[3]) else pw.Expanded(child: pw.SizedBox()),
                  ]
                )
              );
              content = pw.Expanded(
                 child: pw.Column(
                   children: [topRow, bottomRow]
                 )
              );
            } else {
              content = pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: builtQuestions.map((q) => pw.Expanded(child: q)).toList(),
                )
              );
            }

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                header,
                content,
                footer,
              ],
            );
          },
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          fontFallback: [fontRegular],
        ),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(
                '$examTitle - Cevap Anahtarı ve Notlar',
                style: pw.TextStyle(font: fontBold, fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
        build: (pw.Context context) {
          final List<pw.Widget> noteWidgets = [];
          
          for (int i = 0; i < questions.length; i++) {
            final question = questions[i];
            noteWidgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Soru ${i + 1}: ${question['subject']} - ${question['topic']}',
                    style: pw.TextStyle(font: fontBold, fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  if (question['category'] != null && question['category'].toString().trim().isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Kategori: ${question['category']}',
                      style: pw.TextStyle(font: fontRegular, fontSize: 12, color: PdfColors.grey700),
                    ),
                  ],
                  if (question['note'] != null && question['note'].toString().trim().isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Not: ${question['note']}',
                      style: pw.TextStyle(font: fontRegular, fontSize: 12, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                  pw.SizedBox(height: 15),
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 15),
                ],
              ),
            );
          }
          return noteWidgets;
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10.0),
            child: pw.Text(
              'Sayfa ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(font: fontRegular, color: PdfColors.grey),
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }
}
