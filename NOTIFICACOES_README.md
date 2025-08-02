# Sistema de Notificações Diárias - Lista de Tarefas

## 📱 Funcionalidades Implementadas

- ✅ Notificações locais para Android, iOS e Windows
- ✅ Configuração de horário personalizado
- ✅ Suporte limitado para PWA/Web
- ✅ Interface de configuração amigável
- ✅ Testes de notificação
- ✅ Contagem automática de tarefas pendentes

## 🔧 Configuração por Plataforma

### 🤖 Android
- **Status**: ✅ Funciona completamente
- **Funciona em segundo plano**: Sim
- **Permissões**: Configuradas automaticamente
- **Limitações**: 
  - Pode ser afetado por otimizações de bateria
  - Android 13+ requer permissão explícita

**Configuração adicional para produção:**
1. No arquivo `android/app/build.gradle`, adicione se necessário:
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        targetSdkVersion 34
    }
}
```

### 🍎 iOS
- **Status**: ✅ Funciona completamente
- **Funciona em segundo plano**: Sim
- **Permissões**: Solicitadas automaticamente
- **Limitações**:
  - Máximo de 64 notificações agendadas
  - Usuário pode desabilitar nas configurações

**Configuração adicional para produção:**
1. No Xcode, certificar que as capabilities estão habilitadas:
   - Background Modes → Background Processing
   - Push Notifications

### 🌐 PWA/Web
- **Status**: ⚠️ Funciona com limitações
- **Funciona em segundo plano**: Não
- **Permissões**: Requer aprovação manual do usuário
- **Limitações**:
  - Funciona apenas com navegador/PWA aberto
  - iOS Safari tem restrições severas
  - Não funciona se a aba for fechada

**Soluções alternativas para Web:**
1. **Service Worker**: Implementado para cache e notificações básicas
2. **Push API**: Requer servidor backend (não implementado)
3. **Instruções para o usuário**: Manter PWA aberto em segundo plano

### 🪟 Windows
- **Status**: ⚠️ Suporte limitado
- **Funciona em segundo plano**: Depende do sistema
- **Permissões**: Configuradas via Windows
- **Limitações**: Varia por versão do Windows

## 🚀 Como Usar

### 1. Acessar Configurações
- Clique no ícone de relógio (⏰) na barra superior
- Ou navegue para a tela de configurações

### 2. Configurar Notificações
1. **Ativar notificações**: Toggle principal
2. **Definir horário**: Clique em "Horário do Lembrete"
3. **Testar**: Use "Testar Notificação" para verificar se funciona

### 3. Permissões
- **Android**: Concedidas automaticamente na primeira execução
- **iOS**: Popup de permissão aparece automaticamente
- **Web**: Clique em "Permitir" quando o navegador solicitar
- **Windows**: Configurar nas configurações do sistema se necessário

## 📋 Funcionalidades Técnicas

### Notificação Inteligente
- Conta automaticamente as tarefas pendentes
- Mensagem personalizada baseada no número de tarefas
- Exemplo: "Você tem 3 tarefa(s) pendente(s) para hoje!"

### Persistência de Configuração
- Configurações salvas localmente
- Mantém preferências após reinicialização
- Horário e status de ativação persistentes

### Interface Amigável
- Design Material Design
- Informações específicas por plataforma
- Status visual das permissões
- Botão de teste integrado

## ⚠️ Limitações Conhecidas

### iOS Safari (PWA)
- **Problema**: Push notifications limitadas
- **Solução**: Usar app nativo ou instruir usuário a manter PWA aberto

### Android com Otimização de Bateria
- **Problema**: Sistema pode matar notificações
- **Solução**: Instruir usuário a desabilitar otimização para o app

### Web sem Service Worker
- **Problema**: Notificações não funcionam offline
- **Solução**: Service Worker implementado para cache básico

## 🔧 Desenvolvimento e Deploy

### Comandos Úteis
```bash
# Instalar dependências
flutter pub get

# Executar em modo debug
flutter run

# Build para produção Web
flutter build web

# Build para Android
flutter build apk --release

# Build para iOS
flutter build ios --release
```

### Deploy no Vercel
1. Fazer build web: `flutter build web`
2. Configurar `vercel.json` (já incluído)
3. Deploy: `vercel --prod`

### Teste de Notificações
1. **Local**: Use o botão "Testar Notificação" na interface
2. **Produção**: Configure um horário próximo e aguarde
3. **Debug**: Verifique os logs do console para Web

## 📚 Arquivos Importantes

- **`lib/services/notification_service.dart`**: Lógica principal de notificações
- **`lib/pages/notification_settings_page.dart`**: Interface de configuração
- **`lib/helpers/pwa_helper.dart`**: Helpers específicos para PWA
- **`web/sw.js`**: Service Worker para PWA
- **`android/app/src/main/AndroidManifest.xml`**: Permissões Android

## 🎯 Próximos Passos (Opcional)

1. **Push Notifications para Web**: Implementar servidor backend
2. **Notificações Rich**: Adicionar imagens e ações
3. **Múltiplos Horários**: Permitir vários lembretes por dia
4. **Integração com Calendário**: Sincronizar com calendários do sistema
5. **Analytics**: Rastrear efetividade das notificações

## 🐛 Troubleshooting

### Notificações não aparecem
1. Verificar permissões nas configurações do dispositivo
2. Para Android: Desabilitar otimizações de bateria
3. Para iOS: Verificar configurações de notificação
4. Para Web: Verificar se navegador suporta notificações

### App não compila
1. Executar `flutter clean && flutter pub get`
2. Verificar versões das dependências
3. Para iOS: Abrir projeto no Xcode e verificar certificates

### Service Worker não funciona
1. Verificar se está sendo servido via HTTPS
2. Para desenvolvimento local: Usar `flutter run -d web-server --web-port 8080`
3. Verificar console do navegador para erros
