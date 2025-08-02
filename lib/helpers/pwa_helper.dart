import 'package:flutter/foundation.dart';
// Imports condicionais para evitar erros
import 'dart:html' as html show window, Notification;
import 'dart:js' as js show context, allowInterop, JsObject;

class PwaHelper {
  // Verifica se está rodando como PWA
  static bool get isPwa {
    if (!kIsWeb) return false;

    try {
      return js.context['navigator']['standalone'] == true ||
          html.window.matchMedia('(display-mode: standalone)').matches;
    } catch (e) {
      return false;
    }
  }

  // Solicita permissão para notificações no web
  static Future<bool> requestNotificationPermission() async {
    if (!kIsWeb) return true;

    try {
      // Verifica se Notification API está disponível
      if (js.context['Notification'] == null) {
        print('Notification API não está disponível');
        return false;
      }

      // Verifica permissão atual
      final permission = js.context['Notification']['permission'];
      if (permission == 'granted') return true;
      if (permission == 'denied') return false;

      // Solicita permissão
      final result = await html.Notification.requestPermission();
      return result == 'granted';
    } catch (e) {
      print('Erro ao solicitar permissão: $e');
      return false;
    }
  }

  // Agenda notificação via Service Worker
  static void scheduleWebNotification(
    int hour,
    int minute,
    String title,
    String body,
  ) {
    if (!kIsWeb) return;

    try {
      // Verifica se service worker está disponível
      if (js.context['navigator']['serviceWorker'] == null) {
        print('Service Worker não disponível');
        return;
      }

      // Agenda via setTimeout (limitado mas funcional)
      _scheduleViaTimeout(hour, minute, title, body);

      // Tenta também via Service Worker se disponível
      final controller = js.context['navigator']['serviceWorker']['controller'];
      if (controller != null) {
        controller.callMethod('postMessage', [
          js.JsObject.jsify({
            'type': 'SCHEDULE_NOTIFICATION',
            'hour': hour,
            'minute': minute,
            'title': title,
            'body': body,
          }),
        ]);
      }
    } catch (e) {
      print('Erro ao agendar notificação web: $e');
      // Fallback para setTimeout
      _scheduleViaTimeout(hour, minute, title, body);
    }
  }

  // Agenda via setTimeout (funciona enquanto aba estiver aberta)
  static void _scheduleViaTimeout(
    int hour,
    int minute,
    String title,
    String body,
  ) {
    try {
      final now = DateTime.now();
      var scheduled = DateTime(now.year, now.month, now.day, hour, minute);

      // Se já passou hoje, agenda para amanhã
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final delay = scheduled.difference(now).inMilliseconds;

      // Agenda notificação
      js.context.callMethod('setTimeout', [
        js.allowInterop(() {
          showWebNotification(title, body);
        }),
        delay,
      ]);

      print('Notificação agendada para $hour:$minute (delay: ${delay}ms)');
    } catch (e) {
      print('Erro no setTimeout: $e');
    }
  }

  // Mostra notificação imediata no web
  static void showWebNotification(String title, String body) {
    if (!kIsWeb) return;

    try {
      // Verifica permissão primeiro
      if (js.context['Notification']['permission'] != 'granted') {
        print('Permissão de notificação não concedida');
        return;
      }

      // Cria notificação
      final notification = js.context['Notification'].callMethod('new', [
        title,
        js.JsObject.jsify({
          'body': body,
          'icon': '/favicon.png',
          'badge': '/favicon.png',
          'tag': 'lista-tarefas',
          'renotify': true,
          'requireInteraction': false,
        }),
      ]);

      // Auto-close após 5 segundos
      js.context.callMethod('setTimeout', [
        js.allowInterop(() {
          notification.callMethod('close');
        }),
        5000,
      ]);

      print('Notificação web mostrada: $title');
    } catch (e) {
      print('Erro ao mostrar notificação web: $e');
      // Fallback para alert
      _showFallbackNotification(title, body);
    }
  }

  // Fallback para quando Notification API não funciona
  static void _showFallbackNotification(String title, String body) {
    try {
      js.context.callMethod('alert', ['$title\n\n$body']);
    } catch (e) {
      print('Erro no fallback de notificação: $e');
    }
  }

  // Verifica se notificações são suportadas
  static bool get notificationsSupported {
    if (!kIsWeb) return true;

    try {
      return js.context['Notification'] != null;
    } catch (e) {
      return false;
    }
  }

  // Adiciona evento para instalar PWA
  static void showInstallPrompt() {
    if (!kIsWeb) return;

    // Este evento é capturado automaticamente pelos navegadores
    print('PWA pode ser instalado');
  }

  // Verifica status da permissão atual
  static String getPermissionStatus() {
    if (!kIsWeb) return 'granted';

    try {
      return js.context['Notification']['permission'] ?? 'default';
    } catch (e) {
      return 'unsupported';
    }
  }

  // Testa se consegue mostrar notificação agora
  static Future<bool> testNotification() async {
    if (!kIsWeb) return true;

    try {
      final hasPermission = await requestNotificationPermission();
      if (!hasPermission) return false;

      showWebNotification('Teste', 'Notificações estão funcionando!');
      return true;
    } catch (e) {
      print('Erro no teste de notificação: $e');
      return false;
    }
  }
}
