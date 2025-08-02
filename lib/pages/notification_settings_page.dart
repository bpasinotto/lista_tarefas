import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../helpers/pwa_helper.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _notificationsEnabled = false;
  int _selectedHour = 8;
  int _selectedMinute = 0;
  bool _loading = true;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissions();
  }

  Future<void> _loadSettings() async {
    final settings = await NotificationService.getNotificationSettings();
    setState(() {
      _notificationsEnabled = settings['enabled'];
      _selectedHour = settings['hour'];
      _selectedMinute = settings['minute'];
      _loading = false;
    });
  }

  Future<void> _checkPermissions() async {
    if (kIsWeb) {
      // Para web, verifica de forma mais detalhada
      final supported = PwaHelper.notificationsSupported;
      if (!supported) {
        _permissionGranted = false;
      } else {
        _permissionGranted = await NotificationService.requestPermissions();
      }
    } else {
      _permissionGranted = await NotificationService.requestPermissions();
    }
    setState(() {});
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (enabled && !_permissionGranted) {
      _permissionGranted = await NotificationService.requestPermissions();
      if (!_permissionGranted) {
        _showPermissionDialog();
        return;
      }
    }

    setState(() {
      _notificationsEnabled = enabled;
    });

    if (enabled) {
      await _scheduleNotification();
    } else {
      await NotificationService.cancelDailyNotification();
    }
  }

  Future<void> _scheduleNotification() async {
    final pendingTasks = await NotificationService.getPendingTasksCount();
    final message = pendingTasks > 0
        ? 'Você tem $pendingTasks tarefa(s) pendente(s) para hoje!'
        : 'Bom dia! Não esqueça de verificar suas tarefas.';

    await NotificationService.scheduleDailyNotification(
      hour: _selectedHour,
      minute: _selectedMinute,
      title: 'Lembrete das Tarefas',
      body: message,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notificação agendada para ${_formatTime(_selectedHour, _selectedMinute)}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissão Necessária'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Para receber notificações, você precisa conceder permissão.'),
            const SizedBox(height: 16),
            if (kIsWeb)
              const Text(
                'No navegador:\n'
                '• Clique no ícone de cadeado na barra de endereço\n'
                '• Permita notificações para este site',
                style: TextStyle(fontSize: 12),
              )
            else
              const Text(
                'Vá para Configurações > Apps > Lista de Tarefas > Notificações '
                'e ative as permissões.',
                style: TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: Colors.black,
              dayPeriodTextColor: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedHour = picked.hour;
        _selectedMinute = picked.minute;
      });

      if (_notificationsEnabled) {
        await _scheduleNotification();
      }
    }
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<void> _testNotification() async {
    await NotificationService.showTestNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificação de teste enviada!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildPlatformInfo() {
    String platform;
    String limitations;
    String permissionStatus = '';

    if (kIsWeb) {
      platform = 'PWA/Web';
      if (!PwaHelper.notificationsSupported) {
        permissionStatus = ' (Não suportado neste navegador)';
        limitations = '• Notification API não está disponível\n'
            '• Tente um navegador mais recente\n'
            '• Chrome, Firefox, Edge são recomendados';
      } else {
        final status = PwaHelper.getPermissionStatus();
        permissionStatus = ' (Status: $status)';
        limitations = '• Funciona apenas com navegador aberto\n'
            '• Limitações no iOS Safari\n'
            '• Requer permissão do usuário\n'
            '• Use "Adicionar à tela inicial" para melhor experiência';
      }
    } else {
      platform = Theme.of(context).platform.name;
      switch (Theme.of(context).platform) {
        case TargetPlatform.android:
          limitations = '• Funciona em segundo plano\n'
              '• Pode ser limitado por otimizações de bateria\n'
              '• Android 13+ requer permissão explícita';
          break;
        case TargetPlatform.iOS:
          limitations = '• Funciona em segundo plano\n'
              '• Limitado a 64 notificações agendadas\n'
              '• Usuário pode desabilitar nas configurações';
          break;
        default:
          limitations = '• Suporte limitado\n'
              '• Pode não funcionar em segundo plano';
      }
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plataforma: $platform$permissionStatus',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Limitações:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(limitations, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configurações'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status das permissões
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _permissionGranted ? Colors.green.shade50 : Colors.red.shade50,
              child: Row(
                children: [
                  Icon(
                    _permissionGranted ? Icons.check_circle : Icons.error,
                    color: _permissionGranted ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _permissionGranted 
                        ? 'Permissões concedidas' 
                        : 'Permissões necessárias',
                    style: TextStyle(
                      color: _permissionGranted ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Configurações principais
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Toggle principal
                  SwitchListTile(
                    title: const Text('Ativar Notificações Diárias'),
                    subtitle: const Text('Receba lembretes das suas tarefas'),
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    activeColor: Colors.blue,
                  ),

                  const Divider(),

                  // Seleção de horário
                  ListTile(
                    title: const Text('Horário do Lembrete'),
                    subtitle: Text('Notificação às ${_formatTime(_selectedHour, _selectedMinute)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: _notificationsEnabled ? _showTimePicker : null,
                    enabled: _notificationsEnabled,
                  ),

                  const Divider(),

                  // Botão de teste
                  ListTile(
                    title: const Text('Testar Notificação'),
                    subtitle: const Text('Enviar uma notificação de teste agora'),
                    trailing: const Icon(Icons.send),
                    onTap: _permissionGranted ? _testNotification : null,
                    enabled: _permissionGranted,
                  ),

                  const SizedBox(height: 20),

                  // Instruções específicas da plataforma
                  if (!_permissionGranted)
                    ElevatedButton(
                      onPressed: _checkPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Verificar Permissões'),
                    ),
                ],
              ),
            ),

            // Informações da plataforma
            _buildPlatformInfo(),
          ],
        ),
      ),
    );
  }
}
