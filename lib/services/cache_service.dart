import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  static CacheService get instance => _instance;
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache configuration
  static const Duration defaultCacheDuration = Duration(minutes: 15);
  static const Duration shortCacheDuration = Duration(minutes: 5);
  static const Duration longCacheDuration = Duration(hours: 1);
  static const int maxMemoryCacheSize = 100;

  // Initialize the cache service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      Logger.info('Cache service initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize cache service: $e');
    }
  }

  // Memory cache operations
  void setMemoryCache(String key, dynamic value, {Duration? duration}) {
    try {
      // Manage cache size
      if (_memoryCache.length >= maxMemoryCacheSize) {
        _evictOldestMemoryCache();
      }
      
      _memoryCache[key] = value;
      _cacheTimestamps[key] = DateTime.now();
      
      Logger.debug('Cached data in memory for key: $key');
    } catch (e) {
      Logger.error('Failed to set memory cache for key $key: $e');
    }
  }

  T? getMemoryCache<T>(String key, {Duration? duration}) {
    try {
      final timestamp = _cacheTimestamps[key];
      if (timestamp == null) return null;
      
      final cacheDuration = duration ?? defaultCacheDuration;
      if (DateTime.now().difference(timestamp) > cacheDuration) {
        _removeMemoryCache(key);
        return null;
      }
      
      final value = _memoryCache[key];
      Logger.debug('Retrieved cached data from memory for key: $key');
      return value as T?;
    } catch (e) {
      Logger.error('Failed to get memory cache for key $key: $e');
      return null;
    }
  }

  void _removeMemoryCache(String key) {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  void _evictOldestMemoryCache() {
    if (_cacheTimestamps.isEmpty) return;
    
    final oldestKey = _cacheTimestamps.entries
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key;
    
    _removeMemoryCache(oldestKey);
    Logger.debug('Evicted oldest cache entry: $oldestKey');
  }

  // Persistent cache operations
  Future<void> setPersistentCache(String key, dynamic value, {Duration? duration}) async {
    if (_prefs == null) return;
    
    try {
      final cacheData = {
        'value': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'duration': (duration ?? defaultCacheDuration).inMilliseconds,
      };
      
      await _prefs!.setString(key, jsonEncode(cacheData));
      Logger.debug('Cached data persistently for key: $key');
    } catch (e) {
      Logger.error('Failed to set persistent cache for key $key: $e');
    }
  }

  Future<T?> getPersistentCache<T>(String key) async {
    if (_prefs == null) return null;
    
    try {
      final cachedString = _prefs!.getString(key);
      if (cachedString == null) return null;
      
      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
      final duration = Duration(milliseconds: cacheData['duration']);
      
      if (DateTime.now().difference(timestamp) > duration) {
        await _prefs!.remove(key);
        return null;
      }
      
      Logger.debug('Retrieved cached data persistently for key: $key');
      return cacheData['value'] as T?;
    } catch (e) {
      Logger.error('Failed to get persistent cache for key $key: $e');
      return null;
    }
  }

  // Combined cache operations (memory first, then persistent)
  Future<void> setCache(String key, dynamic value, {Duration? duration, bool persistentOnly = false}) async {
    if (!persistentOnly) {
      setMemoryCache(key, value, duration: duration);
    }
    await setPersistentCache(key, value, duration: duration);
  }

  Future<T?> getCache<T>(String key, {Duration? duration}) async {
    // Try memory cache first
    final memoryResult = getMemoryCache<T>(key, duration: duration);
    if (memoryResult != null) {
      return memoryResult;
    }
    
    // Fall back to persistent cache
    final persistentResult = await getPersistentCache<T>(key);
    if (persistentResult != null) {
      // Restore to memory cache
      setMemoryCache(key, persistentResult, duration: duration);
    }
    
    return persistentResult;
  }

  // Cache invalidation
  Future<void> invalidateCache(String key) async {
    _removeMemoryCache(key);
    if (_prefs != null) {
      await _prefs!.remove(key);
    }
    Logger.debug('Invalidated cache for key: $key');
  }

  Future<void> invalidateCacheByPattern(String pattern) async {
    final regex = RegExp(pattern);
    
    // Clear memory cache
    final memoryKeysToRemove = _memoryCache.keys.where((key) => regex.hasMatch(key)).toList();
    for (final key in memoryKeysToRemove) {
      _removeMemoryCache(key);
    }
    
    // Clear persistent cache
    if (_prefs != null) {
      final persistentKeys = _prefs!.getKeys();
      final persistentKeysToRemove = persistentKeys.where((key) => regex.hasMatch(key)).toList();
      for (final key in persistentKeysToRemove) {
        await _prefs!.remove(key);
      }
    }
    
    Logger.debug('Invalidated cache entries matching pattern: $pattern');
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    
    if (_prefs != null) {
      await _prefs!.clear();
    }
    
    Logger.info('Cleared all cache data');
  }

  // Cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'memory_cache_size': _memoryCache.length,
      'memory_cache_keys': _memoryCache.keys.toList(),
      'persistent_cache_keys': _prefs?.getKeys().toList() ?? [],
      'max_memory_cache_size': maxMemoryCacheSize,
    };
  }

  // Utility methods for common cache keys
  static String userCacheKey(String userId) => 'user_$userId';
  static String usersCacheKey() => 'users_list';
  static String destinationCacheKey(String destinationId) => 'destination_$destinationId';
  static String destinationsCacheKey() => 'destinations_list';
  static String postCacheKey(String postId) => 'post_$postId';
  static String postsCacheKey() => 'posts_list';
  static String conversationCacheKey(String conversationId) => 'conversation_$conversationId';
  static String conversationsCacheKey(String userId) => 'conversations_$userId';
  static String messagesCacheKey(String conversationId) => 'messages_$conversationId';
}