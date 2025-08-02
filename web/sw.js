// Este SW vai trabalhar junto com o flutter_service_worker.js
console.log('SW personalizado carregado');

// Armazenar referências dos timeouts para poder cancelá-los
let scheduledTimeouts = [];

self.addEventListener('install', function (event) {
    console.log('SW personalizado instalado');
    self.skipWaiting();
});

self.addEventListener('activate', function (event) {
    console.log('SW personalizado ativado');
    event.waitUntil(self.clients.claim());
});

self.addEventListener('message', function (event) {
    console.log('=== MENSAGEM RECEBIDA NO SW PERSONALIZADO ===');
    console.log('Event:', event);
    console.log('Data:', event.data);
    console.log('Type:', event.data?.type);

    if (event.data && event.data.type === 'SCHEDULE_NOTIFICATION') {
        const { title, body, delay } = event.data;

        console.log('Agendando notificação:', { title, body, delay });

        // Cancelar notificações anteriores
        scheduledTimeouts.forEach(timeout => clearTimeout(timeout));
        scheduledTimeouts = [];

        // Agendar nova notificação
        const timeoutId = setTimeout(() => {
            console.log('EXECUTANDO NOTIFICAÇÃO:', title);
            self.registration.showNotification(title, {
                body: body,
                icon: '/icons/Icon-192.png',
                badge: '/icons/Icon-192.png',
                tag: 'tarefas-reminder',
                requireInteraction: true,
                silent: false,
                vibrate: [200, 100, 200],
                actions: [
                    {
                        action: 'view',
                        title: 'Ver Tarefas'
                    },
                    {
                        action: 'dismiss',
                        title: 'Dispensar'
                    }
                ]
            });
        }, delay);

        scheduledTimeouts.push(timeoutId);
        console.log('Timeout agendado com ID:', timeoutId);
    } else {
        console.log('Mensagem ignorada - tipo não reconhecido');
    }
});

self.addEventListener('notificationclick', function (event) {
    console.log('Notificação clicada:', event.action);
    event.notification.close();

    if (event.action === 'view' || !event.action) {
        event.waitUntil(
            clients.openWindow('/')
        );
    }
});