import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../providers/question_provider.dart';
import '../main_layout.dart';

class ExamSelectionPage extends StatelessWidget {
  const ExamSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final exams = AppConstants.examSubjects.keys.toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Icon(Icons.school_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                "Hangi sınava\nhazırlanıyorsun?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Sana uygun ders programını ve kütüphaneyi oluşturabilmemiz için hedefini seç.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.0,
                  ),
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    return InkWell(
                      onTap: () async {
                        await context.read<QuestionProvider>().saveUserExam(exam);
                        if (context.mounted) {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context); // Zaten uygulamanın içinden çağrıldıysa sadece kapat
                          } else {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('isFirstTime', false);
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const MainLayout()),
                              );
                            }
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                          border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          exam,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
