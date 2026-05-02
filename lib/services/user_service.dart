import 'package:roadfix/models/user_model.dart';
import 'package:roadfix/services/auth_service.dart';
import 'package:roadfix/services/sqlite_service.dart';

class UserService {
  final AuthService _authService = AuthService.instance;
  final SqliteService _sqlite = SqliteService.instance;

  UserModel? _cachedUser;
  int? _cacheTimestamp;

  static const Duration _cacheDuration = Duration(seconds: 5);

  // =========================
  // GET CURRENT USER (WITH CACHE)
  // =========================
  Future<UserModel?> getCurrentUser() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // ✅ return cache if still valid
      if (_cachedUser != null &&
          _cacheTimestamp != null &&
          now - _cacheTimestamp! < _cacheDuration.inMilliseconds) {
        return _cachedUser;
      }

      final user = _authService.currentUser;
      if (user == null) return null;

      final freshUser = UserModel(
        uid: user['id'],
        fname: '',
        lname: '',
        mi: '',
        email: user['email'],
        contactNumber: '',
        address: '',
        totpEnabled: (user['totpEnabled'] ?? 0) == 1,
        totpSecret: user['totpSecret'],
      );

      // cache it
      _cachedUser = freshUser;
      _cacheTimestamp = now;

      return freshUser;
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  // =========================
  // STREAM (SAFE VERSION)
  // =========================
  Stream<UserModel?> getCurrentUserStream() async* {
    while (true) {
      yield await getCurrentUser();
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  // =========================
  // UPDATE PROFILE
  // =========================
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? middleInitial,
    String? contactNumber,
    String? address,
    String? userProfile,
    int? lastUpdated,
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception("No user logged in");

    await _sqlite.update(
      'users',
      {
        'fname': firstName,
        'lname': lastName,
        'mi': middleInitial,
        'contactNumber': contactNumber,
        'address': address,
        'userProfile': userProfile,
        'lastUpdated': lastUpdated ?? DateTime.now().millisecondsSinceEpoch,
      }..removeWhere((key, value) => value == null),
      where: 'uid = ?',
      whereArgs: [user['id']],
    );

    // 🔥 invalidate cache after update
    clearCache();
  }

  // =========================
  // USER NAME
  // =========================
  Future<String> getCurrentUserName() async {
    final user = await getCurrentUser();
    return user?.email ?? 'User';
  }

  // =========================
  // PROFILE CHECK
  // =========================
  Future<bool> isProfileComplete() async {
    final user = await getCurrentUser();
    return user != null;
  }

  // =========================
  // CACHE CONTROL
  // =========================
  void clearCache() {
    _cachedUser = null;
    _cacheTimestamp = null;
  }

  // =========================
  // TOTP ENABLE
  // =========================
  Future<void> enableTotp(String uid, String secret) async {
    await _sqlite.update(
      'users',
      {'totpEnabled': 1, 'totpSecret': secret},
      where: 'uid = ?',
      whereArgs: [uid],
    );

    clearCache();
  }

  // =========================
  // TOTP DISABLE
  // =========================
  Future<void> disableTotp(String uid) async {
    await _sqlite.update(
      'users',
      {'totpEnabled': 0, 'totpSecret': null},
      where: 'uid = ?',
      whereArgs: [uid],
    );

    clearCache();
  }
}
