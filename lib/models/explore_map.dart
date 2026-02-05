import 'dart:collection';
import 'dart:math';

import '../constants.dart';

/// Types of cells in the explore map
enum ExploreCellType { blank, mountain, river, house, monster, boss, npc }

/// Represents a single cell in the explore map
class ExploreCell {
  final ExploreCellType type;
  final int x;
  final int y;

  const ExploreCell({required this.type, required this.x, required this.y});

  ExploreCell copyWith({ExploreCellType? type}) {
    return ExploreCell(type: type ?? this.type, x: x, y: y);
  }

  /// Check if this cell is walkable (player can move here)
  bool get isWalkable =>
      type != ExploreCellType.mountain && type != ExploreCellType.river;

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() => {'type': type.index, 'x': x, 'y': y};

  /// Create from JSON
  factory ExploreCell.fromJson(Map<String, dynamic> json) => ExploreCell(
    type: ExploreCellType.values[json['type'] as int],
    x: json['x'] as int,
    y: json['y'] as int,
  );
}

/// Represents the explore map data
class ExploreMap {
  final List<List<ExploreCell>> grid;
  final int width;
  final int height;
  int playerX;
  int playerY;

  ExploreMap({
    required this.grid,
    required this.width,
    required this.height,
    required this.playerX,
    required this.playerY,
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'playerX': playerX,
    'playerY': playerY,
    'grid': grid
        .map((row) => row.map((cell) => cell.toJson()).toList())
        .toList(),
  };

  /// Create from JSON
  factory ExploreMap.fromJson(Map<String, dynamic> json) {
    final width = json['width'] as int;
    final height = json['height'] as int;
    final gridJson = json['grid'] as List<dynamic>;
    final grid = gridJson.map((row) {
      return (row as List<dynamic>).map((cell) {
        return ExploreCell.fromJson(cell as Map<String, dynamic>);
      }).toList();
    }).toList();

    return ExploreMap(
      grid: grid,
      width: width,
      height: height,
      playerX: json['playerX'] as int,
      playerY: json['playerY'] as int,
    );
  }

  /// Get cell at position
  ExploreCell? getCell(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return null;
    return grid[y][x];
  }

  /// Check if position is valid and walkable
  bool canMoveTo(int x, int y) {
    final cell = getCell(x, y);
    return cell != null && cell.isWalkable;
  }

  /// Move player in direction, returns true if successful
  bool movePlayer(int dx, int dy) {
    final newX = playerX + dx;
    final newY = playerY + dy;
    if (canMoveTo(newX, newY)) {
      playerX = newX;
      playerY = newY;
      return true;
    }
    return false;
  }
}

/// Generates explore maps using cellular automata and flood fill
class ExploreMapGenerator {
  final Random _random;

  ExploreMapGenerator({int? seed})
    : _random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  /// Generate a new explore map
  ExploreMap generate() {
    final width = ExploreConstants.gridSize;
    final height = ExploreConstants.gridSize;

    // Initialize grid with blank cells
    final grid = List.generate(
      height,
      (y) => List.generate(
        width,
        (x) => ExploreCell(type: ExploreCellType.blank, x: x, y: y),
      ),
    );

    // Step 1: Generate mountains using cellular automata
    _generateMountains(grid, width, height);

    // Step 2: Generate rivers as connected paths
    _generateRivers(grid, width, height);

    // Step 3: Place other actors on blank cells
    _placeActors(grid, width, height);

    // Step 4: Find valid player spawn position (only on blank cells)
    final spawnPos = _findValidSpawnPosition(grid, width, height);

    // Step 5: Ensure houses are accessible from player spawn
    _ensureHouseAccessibility(grid, width, height, spawnPos.$1, spawnPos.$2);

    return ExploreMap(
      grid: grid,
      width: width,
      height: height,
      playerX: spawnPos.$1,
      playerY: spawnPos.$2,
    );
  }

