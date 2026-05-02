class ReportModel {
  final String? id;
  final String description;
  final String location;

  final double? latitude;
  final double? longitude;

  final List<String> imageUrl;
  final String reportType;
  final List<String> tags;

  final String userId;
  final String email;
  final String fullName;
  final String phoneNumber;

  final DateTime reportedAt;

  final String status;
  final String adminNotes;
  final String reviewedBy;
  final DateTime? reviewedAt;

  final String priority;
  final bool isRead;

  final String? resolvedImageUrl;
  final List<String> resolvedImages;

  final String? completionNotes;
  final DateTime? completionImageUploadedAt;

  const ReportModel({
    this.id,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    required this.imageUrl,
    required this.reportType,
    required this.tags,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.reportedAt,
    this.status = ReportStatus.pending,
    this.adminNotes = '',
    this.reviewedBy = '',
    this.reviewedAt,
    this.priority = ReportPriority.medium,
    this.isRead = false,
    this.resolvedImageUrl,
    this.resolvedImages = const [],
    this.completionNotes,
    this.completionImageUploadedAt,
  });

  // =========================
  // FROM MAP (OFFLINE)
  // =========================

  factory ReportModel.fromMap(Map<String, dynamic> data, {String? id}) {
    List<String> tagsList = [];
    final tagsData = data['tags'];
    if (tagsData is List) {
      tagsList = List<String>.from(tagsData);
    }

    List<String> imageList = [];
    final imageData = data['imageUrl'];
    if (imageData is List) {
      imageList = List<String>.from(imageData);
    } else if (imageData is String && imageData.isNotEmpty) {
      imageList = [imageData];
    }

    List<String> resolvedList = [];
    final resolvedData = data['resolvedImages'];
    if (resolvedData is List) {
      resolvedList = List<String>.from(resolvedData);
    } else if (data['resolvedImageUrl'] is String) {
      resolvedList = [data['resolvedImageUrl']];
    }

    return ReportModel(
      id: id,
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      imageUrl: imageList,
      reportType: data['reportType'] ?? '',
      tags: tagsList,
      userId: data['userId'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      reportedAt: data['reportedAt'] != null
          ? DateTime.parse(data['reportedAt'])
          : DateTime.now(),
      status: data['status'] ?? ReportStatus.pending,
      adminNotes: data['adminNotes'] ?? '',
      reviewedBy: data['reviewedBy'] ?? '',
      reviewedAt: data['reviewedAt'] != null
          ? DateTime.parse(data['reviewedAt'])
          : null,
      priority: data['priority'] ?? ReportPriority.medium,
      isRead: data['isRead'] ?? false,
      resolvedImageUrl: data['resolvedImageUrl'],
      resolvedImages: resolvedList,
      completionNotes: data['completionNotes'],
      completionImageUploadedAt: data['completionImageUploadedAt'] != null
          ? DateTime.parse(data['completionImageUploadedAt'])
          : null,
    );
  }

  // =========================
  // TO MAP (OFFLINE STORAGE)
  // =========================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'reportType': reportType,
      'tags': tags,
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'reportedAt': reportedAt.toIso8601String(),
      'status': status,
      'adminNotes': adminNotes,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'priority': priority,
      'isRead': isRead,
      'resolvedImageUrl': resolvedImageUrl,
      'resolvedImages': resolvedImages,
      'completionNotes': completionNotes,
      'completionImageUploadedAt': completionImageUploadedAt?.toIso8601String(),
    };
  }

  // =========================
  // HELPERS
  // =========================

  bool get isPending => status == ReportStatus.pending;
  bool get isAccepted => status == ReportStatus.accepted;
  bool get isResolved => status == ReportStatus.resolved;
  bool get isInvalid => status == ReportStatus.invalid;
  bool get isInProgress => status == ReportStatus.inProgress;

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get hasResolvedImage => resolvedImages.isNotEmpty;

  String get primaryImageUrl => imageUrl.isNotEmpty ? imageUrl.first : '';

  String get formattedReportedAt =>
      '${reportedAt.day}/${reportedAt.month}/${reportedAt.year} '
      '${reportedAt.hour}:${reportedAt.minute.toString().padLeft(2, '0')}';

  ReportModel copyWith({
    String? id,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? imageUrl,
    String? reportType,
    List<String>? tags,
    String? userId,
    String? email,
    String? fullName,
    String? phoneNumber,
    DateTime? reportedAt,
    String? status,
    String? adminNotes,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? priority,
    bool? isRead,
    String? resolvedImageUrl,
    List<String>? resolvedImages,
    String? completionNotes,
    DateTime? completionImageUploadedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      reportType: reportType ?? this.reportType,
      tags: tags ?? this.tags,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      reportedAt: reportedAt ?? this.reportedAt,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      resolvedImageUrl: resolvedImageUrl ?? this.resolvedImageUrl,
      resolvedImages: resolvedImages ?? this.resolvedImages,
      completionNotes: completionNotes ?? this.completionNotes,
      completionImageUploadedAt:
          completionImageUploadedAt ?? this.completionImageUploadedAt,
    );
  }
}

// =========================
// CONSTANTS
// =========================

class ReportStatus {
  static const pending = 'pending';
  static const inProgress = 'in_progress';
  static const accepted = 'accepted';
  static const resolved = 'resolved';
  static const invalid = 'invalid';

  static const all = [pending, inProgress, accepted, resolved, invalid];
}

class ReportPriority {
  static const low = 'low';
  static const medium = 'medium';
  static const high = 'high';
  static const urgent = 'urgent';

  static const all = [low, medium, high, urgent];
}
