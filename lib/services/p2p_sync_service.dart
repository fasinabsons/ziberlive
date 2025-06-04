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
          // Get item-level timestamps if available from 'lastModified' field
          // The value from remote could be a primitive, a map, or a list.
          // This specific 'else' block in _resolveConflicts is for when merged[key] is not a Map or List,
          // or 'value' is not of the same type.
          // We should prioritize based on remoteMeta.timestamp (payload timestamp) for direct field overwrites at this level,
          // unless the items themselves are timestamped objects not fitting map/list merge.
          // For direct replacement of a top-level key (e.g. globalTreePoints object)
          if (value is Map && value.containsKey('lastModified') && merged[key] is Map && (merged[key] as Map).containsKey('lastModified')) {
            try {
              DateTime remoteItemLastModified = DateTime.parse(value['lastModified']);
              DateTime localItemLastModified = DateTime.parse((merged[key] as Map)['lastModified']);
              if (remoteItemLastModified.isAfter(localItemLastModified)) {
                merged[key] = value;
              } else if (remoteItemLastModified.isAtSameMomentAs(localItemLastModified) && remoteIsAdmin && !isAdmin) {
                // If timestamps are same, admin data takes precedence
                merged[key] = value;
              }
            } catch (e) {
              logger.w("Error parsing lastModified for key $key, falling back to payload timestamp: $e");
              // Fallback to payload timestamp if item 'lastModified' is missing or malformed
              if (remoteTimestamp > (localData['_meta']?['timestamp'] ?? 0) ) { // Compare with local payload timestamp
                 merged[key] = value;
              }
            }
          } else {
            // Fallback for primitives or if one doesn't have lastModified: use payload timestamp or admin priority
            // This part of the logic might need to be re-evaluated based on how often non-map/non-list items are top-level.
            // For now, assume top-level items that are not lists/maps and need merging are maps with lastModified (like global stats).
            // If 'value' is a primitive, it's just replaced if remote payload is newer or admin.
             int localPayloadTimestamp = localData['_meta']?['timestamp'] ?? 0; // Assuming localData also has _meta from previous syncs
             if (remoteIsAdmin && !isAdmin) {
                merged[key] = value;
             } else if (remoteTimestamp > localPayloadTimestamp) {
                merged[key] = value;
            }
          }
        }
      }
    });

    return merged;
  }

  Map<String, dynamic> _parseDateTimeFields(Map<String, dynamic> item) {
    // Helper to ensure 'lastModified' (and other date fields) are DateTime objects for comparison
    // This is more relevant if the maps are not yet fully typed objects.
    // However, our models' fromJson should handle this. This is a safeguard.
    if (item.containsKey('lastModified') && item['lastModified'] is String) {
      try {
        item['lastModified_dt'] = DateTime.parse(item['lastModified']);
      } catch (_) {} // Ignore if parsing fails
    }
    return item;
  }

  DateTime _getItemTimestamp(Map<String, dynamic> item, {DateTime? defaultTimestamp}) {
    if (item.containsKey('lastModified') && item['lastModified'] != null) {
      try {
        return DateTime.parse(item['lastModified'] as String);
      } catch (e) {
        logger.w("Could not parse 'lastModified' string: ${item['lastModified']}. Error: $e");
      }
    }
    return defaultTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0); // Very old date if no timestamp
  }


  Map<String, dynamic> _mergeNestedMaps(Map<String, dynamic> local,
      Map<String, dynamic> remote, DateTime remotePayloadTimestamp, bool remoteIsAdmin) {
    Map<String, dynamic> result = Map<String, dynamic>.from(local);

    remote.forEach((key, value) {
      if (!result.containsKey(key)) {
        result[key] = value;
      } else if (value is Map && result[key] is Map) {
        // If both are maps, check for 'lastModified' to decide if we replace the whole map or recurse
        DateTime localItemTimestamp = _getItemTimestamp(result[key] as Map<String,dynamic>);
        DateTime remoteItemTimestamp = _getItemTimestamp(value as Map<String,dynamic>);

        if (key == '_meta') { // Special handling for _meta map, just take remote
            result[key] = value;
        } else if (remoteItemTimestamp.isAfter(localItemTimestamp)) {
          result[key] = value; // Remote item map is newer, take the whole map
        } else if (localItemTimestamp.isAfter(remoteItemTimestamp)) {
          // Local item map is newer, keep local (do nothing for this key)
        } else { // Timestamps are same or one is missing/invalid, or no timestamp on items themselves
                 // If same, admin has priority, else recurse to merge fields inside.
          if (remoteIsAdmin && !isAdmin && remoteItemTimestamp.isAtSameMomentAs(localItemTimestamp)) {
             result[key] = value;
          } else {
             result[key] = _mergeNestedMaps(Map<String, dynamic>.from(result[key] as Map),
              Map<String, dynamic>.from(value as Map), remotePayloadTimestamp, remoteIsAdmin);
          }
        }
      } else if (value is List && result[key] is List) {
        result[key] = _mergeLists(List.from(result[key] as List), List.from(value as List),
            remotePayloadTimestamp, remoteIsAdmin);
      } else { // Primitive values or type mismatch in nested maps
        // For direct field replacement within a map if not further merging.
        // This usually means the map itself was not replaced based on 'lastModified', so we're merging its fields.
        // Here, remotePayloadTimestamp is the fallback if items don't have their own timestamps.
        // This specific 'else' implies one is a primitive and the other isn't, or both are primitives.
        // We generally assume the structure is the same; if not, replacement is based on payload or admin.
        DateTime localPayloadTimestamp = DateTime.fromMillisecondsSinceEpoch(localData['_meta']?['timestamp'] ?? 0);

        if (remoteIsAdmin && !isAdmin) {
          result[key] = value;
        } else if (remotePayloadTimestamp.isAfter(localPayloadTimestamp)) {
           // This comparison should ideally be against the local item's last modified date if available,
           // or the local payload's date if we are deciding to overwrite a primitive.
           // Given we are inside _mergeNestedMaps, it means the parent map wasn't replaced wholesale.
           // So, replacing a primitive field should be fine if the remote payload is generally newer.
          result[key] = value;
        }
      }
    });

    return result;
  }

  List _mergeLists(
      List local, List remote, DateTime remotePayloadTimestamp, bool remoteIsAdmin) {
    if (local.isNotEmpty && local.first is Map && remote.isNotEmpty && remote.first is Map) {
      bool hasIds = (local.first as Map).containsKey('id');

      if (hasIds) {
        Map<String, dynamic> localById = {
          for (var item in local.whereType<Map<String,dynamic>>())
            if (item.containsKey('id')) item['id'].toString(): item,
        };
        List resultList = [];

        for (var remoteItemDynamic in remote.whereType<Map<String,dynamic>>()) {
          if (!remoteItemDynamic.containsKey('id')) { // Remote item without ID, just add if not present structurally (hard to do)
            resultList.add(remoteItemDynamic);
            continue;
          }
          String id = remoteItemDynamic['id'].toString();
          var localItemDynamic = localById[id];

          if (localItemDynamic == null) { // New item, add it
            resultList.add(remoteItemDynamic);
            localById.remove(id); // Mark as processed
          } else { // Existing item, compare timestamps
            DateTime localItemTimestamp = _getItemTimestamp(localItemDynamic);
            DateTime remoteItemTimestamp = _getItemTimestamp(remoteItemDynamic);

            if (remoteItemTimestamp.isAfter(localItemTimestamp)) {
              resultList.add(remoteItemDynamic);
            } else if (localItemTimestamp.isAfter(remoteItemTimestamp)) {
              resultList.add(localItemDynamic);
            } else { // Timestamps are same
              if (remoteIsAdmin && !isAdmin) {
                resultList.add(remoteItemDynamic);
              } else {
                // Optionally, if items are maps, merge them field by field (deep merge)
                // For now, if timestamps same & not admin override, prefer local.
                resultList.add(localItemDynamic);
              }
            }
            localById.remove(id); // Mark as processed
          }
        }
        // Add any remaining local items that were not in remote (shouldn't typically happen if remote is comprehensive)
        resultList.addAll(localById.values);
        return resultList;
      }
    }

    // For lists without IDs, or non-map items, or if one list is empty: use a set-based approach for simple union.
    // This might not be ideal for all scenarios (e.g., list of chat messages where order matters and items don't have unique IDs but are timestamped).
    // For chat messages, they usually have timestamps and might be merged then sorted.
    // For now, simple union for non-ID'd lists.
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
