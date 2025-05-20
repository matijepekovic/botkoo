// lib/core/services/auth_service.dart with proper logging
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botko/core/models/social_account.dart';
import 'package:botko/data/local/database_helper.dart';
import 'package:botko/core/utils/logger.dart';

class AuthService {
  static const String _tag = 'AuthService';
  static const String _prefsKey = 'social_accounts';

  // Platform-specific authentication methods
  Future<SocialAccount> _authenticateTikTok(String username, String password) async {
    // In a real app, this would use TikTok's OAuth flow
    await Future.delayed(const Duration(seconds: 1));

    if (password.isEmpty) {
      throw Exception('Invalid credentials');
    }

    // Mock TikTok-specific data
    final platformSpecificData = {
      'accountType': 'creator',
      'followerCount': 1000,
      'verificationStatus': 'unverified',
    };

    final mockToken = base64Encode(utf8.encode('tiktok:$username:${DateTime.now().millisecondsSinceEpoch}'));

    return SocialAccount(
      platform: 'tiktok',
      username: username,
      token: mockToken,
      isActive: true,
      platformSpecificData: platformSpecificData,
    );
  }

  Future<SocialAccount> _authenticateThreads(String username, String password) async {
    // In a real app, this would connect to Threads via Instagram authentication
    await Future.delayed(const Duration(seconds: 1));

    if (password.isEmpty) {
      throw Exception('Invalid credentials');
    }

    // Check if user has an Instagram account
    final hasInstagramAccount = await _hasConnectedInstagramAccount(username);

    if (!hasInstagramAccount) {
      throw Exception('You must connect an Instagram account before adding Threads');
    }

    // Mock Threads-specific data
    final platformSpecificData = {
      'connectedViaInstagram': true,
      'instagramUsername': username,
    };

    final mockToken = base64Encode(utf8.encode('threads:$username:${DateTime.now().millisecondsSinceEpoch}'));

    return SocialAccount(
      platform: 'threads',
      username: username,
      token: mockToken,
      isActive: true,
      platformSpecificData: platformSpecificData,
    );
  }

  Future<SocialAccount> _authenticateYouTube(String username, String password) async {
    // In a real app, this would use YouTube/Google's OAuth flow
    await Future.delayed(const Duration(seconds: 1));

    if (password.isEmpty) {
      throw Exception('Invalid credentials');
    }

    // Mock YouTube-specific data including channel info
    final platformSpecificData = {
      'channels': [
        {
          'id': 'UC123456789',
          'name': '$username Channel',
          'subscriberCount': 5000,
          'isDefault': true,
        },
        {
          'id': 'UC987654321',
          'name': '$username Second Channel',
          'subscriberCount': 1000,
          'isDefault': false,
        }
      ],
      'hasContentID': false,
      'monetizationStatus': 'enabled',
    };

    final mockToken = base64Encode(utf8.encode('youtube:$username:${DateTime.now().millisecondsSinceEpoch}'));

    return SocialAccount(
      platform: 'youtube',
      username: username,
      token: mockToken,
      isActive: true,
      platformSpecificData: platformSpecificData,
    );
  }

  // Helper method to check if user has Instagram account
  Future<bool> _hasConnectedInstagramAccount(String username) async {
    final accounts = await getAccounts();
    return accounts.any((account) =>
    account.platform == 'instagram' &&
        account.username == username &&
        account.isActive
    );
  }

  // Enhanced connectAccount method to support new platforms
  Future<SocialAccount> connectAccount(String platform, String username, String password) async {
    Logger.i(_tag, 'Connecting account for platform: $platform, username: $username');

    // Platform-specific authentication methods
    switch (platform) {
      case 'tiktok':
        return await _authenticateTikTok(username, password);
      case 'threads':
        return await _authenticateThreads(username, password);
      case 'youtube':
        return await _authenticateYouTube(username, password);
      default:
      // Default authentication for existing platforms
        await Future.delayed(const Duration(seconds: 1));

        if (password.isEmpty) {
          throw Exception('Invalid credentials');
        }

        final mockToken = base64Encode(utf8.encode('$platform:$username:${DateTime.now().millisecondsSinceEpoch}'));

        return SocialAccount(
          platform: platform,
          username: username,
          token: mockToken,
          isActive: true,
        );
    }
  }

  // Updated saveAccount method to handle platform-specific data
  Future<SocialAccount> saveAccount(SocialAccount account) async {
    Logger.i(_tag, 'Saving account: ${account.platform} - ${account.username}');

    // Get database helper
    final DatabaseHelper dbHelper = DatabaseHelper();

    // Convert platformSpecificData to JSON string if present
    final Map<String, dynamic> accountMap = account.toMap();
    if (account.platformSpecificData != null) {
      accountMap['platformSpecificData'] = jsonEncode(account.platformSpecificData);
    }

    // Insert the account into the database and get the ID
    final int id = await dbHelper.insertSocialAccount(accountMap);

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

  // Rest of the AuthService implementation...
  // Retrieved from the existing code in lib/core/services/auth_service.dart

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
        Logger.i(_tag, 'Migrating accounts from preferences to database');
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

    return accounts.map((accountMap) {
      // Parse platformSpecificData from JSON string
      Map<String, dynamic>? platformSpecificData;
      if (accountMap['platformSpecificData'] != null) {
        try {
          platformSpecificData = jsonDecode(accountMap['platformSpecificData']);
        } catch (e) {
          Logger.e(_tag, 'Error parsing platformSpecificData', e);
        }
      }

      return SocialAccount(
        id: accountMap['id'],
        platform: accountMap['platform'],
        username: accountMap['username'],
        token: accountMap['token'],
        refreshToken: accountMap['refreshToken'],
        tokenExpiry: accountMap['tokenExpiry'] != null
            ? DateTime.parse(accountMap['tokenExpiry'])
            : null,
        isActive: accountMap['isActive'] == 1,
        platformSpecificData: platformSpecificData,
      );
    }).toList();
  }

  Future<void> removeAccount(String platform, String username) async {
    Logger.i(_tag, 'Removing account: $platform - $username');
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
    Logger.i(_tag, 'Clearing all accounts');
    final DatabaseHelper dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Clear database table
    await db.delete('social_accounts');

    // Clear preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}