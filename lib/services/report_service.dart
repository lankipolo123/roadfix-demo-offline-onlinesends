import 'package:roadfix/services/sqlite_service.dart';
import 'package:roadfix/services/auth_service.dart';
import 'package:roadfix/models/report_model.dart';

class ReportService {
  final SqliteService _db = SqliteService.instance;
  final AuthService _auth = AuthService.instance;

  // =========================
  // SUBMIT REPORT (OFFLINE)
  // =========================
  Future<String?> submitReport({
    required String description,
    required String location,
    required double latitude,
    required double longitude,
    required String reportType,
    required List<String> detections,
    required dynamic imageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final reportId = DateTime.now().millisecondsSinceEpoch.toString();

    final report = ReportModel(
      id: reportId,
      description: description,
      location: location,
      latitude: latitude,
      longitude: longitude,
      imageUrl: [], // local/offline placeholder
      reportType: reportType,
      tags: detections,
      userId: user['id'],
      email: user['email'],
      fullName: user['name'],
      phoneNumber: '',
      reportedAt: DateTime.now(),
    );

    await _db.insert('reports', report.toMap());

    return reportId;
  }

  // =========================
  // GET USER REPORTS
  // =========================
  Future<List<ReportModel>> getUserReports() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final result = await _db.query(
      'reports',
      where: 'userId = ?',
      whereArgs: [user['id']],
      orderBy: 'reportedAt DESC',
    );

    return result.map((data) {
      return ReportModel.fromMap(data, id: data['id']?.toString());
    }).toList();
  }

  // =========================
  // GET SINGLE REPORT
  // =========================
  Future<ReportModel?> getReportById(String id) async {
    final result = await _db.query('reports', where: 'id = ?', whereArgs: [id]);

    if (result.isEmpty) return null;

    return ReportModel.fromMap(
      result.first,
      id: result.first['id']?.toString(),
    );
  }

  // =========================
  // UPDATE STATUS
  // =========================
  Future<void> updateStatus(String reportId, String status) async {
    await _db.update(
      'reports',
      {'status': status},
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }

  // =========================
  // DELETE REPORT
  // =========================
  Future<void> deleteReport(String reportId) async {
    await _db.delete('reports', where: 'id = ?', whereArgs: [reportId]);
  }

  // =========================
  // STREAM: ACCEPTED REPORTS
  // =========================
  Stream<List<ReportModel>> getAcceptedReportsStream({int limit = 5}) async* {
    while (true) {
      final result = await _db.query(
        'reports',
        where: 'status = ?',
        whereArgs: ['accepted'],
        orderBy: 'reportedAt DESC',
        limit: limit,
      );

      yield result.map((data) {
        return ReportModel.fromMap(data, id: data['id']?.toString());
      }).toList();

      await Future.delayed(const Duration(seconds: 2));
    }
  }

  // =========================
  // STREAM: USER REPORT COUNTS (FIXED + CLEAN)
  // =========================
  Stream<Map<String, int>> getUserReportCountsStream() async* {
    while (true) {
      final user = _auth.currentUser;

      if (user == null) {
        yield {'total': 0, 'pending': 0, 'accepted': 0, 'resolved': 0};
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }

      final reports = await _db.query(
        'reports',
        where: 'userId = ?',
        whereArgs: [user['id']],
      );

      int total = reports.length;
      int pending = 0;
      int accepted = 0;
      int resolved = 0;

      for (final r in reports) {
        final status = (r['status'] ?? 'pending').toString().toLowerCase();

        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'accepted':
            accepted++;
            break;
          case 'resolved':
            resolved++;
            break;
        }
      }

      yield {
        'total': total,
        'pending': pending,
        'accepted': accepted,
        'resolved': resolved,
      };

      await Future.delayed(const Duration(seconds: 2));
    }
  }
}
