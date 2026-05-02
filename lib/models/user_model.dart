// lib/models/user_model.dart

class UserModel {
  final String? uid;
  final String fname;
  final String lname;
  final String mi;
  final String email;
  final String contactNumber;
  final String address;
  final bool isActive;
  final String role;
  final String userProfile;

  // offline-safe dates
  final DateTime? joinedAt;

  // TOTP fields
  final bool totpEnabled;
  final String? totpSecret;
  final DateTime? totpEnabledAt;

  final int? lastUpdated;

  const UserModel({
    this.uid,
    required this.fname,
    required this.lname,
    required this.mi,
    required this.email,
    required this.contactNumber,
    required this.address,
    this.isActive = true,
    this.role = 'user',
    this.userProfile = '',
    this.joinedAt,
    this.totpEnabled = false,
    this.totpSecret,
    this.totpEnabledAt,
    this.lastUpdated,
  });

  /// OFFLINE: from Map instead of Firestore
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    int? parsedLastUpdated;

    final rawLast = data['lastUpdated'];
    if (rawLast is int) {
      parsedLastUpdated = rawLast;
    } else if (rawLast is String) {
      parsedLastUpdated = int.tryParse(rawLast);
    }

    return UserModel(
      uid: id,
      fname: data['fname'] ?? '',
      lname: data['lname'] ?? '',
      mi: data['mi'] ?? '',
      email: data['email'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      address: data['address'] ?? '',
      isActive: data['isActive'] ?? true,
      role: data['role'] ?? 'user',
      userProfile: data['userProfile'] ?? '',
      joinedAt: data['joinedAt'] != null
          ? DateTime.tryParse(data['joinedAt'])
          : null,
      totpEnabled: data['totpEnabled'] ?? false,
      totpSecret: data['totpSecret'],
      totpEnabledAt: data['totpEnabledAt'] != null
          ? DateTime.tryParse(data['totpEnabledAt'])
          : null,
      lastUpdated: parsedLastUpdated,
    );
  }

  /// OFFLINE: convert to Map (for SQLite / Hive / local JSON)
  Map<String, dynamic> toMap() {
    return {
      'fname': fname,
      'lname': lname,
      'mi': mi,
      'email': email,
      'contactNumber': contactNumber,
      'address': address,
      'isActive': isActive,
      'role': role,
      'userProfile': userProfile,
      'joinedAt': joinedAt?.toIso8601String(),
      'totpEnabled': totpEnabled,
      'totpSecret': totpSecret,
      'totpEnabledAt': totpEnabledAt?.toIso8601String(),
      'lastUpdated': lastUpdated,
    };
  }

  UserModel copyWith({
    String? uid,
    String? fname,
    String? lname,
    String? mi,
    String? email,
    String? contactNumber,
    String? address,
    bool? isActive,
    String? role,
    String? userProfile,
    DateTime? joinedAt,
    bool? totpEnabled,
    String? totpSecret,
    DateTime? totpEnabledAt,
    int? lastUpdated,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fname: fname ?? this.fname,
      lname: lname ?? this.lname,
      mi: mi ?? this.mi,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      userProfile: userProfile ?? this.userProfile,
      joinedAt: joinedAt ?? this.joinedAt,
      totpEnabled: totpEnabled ?? this.totpEnabled,
      totpSecret: totpSecret ?? this.totpSecret,
      totpEnabledAt: totpEnabledAt ?? this.totpEnabledAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  String get fullName {
    final middle = mi.isNotEmpty ? ' $mi ' : ' ';
    return '$fname$middle$lname'.trim();
  }
}
