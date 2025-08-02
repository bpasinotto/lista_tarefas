// Service Worker para notificações PWA - Lista de Tarefas
const CACHE_NAME = 'lista-tarefas-v1.1';
const urlsToCache = [
    '/',
    '/main.dart.js',
    '/favicon.png',
    '/manifest.json'
];

console.log('Service Worker: Iniciando...');

// Instala o service worker
self.addEventListener('install', function (event) {
    console.log('Service Worker: Instalando...');
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(function (cache) {
                console.log('Service Worker: Cache aberto');
                return cache.addAll(urlsToCache);
            })
            .catch(function (error) {
                console.error('Service Worker: Erro no cache:', error);
            })
    );
    // Força ativação imediata
    self.skipWaiting();
});

// Ativa o service worker
self.addEventListener('activate', function (event) {
    console.log('Service Worker: Ativando...');
    event.waitUntil(
        // Limpa caches antigos
        caches.keys().then(function (cacheNames) {
            return Promise.all(
                cacheNames.map(function (cacheName) {
                    if (cacheName !== CACHE_NAME) {
                        console.log('Service Worker: Removendo cache antigo:', cacheName);
                        return caches.delete(cacheName);
                    }
                })
            );
        })
    );
    // Assume controle imediatamente
    return self.clients.claim();
});

// Intercepta requests
self.addEventListener('fetch', function (event) {
    event.respondWith(
        caches.match(event.request)
            .then(function (response) {
                if (response) {
                    return response;
                }
                return fetch(event.request);
            })
            .catch(function (error) {
                console.error('Service Worker: Erro no fetch:', error);
                return fetch(event.request);
            })
    );
});

// Gerencia cliques em notificações
self.addEventListener('notificationclick', function (event) {
    console.log('Service Worker: Notificação clicada');
    event.notification.close();

    event.waitUntil(
        clients.matchAll().then(function (clientList) {
            // Se já há uma janela aberta, foca nela
            for (let i = 0; i < clientList.length; i++) {
                const client = clientList[i];
                if (client.url === '/' && 'focus' in client) {
                    return client.focus();
                }
            }
            // Senão, abre nova janela
            if (clients.openWindow) {
                return clients.openWindow('/');
            }
        })
    );
});

// Variável global para armazenar timeouts
let scheduledTimeouts = new Map();

// Processa mensagens do app principal
self.addEventListener('message', function (event) {
    console.log('Service Worker: Mensagem recebida:', event.data);

    if (event.data && event.data.type === 'SCHEDULE_NOTIFICATION') {
        const { hour, minute, title, body } = event.data;

        console.log(`Service Worker: Agendando notificação para ${hour}:${minute}`);

        // Limpa timeout anterior se existir
        if (scheduledTimeouts.has('daily-reminder')) {
            clearTimeout(scheduledTimeouts.get('daily-reminder'));
            scheduledTimeouts.delete('daily-reminder');
        }

        // Calcula próximo horário
        const now = new Date();
        const scheduledTime = new Date();
        scheduledTime.setHours(hour, minute, 0, 0);

        // Se já passou hoje, agenda para amanhã
        if (scheduledTime <= now) {
            scheduledTime.setDate(scheduledTime.getDate() + 1);
        }

        const delay = scheduledTime.getTime() - now.getTime();
        console.log(`Service Worker: Delay calculado: ${delay}ms (${Math.round(delay / 1000 / 60)} minutos)`);

        // Agenda notificação
        const timeoutId = setTimeout(() => {
            console.log('Service Worker: Mostrando notificação agendada');

            // Verifica se temos permissão
            if (Notification.permission === 'granted') {
                self.registration.showNotification(title, {
                    body: body,
                    icon: '/favicon.png',
                    badge: '/favicon.png',
                    tag: 'daily-reminder',
                    renotify: true,
                    requireInteraction: false,
                    silent: false,
                    actions: [
                        {
                            action: 'view',
                            title: 'Ver Tarefas'
                        },
                        {
                            action: 'close',
                            title: 'Fechar'
                        }
                    ]
                }).then(() => {
                    console.log('Service Worker: Notificação mostrada com sucesso');
                }).catch((error) => {
                    console.error('Service Worker: Erro ao mostrar notificação:', error);
                });
            } else {
                console.warn('Service Worker: Sem permissão para notificações');
            }

            // Agenda próxima notificação para amanhã
            scheduleNextDay(hour, minute, title, body);

        }, delay);

        // Armazena o timeout para poder cancelar depois
        scheduledTimeouts.set('daily-reminder', timeoutId);

        // Responde ao cliente
        if (event.ports && event.ports[0]) {
            event.ports[0].postMessage({
                success: true,
                message: `Notificação agendada para ${hour}:${minute}`
            });
        }
    }

    if (event.data && event.data.type === 'CANCEL_NOTIFICATION') {
        console.log('Service Worker: Cancelando notificações');

        // Cancela timeout
        if (scheduledTimeouts.has('daily-reminder')) {
            clearTimeout(scheduledTimeouts.get('daily-reminder'));
            scheduledTimeouts.delete('daily-reminder');
        }

        // Remove notificações ativas
        self.registration.getNotifications().then(notifications => {
            notifications.forEach(notification => {
                if (notification.tag === 'daily-reminder') {
                    notification.close();
                }
            });
        });
    }
});

// Função para agendar o próximo dia
function scheduleNextDay(hour, minute, title, body) {
    const nextDay = new Date();
    nextDay.setDate(nextDay.getDate() + 1);
    nextDay.setHours(hour, minute, 0, 0);

    const delay = nextDay.getTime() - Date.now();

    const timeoutId = setTimeout(() => {
        if (Notification.permission === 'granted') {
            self.registration.showNotification(title, {
                body: body,
                icon: '/favicon.png',
                badge: '/favicon.png',
                tag: 'daily-reminder',
                renotify: true,
                requireInteraction: false
            });
        }
        scheduleNextDay(hour, minute, title, body);
    }, delay);

    scheduledTimeouts.set('daily-reminder', timeoutId);
}

console.log('Service Worker: Carregado com sucesso');
