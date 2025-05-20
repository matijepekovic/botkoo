import 'package:flutter/material.dart';
import 'package:botko/core/models/social_account.dart';
import 'package:botko/core/services/auth_service.dart';

class AccountProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  List<SocialAccount> _accounts = [];
  bool _isLoading = false;
  String? _error;

  List<SocialAccount> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize provider by loading accounts
  Future<void> init() async {
    _setLoading(true);
    try {
      _accounts = await _authService.getAccounts();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Connect a new social media account
  Future<void> connectAccount(String platform, String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final account = await _authService.connectAccount(platform, username, password);
      await _authService.saveAccount(account);

      // Reload accounts from database to ensure IDs are present
      _accounts = await _authService.getAccounts();

      notifyListeners();
    } catch (e) {
      _setError('Failed to connect account: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Remove a connected account
  Future<void> removeAccount(String platform, String username) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.removeAccount(platform, username);
      _accounts.removeWhere(
              (account) => account.platform == platform && account.username == username
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove account: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}