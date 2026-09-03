/// Centralised validation logic.
/// All validators return null when valid, or an error string when invalid.
class Validators {
  /// Password must be ≥8 chars, contain ≥1 digit, ≥1 letter.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Password must contain at least one digit';
    if (!value.contains(RegExp(r'[a-zA-Z]'))) return 'Password must contain at least one letter';
    return null;
  }

  /// 6-digit numeric PIN validator.
  static String? pin(String? value) {
    if (value == null || value.isEmpty) return 'PIN is required';
    if (value.length != 6) return 'PIN must be exactly 6 digits';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'PIN must contain only digits';
    return null;
  }

  /// Phone number — basic E.164-style validation for Ethiopian numbers.
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(cleaned)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'Enter the 6-digit OTP';
    return null;
  }

  /// Evidence file size: max 100 MB per file.
  static String? evidenceFileSize(int bytes) {
    const maxBytes = 100 * 1024 * 1024;
    if (bytes > maxBytes) return 'File exceeds the 100 MB limit';
    return null;
  }

  /// Total evidence size: max 500 MB per report.
  static String? totalEvidenceSize(int totalBytes) {
    const maxBytes = 500 * 1024 * 1024;
    if (totalBytes > maxBytes) return 'Total evidence exceeds the 500 MB limit';
    return null;
  }
}
