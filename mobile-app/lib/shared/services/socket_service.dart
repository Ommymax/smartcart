import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  SocketService({required this.socketUrl});
  final String socketUrl;
  io.Socket? _socket;

  void connect(String token, {required ValueChanged<Map<String, dynamic>> onTelemetry, required ValueChanged<List<dynamic>> onAlerts}) {
    _socket?.dispose();
    _socket = io.io(
      socketUrl,
      io.OptionBuilder().setTransports(['websocket']).setAuth({'token': token}).disableAutoConnect().build(),
    );
    _socket!
      ..on('telemetry:new', (data) => onTelemetry(Map<String, dynamic>.from(data as Map)))
      ..on('alerts:new', (data) => onAlerts(data as List<dynamic>))
      ..connect();
  }

  void joinCart(String cartId) => _socket?.emit('cart:join', cartId);
  void leaveCart(String cartId) => _socket?.emit('cart:leave', cartId);
  void disconnect() => _socket?.dispose();
}
