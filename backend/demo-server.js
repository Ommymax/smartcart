const http = require('http');
const crypto = require('crypto');

const port = Number(process.env.PORT || 5000);
const esp32Token = process.env.ESP32_API_TOKEN || 'local-demo-esp32-token';

const users = [];
const carts = [];
const telemetry = [];
const alerts = [];

function send(res, statusCode, body) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Token',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
  });
  res.end(JSON.stringify(body));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (chunk) => {
      data += chunk;
      if (data.length > 1024 * 1024) req.destroy();
    });
    req.on('end', () => {
      try {
        resolve(data ? JSON.parse(data) : {});
      } catch (error) {
        reject(error);
      }
    });
  });
}

function tokenFor(user) {
  return Buffer.from(JSON.stringify({ sub: user.id, email: user.email, role: user.role })).toString('base64url');
}

function userFromAuth(req) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return null;
  try {
    const data = JSON.parse(Buffer.from(token, 'base64url').toString('utf8'));
    return users.find((user) => user.id === data.sub) || null;
  } catch (_error) {
    return null;
  }
}

function publicUser(user) {
  return { id: user.id, name: user.name, email: user.email, role: user.role };
}

function latestForCart(cartId) {
  return telemetry.filter((item) => item.cart_id === cartId).at(-1) || null;
}

function createTelemetryRecord(payload) {
  return {
    id: crypto.randomUUID(),
    cart_id: payload.cartId,
    power_status: payload.powerStatus,
    motion_status: payload.motionStatus,
    stop_reason: payload.stopReason,
    battery_voltage: payload.batteryVoltage,
    battery_percentage: payload.batteryPercentage,
    radio_connected: payload.radioConnected,
    internet_connected: payload.internetConnected,
    front_sensor_active: payload.ultrasonic?.front?.active,
    front_distance_cm: payload.ultrasonic?.front?.distanceCm,
    left_sensor_active: payload.ultrasonic?.left?.active,
    left_distance_cm: payload.ultrasonic?.left?.distanceCm,
    right_sensor_active: payload.ultrasonic?.right?.active,
    right_distance_cm: payload.ultrasonic?.right?.distanceCm,
    left_rssi: payload.rssi?.left,
    right_rssi: payload.rssi?.right,
    latitude: payload.location?.latitude,
    longitude: payload.location?.longitude,
    location_available: payload.location?.available || false,
    uptime_ms: payload.uptimeMs,
    created_at: new Date().toISOString()
  };
}

function createAlerts(payload) {
  const created = [];
  const add = (alertType, message, severity) => {
    const alert = {
      id: crypto.randomUUID(),
      cart_id: payload.cartId,
      alert_type: alertType,
      message,
      severity,
      is_read: false,
      created_at: new Date().toISOString()
    };
    alerts.unshift(alert);
    created.push(alert);
  };

  if (payload.batteryPercentage < 10) add('battery_critical', `${payload.cartId} battery is critically low.`, 'critical');
  else if (payload.batteryPercentage < 20) add('low_battery', `${payload.cartId} battery is low.`, 'warning');
  if (!payload.radioConnected) add('radio_disconnected', `${payload.cartId} radio is disconnected.`, 'critical');
  if (!payload.internetConnected) add('internet_disconnected', `${payload.cartId} internet is disconnected.`, 'critical');
  if (payload.motionStatus === 'emergency_stop') add('emergency_stop', `${payload.cartId} is in emergency stop.`, 'critical');
  if ((payload.stopReason || '').toLowerCase().includes('obstacle')) add('obstacle_detected', `${payload.cartId} detected an obstacle.`, 'warning');
  return created;
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') return send(res, 204, {});

  try {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const path = url.pathname;

    if (req.method === 'GET' && path === '/health') {
      return send(res, 200, { status: 'ok', service: 'smartcart-demo-backend' });
    }

    if (req.method === 'POST' && path === '/api/auth/register') {
      const body = await readBody(req);
      if (!body.name || !body.email || !body.password) return send(res, 400, { message: 'Name, email, and password are required' });
      if (users.some((user) => user.email === body.email.toLowerCase())) return send(res, 409, { message: 'Email is already registered' });
      const user = {
        id: crypto.randomUUID(),
        name: body.name,
        email: body.email.toLowerCase(),
        password: body.password,
        role: body.role === 'administrator' ? 'administrator' : 'operator'
      };
      users.push(user);
      return send(res, 201, { user: publicUser(user), token: tokenFor(user) });
    }

    if (req.method === 'POST' && path === '/api/auth/login') {
      const body = await readBody(req);
      const user = users.find((item) => item.email === String(body.email || '').toLowerCase() && item.password === body.password);
      if (!user) return send(res, 401, { message: 'Invalid email or password' });
      return send(res, 200, { user: publicUser(user), token: tokenFor(user) });
    }

    if (req.method === 'GET' && path === '/api/auth/me') {
      const user = userFromAuth(req);
      if (!user) return send(res, 401, { message: 'Authentication token is required' });
      return send(res, 200, { user: publicUser(user) });
    }

    if (req.method === 'GET' && path === '/api/carts') {
      const user = userFromAuth(req);
      if (!user) return send(res, 401, { message: 'Authentication token is required' });
      const visible = user.role === 'administrator' ? carts : carts.filter((cart) => cart.assigned_user_id === user.id);
      const data = visible.map((cart) => ({ ...cart, ...latestForCart(cart.cart_id), last_telemetry_at: latestForCart(cart.cart_id)?.created_at || null }));
      return send(res, 200, { data });
    }

    if (req.method === 'POST' && path === '/api/carts/mine') {
      const user = userFromAuth(req);
      if (!user) return send(res, 401, { message: 'Authentication token is required' });
      const body = await readBody(req);
      if (!body.cartId || !body.cartName) return send(res, 400, { message: 'Cart ID and cart name are required' });
      if (carts.some((cart) => cart.cart_id === body.cartId)) return send(res, 409, { message: 'Cart ID already exists' });
      const cart = {
        id: crypto.randomUUID(),
        cart_id: body.cartId,
        cart_name: body.cartName,
        description: body.description || null,
        serial_number: body.serialNumber || null,
        model: body.model || null,
        installation_date: body.installationDate || null,
        assigned_user_id: user.id,
        status: 'active',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };
      carts.push(cart);
      return send(res, 201, { data: cart });
    }

    if (req.method === 'POST' && path === '/api/cart/telemetry') {
      if (req.headers['x-api-token'] !== esp32Token) return send(res, 401, { message: 'Invalid telemetry API token' });
      const body = await readBody(req);
      if (!carts.some((cart) => cart.cart_id === body.cartId)) return send(res, 404, { message: `Unknown cart ID: ${body.cartId}` });
      const record = createTelemetryRecord(body);
      telemetry.push(record);
      const createdAlerts = createAlerts(body);
      return send(res, 201, { message: 'Telemetry accepted', data: { cartId: body.cartId, telemetry: record, alerts: createdAlerts } });
    }

    if (req.method === 'GET' && path === '/api/alerts') {
      const user = userFromAuth(req);
      if (!user) return send(res, 401, { message: 'Authentication token is required' });
      return send(res, 200, { data: alerts });
    }

    return send(res, 404, { message: 'Route not found' });
  } catch (error) {
    return send(res, 500, { message: error.message || 'Server error' });
  }
});

server.listen(port, () => {
  console.log(`SmartCart demo backend running at http://localhost:${port}`);
  console.log(`ESP32 demo token: ${esp32Token}`);
});
