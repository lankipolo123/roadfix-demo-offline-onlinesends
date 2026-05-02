// lib/services/auth_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:roadfix/models/user_model.dart';

class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  Database? _db;

  Map<String, dynamic>? _currentUser;

  // =========================
  // INIT DATABASE
  // =========================
  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'roadfix.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            fname TEXT,
            lname TEXT,
            mi TEXT,
            email TEXT UNIQUE,
            password TEXT,
            contactNumber TEXT,
            address TEXT,
            isActive INTEGER,
            role TEXT
          )
        ''');
      },
    );
  }

  // =========================
  // STATE
  // =========================
  Map<String, dynamic>? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  String? get currentEmail => _currentUser?['email'];

  // =========================
  // SIGN UP
  // =========================
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required UserModel userData,
  }) async {
    final db = _db!;

    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (existing.isNotEmpty) {
      return {"success": false, "message": "User already exists"};
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('users', {
      'id': id,
      'fname': userData.fname,
      'lname': userData.lname,
      'mi': userData.mi,
      'email': email,
      'password': password,
      'contactNumber': userData.contactNumber,
      'address': userData.address,
      'isActive': 1,
      'role': 'user',
    });

    _currentUser = {
      'id': id,
      'email': email,
      'name': '${userData.fname} ${userData.lname}',
    };

    return {"success": true, "message": "Account created"};
  }

  // =========================
  // SIGN IN
  // =========================
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final db = _db!;

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isEmpty) {
      return {"success": false, "message": "Invalid credentials"};
    }

    final user = result.first;

    _currentUser = {
      'id': user['id'],
      'email': user['email'],
      'name': '${user['fname']} ${user['lname']}',
    };

    return {
      "success": true,
      "message": "Login successful",
      "user": _currentUser,
    };
  }

  // =========================
  // CHANGE EMAIL
  // =========================
  Future<String?> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final db = _db!;

    if (_currentUser == null) {
      return 'No logged in user';
    }

    final currentUserResult = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [_currentUser!['id']],
    );

    if (currentUserResult.isEmpty) {
      return 'User not found';
    }

    final currentUserData = currentUserResult.first;

    if (currentUserData['password'] != currentPassword) {
      return 'Incorrect password';
    }

    final existingEmail = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [newEmail],
    );

    if (existingEmail.isNotEmpty) {
      return 'Email already exists';
    }

    await db.update(
      'users',
      {'email': newEmail},
      where: 'id = ?',
      whereArgs: [_currentUser!['id']],
    );

    _currentUser = {..._currentUser!, 'email': newEmail};

    return null;
  }

  // =========================
  // CHANGE PASSWORD
  // =========================
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final db = _db!;

    if (_currentUser == null) {
      return 'No logged in user';
    }

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [_currentUser!['id']],
    );

    if (result.isEmpty) {
      return 'User not found';
    }

    final user = result.first;

    if (user['password'] != currentPassword) {
      return 'Incorrect current password';
    }

    await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [_currentUser!['id']],
    );

    return null;
  }

  // =========================
  // SIGN OUT
  // =========================
  Future<void> signOut() async {
    _currentUser = null;
  }

  // =========================
  // RESET PASSWORD (MOCK)
  // =========================
  Future<String?> resetPassword(String email) async {
    final db = _db!;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isEmpty) {
      return "Email not found";
    }

    return null;
  }

  // =========================
  // EMAIL VERIFICATION (MOCK)
  // =========================
  Future<String?> checkEmailVerificationAndActivate() async {
    return null;
  }

  Future<String?> resendEmailVerification() async {
    return null;
  }
}
