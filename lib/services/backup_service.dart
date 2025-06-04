import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt; // Import the encrypt package
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

class BackupService {
  encrypt.Key? _currentKey;
  encrypt.IV? _currentIV; // IV should ideally be unique per encryption but derived consistently for decryption if not stored with data.
                         // For simplicity with custom keys, we might derive it from the key or use a fixed one (less secure).
                         // Or, even better, generate a new IV for each encryption and prepend it to the ciphertext.
                         // For this iteration, we'll use a fixed IV derived from a portion of the key or a fixed string.

  // Default hardcoded key if no custom key is provided (highly insecure placeholder)
  static final _defaultEncryptionKeyString = "my32lengthsupersecretnoquotekey!"; // Ensure 32 bytes
  static final _defaultIVString = "my16lengthivneed"; // Ensure 16 bytes

  encrypt.Encrypter? _encrypter;

  BackupService() {
    // Initialize with default key. Should be replaced by custom key logic via AppStateProvider.
    _initializeEncrypter(_defaultEncryptionKeyString, _defaultIVString);
    debugPrint("BackupService: Initialized with DEFAULT (insecure) encryption key.");
  }

  void _initializeEncrypter(String keyString, String ivString) {
    try {
      _currentKey = encrypt.Key.fromUtf8(keyString.padRight(32, '#').substring(0,32)); // Ensure 32 bytes
      _currentIV = encrypt.IV.fromUtf8(ivString.padRight(16, '#').substring(0,16));   // Ensure 16 bytes
      _encrypter = encrypt.Encrypter(encrypt.AES(_currentKey!, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
    } catch (e) {
      debugPrint("BackupService: Error initializing encrypter - key or IV might be invalid. $e");
      _encrypter = null; // Prevent operations if setup fails
    }
  }

  // Method to be called by AppStateProvider after fetching custom key from secure storage
  void setCustomEncryptionKey(String? customKeyString) {
    if (customKeyString != null && customKeyString.isNotEmpty) {
        if (customKeyString.length < 32) {
            debugPrint("BackupService: Custom key too short. Padding (insecure). Minimum 32 chars recommended.");
            // In a real app, enforce length or use a KDF.
        }
        // For IV, we could derive it from the key or use a fixed portion of it.
        // For simplicity, if key is long enough, derive IV from it, otherwise use a default based on it.
        String ivString = customKeyString.length >= 16
            ? customKeyString.substring(customKeyString.length - 16)
            : _defaultIVString;
        _initializeEncrypter(customKeyString, ivString);
        debugPrint("BackupService: Custom encryption key SET.");
    } else {
      // Fallback to default if custom key is null/empty (or handle as error)
      _initializeEncrypter(_defaultEncryptionKeyString, _defaultIVString);
      debugPrint("BackupService: Custom key is null or empty. Using DEFAULT (insecure) key.");
    }
  }


  Future<String?> exportData(Map<String, dynamic> data, String fileName) async {
    if (_encrypter == null || _currentIV == null) {
      debugPrint('BackupService: Encrypter not initialized. Cannot export.');
      return null;
    }
    try {
      final jsonData = jsonEncode(data);
      // SECURITY BEST PRACTICE: Generate a new random IV for each encryption and prepend/store it with the ciphertext.
      // For this iteration, using _currentIV derived or fixed.
      final encrypted = _encrypter!.encrypt(jsonData, iv: _currentIV!);

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(encrypted.base64); // Store as base64

      debugPrint('BackupService: Data encrypted and saved to ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('BackupService: Error exporting data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> importData(String fileName) async {
     if (_encrypter == null || _currentIV == null) {
      debugPrint('BackupService: Encrypter not initialized. Cannot import.');
      return null;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');

      if (await file.exists()) {
        final encryptedBase64Data = await file.readAsString();
        // When using unique IVs per encryption: IV would be read from the start of encryptedBase64Data
        final decrypted = _encrypter!.decrypt64(encryptedBase64Data, iv: _currentIV!);

        debugPrint('BackupService: Data decrypted successfully from $fileName');
        return jsonDecode(decrypted) as Map<String, dynamic>;
      } else {
        debugPrint('BackupService: Backup file not found: $fileName');
        return null;
      }
    } catch (e) {
      debugPrint('BackupService: Error importing/decrypting data: $e. This could be due to a wrong key/IV, corrupted data, or format change.');
      return null;
    }
  }
}
