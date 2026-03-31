import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'otp_service.dart';

class AuthProvider extends ChangeNotifier {
  late Box<UserModel> _userBox;
  late Box _settingsBox;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _userBox = Hive.box<UserModel>('users');
    _settingsBox = Hive.box('settings');
    _loadSession();
    _createDemoAccount();
  }

  void _loadSession() {
    final userId = _settingsBox.get('currentUserId');
    if (userId != null) {
      _currentUser = _userBox.values.where((u) => u.id == userId).firstOrNull;
    }
  }

  void _createDemoAccount() {
    final exists = _userBox.values.any((u) => u.email == 'demo@pronutri.com');
    if (!exists) {
      _userBox.add(UserModel(
        id: 'demo-user-001', name: 'Demo User',
        email: 'demo@pronutri.com', password: _hash('demo123'),
        weight: 75, height: 175, age: 28, gender: 'male',
        goal: 'maintain', activityLevel: 'moderate',
        createdAt: DateTime.now(), targetWeight: 75,
        emailVerified: true,
      ));
    }
  }

  String _hash(String password) {
    final bytes = utf8.encode(password + 'pronutri_salt_v2');
    return sha256.convert(bytes).toString();
  }

  // Returns null on success, error string on failure
  String? login({required String email, required String password}) {
    if (email.trim().isEmpty) return 'Please enter your email';
    if (password.isEmpty) return 'Please enter your password';
    final user = _userBox.values.where((u) => u.email.toLowerCase() == email.toLowerCase().trim()).firstOrNull;
    if (user == null) return 'No account found with this email';
    if (user.password != _hash(password)) return 'Incorrect password';
    if (!user.emailVerified) return 'Please verify your email first';
    _currentUser = user;
    _settingsBox.put('currentUserId', user.id);
    notifyListeners();
    return null;
  }

  void logout() {
    _currentUser = null;
    _settingsBox.delete('currentUserId');
    notifyListeners();
  }

  // Step 1: Save pending user data and send OTP
  // Returns null on success, error string on failure
  Future<String?> sendRegistrationOtp({
    required String name, required String email, required String password,
    required double weight, required double height, required int age,
    required String gender, required String goal, required String activityLevel,
    required double targetWeight,
  }) async {
    // Validation
    if (name.trim().length < 2) return 'Name must be at least 2 characters';
    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email)) return 'Invalid email address';
    if (password.length < 6) return 'Password must be at least 6 characters';
    if (weight < 20 || weight > 300) return 'Enter a valid weight (20-300 kg)';
    if (height < 100 || height > 250) return 'Enter a valid height (100-250 cm)';
    if (age < 10 || age > 100) return 'Enter a valid age';
    final exists = _userBox.values.any((u) => u.email.toLowerCase() == email.toLowerCase());
    if (exists) return 'Email already registered. Please sign in.';

    // Save pending data
    _settingsBox.put('pending_name', name.trim());
    _settingsBox.put('pending_email', email.toLowerCase().trim());
    _settingsBox.put('pending_password', _hash(password));
    _settingsBox.put('pending_weight', weight);
    _settingsBox.put('pending_height', height);
    _settingsBox.put('pending_age', age);
    _settingsBox.put('pending_gender', gender);
    _settingsBox.put('pending_goal', goal);
    _settingsBox.put('pending_activity', activityLevel);
    _settingsBox.put('pending_targetWeight', targetWeight);

    // Send OTP
    final result = await OtpService.sendOtp(email.toLowerCase().trim());
    return result; // null = success, string = error or EMAIL_NOT_CONFIGURED:otp
  }

  // Step 2: Verify OTP and complete registration
  String? verifyOtpAndRegister(String email, String otp) {
    final isValid = OtpService.verifyOtp(email, otp);
    if (!isValid) return 'Invalid or expired OTP. Please try again.';

    final user = UserModel(
      id: const Uuid().v4(),
      name: _settingsBox.get('pending_name'),
      email: _settingsBox.get('pending_email'),
      password: _settingsBox.get('pending_password'),
      weight: _settingsBox.get('pending_weight'),
      height: _settingsBox.get('pending_height'),
      age: _settingsBox.get('pending_age'),
      gender: _settingsBox.get('pending_gender'),
      goal: _settingsBox.get('pending_goal'),
      activityLevel: _settingsBox.get('pending_activity'),
      createdAt: DateTime.now(),
      targetWeight: _settingsBox.get('pending_targetWeight'),
      emailVerified: true,
    );

    _userBox.add(user);
    // Clean pending data
    for (final key in ['pending_name','pending_email','pending_password','pending_weight','pending_height','pending_age','pending_gender','pending_goal','pending_activity','pending_targetWeight']) {
      _settingsBox.delete(key);
    }

    _currentUser = user;
    _settingsBox.put('currentUserId', user.id);
    notifyListeners();
    return null;
  }

  void updateProfile({String? name, double? weight, double? height, int? age, String? goal, String? activityLevel, String? profileImagePath, double? targetWeight}) {
    if (_currentUser == null) return;
    if (name != null) _currentUser!.name = name;
    if (weight != null) _currentUser!.weight = weight;
    if (height != null) _currentUser!.height = height;
    if (age != null) _currentUser!.age = age;
    if (goal != null) _currentUser!.goal = goal;
    if (activityLevel != null) _currentUser!.activityLevel = activityLevel;
    if (profileImagePath != null) _currentUser!.profileImagePath = profileImagePath;
    if (targetWeight != null) _currentUser!.targetWeight = targetWeight;
    _currentUser!.save();
    notifyListeners();
  }
}
