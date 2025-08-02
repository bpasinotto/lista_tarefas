self.addEventListener('install', function (event) {
    console.log('Service Worker instalado');
    self.skipWaiting();
});

self.addEventListener('activate', function (event) {
    console.log('Service Worker ativado');
    event.waitUntil(self.clients.claim());
});

// Armazenar referências dos timeouts para poder cancelá-los
let scheduledTimeouts = [];

self.addEventListener('message', function (event) {
    console.log('Mensagem recebida no SW:', event.data);

    if (event.data && event.data.type === 'SCHEDULE_NOTIFICATION') {
        const { title, body, delay } = event.data;

        console.log('Agendando notificação para', delay, 'ms');

        // Cancelar notificações anteriores
        scheduledTimeouts.forEach(timeout => clearTimeout(timeout));
        scheduledTimeouts = [];

        // Agendar nova notificação
        const timeoutId = setTimeout(() => {
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
            
            console.log('Notificação mostrada:', title);
        }, delay);

        scheduledTimeouts.push(timeoutId);
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