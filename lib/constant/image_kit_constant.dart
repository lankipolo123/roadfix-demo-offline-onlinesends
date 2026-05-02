class ImageKitConstants {
  static const String publicKey = 'public_Nj2ApVdQr9TIVMApBquPRDWQypo=';
  static const String privateKey = 'private_1X5U8Rq1IoHBkyG4moJUtmwYros=';
  static const String urlEndpoint = 'https://ik.imagekit.io/roadfixqc';
  static const String uploadEndpoint =
      'https://upload.imagekit.io/api/v1/files/upload';

  // UPDATED FOLDERS (DEV / DEMO STRUCTURE)
  static const String reportsFolder = '/reports-demo';
  static const String profilesFolder = '/profiles-demo';

  // File size limits (capstone-safe settings)
  static const int maxFileSize = 25 * 1024 * 1024; // 25MB
  static const int minFileSize = 100 * 1024; // 100KB minimum

  static const List<String> allowedFormats = ['jpg', 'jpeg', 'png', 'webp'];

  // Security limits
  static const int spamCooldownMinutes = 5;
  static const int maxReportsPerDay = 10;
  static const int maxDescriptionLength = 500;

  static const List<String> forbiddenPatterns = [
    '<script',
    '</script>',
    'javascript:',
    'onclick=',
    'onerror=',
    'onload=',
    'eval(',
    'document.',
    'window.',
    'alert(',
    'setTimeout',
    'setInterval',
    'Function(',
    'constructor',
  ];

  // ImageKit transformations
  static const Map<String, dynamic> thumbnailTransform = {
    'w': 150,
    'h': 150,
    'cm': 'maintain_ratio',
    'q': 80,
    'f': 'webp',
  };

  static const Map<String, dynamic> detailTransform = {
    'w': 800,
    'q': 85,
    'f': 'webp',
    'pr': 'true',
  };

  static const Map<String, dynamic> avatarTransform = {
    'cm': 'maintain_ratio',
    'fo': 'face',
    'q': 90,
    'f': 'webp',
  };
}
