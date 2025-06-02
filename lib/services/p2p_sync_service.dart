import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '/config.dart';
import 'package:logger/logger.dart';

/// P2P Sync Service for offline-first data synchronization between devices
/// This service handles peer-to-peer data transfer using nearby_connections
class P2PSyncService {
  final Strategy strategy = Strategy.P2P_CLUSTER;
  final Map<String, dynamic> localData;
  final Function(Map<String, dynamic>) onSyncDataReceived;
  final BuildContext context;
  final String ssid;
  final String deviceId;
  final Function(double)? onTransferProgress;
  final Function(String)? onError;
  final Function(String)? onConnectionStatusChanged;

  // Connection tracking
  final Map<String, ConnectionInfo> _pendingConnections = {};
  final Set<String> _connectedEndpoints = {};

  // Role management
  bool isFirstInstall;
  String role; // 'ownerAdmin', 'roommateAdmin', 'guest'
  List<String> adminDeviceIds;
  Map<String, bool> guestPaymentStatus =
      {}; // Maps guest userId to whether they need to pay (true) or not (false)

  P2PSyncService({
    required this.localData,
    required this.onSyncDataReceived,
    required this.context,
    required this.ssid,
    required this.deviceId,
    this.onTransferProgress,
    this.onError,
    this.onConnectionStatusChanged,
    this.isFirstInstall = false,
    this.role = 'guest',
    this.adminDeviceIds = const [],
  }) {
    // On first install, first user becomes admin
    if (isFirstInstall && adminDeviceIds.isEmpty) {
      role = 'ownerAdmin';
      adminDeviceIds = [deviceId];
    }
  }

  void promoteToAdmin(String newAdminId) {
    if (!adminDeviceIds.contains(newAdminId)) {
      adminDeviceIds.add(newAdminId);
    }
  }