  /// Generate mountains using cellular automata
  void _generateMountains(List<List<ExploreCell>> grid, int width, int height) {
    // Create a temporary boolean grid for cellular automata
    final mountainMap = List.generate(
      height,
      (_) => List.generate(width, (_) => false),
    );

    // Seed initial mountain clusters
    for (int i = 0; i < ExploreConstants.mountainSeedCount; i++) {
      final centerX = _random.nextInt(width);
      final centerY = _random.nextInt(height);

      // Create a small cluster around the seed
      for (int dy = -2; dy <= 2; dy++) {
        for (int dx = -2; dx <= 2; dx++) {
          final x = centerX + dx;
          final y = centerY + dy;
          if (x >= 0 && x < width && y >= 0 && y < height) {
            if (_random.nextDouble() < 0.6) {
              mountainMap[y][x] = true;
            }
          }
        }
      }
    }

    // Run cellular automata iterations
    for (
      int iter = 0;
      iter < ExploreConstants.cellularAutomataIterations;
      iter++
    ) {
      final newMap = List.generate(
        height,
        (y) => List.generate(width, (x) => mountainMap[y][x]),
      );

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final neighbors = _countNeighbors(mountainMap, x, y, width, height);

          if (mountainMap[y][x]) {
            // Mountain cell survives if it has enough neighbors
            newMap[y][x] = neighbors >= 2;
          } else {
            // Blank cell becomes mountain if surrounded by enough mountains
            newMap[y][x] =
                neighbors >= ExploreConstants.mountainGrowthThreshold;
          }
        }
      }

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          mountainMap[y][x] = newMap[y][x];
        }
      }
    }

    // Apply mountains to grid
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (mountainMap[y][x]) {
          grid[y][x] = ExploreCell(type: ExploreCellType.mountain, x: x, y: y);
        }
      }
    }
  }

  /// Count neighboring mountains
  int _countNeighbors(
    List<List<bool>> map,
    int x,
    int y,
    int width,
    int height,
  ) {
    int count = 0;
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 && nx < width && ny >= 0 && ny < height && map[ny][nx]) {
          count++;
        }
      }
    }
    return count;
  }

  /// Generate rivers as connected flowing paths
  void _generateRivers(List<List<ExploreCell>> grid, int width, int height) {
    for (int i = 0; i < ExploreConstants.riverSeedCount; i++) {
      _carveRiver(grid, width, height);
    }
  }

  /// Carve a single river path
  void _carveRiver(List<List<ExploreCell>> grid, int width, int height) {
    // Start from a random position inside the map (not on edges)
    final margin = width ~/ 6; // Keep away from edges
    int x = margin + _random.nextInt(width - 2 * margin);
    int y = margin + _random.nextInt(height - 2 * margin);

    final length =
        ExploreConstants.riverMinLength +
        _random.nextInt(
          ExploreConstants.riverMaxLength - ExploreConstants.riverMinLength,
        );

    // Direction tendencies for more natural flow
    int primaryDx = _random.nextBool() ? 1 : -1;
    int primaryDy = _random.nextBool() ? 1 : -1;

    for (int step = 0; step < length; step++) {
      if (x < 1 || x >= width - 1 || y < 1 || y >= height - 1) break;

      // Only place river on non-mountain cells
      if (grid[y][x].type != ExploreCellType.mountain) {
        grid[y][x] = ExploreCell(type: ExploreCellType.river, x: x, y: y);
      }

      // Choose next direction with meandering behavior
      final r = _random.nextDouble();
      if (r < 0.5) {
        // Continue in primary X direction
        x += primaryDx;
      } else if (r < 0.85) {
        // Continue in primary Y direction
        y += primaryDy;
      } else if (r < 0.92) {
        // Reverse X occasionally for meandering
        primaryDx = -primaryDx;
        x += primaryDx;
      } else {
        // Reverse Y occasionally for meandering
        primaryDy = -primaryDy;
        y += primaryDy;
      }
    }
  }

  /// Place actors on blank cells based on target percentages and fixed counts
  void _placeActors(List<List<ExploreCell>> grid, int width, int height) {
    final blankCells = <(int, int)>[];

    // Collect all blank cells
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (grid[y][x].type == ExploreCellType.blank) {
          blankCells.add((x, y));
        }
      }
    }

    // Shuffle for random placement
    blankCells.shuffle(_random);

    final totalCells = width * height;

    // Calculate actor counts based on target percentages
    int monstersToPlace = (totalCells * ExploreConstants.monsterTargetPercent)
        .round();
    int bossesToPlace = (totalCells * ExploreConstants.bossTargetPercent)
        .round();

    // Fixed counts for NPCs and houses
    int npcsToPlace = ExploreConstants.npcFixedCount;
    int housesToPlace = ExploreConstants.houseFixedCount;

    // Ensure we don't exceed available blank cells
    final totalActors =
        monstersToPlace + bossesToPlace + npcsToPlace + housesToPlace;
    if (totalActors > blankCells.length) {
      // Scale down proportionally if needed
      final scale = blankCells.length / totalActors;
      monstersToPlace = (monstersToPlace * scale).round();
      bossesToPlace = (bossesToPlace * scale).round();
      // Keep NPCs and houses at fixed counts if possible
      npcsToPlace = min(npcsToPlace, blankCells.length ~/ 4);
      housesToPlace = min(housesToPlace, blankCells.length ~/ 4);
    }

    int index = 0;

    // Place NPCs spread across different areas (grid divided into regions)
    _placeSpreadActors(
      grid,
      blankCells,
      ExploreCellType.npc,
      npcsToPlace,
      width,
      height,
    );

    // Place houses spread across different areas
    _placeSpreadActors(
      grid,
      blankCells,
      ExploreCellType.house,
      housesToPlace,
      width,
      height,
    );

    // Recollect remaining blank cells after placing spread actors
    final remainingBlankCells = <(int, int)>[];
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (grid[y][x].type == ExploreCellType.blank) {
          remainingBlankCells.add((x, y));
        }
      }
    }
    remainingBlankCells.shuffle(_random);

    // Place monsters
    for (
      int i = 0;
      i < monstersToPlace && index < remainingBlankCells.length;
      i++
    ) {
      final (x, y) = remainingBlankCells[index++];
      grid[y][x] = ExploreCell(type: ExploreCellType.monster, x: x, y: y);
    }

    // Place bosses
    for (
      int i = 0;
      i < bossesToPlace && index < remainingBlankCells.length;
      i++
    ) {
      final (x, y) = remainingBlankCells[index++];
      grid[y][x] = ExploreCell(type: ExploreCellType.boss, x: x, y: y);
    }
  }

  /// Place actors spread across different areas of the map
  void _placeSpreadActors(
    List<List<ExploreCell>> grid,
    List<(int, int)> blankCells,
    ExploreCellType type,
    int count,
    int width,
    int height,
  ) {
    if (count <= 0) return;

    // Divide map into regions based on count
    final regionsPerSide = sqrt(count).ceil();
    final regionWidth = width / regionsPerSide;
    final regionHeight = height / regionsPerSide;

    int placed = 0;

    // Try to place one actor per region
    for (int ry = 0; ry < regionsPerSide && placed < count; ry++) {
      for (int rx = 0; rx < regionsPerSide && placed < count; rx++) {
        final minX = (rx * regionWidth).round();
        final maxX = ((rx + 1) * regionWidth).round();
        final minY = (ry * regionHeight).round();
        final maxY = ((ry + 1) * regionHeight).round();

        // Find blank cells in this region
        final regionCells = blankCells.where((cell) {
          final (x, y) = cell;
          return x >= minX &&
              x < maxX &&
              y >= minY &&
              y < maxY &&
              grid[y][x].type == ExploreCellType.blank;
        }).toList();

        if (regionCells.isNotEmpty) {
          final cell = regionCells[_random.nextInt(regionCells.length)];
          final (x, y) = cell;
          grid[y][x] = ExploreCell(type: type, x: x, y: y);
          placed++;
        }
      }
    }

    // If not all placed (some regions had no blank cells), place remaining randomly
    if (placed < count) {
      final remaining = blankCells.where((cell) {
        final (x, y) = cell;
        return grid[y][x].type == ExploreCellType.blank;
      }).toList();
      remaining.shuffle(_random);

      for (int i = 0; i < remaining.length && placed < count; i++) {
        final (x, y) = remaining[i];
        grid[y][x] = ExploreCell(type: type, x: x, y: y);
        placed++;
      }
    }
  }

  /// Find a valid spawn position for the player (must be blank cell)
  (int, int) _findValidSpawnPosition(
    List<List<ExploreCell>> grid,
    int width,
    int height,
  ) {
    // Try to spawn near center first
    final centerX = width ~/ 2;
    final centerY = height ~/ 2;

    // Spiral outward from center to find blank cell
    for (int radius = 0; radius < max(width, height); radius++) {
      for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
          if (dx.abs() != radius && dy.abs() != radius) continue;
          final x = centerX + dx;
          final y = centerY + dy;
          if (x >= 0 && x < width && y >= 0 && y < height) {
            // Only spawn on blank cells to avoid reducing actor counts
            if (grid[y][x].type == ExploreCellType.blank) {
              return (x, y);
            }
          }
        }
      }
    }

    // Fallback: find any blank cell
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (grid[y][x].type == ExploreCellType.blank) {
          return (x, y);
        }
      }
    }

    // Last resort: find any walkable cell (may overlap with actor)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (grid[y][x].isWalkable) {
          return (x, y);
        }
      }
    }

    // Should never happen, but return center as last resort
    return (centerX, centerY);
  }

  /// Ensure all houses are accessible from player spawn using flood fill
  void _ensureHouseAccessibility(
    List<List<ExploreCell>> grid,
    int width,
    int height,
    int playerX,
    int playerY,
  ) {
    // Find all reachable cells from player spawn
    final reachable = _floodFill(grid, width, height, playerX, playerY);

    // Find all houses
    final houses = <(int, int)>[];
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (grid[y][x].type == ExploreCellType.house) {
          houses.add((x, y));
        }
      }
    }

    // Check each house and carve path if not reachable
    for (final (hx, hy) in houses) {
      if (!reachable.contains((hx, hy))) {
        // House is not reachable, carve a path to it
        _carvePathToHouse(grid, width, height, playerX, playerY, hx, hy);
      }
    }
  }

  /// Flood fill to find all reachable cells
  Set<(int, int)> _floodFill(
    List<List<ExploreCell>> grid,
    int width,
    int height,
    int startX,
    int startY,
  ) {
    final visited = <(int, int)>{};
    final queue = Queue<(int, int)>();
    queue.add((startX, startY));

    while (queue.isNotEmpty) {
      final (x, y) = queue.removeFirst();
      if (visited.contains((x, y))) continue;
      if (x < 0 || x >= width || y < 0 || y >= height) continue;
      if (!grid[y][x].isWalkable) continue;

      visited.add((x, y));

      queue.add((x + 1, y));
      queue.add((x - 1, y));
      queue.add((x, y + 1));
      queue.add((x, y - 1));
    }

    return visited;
  }

  /// Carve a path from player position to a house
  void _carvePathToHouse(
    List<List<ExploreCell>> grid,
    int width,
    int height,
    int fromX,
    int fromY,
    int toX,
    int toY,
  ) {
    // Simple path carving: move toward target, removing obstacles
    int x = fromX;
    int y = fromY;

    while (x != toX || y != toY) {
      // Move toward target
      if (x < toX) {
        x++;
      } else if (x > toX) {
        x--;
      } else if (y < toY) {
        y++;
      } else if (y > toY) {
        y--;
      }

      // If this cell is an obstacle (mountain/river), clear it
      if (x >= 0 &&
          x < width &&
          y >= 0 &&
          y < height &&
          !grid[y][x].isWalkable &&
          grid[y][x].type != ExploreCellType.house) {
        grid[y][x] = ExploreCell(type: ExploreCellType.blank, x: x, y: y);
      }
    }
  }
}
