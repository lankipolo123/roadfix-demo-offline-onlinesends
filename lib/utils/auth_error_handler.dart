class AuthErrorHandler {
  static const Map<String, String> _errorMessages = {
    'weak-password': 'Password is too weak',
    'email-already-in-use': 'Account already exists for this email',
    'invalid-email': 'Invalid email address',
    'user-not-found': 'No account found for this email',
    'wrong-password': 'Incorrect password',
    'user-disabled': 'Account has been disabled',
    'too-many-requests': 'Too many attempts. Try again later',
    'invalid-credential': 'Invalid email or password',
  };

  /// Generic offline-safe auth error handler
  static String handleError(dynamic error, {String operation = 'Operation'}) {
    final message = error.toString().toLowerCase();

    // match known patterns
    for (final key in _errorMessages.keys) {
      if (message.contains(key)) {
        return _errorMessages[key]!;
      }
    }

    return '$operation failed. Please try again.';
  }
}
