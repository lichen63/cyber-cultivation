import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/game_data.dart';

class GameDataService {
  static const String _fileName = 'game_save.json';

  Future<String> _getFilePath() async {
    if (kDebugMode) {
      // In debug mode, save to current working directory for easier debugging
      final currentDir = Directory.current.path;
      return '$currentDir/$_fileName';
    } else {
      // In release/production mode, use Application Support directory
      final directory = await getApplicationSupportDirectory();
      return '${directory.path}/$_fileName';
    }
  }

  Future<void> saveGameData(GameData data) async {
    try {
      final file = File(await _getFilePath());
      final jsonString = jsonEncode(data.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error saving game data: $e');
    }
  }

  Future<String> generateUserId() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceIdentifier = 'unknown';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceIdentifier =
            '${androidInfo.brand}:${androidInfo.device}:${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceIdentifier = '${iosInfo.name}:${iosInfo.identifierForVendor}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceIdentifier = linuxInfo.machineId ?? 'unknown';
      } else if (Platform.isMacOS) {
        final macOsInfo = await deviceInfo.macOsInfo;
        deviceIdentifier = macOsInfo.systemGUID ?? 'unknown';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceIdentifier = windowsInfo.deviceId;
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
      deviceIdentifier = DateTime.now().toIso8601String(); // Fallback
    }

    var bytes = utf8.encode(deviceIdentifier);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<GameData?> loadGameData() async {
    try {
      final path = await _getFilePath();
      final file = File(path);

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonMap = jsonDecode(jsonString);
        return GameData.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('Error loading game data: $e');
      // Backup corrupted file and start fresh
      await _backupCorruptedFile();
    }
    return null;
  }

  /// Backs up a corrupted save file with timestamp
  Future<void> _backupCorruptedFile() async {
    try {
      final path = await _getFilePath();
      final file = File(path);

      if (await file.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final backupPath = '$path.corrupted.$timestamp';
        await file.rename(backupPath);
        debugPrint('Corrupted save file backed up to: $backupPath');
      }
    } catch (e) {
      debugPrint('Error backing up corrupted file: $e');
      // If backup fails, try to delete the corrupted file
      try {
        final path = await _getFilePath();
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted corrupted save file');
        }
      } catch (deleteError) {
        debugPrint('Error deleting corrupted file: $deleteError');
      }
    }
  }
}
