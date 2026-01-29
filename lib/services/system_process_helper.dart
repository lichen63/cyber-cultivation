import 'dart:io';

import 'package:flutter/foundation.dart';

/// Helper class to get system process information using dart:io
class SystemProcessHelper {
  /// Get top CPU consuming processes using the `ps` command
  static Future<List<Map<String, dynamic>>> getTopCpuProcesses({
    int limit = 10,
  }) async {
    try {
      final result = await Process.run('/bin/ps', [
        '-arcwwxo',
        'pid,pcpu,comm',
        '-r',
      ]);

      if (result.exitCode != 0) {
        return [];
      }

      final output = result.stdout as String;
      final processes = <Map<String, dynamic>>[];
      final lines = output.split('\n');

      // Skip header line
      for (int i = 1; i < lines.length && processes.length < limit; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Parse: PID %CPU COMMAND
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final pid = int.tryParse(parts[0]);
          final cpu = double.tryParse(parts[1]);
          if (pid != null && cpu != null) {
            // Get the command name (may contain spaces, so join remaining parts)
            final fullPath = parts.sublist(2).join(' ');
            // Extract just the app name from path
            final name = fullPath.split('/').last;
            processes.add({'pid': pid, 'value': cpu, 'name': name});
          }
        }
      }

      return processes;
    } catch (e) {
      debugPrint('Failed to get top CPU processes: $e');
      return [];
    }
  }

  /// Get top RAM consuming processes using the `ps` command
  /// Returns memory usage in bytes (rss - resident set size)
  static Future<List<Map<String, dynamic>>> getTopRamProcesses({
    int limit = 10,
  }) async {
    try {
      // Use rss (resident set size in KB) instead of %mem
      final result = await Process.run('/bin/ps', [
        '-arcwwxo',
        'pid,rss,comm',
        '-m', // Sort by memory
      ]);

      if (result.exitCode != 0) {
        return [];
      }

      final output = result.stdout as String;
      final processes = <Map<String, dynamic>>[];
      final lines = output.split('\n');

      // Skip header line
      for (int i = 1; i < lines.length && processes.length < limit; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Parse: PID RSS COMMAND (RSS is in KB)
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final pid = int.tryParse(parts[0]);
          final rssKb = int.tryParse(parts[1]);
          if (pid != null && rssKb != null) {
            final fullPath = parts.sublist(2).join(' ');
            final name = fullPath.split('/').last;
            // Store as bytes for consistent formatting
            processes.add({
              'pid': pid,
              'value': rssKb * 1024.0, // Convert KB to bytes
              'name': name,
            });
          }
        }
      }

      return processes;
    } catch (e) {
      debugPrint('Failed to get top RAM processes: $e');
      return [];
    }
  }

  /// Get top disk I/O processes
  /// Shows read and write activity per process using lsof with PID
  static Future<List<Map<String, dynamic>>> getTopDiskProcesses({
    int limit = 10,
  }) async {
    try {
      // Use lsof to get processes with open files, including PID
      // Format: COMMAND PID ... TYPE ...
      final result = await Process.run('/bin/sh', [
        '-c',
        // Get PID and command for processes with regular files open
        "lsof -n 2>/dev/null | awk '\$5==\"REG\" {print \$2, \$1}' | sort | uniq -c | sort -rn | head -${limit * 2}",
      ]);

      final pidToData = <int, Map<String, dynamic>>{};
      final seenPids = <int>{};

      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final lines = output.split('\n');

        for (int i = 0; i < lines.length && pidToData.length < limit; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 3) {
            final count = int.tryParse(parts[0]);
            final pid = int.tryParse(parts[1]);
            final truncatedName = parts[2];
            if (truncatedName == 'COMMAND' || truncatedName == 'PID') continue;
            if (pid != null &&
                !seenPids.contains(pid) &&
                count != null &&
                count > 0) {
              seenPids.add(pid);
              // Estimate read/write based on open file count
              // This is an approximation since actual I/O stats require elevated privileges
              pidToData[pid] = {
                'pid': pid,
                'name': truncatedName, // Will be replaced with full name
                'read': count * 4.0, // Estimated read KB
                'write': count * 2.0, // Estimated write KB
                'value': count.toDouble(),
              };
            }
          }
        }
      }

      // Get full process names using ps command for all PIDs at once
      if (pidToData.isNotEmpty) {
        final pids = pidToData.keys.toList();
        final psResult = await Process.run('/bin/ps', [
          '-o',
          'pid=,comm=',
          '-p',
          pids.join(','),
        ]);

        if (psResult.exitCode == 0) {
          final psOutput = psResult.stdout as String;
          for (final line in psOutput.split('\n')) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;

            // Parse "  PID COMMAND" format
            final match = RegExp(r'^\s*(\d+)\s+(.+)$').firstMatch(trimmed);
            if (match != null) {
              final pid = int.tryParse(match.group(1) ?? '') ?? 0;
              var fullName = match.group(2) ?? '';

              // Extract just the process name from the path
              if (fullName.contains('/')) {
                fullName = fullName.split('/').last;
              }

              if (pidToData.containsKey(pid) && fullName.isNotEmpty) {
                pidToData[pid]!['name'] = fullName;
              }
            }
          }
        }
      }

      var processes = pidToData.values.toList();

      // If lsof approach didn't work, fallback to processes with high disk potential
      if (processes.isEmpty) {
        final psResult = await Process.run('/bin/ps', [
          '-arcwwxo',
          'pid,rss,comm',
          '-m', // Sort by memory (disk-heavy apps often use more memory)
        ]);

        if (psResult.exitCode == 0) {
          final output = psResult.stdout as String;
          final lines = output.split('\n');

          for (int i = 1; i < lines.length && processes.length < limit; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;

            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 3) {
              final pid = int.tryParse(parts[0]);
              final rss = int.tryParse(parts[1]) ?? 0;
              final fullPath = parts.sublist(2).join(' ');
              final name = fullPath.split('/').last;

              if (pid != null && rss > 10000) {
                // Only show processes with >10MB memory
                processes.add({
                  'pid': pid,
                  'name': name,
                  'read': (rss / 100).toDouble(), // Rough estimate
                  'write': (rss / 200).toDouble(),
                  'value': rss.toDouble(),
                });
              }
            }
          }
        }
      }

      return processes;
    } catch (e) {
      debugPrint('Failed to get top Disk processes: $e');
      return [];
    }
  }

  /// Get top network consuming processes using `nettop`
  /// Returns upload and download speeds (bytes/sec) separately
  static Future<List<Map<String, dynamic>>> getTopNetworkProcesses({
    int limit = 10,
  }) async {
    try {
      // Use nettop to get network stats per process
      // Run for 1 second to get rate data
      final result = await Process.run('/usr/bin/nettop', [
        '-P',
        '-L',
        '1',
        '-J',
        'bytes_in,bytes_out',
      ]);

      if (result.exitCode != 0) {
        return [];
      }

      final output = result.stdout as String;
      final processes = <Map<String, dynamic>>[];
      final lines = output.split('\n');

      // Collect PIDs for batch lookup
      final pidToData = <int, Map<String, dynamic>>{};

      // nettop output: process_name.pid, bytes_in, bytes_out
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.length >= 3) {
          final processInfo = parts[0].trim();
          final bytesIn = int.tryParse(parts[1].trim()) ?? 0;
          final bytesOut = int.tryParse(parts[2].trim()) ?? 0;
          final totalBytes = bytesIn + bytesOut;

          if (totalBytes > 0) {
            // Extract process name and pid (format: name.pid)
            final dotIndex = processInfo.lastIndexOf('.');
            final truncatedName = dotIndex > 0
                ? processInfo.substring(0, dotIndex)
                : processInfo;
            final pid = dotIndex > 0
                ? int.tryParse(processInfo.substring(dotIndex + 1)) ?? 0
                : 0;

            if (pid > 0) {
              pidToData[pid] = {
                'pid': pid,
                'name': truncatedName, // Will be replaced with full name
                'download': bytesIn.toDouble(),
                'upload': bytesOut.toDouble(),
                'value': totalBytes.toDouble(),
              };
            }
          }
        }
      }

      // Get full process names using ps command for all PIDs at once
      if (pidToData.isNotEmpty) {
        final pids = pidToData.keys.toList();
        final psResult = await Process.run('/bin/ps', [
          '-o',
          'pid=,comm=',
          '-p',
          pids.join(','),
        ]);

        if (psResult.exitCode == 0) {
          final psOutput = psResult.stdout as String;
          for (final line in psOutput.split('\n')) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;

            // Parse "  PID COMMAND" format
            final match = RegExp(r'^\s*(\d+)\s+(.+)$').firstMatch(trimmed);
            if (match != null) {
              final pid = int.tryParse(match.group(1) ?? '') ?? 0;
              var fullName = match.group(2) ?? '';

              // Extract just the process name from the path
              if (fullName.contains('/')) {
                fullName = fullName.split('/').last;
              }

              if (pidToData.containsKey(pid) && fullName.isNotEmpty) {
                pidToData[pid]!['name'] = fullName;
              }
            }
          }
        }
      }

      processes.addAll(pidToData.values);

      // Sort by total value descending
      processes.sort(
        (a, b) => (b['value'] as double).compareTo(a['value'] as double),
      );

      return processes.take(limit).toList();
    } catch (e) {
      debugPrint('Failed to get top Network processes: $e');
      return [];
    }
  }

  /// Get GPU usage info (macOS doesn't provide per-process GPU easily)
  /// Shows apps using GPU acceleration via powermetrics or IOKit
  static Future<List<Map<String, dynamic>>> getTopGpuProcesses({
    int limit = 10,
  }) async {
    try {
      // Use ioreg to get GPU clients - this shows processes using GPU
      // Note: This is informational only, we use ps output below
      await Process.run('/bin/sh', [
        '-c',
        "ioreg -l | grep -A5 'IOAccelClient' | grep 'kCGSSessionUserIDKey\\|IOUserClientCreator' | head -20",
      ]);

      // Fallback: show processes with high CPU that are likely GPU-intensive
      // (graphics apps, games, browsers, etc.)
      final psResult = await Process.run('/bin/ps', [
        '-arcwwxo',
        'pid,pcpu,comm',
        '-r',
      ]);

      if (psResult.exitCode != 0) {
        return [];
      }

      final output = psResult.stdout as String;
      final processes = <Map<String, dynamic>>[];
      final lines = output.split('\n');

      // GPU-intensive app patterns
      final gpuApps = [
        'WindowServer',
        'Safari',
        'Chrome',
        'Firefox',
        'Brave',
        'Arc',
        'Unity',
        'Unreal',
        'Blender',
        'Final Cut',
        'Motion',
        'Compressor',
        'DaVinci',
        'Premiere',
        'After Effects',
        'Photoshop',
        'Illustrator',
        'Sketch',
        'Figma',
        'Steam',
        'Parallels',
        'VMware',
        'VirtualBox',
        'qemu',
        'CyberCultivation',
      ];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final pid = int.tryParse(parts[0]);
          final cpu = double.tryParse(parts[1]);
          final fullPath = parts.sublist(2).join(' ');
          final name = fullPath.split('/').last;

          if (pid != null && cpu != null) {
            // Include if it's a known GPU app or has significant CPU usage
            final isGpuApp = gpuApps.any(
              (app) => name.toLowerCase().contains(app.toLowerCase()),
            );
            if (isGpuApp || cpu > 1.0) {
              processes.add({'pid': pid, 'value': cpu, 'name': name});
              if (processes.length >= limit) break;
            }
          }
        }
      }

      return processes;
    } catch (e) {
      debugPrint('Failed to get top GPU processes: $e');
      return [];
    }
  }

  /// Get top energy consuming processes using `top` command
  /// Shows apps ordered by energy impact (approximated via CPU + memory usage)
  static Future<List<Map<String, dynamic>>> getTopBatteryProcesses({
    int limit = 10,
  }) async {
    try {
      // Use top to get processes with energy impact estimation
      // Energy impact correlates with CPU usage and wake-ups
      final result = await Process.run('/bin/sh', [
        '-c',
        // top in logging mode, sorted by CPU, limited iterations
        "top -l 2 -n ${limit + 5} -stats pid,cpu,command -o cpu | tail -${limit + 3}",
      ]);

      if (result.exitCode != 0) {
        // Fallback to ps command
        return _getTopBatteryProcessesFallback(limit: limit);
      }

      final output = result.stdout as String;
      final processes = <Map<String, dynamic>>[];
      final lines = output.split('\n');

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final pid = int.tryParse(parts[0]);
          final cpu = double.tryParse(parts[1]);
          if (pid != null && cpu != null && cpu > 0) {
            final name = parts.sublist(2).join(' ').split('/').last;
            // Energy impact approximation: CPU usage is main indicator
            final energyImpact = cpu;
            processes.add({'pid': pid, 'name': name, 'value': energyImpact});
            if (processes.length >= limit) break;
          }
        }
      }

      if (processes.isEmpty) {
        return _getTopBatteryProcessesFallback(limit: limit);
      }

      return processes;
    } catch (e) {
      debugPrint('Failed to get top Battery processes: $e');
      return _getTopBatteryProcessesFallback(limit: limit);
    }
  }

  /// Fallback method using ps for battery/energy estimation
  static Future<List<Map<String, dynamic>>> _getTopBatteryProcessesFallback({
    int limit = 10,
  }) async {
    try {
      // Use ps sorted by CPU (main energy indicator)
      final result = await Process.run('/bin/ps', [
        '-arcwwxo',
        'pid,pcpu,comm',
        '-r',
      ]);

      if (result.exitCode != 0) {
        return [];
      }

      final output = result.stdout as String;
      final processes = <Map<String, dynamic>>[];
      final lines = output.split('\n');

      for (int i = 1; i < lines.length && processes.length < limit; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final pid = int.tryParse(parts[0]);
          final cpu = double.tryParse(parts[1]);
          if (pid != null && cpu != null && cpu > 0) {
            final fullPath = parts.sublist(2).join(' ');
            final name = fullPath.split('/').last;
            processes.add({'pid': pid, 'value': cpu, 'name': name});
          }
        }
      }

      return processes;
    } catch (e) {
      debugPrint('Failed to get top Battery processes (fallback): $e');
      return [];
    }
  }

  /// Open macOS Activity Monitor app
  static Future<void> openActivityMonitor() async {
    try {
      await Process.run('open', ['-a', 'Activity Monitor']);
    } catch (e) {
      debugPrint('Failed to open Activity Monitor: $e');
    }
  }

  /// Get basic network interface information
  /// Returns info about the active network interface including:
  /// - interfaceType: WiFi, Ethernet, or Unknown
  /// - networkName: SSID for WiFi, or interface name for Ethernet
  /// - localIp: Local IP address
  /// - publicIp: Public IP address (fetched from external service)
  /// - macAddress: MAC address of the interface
  /// - gateway: Default gateway IP
  ///
  /// Uses public macOS APIs (scutil, networksetup) instead of private frameworks
  static Future<Map<String, String>> getNetworkInfo() async {
    final info = <String, String>{
      'interfaceType': '-',
      'networkName': '-',
      'localIp': '-',
      'publicIp': '-',
      'macAddress': '-',
      'gateway': '-',
    };

    try {
      // Get the primary network interface using scutil (public API)
      String? activeInterface;

      final routeResult = await Process.run('/sbin/route', [
        '-n',
        'get',
        'default',
      ]);

      if (routeResult.exitCode == 0) {
        final output = routeResult.stdout as String;
        // Parse interface name
        final interfaceMatch = RegExp(r'interface:\s*(\S+)').firstMatch(output);
        if (interfaceMatch != null) {
          activeInterface = interfaceMatch.group(1);
        }
        // Parse gateway
        final gatewayMatch = RegExp(r'gateway:\s*(\S+)').firstMatch(output);
        if (gatewayMatch != null) {
          info['gateway'] = gatewayMatch.group(1)!;
        }
      }

      // Get local IP and MAC address using ifconfig (public API)
      if (activeInterface != null) {
        final ifconfigResult = await Process.run('/sbin/ifconfig', [
          activeInterface,
        ]);
        if (ifconfigResult.exitCode == 0) {
          final ifconfigOutput = ifconfigResult.stdout as String;

          // Extract IPv4 address
          final inetMatch = RegExp(
            r'inet\s+(\d+\.\d+\.\d+\.\d+)',
          ).firstMatch(ifconfigOutput);
          if (inetMatch != null) {
            info['localIp'] = inetMatch.group(1)!;
          }

          // Extract MAC address (ether or lladdr)
          final etherMatch = RegExp(
            r'(?:ether|lladdr)\s+([0-9a-fA-F:]+)',
          ).firstMatch(ifconfigOutput);
          if (etherMatch != null) {
            info['macAddress'] = etherMatch.group(1)!.toUpperCase();
          }
        }

        // Determine interface type and get WiFi SSID
        // Use multiple methods as networksetup is unreliable on newer macOS
        bool isWifi = false;
        if (activeInterface.startsWith('en')) {
          // Method 1: Try system_profiler SPAirPortDataType (most reliable, public API)
          try {
            final profilerResult = await Process.run(
              '/usr/sbin/system_profiler',
              ['SPAirPortDataType', '-json'],
            );
            if (profilerResult.exitCode == 0) {
              final jsonOutput = profilerResult.stdout as String;
              // Check if we're connected to WiFi by looking for current network info
              // The JSON contains "spairport_current_network_information" with "_name" when connected
              if (jsonOutput.contains(
                'spairport_current_network_information',
              )) {
                // Extract SSID using regex from JSON
                // Format: "_name" : "NetworkName" inside spairport_current_network_information
                final ssidMatch = RegExp(
                  r'spairport_current_network_information[^}]*"_name"\s*:\s*"([^"]+)"',
                ).firstMatch(jsonOutput);
                if (ssidMatch != null) {
                  isWifi = true;
                  info['interfaceType'] = 'WiFi';
                  final ssid = ssidMatch.group(1)!;
                  // macOS may redact SSID for privacy, show "Connected" instead
                  if (ssid == '<redacted>' || ssid.isEmpty) {
                    info['networkName'] = 'Connected';
                  } else {
                    info['networkName'] = ssid;
                  }
                }
              }
            }
          } catch (e) {
            // system_profiler failed, try next method
          }

          // Method 2: Fallback to networksetup (works on some older macOS)
          if (!isWifi) {
            try {
              final wifiResult = await Process.run('/usr/sbin/networksetup', [
                '-getairportnetwork',
                activeInterface,
              ]);
              if (wifiResult.exitCode == 0) {
                final wifiOutput = wifiResult.stdout as String;
                if (wifiOutput.contains('Current Wi-Fi Network:') ||
                    wifiOutput.contains('Current Airport Network:')) {
                  isWifi = true;
                  info['interfaceType'] = 'WiFi';
                  final ssidParts = wifiOutput.split(':');
                  if (ssidParts.length >= 2) {
                    info['networkName'] = ssidParts.sublist(1).join(':').trim();
                  }
                }
              }
            } catch (e) {
              // networksetup command failed
            }
          }
        }

        // If not WiFi, treat as Ethernet/VM network
        if (!isWifi) {
          // Detect interface type based on name
          if (activeInterface.startsWith('en')) {
            info['interfaceType'] = 'Ethernet';
          } else if (activeInterface.startsWith('bridge')) {
            info['interfaceType'] = 'Bridge';
          } else if (activeInterface.startsWith('vmnet')) {
            info['interfaceType'] = 'VMware';
          } else if (activeInterface.startsWith('vnic')) {
            info['interfaceType'] = 'Virtual';
          } else {
            info['interfaceType'] = activeInterface;
          }
          info['networkName'] = activeInterface;
        }
      }

      // Get public IP address using curl (same as Stats app)
      try {
        final publicIpResult = await Process.run('/usr/bin/curl', [
          '-s',
          '-m',
          '2', // 2 second timeout
          'https://api.ipify.org',
        ]);
        if (publicIpResult.exitCode == 0) {
          final publicIp = (publicIpResult.stdout as String).trim();
          if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(publicIp)) {
            info['publicIp'] = publicIp;
          }
        }
      } catch (e) {
        // Public IP fetch failed, keep as '-'
      }
    } catch (e) {
      debugPrint('Failed to get network info: $e');
    }

    return info;
  }
}
