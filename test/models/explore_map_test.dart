import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/models/explore_map.dart';
import 'package:cyber_cultivation/constants.dart';

void main() {
  group('ExploreMap.calculateMaxAP', () {
    test('level 1 returns base AP', () {
      expect(ExploreMap.calculateMaxAP(1), ExploreConstants.apBase);
    });

    test('level 10 (realm 0) includes level scaling only', () {
      // base + (10-1)*2 + 0*20 = 100 + 18 = 118
      expect(ExploreMap.calculateMaxAP(10), 118);
    });

    test('level 11 (realm 1) includes first realm bonus', () {
      // base + (11-1)*2 + 1*20 = 100 + 20 + 20 = 140
      expect(ExploreMap.calculateMaxAP(11), 140);
    });

    test('level 50 (realm 4) scales correctly', () {
      // base + (50-1)*2 + 4*20 = 100 + 98 + 80 = 278
      expect(ExploreMap.calculateMaxAP(50), 278);
    });

    test('level 100 (realm 9) scales correctly', () {
      // base + (100-1)*2 + 9*20 = 100 + 198 + 180 = 478
      expect(ExploreMap.calculateMaxAP(100), 478);
    });
  });

  group('ExploreMap AP fields', () {
    late ExploreMap map;

    setUp(() {
      // Create a minimal 3x3 map for testing
      final grid = List.generate(
        3,
        (y) => List.generate(
          3,
          (x) => ExploreCell(type: ExploreCellType.blank, x: x, y: y),
        ),
      );
      map = ExploreMap(
        grid: grid,
        width: 3,
        height: 3,
        playerX: 1,
        playerY: 1,
        generatedAtLevel: 1,
        generatedAtExp: 0.0,
        currentAP: 100,
        maxAP: 100,
      );
    });

    test('currentAP and maxAP default to 0', () {
      final grid = List.generate(
        3,
        (y) => List.generate(
          3,
          (x) => ExploreCell(type: ExploreCellType.blank, x: x, y: y),
        ),
      );
      final defaultMap = ExploreMap(
        grid: grid,
        width: 3,
        height: 3,
        playerX: 1,
        playerY: 1,
        generatedAtLevel: 1,
        generatedAtExp: 0.0,
      );
      expect(defaultMap.currentAP, 0);
      expect(defaultMap.maxAP, 0);
      expect(defaultMap.usedHouses.isEmpty, true);
    });

    test('AP values are set correctly via constructor', () {
      expect(map.currentAP, 100);
      expect(map.maxAP, 100);
    });

    test('AP values can be mutated', () {
      map.currentAP -= 3;
      expect(map.currentAP, 97);
    });
  });

  group('ExploreMap house tracking', () {
    late ExploreMap map;

    setUp(() {
      final grid = List.generate(
        5,
        (y) => List.generate(
          5,
          (x) => ExploreCell(type: ExploreCellType.blank, x: x, y: y),
        ),
      );
      // Place a house at (2, 3)
      grid[3][2] = const ExploreCell(type: ExploreCellType.house, x: 2, y: 3);
      map = ExploreMap(
        grid: grid,
        width: 5,
        height: 5,
        playerX: 0,
        playerY: 0,
        generatedAtLevel: 1,
        generatedAtExp: 0.0,
        currentAP: 100,
        maxAP: 100,
      );
    });

    test('house is initially not used', () {
      expect(map.isHouseUsed(2, 3), false);
    });

    test('markHouseUsed marks the house', () {
      map.markHouseUsed(2, 3);
      expect(map.isHouseUsed(2, 3), true);
    });

    test('other positions are not affected', () {
      map.markHouseUsed(2, 3);
      expect(map.isHouseUsed(0, 0), false);
      expect(map.isHouseUsed(4, 4), false);
    });
  });

  group('ExploreMap AP serialization', () {
    test('toJson includes AP and usedHouses fields', () {
      final grid = List.generate(
        3,
        (y) => List.generate(
          3,
          (x) => ExploreCell(type: ExploreCellType.blank, x: x, y: y),
        ),
      );
      final map = ExploreMap(
        grid: grid,
        width: 3,
        height: 3,
        playerX: 1,
        playerY: 1,
        generatedAtLevel: 5,
        generatedAtExp: 50.0,
        currentAP: 87,
        maxAP: 110,
        usedHouses: {3 * 3 + 1}, // x=1, y=1 encoded for width 3
      );

      final json = map.toJson();
      expect(json['currentAP'], 87);
      expect(json['maxAP'], 110);
      expect(json['usedHouses'], isA<List>());
      expect((json['usedHouses'] as List).length, 1);
    });

    test('fromJson restores AP and usedHouses fields', () {
      final grid = List.generate(
        3,
        (y) => List.generate(
          3,
          (x) => ExploreCell(type: ExploreCellType.blank, x: x, y: y),
        ),
      );
      final original = ExploreMap(
        grid: grid,
        width: 3,
        height: 3,
        playerX: 1,
        playerY: 1,
        generatedAtLevel: 5,
        generatedAtExp: 50.0,
        currentAP: 87,
        maxAP: 110,
        usedHouses: {10},
      );

      final json = original.toJson();
      final restored = ExploreMap.fromJson(json);

      expect(restored.currentAP, 87);
      expect(restored.maxAP, 110);
      expect(restored.usedHouses.contains(10), true);
    });

    test('fromJson handles missing AP fields for backward compatibility', () {
      // Simulate an old save without AP fields
      final grid = List.generate(
        3,
        (y) => List.generate(
          3,
          (x) => ExploreCell(type: ExploreCellType.blank, x: x, y: y),
        ),
      );
      final oldMap = ExploreMap(
        grid: grid,
        width: 3,
        height: 3,
        playerX: 1,
        playerY: 1,
        generatedAtLevel: 1,
        generatedAtExp: 0.0,
      );

      final json = oldMap.toJson();
      // Remove AP fields to simulate old save format
      json.remove('currentAP');
      json.remove('maxAP');
      json.remove('usedHouses');

      final restored = ExploreMap.fromJson(json);
      expect(restored.currentAP, 0);
      expect(restored.maxAP, 0);
      expect(restored.usedHouses.isEmpty, true);
    });
  });

  group('ExploreMapGenerator', () {
    test('generates a map with correct dimensions', () {
      final generator = ExploreMapGenerator(seed: 42);
      final map = generator.generate(playerLevel: 1, playerExp: 0.0);

      expect(map.width, ExploreConstants.gridSize);
      expect(map.height, ExploreConstants.gridSize);
      expect(map.grid.length, ExploreConstants.gridSize);
      expect(map.grid[0].length, ExploreConstants.gridSize);
    });

    test('player spawns on a blank cell', () {
      final generator = ExploreMapGenerator(seed: 42);
      final map = generator.generate(playerLevel: 1, playerExp: 0.0);

      final playerCell = map.getCell(map.playerX, map.playerY);
      expect(playerCell, isNotNull);
      expect(playerCell!.type, ExploreCellType.blank);
    });

    test('stores level and exp in generated map', () {
      final generator = ExploreMapGenerator(seed: 42);
      final map = generator.generate(playerLevel: 25, playerExp: 123.45);

      expect(map.generatedAtLevel, 25);
      expect(map.generatedAtExp, 123.45);
    });
  });
}
