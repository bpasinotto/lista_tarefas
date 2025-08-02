import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../helpers/pwa_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Inicializa o serviço de notificações
  static Future<void> init() async {
    if (_initialized) return;

    // Inicializa timezone
    tz.initializeTimeZones();

    // Configurações para Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Configurações para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configurações para Windows
    // const windowsSettings = null; // Suporte limitado no flutter_local_notifications

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  // Callback quando notificação é tocada
  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    print('Notificação tocada: ${notificationResponse.payload}');
    // Aqui você pode navegar para uma tela específica se necessário
  }

  // Solicita permissões necessárias
  static Future<bool> requestPermissions() async {
    if (kIsWeb) {
      // Para PWA/Web, use a Notification API
      return await _requestWebPermissions();
    }

    if (Platform.isAndroid) {
      // Android 13+ requer permissão específica para notificações
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        return status == PermissionStatus.granted;
      }
      return true;
    }

    if (Platform.isIOS) {
      final status = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return status ?? false;
    }

    return true; // Windows e outras plataformas
  }

  // Solicita permissões para Web/PWA
  static Future<bool> _requestWebPermissions() async {
    if (!PwaHelper.notificationsSupported) {
      print('Notificações não suportadas neste navegador');
      return false;
    }

    return await PwaHelper.requestNotificationPermission();
  }

  // Agenda notificação diária
  static Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await init();

    if (kIsWeb) {
      await _scheduleWebNotification(hour, minute, title, body);
      return;
    }

    const notificationId = 0;

    // Configurações específicas para Android
    const androidDetails = AndroidNotificationDetails(
      'daily_tasks_channel',
      'Lembretes Diários',
      channelDescription: 'Notificações diárias para lembrar das tarefas',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    // Configurações específicas para iOS
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Calcula o próximo horário de notificação
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Se o horário já passou hoje, agenda para amanhã
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repete diariamente
    );

    // Salva configuração
    await _saveNotificationSettings(hour, minute, true);
  }

  // Agenda notificação para Web/PWA
  static Future<void> _scheduleWebNotification(
    int hour,
    int minute,
    String title,
    String body,
  ) async {
    // Para PWA, salva as configurações e usa o service worker
    await _saveNotificationSettings(hour, minute, true);

    // Usa o helper PWA para agendar via Service Worker
    PwaHelper.scheduleWebNotification(hour, minute, title, body);

    print('Notificação PWA configurada para $hour:$minute');
  }

  // Cancela notificações diárias
  static Future<void> cancelDailyNotification() async {
    await init();

    if (kIsWeb) {
      await _saveNotificationSettings(0, 0, false);
      return;
    }

    await _notifications.cancel(0);
    await _saveNotificationSettings(0, 0, false);
  }

  // Salva configurações de notificação
  static Future<void> _saveNotificationSettings(
    int hour,
    int minute,
    bool enabled,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_hour', hour);
    await prefs.setInt('notification_minute', minute);
    await prefs.setBool('notifications_enabled', enabled);
  }

  // Carrega configurações de notificação
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'hour': prefs.getInt('notification_hour') ?? 8,
      'minute': prefs.getInt('notification_minute') ?? 0,
      'enabled': prefs.getBool('notifications_enabled') ?? false,
    };
  }

  // Verifica se há tarefas pendentes
  static Future<int> getPendingTasksCount() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('data');

    if (data != null) {
      try {
        final List<dynamic> decoded = json.decode(data);
        return decoded.where((item) => item['done'] == false).length;
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  // Mostra notificação imediata (para teste)
  static Future<void> showTestNotification() async {
    await init();

    if (kIsWeb) {
      final success = await PwaHelper.testNotification();
      if (!success) {
        print('Falha no teste de notificação web');
      }
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Teste',
      channelDescription: 'Canal para testes de notificação',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      'Teste de Notificação',
      'Suas notificações estão funcionando!',
      notificationDetails,
    );
  }
}
