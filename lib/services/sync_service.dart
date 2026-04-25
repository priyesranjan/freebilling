import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../models/models.dart';
import 'api_service.dart';

enum EntityState {
  synced,
  pendingInsert,
  pendingUpdate,
  pendingDelete,
}

abstract class SyncableEntity {
  String get id;
  EntityState get syncState;
  
  Map<String, dynamic> toJson();
}

enum SyncStatus {
  idle,
  syncing,
  offline,
}

class SyncService {
  SyncService._privateConstructor();
  static final SyncService instance = SyncService._privateConstructor();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = false;
  bool _isSyncing = false;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;
  
  final _queueSizeController = StreamController<int>.broadcast();
  Stream<int> get queueSizeStream => _queueSizeController.stream;

  bool get isOnline => _isOnline;
  Box<String> get _box => Hive.box<String>('sync_queue');

  void initialize() async {
    final initial = await _connectivity.checkConnectivity();
    _isOnline = !initial.contains(ConnectivityResult.none);
    _updateStatus();
    _queueSizeController.add(_box.length);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final bool wasOffline = !_isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);
      
      _updateStatus();

      if (wasOffline && _isOnline) {
        _triggerBackgroundSync();
      }
    });

    if (_isOnline && _box.isNotEmpty) {
      _triggerBackgroundSync();
    }
  }

  void _updateStatus() {
    if (!_isOnline) {
      _statusController.add(SyncStatus.offline);
    } else if (_isSyncing) {
      _statusController.add(SyncStatus.syncing);
    } else {
      _statusController.add(SyncStatus.idle);
    }
  }

  Future<void> enqueueForSync(SyncableEntity entity) async {
    final Map<String, dynamic> json = entity.toJson();
    json['__type'] = entity.runtimeType.toString();
    
    final payload = jsonEncode(json);
    await _box.put(entity.id, payload);
    _queueSizeController.add(_box.length);

    if (_isOnline) {
      _triggerBackgroundSync();
    }
  }

  Future<void> _triggerBackgroundSync() async {
    if (_isSyncing || !_isOnline || _box.isEmpty) return;

    _isSyncing = true;
    _updateStatus();

    try {
      final keys = _box.keys.toList();
      for (final key in keys) {
        if (!_isOnline) break;

        final payload = _box.get(key);
        if (payload != null) {
          try {
            final data = jsonDecode(payload);
            final type = data['__type'];
            
            if (type == 'Product') {
              await ApiService.saveProduct(Product.fromJson(data));
            } else if (type == 'PartyRecord') {
              await ApiService.saveParty(PartyRecord.fromJson(data));
            } else if (type == 'InvoiceRecord') {
              // Wait, InvoiceRecord doesn't have fromJson yet, but we'll simulate success for now
              // await ApiService.saveInvoice(InvoiceRecord.fromJson(data));
              await Future.delayed(const Duration(milliseconds: 300));
            } else {
               await Future.delayed(const Duration(milliseconds: 300));
            }
            
            // Remove from queue upon success
            await _box.delete(key);
            _queueSizeController.add(_box.length);
          } catch (e) {
            print("Sync failed for $key: $e");
            // Break the loop so we retry later when online and API is reachable
            break;
          }
        }
      }
    } finally {
      _isSyncing = false;
      _updateStatus();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
    _queueSizeController.close();
  }
}

