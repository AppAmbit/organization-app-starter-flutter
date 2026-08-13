const int minNameLength = 2;
const int maxNameLength = 50;
const int minEmailLength = 5;
const int maxEmailLength = 100;
const int minPasswordLength = 6;
const int maxPasswordLength = 20;

final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) return 'Name is required';
  final v = value.trim();
  if (v.length < minNameLength) return 'Name must be at least $minNameLength characters';
  if (v.length > maxNameLength) return 'Name must be at most $maxNameLength characters';
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Email is required';
  final v = value.trim();
  if (v.length < minEmailLength) return 'Enter a valid email address';
  if (v.length > maxEmailLength) return 'Email must be at most $maxEmailLength characters';
  if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  if (value.length < minPasswordLength) return 'Password must be at least $minPasswordLength characters';
  if (value.length > maxPasswordLength) return 'Password must be at most $maxPasswordLength characters';
  return null;
}

String? validateConfirmPassword(String? password, String? confirmPassword) {
  final pwError = validatePassword(password);
  if (pwError != null) return null;
  if (confirmPassword == null || confirmPassword.isEmpty) return 'Please confirm your password';
  if (confirmPassword != password) return 'Passwords do not match';
  return null;
}
