import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'models/item.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Tarefas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        appBarTheme: AppBarTheme(color: Colors.blue),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var newTaskCtrl = TextEditingController();
  List<Item> items = [];
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      tz.initializeTimeZones();
      _initializeNotifications();
    } else {
      _initializePWANotifications();
    }
    load();
  }

  // Inicialização para PWA
  void _initializePWANotifications() async {
    if (kIsWeb) {
      // Solicitar permissão para notificações
      String permission = await html.Notification.requestPermission();
      print('Permissão de notificação: $permission');
    }
  }

  // Inicialização para Android/iOS (existente)
  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('Notificação tocada: ${response.payload}');
      },
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // Agendamento para PWA - VERSÃO SIMPLIFICADA SEM SERVICE WORKER
  Future<void> _schedulePWANotification(TimeOfDay time) async {
    print('=== FUNÇÃO _schedulePWANotification CHAMADA ===');
    
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final delay = scheduledDate.difference(now).inMilliseconds;
    final uncompletedCount = items.where((item) => !item.done).length;

    print('DEBUG: Delay calculado: $delay ms');
    print('DEBUG: Tarefas não concluídas: $uncompletedCount');
    print('DEBUG: Agendado para: $scheduledDate');

    // Usar Timer simples - funciona bem para sessões ativas
    Timer(Duration(milliseconds: delay), () {
      print('EXECUTANDO NOTIFICAÇÃO TIMER');
      if (html.Notification.permission == 'granted') {
        var notification = html.Notification(
          'Tarefas Pendentes',
          body: 'Você tem $uncompletedCount tarefas não concluídas para verificar!',
          icon: '/icons/Icon-192.png',
          tag: 'tarefas-reminder',
        );
        
        // Auto-fechar após 10 segundos
        Timer(const Duration(seconds: 10), () {
          notification.close();
        });
        
        print('Notificação exibida via Timer');
      } else {
        print('Permissão de notificação não concedida');
      }
    });
    
    print('Timer agendado para ${Duration(milliseconds: delay)}');
  }

  // Agendamento para Android/iOS (existente)
  Future<void> _scheduleNotification(TimeOfDay time) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'tarefas_channel',
          'Lembretes de Tarefas',
          channelDescription: 'Notificações para lembrar das tarefas pendentes',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
          playSound: true,
          enableVibration: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Tarefas Pendentes',
      'Você tem ${items.where((item) => !item.done).length} tarefas não concluídas para verificar!',
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'tarefas_pendentes',
    );
  }

  // Função unificada para agendamento - CORRIGIR ESTA FUNÇÃO
  Future<void> _scheduleNotificationPlatform(TimeOfDay time) async {
    print('=== _scheduleNotificationPlatform CHAMADA ===');
    print('kIsWeb: $kIsWeb');
    
    if (kIsWeb) {
      print('Chamando _schedulePWANotification...');
      await _schedulePWANotification(time);
    } else {
      print('Chamando _scheduleNotification...');
      await _scheduleNotification(time);
    }
    print('_scheduleNotificationPlatform FINALIZADA');
  }

  void add() {
    if (newTaskCtrl.text.isEmpty) {
      return;
    }

    setState(() {
      items.add(Item(title: newTaskCtrl.text, done: false));
      newTaskCtrl.clear();
    });
    save();
  }

  void remove(int index) {
    setState(() {
      items.removeAt(index);
    });
    save();
  }

  Future load() async {
    try {
      var prefs = await SharedPreferences.getInstance();
      var data = prefs.getString('data');

      if (data != null) {
        Iterable decoded = json.decode(data);
        List<Item> result = decoded.map((x) => Item.fromJson(x)).toList();
        setState(() {
          items = result;
        });
      }
    } catch (e) {
      print('Erro ao carregar: $e');
    }
  }

  save() async {
    try {
      var prefs = await SharedPreferences.getInstance();
      await prefs.setString('data', jsonEncode(items));
    } catch (e) {
      print('Erro ao salvar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          controller: newTaskCtrl,
          keyboardType: TextInputType.text,
          style: TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            labelText: "Nova Tarefa",
            labelStyle: TextStyle(color: Colors.white),
            border: InputBorder.none,
            hintText: "Digite uma nova tarefa",
            hintStyle: TextStyle(color: Colors.white70),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Dismissible(
            key: Key(item.title),
            background: Container(
              color: Colors.red.withOpacity(0.2),
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: Colors.red, size: 30),
            ),
            onDismissed: (direction) {
              remove(index);
            },
            child: CheckboxListTile(
              title: Text(
                item.title,
                style: TextStyle(
                  decoration: item.done ? TextDecoration.lineThrough : null,
                ),
              ),
              value: item.done,
              onChanged: (value) {
                setState(() {
                  item.done = value ?? false;
                });
                save();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: add,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 60,
        color: Colors.blue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () async {
                TimeOfDay? selectedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  helpText: 'Selecione um horário para ser lembrado das tarefas',
                  builder: (BuildContext context, Widget? child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    );
                  },
                );

                if (selectedTime != null) {
                  String formattedTime =
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                  print('Hora selecionada: $formattedTime');

                  bool hasUncompletedTasks = items.any((item) => !item.done);
                  print('Tem tarefas não concluídas: $hasUncompletedTasks');
                  print('Total de tarefas: ${items.length}');

                  if (hasUncompletedTasks) {
                    print('CHAMANDO _scheduleNotificationPlatform...');
                    // Usar função unificada
                    await _scheduleNotificationPlatform(selectedTime);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Notificação agendada para $formattedTime'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    print('Todas as tarefas estão concluídas - não agendando notificação');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Todas as tarefas estão concluídas!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                }
              },
              icon: Icon(Icons.access_time),
              iconSize: 30,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
