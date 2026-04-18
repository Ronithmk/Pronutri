import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/unit_helper.dart';
import 'api_service.dart';
import 'otp_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Boot: restore session from SharedPreferences ──────────────
  Future<void> init() async {
    final token = await ApiService.readToken();
    if (token == null) return;
    final prefs = await SharedPreferences.getInstance();

    // Restore user from saved prefs
    _currentUser = UserModel(
      id:                  prefs.getString('uid') ?? '',
      name:                prefs.getString('user_name') ?? '',
      email:               prefs.getString('user_email') ?? '',
      password:            '',
      weight:              prefs.getDouble('user_weight') ?? 70,
      height:              prefs.getDouble('user_height') ?? 170,
      age:                 prefs.getInt('user_age') ?? 25,
      gender:              prefs.getString('user_gender') ?? 'male',
      goal:                prefs.getString('user_goal') ?? 'maintain',
      activityLevel:       prefs.getString('user_activity') ?? 'moderate',
      targetWeight:        prefs.getDouble('user_target_weight') ?? 70,
      emailVerified:       true,
      credits:             prefs.getInt('user_credits') ?? 100,
      trialEnd:            DateTime.tryParse(prefs.getString('trial_end') ?? '') ?? DateTime.now().add(const Duration(days: 30)),
      subscriptionActive:  prefs.getBool('subscription_active') ?? false,
      role:                prefs.getString('user_role') ?? 'learner',
      trainerStatus:       prefs.getString('trainer_status') ?? '',
      specializations:     (prefs.getStringList('trainer_specs') ?? []),
      yearsExperience:     prefs.getInt('trainer_years') ?? 0,
      bio:                 prefs.getString('trainer_bio') ?? '',
      country:             prefs.getString('user_country') ?? 'India',
      weightUnit:          prefs.getString('weight_unit') ?? 'kg',
      heightUnit:          prefs.getString('height_unit') ?? 'cm',
      distanceUnit:        prefs.getString('distance_unit') ?? 'km',
    );
    notifyListeners();
  }

  // ── Store registration data temporarily for OTP verification ────
  Map<String, dynamic>? _pendingRegistration;

  // ── Trainer: send OTP + store pending trainer registration ────────
  Future<String?> sendTrainerRegistrationOtp({
    required String name,
    required String email,
    required String password,
    required List<String> specializations,
    required int yearsExperience,
    required String bio,
    required String documentPath, // local file path from image_picker
  }) async {
    final normalizedEmail = email.toLowerCase().trim();
    _pendingRegistration = {
      'name':            name,
      'email':           normalizedEmail,
      'password':        password,
      'role':            'trainer',
      'specializations': specializations,
      'years_experience': yearsExperience,
      'bio':             bio,
      'document_path':   documentPath,
      'weight':          70.0,
      'height':          170.0,
      'age':             25,
      'gender':          'male',
      'goal':            'maintain',
      'activityLevel':   'moderate',
      'targetWeight':    70.0,
    };
    final result = await OtpService.sendOtp(normalizedEmail);
    return result;
  }

  // ── Trainer: complete registration + submit application ───────────
  Future<String?> completeTrainerRegistrationAfterOtp(String email) async {
    if (_pendingRegistration == null) {
      return 'Registration session expired. Please try again.';
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Register account on backend
      final res = await ApiService.post('/auth/register', {
        'name':     _pendingRegistration!['name'],
        'email':    email.toLowerCase().trim(),
        'password': _pendingRegistration!['password'],
        'role':     'trainer',
      });

      if (res.containsKey('error')) {
        _error = res['error'];
        _isLoading = false;
        notifyListeners();
        return _error;
      }

      // Save JWT token NOW so ApiService can authenticate the /trainer/apply call below
      await ApiService.saveToken(res['token'] as String);

      // Upload document + trainer profile to backend
      final docPath = _pendingRegistration!['document_path'] as String;
      try {
        await ApiService.uploadFile(
          '/trainer/apply',
          docPath,
          fields: {
            'specializations':  jsonEncode(_pendingRegistration!['specializations']),
            'years_experience': _pendingRegistration!['years_experience'].toString(),
            'bio':              _pendingRegistration!['bio'] as String,
            'doc_type':         'certificate',
          },
        );
      } catch (_) {
        // Application upload failed — account is created, trainer can resubmit later
      }

      await _saveSession(
        token:               res['token'],
        uid:                 res['uid'],
        name:                _pendingRegistration!['name'],
        email:               email.toLowerCase().trim(),
        credits:             0, // trainers don't get welcome credits until approved
        trialEnd:            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        subscriptionActive:  false,
        weight:              _pendingRegistration!['weight'],
        height:              _pendingRegistration!['height'],
        age:                 _pendingRegistration!['age'],
        gender:              _pendingRegistration!['gender'],
        goal:                _pendingRegistration!['goal'],
        activityLevel:       _pendingRegistration!['activityLevel'],
        targetWeight:        _pendingRegistration!['targetWeight'],
        role:                'trainer',
        trainerStatus:       'pending',
        specializations:     List<String>.from(_pendingRegistration!['specializations']),
        yearsExperience:     _pendingRegistration!['years_experience'],
        bio:                 _pendingRegistration!['bio'],
      );

      _pendingRegistration = null;
      _isLoading = false;
      notifyListeners();
      return null; // success
    } catch (e) {
      _error = 'Network error. Check your connection.';
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  // ── Send Registration OTP ──────────────────────────────────────
  Future<String?> sendRegistrationOtp({
    required String name,
    required String email,
    required String password,
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String goal,
    required String activityLevel,
    required double targetWeight,
    String country = 'India',
  }) async {
    final normalizedEmail = email.toLowerCase().trim();
    // Store the registration data temporarily
    _pendingRegistration = {
      'name': name,
      'email': normalizedEmail,
      'password': password,
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender,
      'goal': goal,
      'activityLevel': activityLevel,
      'targetWeight': targetWeight,
      'country': country,
    };

    // Send OTP
    final result = await OtpService.sendOtp(normalizedEmail);
    return result; // null = success, string = error or dev mode
  }

  // ── Complete Registration After OTP Verification ────────────────
  Future<String?> completeRegistrationAfterOtp(String email) async {
    if (_pendingRegistration == null) {
      return 'Registration session expired. Please try again.';
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.post('/auth/register', {
        'name': _pendingRegistration!['name'],
        'email': email.toLowerCase().trim(),
        'password': _pendingRegistration!['password'],
      });

      if (res.containsKey('error')) {
        _error = res['error'];
        _isLoading = false;
        notifyListeners();
        return _error;
      }

      // Save token + user data with 100 credits and 30-day trial
      await _saveSession(
        token: res['token'],
        uid: res['uid'],
        name: _pendingRegistration!['name'],
        email: email.toLowerCase().trim(),
        credits: 100, // Welcome bonus
        trialEnd: DateTime.now().add(const Duration(days: 30)).toIso8601String(), // 30-day trial
        subscriptionActive: false,
        weight: _pendingRegistration!['weight'],
        height: _pendingRegistration!['height'],
        age: _pendingRegistration!['age'],
        gender: _pendingRegistration!['gender'],
        goal: _pendingRegistration!['goal'],
        activityLevel: _pendingRegistration!['activityLevel'],
        targetWeight: _pendingRegistration!['targetWeight'],
        country: _pendingRegistration!['country'] ?? 'India',
      );

      _pendingRegistration = null; // Clear temp data
      _isLoading = false;
      notifyListeners();
      return null; // null = success
    } catch (e) {
      _error = 'Network error. Check your connection.';
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  // ── Register ──────────────────────────────────────────────────
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String goal,
    required String activityLevel,
    required double targetWeight,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final normalizedEmail = email.toLowerCase().trim();
      final res = await ApiService.post('/auth/register', {
        'name':     name,
        'email':    normalizedEmail,
        'password': password,
      });

      if (res.containsKey('error')) {
        _error = res['error'];
        _isLoading = false;
        notifyListeners();
        return _error;
      }

      // Save token + user data
      await _saveSession(
        token:               res['token'],
        uid:                 res['uid'],
        name:                name,
        email:               normalizedEmail,
        credits:             res['credits'] ?? 100,
        trialEnd:            res['trial_end']?.toString() ?? DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        subscriptionActive:  false,
        weight:              weight,
        height:              height,
        age:                 age,
        gender:              gender,
        goal:                goal,
        activityLevel:       activityLevel,
        targetWeight:        targetWeight,
      );

      _isLoading = false;
      notifyListeners();
      return null; // null = success
    } catch (e) {
      _error = 'Network error. Check your connection.';
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  // ── Login ─────────────────────────────────────────────────────
  Future<String?> loginWithBackend({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final normalizedEmail = email.toLowerCase().trim();
      final res = await ApiService.post('/auth/login', {
        'email':    normalizedEmail,
        'password': password,
      });

      if (res.containsKey('error')) {
        _error = res['error'];
        _isLoading = false;
        notifyListeners();
        return _error;
      }

      final prefs = await SharedPreferences.getInstance();

      if (res['token'] == null || res['uid'] == null) {
        _error = 'Login failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return _error;
      }

      // Normalize backend role: old server sends 'user', new sends 'learner'
      final rawRole = res['role'] as String? ?? 'learner';
      final normalizedRole = (rawRole == 'user') ? 'learner' : rawRole;

      await _saveSession(
        token:               res['token'] as String,
        uid:                 res['uid'] as String,
        name:                res['name'] ?? prefs.getString('user_name') ?? '',
        email:               normalizedEmail,
        credits:             res['credits'] ?? 100,
        trialEnd:            res['trial_end']?.toString() ?? '',
        subscriptionActive:  res['subscription_active'] ?? false,
        weight:              prefs.getDouble('user_weight') ?? 70,
        height:              prefs.getDouble('user_height') ?? 170,
        age:                 prefs.getInt('user_age') ?? 25,
        gender:              prefs.getString('user_gender') ?? 'male',
        goal:                prefs.getString('user_goal') ?? 'maintain',
        activityLevel:       prefs.getString('user_activity') ?? 'moderate',
        targetWeight:        prefs.getDouble('user_target_weight') ?? 70,
        role:                normalizedRole,
        trainerStatus:       res['trainer_status'] ?? '',
      );

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Network error. Check your connection.';
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  // ── Demo login (local, no backend) ────────────────────────────
  String? login({required String email, required String password}) {
    if (email == 'demo@pronutri.com' && password == 'demo123') {
      _currentUser = UserModel(
        id:                 'demo',
        name:               'Demo User',
        email:              email,
        password:           '',
        weight:             70,
        height:             170,
        age:                25,
        gender:             'male',
        goal:               'maintain',
        activityLevel:      'moderate',
        targetWeight:       70,
        emailVerified:      true,
        credits:            100,
        trialEnd:           DateTime.now().add(const Duration(days: 30)),
        subscriptionActive: false,
      );
      notifyListeners();
      return null;
    }
    return 'Invalid credentials';
  }

  // ── Update profile locally ────────────────────────────────────
  Future<void> updateProfile({
    String? name,
    double? weight,
    double? height,
    int? age,
    double? targetWeight,
  }) async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();

    _currentUser = _currentUser!.copyWith(
      name:         name,
      weight:       weight,
      height:       height,
      age:          age,
      targetWeight: targetWeight,
    );

    if (name         != null) await prefs.setString('user_name', name);
    if (weight       != null) await prefs.setDouble('user_weight', weight);
    if (height       != null) await prefs.setDouble('user_height', height);
    if (age          != null) await prefs.setInt('user_age', age);
    if (targetWeight != null) await prefs.setDouble('user_target_weight', targetWeight);

    notifyListeners();
  }

  // ── Refresh credits from backend ──────────────────────────────
  Future<void> refreshCredits() async {
    try {
      final res = await ApiService.get('/credits/balance');
      final credits = res['credits'] as int? ?? _currentUser?.credits ?? 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_credits', credits);
      _currentUser = _currentUser?.copyWith(credits: credits);
      notifyListeners();
    } catch (_) {}
  }

  // ── Trainer: refresh status after admin decision ──────────────
  Future<void> refreshTrainerStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trainer_status', status);
    _currentUser = _currentUser?.copyWith(trainerStatus: status);
    notifyListeners();
  }

  // ── Admin: set session from AdminLoginScreen ──────────────────
  Future<void> setAdminSession({
    required String uid,
    required String name,
    required String email,
    required String token,
  }) async {
    await ApiService.saveToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid',        uid);
    await prefs.setString('user_name',  name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_role',  'admin');

    _currentUser = UserModel(
      id:                uid,
      name:              name,
      email:             email,
      password:          '',
      weight:            70,
      height:            170,
      age:               25,
      gender:            'male',
      goal:              'maintain',
      activityLevel:     'moderate',
      targetWeight:      70,
      emailVerified:     true,
      credits:           0,
      trialEnd:          DateTime.now().add(const Duration(days: 365)),
      subscriptionActive: true,
      role:              'admin',
      trainerStatus:     '',
      specializations:   [],
      yearsExperience:   0,
      bio:               '',
    );
    notifyListeners();
  }

  // ── Logout ────────────────────────────────────────────────────
  Future<void> logout() async {
    await ApiService.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _currentUser = null;
    notifyListeners();
  }

  // ── Save session to SharedPreferences ────────────────────────
  Future<void> _saveSession({
    required String token,
    required String uid,
    required String name,
    required String email,
    required int credits,
    required String trialEnd,
    required bool subscriptionActive,
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String goal,
    required String activityLevel,
    required double targetWeight,
    String role                   = 'learner',
    String trainerStatus          = '',
    List<String> specializations  = const [],
    int yearsExperience           = 0,
    String bio                    = '',
    String country                = 'India',
  }) async {
    final wUnit = UnitHelper.weightUnit(country);
    final hUnit = UnitHelper.heightUnit(country);
    final dUnit = UnitHelper.distanceUnit(country);

    await ApiService.saveToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid',                 uid);
    await prefs.setString('user_name',           name);
    await prefs.setString('user_email',          email);
    await prefs.setInt('user_credits',           credits);
    await prefs.setString('trial_end',           trialEnd);
    await prefs.setBool('subscription_active',   subscriptionActive);
    await prefs.setDouble('user_weight',         weight);
    await prefs.setDouble('user_height',         height);
    await prefs.setInt('user_age',               age);
    await prefs.setString('user_gender',         gender);
    await prefs.setString('user_goal',           goal);
    await prefs.setString('user_activity',       activityLevel);
    await prefs.setDouble('user_target_weight',  targetWeight);
    await prefs.setString('user_role',           role);
    await prefs.setString('trainer_status',      trainerStatus);
    await prefs.setStringList('trainer_specs',   specializations);
    await prefs.setInt('trainer_years',          yearsExperience);
    await prefs.setString('trainer_bio',         bio);
    await prefs.setString('user_country',        country);
    await prefs.setString('weight_unit',         wUnit);
    await prefs.setString('height_unit',         hUnit);
    await prefs.setString('distance_unit',       dUnit);

    _currentUser = UserModel(
      id:                 uid,
      name:               name,
      email:              email,
      password:           '',
      weight:             weight,
      height:             height,
      age:                age,
      gender:             gender,
      goal:               goal,
      activityLevel:      activityLevel,
      targetWeight:       targetWeight,
      emailVerified:      true,
      credits:            credits,
      trialEnd:           DateTime.tryParse(trialEnd) ?? DateTime.now().add(const Duration(days: 30)),
      subscriptionActive: subscriptionActive,
      role:               role,
      trainerStatus:      trainerStatus,
      specializations:    specializations,
      yearsExperience:    yearsExperience,
      bio:                bio,
      country:            country,
      weightUnit:         wUnit,
      heightUnit:         hUnit,
      distanceUnit:       dUnit,
    );
  }
}
