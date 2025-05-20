import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botko/core/models/social_account.dart';
import 'package:botko/data/local/database_helper.dart';

class AuthService {
  static const String _prefsKey = 'social_accounts';

  // Updated to retrieve accounts from database as the primary source
  Future<List<SocialAccount>> getAccounts() async {
    final DatabaseHelper dbHelper = DatabaseHelper();
    final List<Map<String, dynamic>> accounts = await dbHelper.getSocialAccounts();

    if (accounts.isEmpty) {
      // Fallback to preferences only if database is empty
      // This helps with migration of existing users
      final prefs = await SharedPreferences.getInstance();
      List<String> accountsJson = prefs.getStringList(_prefsKey) ?? [];

      // If we have accounts in preferences but not in DB, migrate them
      if (accountsJson.isNotEmpty) {
        List<SocialAccount> prefAccounts = accountsJson.map((accountJson) {
          Map<String, dynamic> accountMap = jsonDecode(accountJson);
          return SocialAccount.fromMap(accountMap);
        }).toList();

        // Save accounts to database for future use
        for (var account in prefAccounts) {
          await saveAccount(account);
        }

        // Now get accounts from database after migration
        return await getAccounts();
      }

      return [];
    }

    return accounts.map((accountMap) => SocialAccount.fromMap(accountMap)).toList();
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

  // Updated saveAccount method to ensure proper ID handling
  Future<SocialAccount> saveAccount(SocialAccount account) async {
    // Get database helper
    final DatabaseHelper dbHelper = DatabaseHelper();

    // Insert the account into the database and get the ID
    final int id = await dbHelper.insertSocialAccount(account.toMap());

    // Create a new account with the ID
    final accountWithId = account.copyWith(id: id);

    // Save to preferences for backward compatibility
    final prefs = await SharedPreferences.getInstance();
    List<String> accounts = prefs.getStringList(_prefsKey) ?? [];

    // Remove any existing account with same platform/username to avoid duplicates
    accounts = accounts.where((accountJson) {
      Map<String, dynamic> accountMap = jsonDecode(accountJson);
      return !(accountMap['platform'] == account.platform &&
          accountMap['username'] == account.username);
    }).toList();

    // Add the updated account with ID
    accounts.add(jsonEncode(accountWithId.toMap()));
    await prefs.setStringList(_prefsKey, accounts);

    // Return the account with ID for immediate use
    return accountWithId;
  }

  // Updated to remove from both database and preferences
  Future<void> removeAccount(String platform, String username) async {
    final DatabaseHelper dbHelper = DatabaseHelper();

    // First find the account in the database to get its ID
    final List<Map<String, dynamic>> accounts = await dbHelper.getSocialAccounts();
    for (var account in accounts) {
      if (account['platform'] == platform && account['username'] == username) {
        // Delete from database using ID
        await dbHelper.deleteSocialAccount(account['id']);
        break;
      }
    }

    // Also remove from preferences
    final prefs = await SharedPreferences.getInstance();
    List<String> prefAccounts = prefs.getStringList(_prefsKey) ?? [];

    List<String> updatedAccounts = prefAccounts.where((accountJson) {
      Map<String, dynamic> accountMap = jsonDecode(accountJson);
      return !(accountMap['platform'] == platform && accountMap['username'] == username);
    }).toList();

    await prefs.setStringList(_prefsKey, updatedAccounts);
  }

  // Clear all accounts (for testing/logout)
  Future<void> clearAllAccounts() async {
    final DatabaseHelper dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Clear database table
    await db.delete('social_accounts');

    // Clear preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}