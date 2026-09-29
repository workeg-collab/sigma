import 'package:flutter/foundation.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/models/user.dart';

class AuthService extends ChangeNotifier {
  final UserRepository _userRepo;
  User? _currentUser;

  AuthService({UserRepository? userRepo}) : _userRepo = userRepo ?? UserRepository();

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String username, String password) async {
    try {
      final user = await _userRepo.authenticate(username, password);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    return _currentUser!.hasPermission(permission);
  }
}
