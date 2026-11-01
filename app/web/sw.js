// Ablösung des Service Workers der früheren PWA (cache-first, Cache "jubla-app-v*").
// Die Flutter-App bringt ihren eigenen Service Worker (flutter_service_worker.js)
// mit. Ohne diese Datei würde der alte Worker auf bestehenden Installationen
// weiter die veraltete PWA aus dem Cache ausliefern.
self.addEventListener("install", () => self.skipWaiting());

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      for (const key of await caches.keys()) {
        await caches.delete(key);
      }
      await self.registration.unregister();
      const clients = await self.clients.matchAll({ type: "window" });
      clients.forEach((client) => client.navigate(client.url));
    })(),
  );
});
