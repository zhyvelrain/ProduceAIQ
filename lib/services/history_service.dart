import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting and retrieving scan history.
class HistoryService {
  HistoryService._();
  static final HistoryService instance = HistoryService._();

  static const _prefsKey = 'scan_history_v1';
  static const _maxHistoryItems = 50;

  /// Load scan history from SharedPreferences.
  Future<List<ScanHistoryItem>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString == null || jsonString.isEmpty) return [];
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded
          .map((e) => ScanHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Save scan history to SharedPreferences.
  Future<void> _save(List<ScanHistoryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(
        items.take(_maxHistoryItems).map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_prefsKey, jsonString);
    } catch (_) {
      // Non-fatal: history persists for this session.
    }
  }

  /// Add a new scan to history (most recent first).
  Future<void> add(ScanHistoryItem item) async {
    final history = await load();
    history.insert(0, item);
    await _save(history);
  }

  /// Remove a scan from history by ID.
  Future<void> remove(String id) async {
    final history = await load();
    history.removeWhere((item) => item.id == id);
    await _save(history);
  }

  /// Clear all history.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}

/// Represents a single scan history entry.
class ScanHistoryItem {
  final String id;
  final String produceId;
  final String produceName;
  final double? confidence;
  final String? freshnessGrade;
  final String? imagePath;
  final DateTime timestamp;

  ScanHistoryItem({
    required this.id,
    required this.produceId,
    required this.produceName,
    this.confidence,
    this.freshnessGrade,
    this.imagePath,
    required this.timestamp,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id: json['id'] as String,
      produceId: json['produceId'] as String,
      produceName: json['produceName'] as String,
      confidence: (json['confidence'] as num?)?.toDouble(),
      freshnessGrade: json['freshnessGrade'] as String?,
      imagePath: json['imagePath'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produceId': produceId,
      'produceName': produceName,
      'confidence': confidence,
      'freshnessGrade': freshnessGrade,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}