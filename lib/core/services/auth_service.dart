import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botko/core/models/social_account.dart';
import 'package:botko/data/local/database_helper.dart'; // Add this missing import

class AuthService {
  static const String _prefsKey = 'social_accounts';

  // Add this missing method that account_provider is trying to use
  Future<List<SocialAccount>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> accountsJson = prefs.getStringList(_prefsKey) ?? [];

    return accountsJson.map((accountJson) {
      Map<String, dynamic> accountMap = jsonDecode(accountJson);
      return SocialAccount.fromMap(accountMap);
    }).toList();
  }

  // Mock authentication for demonstration purposes
  // In a real app, this would connect to actual social media APIs
  Future<SocialAccount> connectAccount(String platform, String username, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // This is just a simulation - in a real app, you would:
    // 1. Make OAuth requests to the platform's authentication endpoints
    // 2. Store the returned tokens securely
    // 3. Handle token refresh and expiration

    if (password.isEmpty) {
      throw Exception('Invalid credentials');
    }

    // Create a mock token
    final mockToken = base64Encode(utf8.encode('$username:${DateTime.now().millisecondsSinceEpoch}'));

    // Return a new social account with mock data
    return SocialAccount(
      platform: platform,
      username: username,
      token: mockToken,
      isActive: true,
    );
  }

  // Save account to preferences (temporary storage solution)
  Future<void> saveAccount(SocialAccount account) async {
    // Get database helper
    final DatabaseHelper dbHelper = DatabaseHelper();

    // Insert the account into the database and get the ID
    final int id = await dbHelper.insertSocialAccount(account.toMap());

    // Create a new account with the ID
    final accountWithId = SocialAccount(
      id: id,
      platform: account.platform,
      username: account.username,
      token: account.token,
      refreshToken: account.refreshToken,
      tokenExpiry: account.tokenExpiry,
      isActive: account.isActive,
    );

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    List<String> accounts = prefs.getStringList(_prefsKey) ?? [];

    // Convert account to JSON and add to list
    accounts.add(jsonEncode(accountWithId.toMap()));

    await prefs.setStringList(_prefsKey, accounts);
  }

  // Remove account from preferences
  Future<void> removeAccount(String platform, String username) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> accounts = prefs.getStringList(_prefsKey) ?? [];

    List<String> updatedAccounts = accounts.where((accountJson) {
      Map<String, dynamic> accountMap = jsonDecode(accountJson);
      return !(accountMap['platform'] == platform && accountMap['username'] == username);
    }).toList();

    await prefs.setStringList(_prefsKey, updatedAccounts);
  }

  // Clear all accounts (for testing/logout)
  Future<void> clearAllAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}