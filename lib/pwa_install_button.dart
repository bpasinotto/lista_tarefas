import 'dart:async';
import 'dart:html' as html; // Importante: Usado para interagir com o DOM da web
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:js/js_util.dart' as js_util;

class PwaInstallButton extends StatefulWidget {
  const PwaInstallButton({super.key});

  @override
  State<PwaInstallButton> createState() => _PwaInstallButtonState();
}

class _PwaInstallButtonState extends State<PwaInstallButton> {
  bool _showInstallButton = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();

    // Este código só roda se estiver na web
    if (kIsWeb) {
      // 1. Injeta o script que escuta o evento de instalação
      _injectJsScript();

      // 2. Inicia um timer para verificar se o evento foi capturado
      _checkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // A função `hasProperty` verifica se uma variável existe no escopo global `window` do JS
        if (js_util.hasProperty(html.window, 'deferredPrompt')) {
          if (mounted) {
            setState(() {
              _showInstallButton = true;
            });
          }
          // Para o timer assim que encontrar o prompt, para não gastar recursos
          timer.cancel();
          debugPrint("PWA é instalável. Botão será exibido.");
        }
      });
    }
  }

  @override
  void dispose() {
    // Cancela o timer se o widget for destruído
    _checkTimer?.cancel();
    super.dispose();
  }

  void _injectJsScript() {
    const script = '''
      let deferredPrompt;
      window.addEventListener('beforeinstallprompt', (e) => {
        e.preventDefault();
        deferredPrompt = e;
        // Expõe o evento para o Dart poder encontrá-lo
        window.deferredPrompt = deferredPrompt;
      });

      window.addEventListener('appinstalled', () => {
        // Esconde o botão se o app for instalado
        // (O widget do Flutter precisa ser reconstruído para isso ter efeito)
        window.deferredPrompt = null;
      });
    ''';

    final scriptElement = html.ScriptElement()
      ..type = 'text/javascript'
      ..innerHtml = script;
    html.document.head?.append(scriptElement);
  }

  Future<void> _triggerInstallPrompt() async {
    // Pega o objeto `deferredPrompt` do JS
    final prompt = js_util.getProperty(html.window, 'deferredPrompt');
    if (prompt == null) {
      debugPrint("Prompt de instalação não encontrado.");
      return;
    }

    // Chama o método `prompt()` do objeto
    await js_util.callMethod(prompt, 'prompt', []);

    // Opcional: esconde o botão após o prompt ser exibido
    setState(() {
      _showInstallButton = false;
    });

    // Limpa o prompt no JS para não ser usado de novo
    js_util.setProperty(html.window, 'deferredPrompt', null);
  }

  @override
  Widget build(BuildContext context) {
    // Só mostra o botão se a flag for verdadeira E se estiver na web
    if (kIsWeb && _showInstallButton) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.download_for_offline),
        label: const Text('Instalar App'),
        onPressed: _triggerInstallPrompt,
      );
    }
    // Caso contrário, retorna um widget vazio
    return const SizedBox.shrink();
  }
}