  void demoteSelfToUser() {
    adminDeviceIds.remove(deviceId);
    if (role == 'ownerAdmin') {
      role = 'roommateAdmin';
    } else {
      role = 'guest';
    }
  }
  final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);


  bool get isAdmin => adminDeviceIds.contains(deviceId);
  bool get isOwnerAdmin => role == 'ownerAdmin';
  bool get isRoommateAdmin => role == 'roommateAdmin';

  // Guest payment methods
  void setGuestPaymentStatus(String guestId, bool needsToPayRent,
      {String? relationship}) {
    // Admin can set if a guest needs to pay or not (for relatives/acquaintances)
    if (isAdmin) {
      guestPaymentStatus[guestId] = needsToPayRent;

      // Optionally record relationship in user metadata
      if (relationship != null && localData.containsKey('users')) {
        final users = List<Map<String, dynamic>>.from(localData['users']);
        final userIndex = users.indexWhere((u) => u['id'] == guestId);

        if (userIndex >= 0) {
          users[userIndex]['relationship'] = relationship;
          users[userIndex]['needsToPayRent'] = needsToPayRent;
          localData['users'] = users;
        }
      }
    }
  }

  bool guestNeedsToPayRent(String guestId) {
    // Default is true (guest pays) unless explicitly set to false
    return guestPaymentStatus[guestId] ?? true;
  }

  // Multi-SSID support
  String get currentSSID => ssid;

  /// Check required permissions for nearby connections
  /// Returns true if all permissions are granted
  Future<bool> checkPermissions() async {
    try {
      // For MVP, we'll assume permissions are granted
      // In production, this would check location and Bluetooth permissions
      return true;
    } catch (e) {
      if (onError != null) {
        onError!('Error checking permissions: $e');
      }
      return false;
    }
  }

  /// Start advertising this device to nearby peers
  /// Returns true if advertising started successfully
  Future<bool> startAdvertising(String userName, String userId) async {
    if (!await checkPermissions()) {
      return false;
    }

    try {
      bool started = await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (String endpointId, ConnectionInfo info) {
          _pendingConnections[endpointId] = info;
          _handleConnectionInitiated(endpointId, info);
        },
        onConnectionResult: (String endpointId, Status status) {
          _handleConnectionResult(endpointId, status);
        },
        onDisconnected: (String endpointId) {
          _connectedEndpoints.remove(endpointId);
          if (onConnectionStatusChanged != null) {
            onConnectionStatusChanged!('Disconnected from peer');
          }
        },
        serviceId: kServiceId,
      );

      if (started && onConnectionStatusChanged != null) {
        onConnectionStatusChanged!('Started advertising as $userName');
      }
      return started;
    } catch (e) {
      if (onError != null) {
        onError!('Error starting advertising: $e');
      }
      return false;
    }
  }

  /// Handle a new connection initiated by a peer
  void _handleConnectionInitiated(
      String endpointId, ConnectionInfo connectionInfo) {
    // Auto-accept connections
    try {
      Nearby().acceptConnection(
        endpointId,
        onPayLoadRecieved: (String id, Payload payload) {
          if (payload.type == PayloadType.BYTES) {
            handleReceivedData(payload.bytes!);
          }
        },
        onPayloadTransferUpdate: (String id, PayloadTransferUpdate update) {
          if (update.status == PayloadStatus.SUCCESS &&
              onTransferProgress != null) {
            onTransferProgress!(1.0); // Complete
          } else if (update.status == PayloadStatus.IN_PROGRESS &&
              onTransferProgress != null &&
              update.totalBytes > 0) {
            onTransferProgress!(update.bytesTransferred / update.totalBytes);
          }
        },
      );

      if (onConnectionStatusChanged != null) {
        onConnectionStatusChanged!(
            'Accepted connection from ${connectionInfo.endpointName}');
      }
    } catch (e) {
      if (onError != null) {
        onError!('Error accepting connection: $e');
      }
    }
  }

  /// Handle connection result
  void _handleConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      _connectedEndpoints.add(endpointId);
      if (onConnectionStatusChanged != null) {
        String peerName =
            _pendingConnections[endpointId]?.endpointName ?? 'Unknown';
        onConnectionStatusChanged!('Connected to $peerName');
      }

      // Send data immediately after connection
      sendSyncData(endpointId);
    } else if (status == Status.REJECTED) {
      if (onConnectionStatusChanged != null) {
        onConnectionStatusChanged!('Connection rejected by peer');
      }
    } else if (status == Status.ERROR) {
      if (onError != null) {
        onError!('Connection error');
      }
    }

    _pendingConnections.remove(endpointId);
  }

  /// Start discovering nearby peers
  /// Returns true if discovery started successfully
  Future<bool> startDiscovery(String userId) async {
    if (!await checkPermissions()) {
      return false;
    }

    try {
      bool started = await Nearby().startDiscovery(
        userId,
        strategy,
        onEndpointFound:
            (String endpointId, String endpointName, String serviceId) {
          if (onConnectionStatusChanged != null) {
            onConnectionStatusChanged!('Found endpoint: $endpointName');
          }

          // Auto-request connection
          _requestConnection(endpointId, userId);
        },
        onEndpointLost: (endpointId) {
          if (onConnectionStatusChanged != null) {
            onConnectionStatusChanged!('Lost endpoint: $endpointId');
          }
        },
        serviceId: kServiceId,
      );

      if (started && onConnectionStatusChanged != null) {
        onConnectionStatusChanged!('Started discovering peers');
      }
      return started;
    } catch (e) {
      if (onError != null) {
        onError!('Error starting discovery: $e');
      }
      return false;
    }
  }

  /// Request connection to a discovered endpoint
  void _requestConnection(String endpointId, String myName) {
    try {
      Nearby().requestConnection(
        myName,
        endpointId,
        onConnectionInitiated: (String endpointId, ConnectionInfo info) {
          _pendingConnections[endpointId] = info;
          _handleConnectionInitiated(endpointId, info);
        },
        onConnectionResult: (String endpointId, Status status) {
          _handleConnectionResult(endpointId, status);
        },
        onDisconnected: (String endpointId) {
          _connectedEndpoints.remove(endpointId);
          if (onConnectionStatusChanged != null) {
            onConnectionStatusChanged!('Disconnected from peer');
          }
        },
      );
    } catch (e) {
      if (onError != null) {
        onError!('Error requesting connection: $e');
      }
    }
  }

  /// Send local data to a connected endpoint
  /// Returns true if data was sent successfully
  Future<bool> sendSyncData(String endpointId) async {
    try {
      // Add timestamp and device ID to data for conflict resolution
      final dataToSend = {...localData};
      dataToSend['_meta'] = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'deviceId': deviceId,
        'role': role,
      };

      final bytes = utf8.encode(jsonEncode(dataToSend));

      // Send data using bytes payload
      await Nearby().sendBytesPayload(endpointId, bytes);

      if (onTransferProgress != null) {
        onTransferProgress!(1.0); // Complete progress
      }

      if (onConnectionStatusChanged != null) {
        onConnectionStatusChanged!(
            'Data sent to $endpointId (${bytes.length} bytes)');
      }

      return true;
    } catch (e) {
      if (onError != null) {
        onError!('Error sending data: $e');
      }
      if (onTransferProgress != null) {
        onTransferProgress!(0); // Reset progress on error
      }
      return false;
    }
  }

  /// Handle data received from a peer
  void handleReceivedData(List<int> bytes) {
    try {
      final String jsonString = utf8.decode(bytes);
      final Map<String, dynamic> remoteData = jsonDecode(jsonString);

      // Log received data for debugging
      if (kVerboseLogging) {
        logger.d('Received data: ${remoteData.length} keys');
      }

      // Extract metadata if present
      Map<String, dynamic>? meta;
      if (remoteData.containsKey('_meta')) {
        meta = Map<String, dynamic>.from(remoteData['_meta']);
        remoteData.remove('_meta'); // Remove metadata before merging
      }

      // Resolve conflicts and merge data
      final merged = _resolveConflicts(localData, remoteData, meta);
      onSyncDataReceived(merged);

      // Handle admin recovery requests
      if (isAdmin &&
          meta != null &&
          remoteData.containsKey('adminRecovery') &&
          remoteData['adminRecovery'] == true) {
        final String requestingAdminId = remoteData['requestingAdminId'] ?? '';
        if (requestingAdminId.isNotEmpty) {
          // Send recovery data
          sendSyncData(requestingAdminId);

          if (onConnectionStatusChanged != null) {
            onConnectionStatusChanged!(
                'Sent recovery data to admin $requestingAdminId');
          }
        }
      }

      // Update connection status
      if (onConnectionStatusChanged != null) {
        String peerInfo = meta != null ? '${meta['deviceId']}' : 'unknown peer';
        onConnectionStatusChanged!('Received data from $peerInfo');
      }
    } catch (e) {
      if (onError != null) {
        onError!('Error processing received data: $e');
      }

      // Try to recover what we can
      try {
        if (bytes.isNotEmpty) {
          final partialData = _recoverPartialData(bytes);
          if (partialData.isNotEmpty) {
            final merged = _resolveConflicts(localData, partialData, null);
            onSyncDataReceived(merged);

            if (onConnectionStatusChanged != null) {
              onConnectionStatusChanged!('Recovered partial data');
            }
          }
        }
      } catch (innerError) {
        if (onError != null) {
          onError!('Could not recover partial data: $innerError');
        }
      }
    }
  }

  Map<String, dynamic> _recoverPartialData(List<int> bytes) {
    // Try to recover as much data as possible from corrupted bytes
    try {
      // First try to find valid JSON chunks
      String rawData = utf8.decode(bytes, allowMalformed: true);
      if (rawData.contains('{') && rawData.contains('}')) {
        int start = rawData.indexOf('{');
        int end = rawData.lastIndexOf('}') + 1;
        if (start < end) {
          String possibleJson = rawData.substring(start, end);
          return jsonDecode(possibleJson);
        }
      }
    } catch (e) {
      logger.d('Recovery failed: $e');
    }
    return {};
  }

  Map<String, dynamic> _resolveConflicts(Map<String, dynamic> local,
      Map<String, dynamic> remote, Map<String, dynamic>? remoteMeta) {
    // Create a deep copy of local data to avoid modifying the original
    Map<String, dynamic> merged = Map<String, dynamic>.from(local);

    // Get remote timestamp for conflict resolution
    int remoteTimestamp = remoteMeta != null
        ? (remoteMeta['timestamp'] ?? DateTime.now().millisecondsSinceEpoch)
        : DateTime.now().millisecondsSinceEpoch;

    // Special handling for admin data (admin data has higher priority)
    bool remoteIsAdmin = remoteMeta != null &&
        (remoteMeta['role'] == 'ownerAdmin' ||
            remoteMeta['role'] == 'roommateAdmin');

    // Process each key in remote data
    remote.forEach((key, value) {
      // Skip null values
      if (value == null) return;

      // If key doesn't exist locally, add it
      if (!merged.containsKey(key)) {
        merged[key] = value;
        return;
      }

      // Handle different data types
      if (value is Map && merged[key] is Map) {
        // Recursively merge nested maps
        merged[key] = _mergeNestedMaps(Map<String, dynamic>.from(merged[key]),
            Map<String, dynamic>.from(value), remoteTimestamp, remoteIsAdmin);
      } else if (value is List && merged[key] is List) {
        // Merge lists based on IDs if available
        merged[key] = _mergeLists(List.from(merged[key]), List.from(value),
            remoteTimestamp, remoteIsAdmin);
      } else {
        // For primitive values, use timestamp-based conflict resolution
        // Admin data gets priority
        if (remoteIsAdmin && !isAdmin) {
          merged[key] = value;
        } else {
          // Get timestamps if available
          int localTimestamp = 0;
          int remoteItemTimestamp = 0;

          if (merged[key] is Map && merged[key].containsKey('timestamp')) {
            localTimestamp = merged[key]['timestamp'];
          }

          if (value is Map && value.containsKey('timestamp')) {
            remoteItemTimestamp = value['timestamp'];
          }

          // Use the most recent value
          if (remoteItemTimestamp > localTimestamp) {
            merged[key] = value;
          }
        }
      }
    });

    return merged;
  }

  Map<String, dynamic> _mergeNestedMaps(Map<String, dynamic> local,
      Map<String, dynamic> remote, int remoteTimestamp, bool remoteIsAdmin) {
    Map<String, dynamic> result = Map<String, dynamic>.from(local);

    remote.forEach((key, value) {
      if (!result.containsKey(key)) {
        result[key] = value;
      } else if (value is Map && result[key] is Map) {
        result[key] = _mergeNestedMaps(Map<String, dynamic>.from(result[key]),
            Map<String, dynamic>.from(value), remoteTimestamp, remoteIsAdmin);
      } else if (value is List && result[key] is List) {
        result[key] = _mergeLists(List.from(result[key]), List.from(value),
            remoteTimestamp, remoteIsAdmin);
      } else {
        // For primitive values in nested maps
        int localTimestamp =
            local.containsKey('timestamp') ? local['timestamp'] : 0;
        int remoteItemTimestamp = remote.containsKey('timestamp')
            ? remote['timestamp']
            : remoteTimestamp;

        if (remoteIsAdmin && !isAdmin) {
          result[key] = value;
        } else if (remoteItemTimestamp > localTimestamp) {
          result[key] = value;
        }
      }
    });

    return result;
  }

  List _mergeLists(
      List local, List remote, int remoteTimestamp, bool remoteIsAdmin) {
    // If the lists contain maps with IDs, merge by ID
    if (local.isNotEmpty &&
        local.first is Map &&
        remote.isNotEmpty &&
        remote.first is Map) {
      // Check if items have IDs
      bool hasIds = false;
      if (local.first is Map && (local.first as Map).containsKey('id')) {
        hasIds = true;
      }

      if (hasIds) {
        // Create a map of local items by ID
        Map<String, dynamic> localById = {};
        for (var item in local) {
          if (item is Map && item.containsKey('id')) {
            localById[item['id'].toString()] = item;
          }
        }

        // Process remote items
        for (var remoteItem in remote) {
          if (remoteItem is Map && remoteItem.containsKey('id')) {
            String id = remoteItem['id'].toString();

            if (!localById.containsKey(id)) {
              // New item, add it
              localById[id] = remoteItem;
            } else {
              // Existing item, check timestamps
              var localItem = localById[id];

              int localItemTimestamp = localItem.containsKey('timestamp')
                  ? localItem['timestamp']
                  : 0;
              int remoteItemTimestamp = remoteItem.containsKey('timestamp')
                  ? remoteItem['timestamp']
                  : remoteTimestamp;

              if (remoteIsAdmin && !isAdmin) {
                localById[id] = remoteItem;
              } else if (remoteItemTimestamp > localItemTimestamp) {
                localById[id] = remoteItem;
              }
            }
          }
        }

        // Convert back to list
        return localById.values.toList();
      }
    }

    // For lists without IDs or non-map items, use a set-based approach
    Set combinedSet = Set.from(local);
    combinedSet.addAll(remote);
    return combinedSet.toList();
  }

  /// Build a QR code widget for connection sharing
  Widget buildQR(String userId) {
    return QrImageView(
      data: userId,
      version: QrVersions.auto,
      size: 200.0,
    );
  }

  void stopAll() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
  }
}
