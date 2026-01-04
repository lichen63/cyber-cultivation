import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/game_data.dart';

class GameDataService {
  static const String _fileName = 'game_save.json';

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  Future<void> saveGameData(GameData data) async {
    try {
      final file = File(await _getFilePath());
      final jsonString = jsonEncode(data.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error saving game data: $e');
    }
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
      print('Error loading game data: $e');
    }
    return null;
  }
}
