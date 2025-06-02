import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'dart:convert'; // For jsonEncode and jsonDecode
import '../database/database_helper.dart'; // Assuming this path is correct

class P2PService {
  final Strategy strategy = Strategy.P2P_STAR; // Or other strategies like P2P_CLUSTER, P2P_POINT_TO_POINT
  final Nearby _nearby = Nearby();

  String _localUserId = ''; // To be set after user identification
  final Map<String, ConnectionInfo> _connectedDevices = {};

  // Callbacks for UI updates or data handling
  Function(String deviceId, String name)? onDeviceDiscovered;
  Function(String deviceId)? onDeviceLost;
  Function(String deviceId, ConnectionInfo info)? onConnectionInitiated;
  Function(String deviceId, String status)? onConnectionResult;
  Function(String deviceId)? onDisconnected;
  Function(String endpointId, Uint8List data)? onPayloadReceived;

  P2PService() {
    _nearby.askLocationPermission(); // Recommended for discovery
    _nearby.askBluetoothPermission(); // Recommended for discovery/connection
  }

  void setLocalUserId(String userId) {
    _localUserId = userId;
  }

  Future<void> startDiscovery(String serviceId, {Function(String deviceId, String name)? onDiscovered, Function(String deviceId)? onLost}) async {
    onDeviceDiscovered = onDiscovered;
    onDeviceLost = onLost;
    try {
      await _nearby.startDiscovery(
        _localUserId, // User Nickname for discovery
        strategy,
        onEndpointFound: (id, name, serviceId) {
          print('Device Found: $id, Name: $name, ServiceID: $serviceId');
          if (onDeviceDiscovered != null) {
            onDeviceDiscovered!(id, name);
          }
        },
        onEndpointLost: (id) {
          print('Device Lost: $id');
          if (onDeviceLost != null && id != null) {
            onDeviceLost!(id);
          }
        },
        serviceId: serviceId, // Your unique service ID
      );
      print('Discovery started');
    } catch (e) {
      print('Error starting discovery: $e');
    }
  }

  Future<void> stopDiscovery() async {
    await _nearby.stopDiscovery();
    print('Discovery stopped');
  }

  Future<void> startAdvertising(String serviceId) async {
    try {
      await _nearby.startAdvertising(
        _localUserId,
        strategy,
        onConnectionInitiated: (endpointId, connectionInfo) {
          print('Connection initiated from $endpointId, Name: ${connectionInfo.endpointName}, Token: ${connectionInfo.authenticationToken}');
          if (onConnectionInitiated != null) {
            onConnectionInitiated!(endpointId, connectionInfo);
          }
          // Automatically accept connection or use a dialog
          // _nearby.acceptConnection(endpointId, onPayLoadRecieved: _handlePayload);
        },
        onConnectionResult: (endpointId, status) {
          print('Connection result: $endpointId, Status: $status');
          if (status == Status.CONNECTED) {
            _connectedDevices[endpointId] = ConnectionInfo(endpointId, '', ''); // Store minimal info for now
             print('Connected to: $endpointId');
          } else {
            _connectedDevices.remove(endpointId);
          }
          if (onConnectionResult != null) {
            onConnectionResult!(endpointId, status.toString());
          }
        },
        onDisconnected: (endpointId) {
          print('Disconnected from: $endpointId');
          _connectedDevices.remove(endpointId);
          if (onDisconnected != null) {
            onDisconnected!(endpointId);
          }
        },
        serviceId: serviceId, // Your unique service ID
      );
      print('Advertising started');
    } catch (e) {
      print('Error starting advertising: $e');
    }
  }

  Future<void> stopAdvertising() async {
    await _nearby.stopAdvertising();
    print('Advertising stopped');
  }

  Future<void> connectToDevice(String endpointId, {Function(String deviceId, String status)? onResult, Function(String deviceId)? onDisconnectedCallback}) async {
    onConnectionResult = onResult;
    onDisconnected = onDisconnectedCallback;
    try {
      await _nearby.requestConnection(
        _localUserId,
        endpointId,
        onConnectionInitiated: (id, info) {
          print('Connection initiated to $id, Name: ${info.endpointName}');
          if (onConnectionInitiated != null) {
            onConnectionInitiated!(id, info);
          }
          // Automatically accept connection or use a dialog
          // _nearby.acceptConnection(id, onPayLoadRecieved: _handlePayload);
        },
        onConnectionResult: (id, status) {
          print('Connection result with $id: $status');
           if (status == Status.CONNECTED) {
            _connectedDevices[id] = ConnectionInfo(id, '', ''); // Store minimal info for now
            print('Connected to: $id');
          } else {
            _connectedDevices.remove(id);
          }
          if (onConnectionResult != null) {
            onConnectionResult!(id, status.toString());
          }
        },
        onDisconnected: (id) {
          print('Disconnected from: $id');
          _connectedDevices.remove(id);
          if (onDisconnected != null) {
            onDisconnected!(id);
          }
        },
      );
    } catch (e) {
      print('Error connecting to device $endpointId: $e');
    }
  }

