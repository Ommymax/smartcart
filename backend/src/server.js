const http = require('http');
const { Server } = require('socket.io');
const app = require('./app');
const env = require('./config/env');
const registerSockets = require('./sockets');
const telemetryModel = require('./models/telemetryModel');
const alertService = require('./services/alertService');

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: env.corsOrigin.includes('*') ? '*' : env.corsOrigin }
});

app.set('io', io);
registerSockets(io);

setInterval(async () => {
  try {
    const stale = await telemetryModel.staleCarts(30);
    for (const cart of stale) {
      const alert = await alertService.createOfflineAlert(cart);
      if (alert) io.emit('alerts:new', [alert]);
    }
  } catch (error) {
    console.error('Offline alert check failed:', error.message);
  }
}, 15000);

server.listen(env.port, () => {
  console.log(`SmartCart API listening on port ${env.port}`);
});
