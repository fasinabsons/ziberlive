import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart'; // Placeholder, ensure added to pubspec
import 'package:ziberlive/providers/app_state_provider.dart';
import 'package:ziberlive/config.dart'; // For kServiceId (assuming it's defined there)

class QrSyncScreen extends StatefulWidget {
  const QrSyncScreen({super.key});

  @override
  State<QrSyncScreen> createState() => _QrSyncScreenState();
}

class _QrSyncScreenState extends State<QrSyncScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _qrViewController;
  bool _isScanning = false;
  String? _scannedDataError;
  String _connectionStatus = "";
  bool _isConnectingAfterScan = false; // New state for progress bar

  // Simulate fetching local device info (replace with actual implementation)
  String get _localDeviceId => Provider.of<AppStateProvider>(context, listen: false).currentUser?.deviceId ?? "unknown_device_id";
  String get _localDeviceName => Provider.of<AppStateProvider>(context, listen: false).currentUser?.name ?? "Unknown Device";
  // Assuming kServiceId is defined in config.dart, e.g., const String kServiceId = "com.example.myapp.p2p";


  @override
  void dispose() {
    _qrViewController?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _qrViewController = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code == null) return;
      setState(() {
        _isScanning = false;
        _qrViewController?.pauseCamera();
        _connectionStatus = "Processing scanned QR code...";
        _isConnectingAfterScan = true; // Start progress indication
        _scannedDataError = null;
      });

      try {
        final Map<String, dynamic> decodedData = jsonDecode(scanData.code!);
        if (decodedData.containsKey('deviceId') && decodedData.containsKey('serviceId')) {
          if (decodedData['serviceId'] != kServiceId) {
            setState(() {
              _scannedDataError = "Invalid QR Code: Mismatched service ID.";
              _connectionStatus = "Error: Mismatched service ID.";
              _isConnectingAfterScan = false;
            });
            return;
          }
          setState(() {
            _connectionStatus = "Connecting to ${decodedData['deviceName'] ?? decodedData['deviceId']}...";
          });

          bool success = await Provider.of<AppStateProvider>(context, listen: false)
              .connectToPeerViaScannedData(decodedData);

          setState(() {
            _connectionStatus = success ? "Connection successful (simulated)!" : "Connection failed (simulated).";
            _isConnectingAfterScan = false;
          });

        } else {
          setState(() {
            _scannedDataError = "Invalid QR Code: Missing required data.";
            _connectionStatus = "Error: Invalid QR data.";
            _isConnectingAfterScan = false;
          });
        }
      } catch (e) {
        setState(() {
          _scannedDataError = "Error decoding QR data: ${e.toString()}";
          _connectionStatus = "Error: Could not read QR data.";
          _isConnectingAfterScan = false;
        });
      } finally {
        // No automatic navigation here, let user see the status.
        // If successful, appState.connectToPeerViaScannedData might navigate or update global state.
      }
    });
  }

  Widget _buildQrScanner(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Theme.of(context).colorScheme.primary,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: MediaQuery.of(context).size.width * 0.8,
          ),
        ),
        Positioned(
          bottom: 50,
          child: ElevatedButton(
            child: const Text("Stop Scanning"),
            onPressed: () {
              setState(() {
                _isScanning = false;
                _qrViewController?.stopCamera();
              });
            },
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final String qrDataToEncode = jsonEncode({
      'deviceId': _localDeviceId,
      'deviceName': _localDeviceName,
      'serviceId': kServiceId, // Make sure kServiceId is defined in config.dart
    });

    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(title: const Text("Scan QR Code to Join Sync")),
        body: _buildQrScanner(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Sync'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                "Host Sync: Let others scan your code",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_localDeviceId == "unknown_device_id")
                const Text("Loading your device info...")
              else
                QrImageView( // From qr_flutter package
                  data: qrDataToEncode,
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                  embeddedImageStyle: const QrEmbeddedImageStyle(
                    size: Size(40, 40), // Optional: if you have an embedded image
                  ),
                  // embeddedImage: AssetImage('assets/images/app_logo_small.png'), // Optional
                  onError: (ex) {
                    print("[QR] ERROR - $ex");
                    // Handle error, e.g. show a message
                  },
                ),
              const SizedBox(height: 10),
              Text("Your Device ID: $_localDeviceId", style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 40),
              Text(
                "Join Sync: Scan another device's QR code",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan QR Code to Join'),
                onPressed: () {
                  setState(() {
                    _isScanning = true;
                    _scannedDataError = null; // Reset error on new scan attempt
                    _connectionStatus = ""; // Reset status
                  });
                  // QR Scanner view will be built by the next build() call
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              ),
              const SizedBox(height: 20),
              if (_isConnectingAfterScan)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: LinearProgressIndicator(),
                ),
              if (!_isConnectingAfterScan && _connectionStatus.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_connectionStatus, style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.center),
                ),
              if (!_isConnectingAfterScan && _scannedDataError != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _scannedDataError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              const Divider(height: 50, thickness: 1, indent: 20, endIndent: 20),
              Text(
                "Discover Nearby Devices",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Ensure Bluetooth and/or Wi-Fi is enabled on both devices. Then, one device hosts (via QR or by waiting) and the other discovers.",
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth_searching_rounded),
                label: const Text('Start Discovery & Sync'),
                onPressed: () async {
                  // This would call a method in AppStateProvider that starts the P2P discovery
                  // which P2PSyncService already handles (startDiscovery).
                  // AppStateProvider.startSync() already encapsulates this.
                  // For a dedicated "discovery" button, it might bypass ads or have a different flow.
                  // For now, let's assume it triggers the standard sync/discovery process.
                  setState(() {
                    _connectionStatus = "Starting discovery...";
                  });
                  // Potentially navigate away or show a list of discovered devices if AppStateProvider exposes it.
                  // This call might be to a more specific discovery method if available.
                  await Provider.of<AppStateProvider>(context, listen: false).startSync();
                  // After startSync completes (or if it runs in background), update status.
                  // This is a simplified representation; a real UI would show discovered peers.
                  // setState(() {
                  //  _connectionStatus = "Discovery active. Waiting for connections or for you to select a peer.";
                  // });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
              // Here you could list discovered devices if AppStateProvider._discoveredUsers is populated and exposed.
            ],
          ),
        ),
      ),
    );
  }
}

// Ensure kServiceId is defined in your config.dart:
// const String kServiceId = "com.example.yourapp.p2psync"; // Example