  void acceptConnection(String endpointId) {
    _nearby.acceptConnection(endpointId, onPayLoadRecieved: _handlePayload);
    print("Connection accepted for $endpointId");
  }

  void rejectConnection(String endpointId) {
    _nearby.rejectConnection(endpointId);
     print("Connection rejected for $endpointId");
  }

  void _handlePayload(String endpointId, Payload payload) {
    print('Payload received from $endpointId');
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      try {
        final String receivedJson = utf8.decode(payload.bytes!);
        final Map<String, dynamic> receivedData = jsonDecode(receivedJson);

        print('Data received: $receivedData');

        // Example: Handling a 'notice' data type
        if (receivedData.containsKey('type') && receivedData['type'] == 'notice_sync') {
          final Map<String, dynamic> noticePayload = receivedData['payload'] as Map<String, dynamic>;
          final String noticeId = noticePayload['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(); // Or a proper ID
          final String receivedTimestamp = noticePayload['timestamp'] as String;

          // --- Conflict Resolution (Last Writer Wins) ---
          // 1. Attempt to fetch existing notice from local DB by noticeId.
          //    Example: final localNotice = await DatabaseHelper.instance.readNotice(noticeId);
          // 2. If localNotice exists and localNotice.timestamp is newer than receivedTimestamp, ignore received.
          // 3. Else, save/update the received notice.
          print('Received notice: $noticePayload with timestamp $receivedTimestamp. Implement conflict resolution and DB save here.');

          // --- Database Interaction (Placeholder) ---
          // Example:
          // await DatabaseHelper.instance.createOrUpdateNotice(noticePayload);
          // This method would internally handle if it's a new notice or an update based on ID.
          // It should also store the timestamp.

          // Notify UI or other services if needed
          if (onPayloadReceived != null) {
            // Pass a structured object or relevant info
            onPayloadReceived!(endpointId, payload.bytes!);
          }
        } else {
          // Handle other data types or pass to a general handler
           if (onPayloadReceived != null) {
            onPayloadReceived!(endpointId, payload.bytes!);
          }
        }
      } catch (e) {
        print('Error processing received payload: $e');
      }
    }
  }

  Future<void> sendNoticeToAll(Map<String, dynamic> noticeContent) async {
    // Ensure the notice has a timestamp for conflict resolution
    // The actual 'id' should be managed by the database or a UUID generator
    final Map<String, dynamic> noticeData = {
      'type': 'notice_sync', // To identify the type of data being synced
      'payload': {
        ...noticeContent, // e.g., {id: 'some_uuid', message: 'Hello', created_at: 'iso_string'}
        'timestamp': DateTime.now().toUtc().toIso8601String(), // Crucial for LWW
      }
    };
    print('Sending notice to all: $noticeData');
    await sendDataToAllConnected(noticeData);
  }

  // Modify sendData to also include a type, or make it more generic if not already
  // For this task, sendDataToAllConnected is used by sendNoticeToAll, which wraps the payload.
  Future<void> sendData(String endpointId, Map<String, dynamic> data) async {
    if (!_connectedDevices.containsKey(endpointId)) {
      print('Error: Not connected to device $endpointId');
      return;
    }
    try {
      final String jsonData = jsonEncode(data);
      await _nearby.sendBytesPayload(endpointId, Uint8List.fromList(utf8.encode(jsonData)));
      print('Data sent to $endpointId: $jsonData');
    } catch (e) {
      print('Error sending data to $endpointId: $e');
    }
  }

  Future<void> sendDataToAllConnected(Map<String, dynamic> data) async {
    if (_connectedDevices.isEmpty) {
      print('No devices connected.');
      return;
    }
    final String jsonData = jsonEncode(data);
    final Uint8List payloadBytes = Uint8List.fromList(utf8.encode(jsonData));

    for (String endpointId in _connectedDevices.keys) {
      try {
        await _nearby.sendBytesPayload(endpointId, payloadBytes);
        print('Data sent to $endpointId: $jsonData');
      } catch (e) {
        print('Error sending data to $endpointId: $e');
        // Optionally, handle individual send failures (e.g., retry, remove device)
      }
    }
  }

  Future<void> disconnectFromDevice(String endpointId) async {
    await _nearby.disconnectFromEndpoint(endpointId);
    _connectedDevices.remove(endpointId);
    print('Disconnected from $endpointId');
  }

  Future<void> stopAllEndpoints() async {
    await _nearby.stopAllEndpoints();
    _connectedDevices.clear();
    print('All endpoints stopped');
  }

  Map<String, ConnectionInfo> getConnectedDevices() {
    return Map.unmodifiable(_connectedDevices);
  }
}

// Note: The ConnectionInfo class provided by nearby_connections might not be directly instantiable
// or might not have all fields public. For _connectedDevices, you might store just IDs
// or create your own simple class/map if you need to store more metadata.
// For simplicity here, I'm implying ConnectionInfo can be stored, but it might just be endpointId.
