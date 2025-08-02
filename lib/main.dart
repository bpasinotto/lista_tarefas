import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/item.dart';
import 'services/notification_service.dart';
import 'pages/notification_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o serviço de notificações
  await NotificationService.init();

  runApp(App());
}

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
  var focusNode = FocusNode(); // Adicionar FocusNode
  List<Item> items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    focusNode.dispose(); // Limpar o FocusNode
    super.dispose();
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

    // Voltar o foco para o campo de entrada
    focusNode.requestFocus();
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
          focusNode: focusNode, // Adicionar o focusNode
          keyboardType: TextInputType.text,
          style: TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            labelText: "Nova Tarefa",
            labelStyle: TextStyle(color: Colors.white),
            border: InputBorder.none,
            hintText: "Digite uma nova tarefa",
            hintStyle: TextStyle(color: Colors.white70),
          ),
          onFieldSubmitted: (value) {
            add();
          },
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          // Ícone de notificações
          IconButton(
            icon: const Icon(Icons.schedule, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsPage(),
                ),
              );
            },
            tooltip: 'Configurar Notificações',
          ),
        ],
      ),
      body: Container(
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Dismissible(
              key: Key(item.title),
              background: Container(
                color: Colors.red.withOpacity(0.2),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: 20.0),
                child: Icon(Icons.delete, color: Colors.red, size: 30.0),
              ),
              secondaryBackground: Container(
                color: Colors.red.withOpacity(0.2),
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20.0),
                child: Icon(Icons.delete, color: Colors.red, size: 30.0),
              ),
              onDismissed: (direction) {
                remove(index);
              },
              child: CheckboxListTile(
                title: Text(
                  item.title,
                  style: TextStyle(
                    decoration: item.done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: item.done ? Colors.grey : Colors.black,
                  ),
                ),
                value: item.done,
                onChanged: (value) {
                  setState(() {
                    item.done = value!;
                  });
                  save();
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: add,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
