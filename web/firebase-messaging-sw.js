self.addEventListener('install', function (event) {
    console.log('Service Worker instalado');
    self.skipWaiting();
});

self.addEventListener('activate', function (event) {
    console.log('Service Worker ativado');
    event.waitUntil(self.clients.claim());
});

self.addEventListener('message', function (event) {
    console.log('Mensagem recebida no SW:', event.data);

    if (event.data && event.data.type === 'SCHEDULE_NOTIFICATION') {
        const { title, body, delay } = event.data;

        console.log('Agendando notificação para', delay, 'ms');

        setTimeout(() => {
            self.registration.showNotification(title, {
                body: body,
                icon: '/icons/Icon-192.png',
                badge: '/icons/Icon-192.png',
                tag: 'tarefas-reminder',
                requireInteraction: false,
                silent: false
            });
        }, delay);
    }
});

self.addEventListener('notificationclick', function (event) {
    console.log('Notificação clicada');
    event.notification.close();

    event.waitUntil(
        clients.openWindow('/')
    );
});