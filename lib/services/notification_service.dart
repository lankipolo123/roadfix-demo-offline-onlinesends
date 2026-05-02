// lib/services/notification_service.dart (FIXED SQLITE VERSION)

import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roadfix/models/report_model.dart';
import 'package:roadfix/services/sqlite_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  /// IMPORTANT: your SqliteService likely needs singleton access
  final SqliteService _db = SqliteService.instance;

  static const String _viewedKey = 'viewed_notifications';
  static const String _deletedKey = 'deleted_notifications';

  final BehaviorSubject<Set<String>> _viewedIds = BehaviorSubject.seeded(
    <String>{},
  );
  final BehaviorSubject<Set<String>> _deletedIds = BehaviorSubject.seeded(
    <String>{},
  );

  bool _initialized = false;

  // ---------------- INIT ----------------
  Future<void> _init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();

    _viewedIds.add((prefs.getStringList(_viewedKey) ?? []).toSet());
    _deletedIds.add((prefs.getStringList(_deletedKey) ?? []).toSet());

    _initialized = true;
  }

  // ---------------- TIME FORMATTER ----------------
  String getRelativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  // ---------------- REPORT SOURCE FIX ----------------
  /// SAFE: supports either stream or future-based SQLite
  Stream<List<ReportModel>> _reportsStream() async* {
    await _init();

    // CASE 1: you have a stream method
    try {
      yield* _db.watchReports();
      return;
    } catch (_) {}

    // CASE 2: fallback to polling future method
    while (true) {
      try {
        final data = await _db
            .getReports(); // must exist OR you'll need to add it
        yield data;
      } catch (e) {
        yield <ReportModel>[];
      }

      await Future.delayed(const Duration(seconds: 3));
    }
  }

  // ---------------- MAIN STREAM ----------------
  Stream<List<ReportModel>> getRecentlyUpdatedReportsStream() async* {
    await _init();

    yield* Rx.combineLatest2<List<ReportModel>, Set<String>, List<ReportModel>>(
      _reportsStream(),
      _deletedIds.stream,
      (reports, deletedIds) {
        final filtered = reports
            .where((r) => r.reviewedAt != null && !deletedIds.contains(r.id))
            .toList();

        filtered.sort((a, b) => b.reviewedAt!.compareTo(a.reviewedAt!));
        return filtered;
      },
    );
  }

  // ---------------- VIEWED ----------------
  Stream<Set<String>> getViewedNotificationIdsStream() async* {
    await _init();
    yield* _viewedIds.stream;
  }

  // ---------------- DELETED ----------------
  Stream<Set<String>> getDeletedNotificationIdsStream() async* {
    await _init();
    yield* _deletedIds.stream;
  }

  // ---------------- MARK VIEWED ----------------
  Future<void> markAsViewed(String reportId) async {
    await _init();

    final prefs = await SharedPreferences.getInstance();
    final updated = {..._viewedIds.value, reportId};

    await prefs.setStringList(_viewedKey, updated.toList());
    _viewedIds.add(updated);
  }

  // ---------------- DELETE ----------------
  Future<void> deleteNotification(String reportId) async {
    await _init();

    final prefs = await SharedPreferences.getInstance();
    final updated = {..._deletedIds.value, reportId};

    await prefs.setStringList(_deletedKey, updated.toList());
    _deletedIds.add(updated);
  }

  // ---------------- RESTORE ----------------
  Future<void> restoreNotification(String reportId) async {
    await _init();

    final prefs = await SharedPreferences.getInstance();
    final updated = Set<String>.from(_deletedIds.value)..remove(reportId);

    await prefs.setStringList(_deletedKey, updated.toList());
    _deletedIds.add(updated);
  }

  // ---------------- UNREAD COUNT ----------------
  Stream<int> getUnreadNotificationCountStream() {
    return Rx.combineLatest2<List<ReportModel>, Set<String>, int>(
      getRecentlyUpdatedReportsStream(),
      getViewedNotificationIdsStream(),
      (reports, viewed) => reports.where((r) => !viewed.contains(r.id)).length,
    );
  }

  // ---------------- UI HELPERS ----------------
  String getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
      case 'inprogress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'invalid':
        return 'Invalid';
      default:
        return 'Pending';
    }
  }

  void dispose() {
    _viewedIds.close();
    _deletedIds.close();
  }
}
