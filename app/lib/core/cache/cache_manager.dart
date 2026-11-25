import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheEntry {
  final dynamic data;
  final int timestamp;

  CacheEntry({required this.data, required this.timestamp});
}

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // L1: In-memory LRU cache
  final Map<String, CacheEntry> _memCache = {};
  static const int maxMemEntries = 200;

  // Single-flight in-flight request dedup
  final Map<String, Future<dynamic>> _inFlightRequests = {};

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Get data from L1 (Memory) or L2 (Disk)
  dynamic get(String key, {Duration maxAge = const Duration(minutes: 15)}) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Check L1 memory cache
    final mem = _memCache[key];
    if (mem != null) {
      if (now - mem.timestamp < maxAge.inMilliseconds) {
        return mem.data;
      }
    }

    // 2. Check L2 disk cache (skipped on Web to avoid localStorage 5MB quota & sync JSON stalls)
    if (!kIsWeb && _prefs != null) {
      final diskStr = _prefs!.getString('cache_$key');
      if (diskStr != null) {
        try {
          final decoded = jsonDecode(diskStr);
          final timestamp = decoded['ts'] as int? ?? 0;
          if (now - timestamp < maxAge.inMilliseconds) {
            final data = decoded['data'];
            // Elevate back to L1
            _setMem(key, data, timestamp);
            return data;
          }
        } catch (e) {
          debugPrint('Cache decode error: $e');
        }
      }
    }

    return null;
  }

  // Stale-While-Revalidate: get stale data if available, regardless of expiry
  dynamic getStale(String key) {
    final mem = _memCache[key];
    if (mem != null) return mem.data;

    if (!kIsWeb && _prefs != null) {
      final diskStr = _prefs!.getString('cache_$key');
      if (diskStr != null) {
        try {
          final decoded = jsonDecode(diskStr);
          final data = decoded['data'];
          _setMem(key, data, decoded['ts'] ?? 0);
          return data;
        } catch (_) {}
      }
    }
    return null;
  }

  // Save data to L1 and asynchronously to L2 on native platforms
  void set(String key, dynamic data) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _setMem(key, data, now);

    // Write to disk on native platforms without blocking Web localStorage
    if (!kIsWeb && _prefs != null) {
      try {
        final payload = jsonEncode({'ts': now, 'data': data});
        _prefs!.setString('cache_$key', payload);
      } catch (e) {
        debugPrint('Cache write error: $e');
      }
    }
  }

  void _setMem(String key, dynamic data, int timestamp) {
    if (_memCache.length >= maxMemEntries) {
      _memCache.remove(_memCache.keys.first);
    }
    _memCache[key] = CacheEntry(data: data, timestamp: timestamp);
  }

  // Single-flight deduplication: ensures multiple concurrent callers share 1 network call
  Future<T> dedup<T>(String key, Future<T> Function() fetcher) async {
    if (_inFlightRequests.containsKey(key)) {
      return await _inFlightRequests[key] as T;
    }

    final future = fetcher();
    _inFlightRequests[key] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _inFlightRequests.remove(key);
    }
  }

  void clear() {
    _memCache.clear();
    _prefs?.clear();
  }
}
