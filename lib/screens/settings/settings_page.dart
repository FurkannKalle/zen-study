import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/notification_service.dart';
import '../../core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/question_provider.dart';
import '../onboarding/exam_selection_page.dart';
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isNotificationEnabled = true;
  TimeOfDay? _notificationTime;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Default olarak bildirimleri açık kabul edelim, istenirse 'notifications_enabled' da tutulabilir
    final enabled = prefs.getBool('notifications_enabled') ?? true;
    final time = await NotificationService.instance.getNotificationTime();
    
    if (mounted) {
      setState(() {
        _isNotificationEnabled = enabled;
        _notificationTime = time;
      });
    }
  }

  Future<void> _toggleNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    
    setState(() {
      _isNotificationEnabled = value;
    });

    if (value) {
      // Bildirimleri aç
      NotificationService.instance.requestPermissions();
      final time = _notificationTime ?? const TimeOfDay(hour: 20, minute: 0);
      await NotificationService.instance.scheduleDailyNotification(time.hour, time.minute);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Bildirimler başarıyla aktifleştirildi ⏰')),
        );
      }
    } else {
      // Bildirimleri kapat
      NotificationService.instance.cancelAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Hatırlatıcı kapatıldı 🔕')),
        );
      }
    }
  }
  
  Future<void> _changeNotificationTime() async {
    final initialTime = _notificationTime ?? const TimeOfDay(hour: 20, minute: 0);
    
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryAccent,
              onPrimary: AppConstants.backgroundZen,
              onSurface: AppConstants.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.primaryAccent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (newTime != null && newTime != initialTime) {
      await NotificationService.instance.saveNotificationTime(newTime);
      setState(() {
        _notificationTime = newTime;
        _isNotificationEnabled = true; // Saati değiştirirse otomatik aç
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', true);

      await NotificationService.instance.scheduleDailyNotification(newTime.hour, newTime.minute);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hatırlatıcı saati ${newTime.format(context)} olarak ayarlandı',
              style: const TextStyle(color: AppConstants.primaryAccent, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppConstants.backgroundZen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppConstants.primaryAccent, width: 2),
            ),
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // App Logo veya Zen Icon
            Center(
              child: Icon(
                Icons.spa,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            // App Name
            Text(
              'Zen Study',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            // Version
            Text(
              'Sürüm 1.0.0',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),
            // Settings List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // --- Bildirim Ayarı ---
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary),
                          title: Text(
                            'Günlük Çalışma Hatırlatıcısı',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Her gün çalışman için sana bildirim göndeririz.'),
                              const SizedBox(height: 4),
                              Text(
                                'Not: Xiaomi, Huawei gibi cihazlarda bildirimlerin zamanında gelmesi için yerel ayarlardan pil kısıtlamalarını (Optimizasyonu) kapatmanız gerekebilir.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          trailing: Switch(
                            value: _isNotificationEnabled,
                            onChanged: (value) {
                              HapticFeedback.lightImpact();
                              _toggleNotification(value);
                            },
                            activeThumbColor: theme.colorScheme.primary,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        if (_isNotificationEnabled && _notificationTime != null) ...[
                          Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                          InkWell(
                            onTap: _changeNotificationTime,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.access_time_filled, size: 16, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Hatırlatıcı Saati: ${_notificationTime!.format(context)} (Değiştir)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // --- Hedef Sınav (Dinamik) ---
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: Icon(Icons.history_edu, color: theme.colorScheme.primary),
                      title: Text(
                        'Hedef Sınav',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        context.watch<QuestionProvider>().selectedExam != null 
                            ? 'Seçili: ${context.watch<QuestionProvider>().selectedExam}' 
                            : 'Hedef Seçilmedi',
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ExamSelectionPage()),
                        );
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // --- Gizlilik Politikası ---
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: Icon(Icons.privacy_tip_outlined, color: theme.colorScheme.primary),
                      title: Text(
                        'Gizlilik Politikası',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () => _launchUrl('https://incredible-houseboat-c4a.notion.site/Zen-Study-Privacy-Policy-3e5942423f778001b958ff9ff77f7254?pvs=143'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
