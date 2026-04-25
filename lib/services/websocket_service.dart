import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class WebSocketService {
  WebSocketService._privateConstructor();
  static final WebSocketService instance = WebSocketService._privateConstructor();

  IO.Socket? _socket;
  
  // Callbacks for UI updates
  void Function()? onDataChanged;

  void connect() async {
    final token = await ApiService.getToken();
    if (token == null) return; // Cannot connect without auth

    _socket = IO.io(ApiService.baseUrl.replaceAll('/api', ''), IO.OptionBuilder()
      .setAuth({'token': token})
      .disableAutoConnect()
      .build());

    _socket?.connect();

    _socket?.onConnect((_) {
      debugPrint('Websocket Connected');
    });

    _socket?.on('sync_event', (data) {
      debugPrint('Sync Event Received: $data');
      // Whenever another device updates the database, trigger a UI refresh
      if (onDataChanged != null) {
        onDataChanged!();
      }
    });

    _socket?.onDisconnect((_) {
      debugPrint('Websocket Disconnected');
    });
    
    _socket?.onError((err) {
      debugPrint('Websocket Error: $err');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
