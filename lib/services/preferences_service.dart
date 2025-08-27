import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  static const String themeModeKey = 'theme_mode';
  static const String usernameKey = 'username';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String appConfigVersionKey = 'app_config_version';

  static SharedPreferences? _prefs;

  // Initialization
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme Preferences
  static ThemeMode get themeMode {
    final value = _prefs?.getString(themeModeKey);
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    try {
      await _prefs?.setString(themeModeKey, mode.name);
    } catch (e) {
      throw Exception('Failed to set theme mode: $e');
    }
  }

  // User Settings
  static String get username => _prefs?.getString(usernameKey) ?? '';
  static Future<void> setUsername(String name) async {
    try {
      await _prefs?.setString(usernameKey, name);
    } catch (e) {
      throw Exception('Failed to set username: $e');
    }
  }

  static bool get notificationsEnabled => _prefs?.getBool(notificationsEnabledKey) ?? true;
  static Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      await _prefs?.setBool(notificationsEnabledKey, enabled);
    } catch (e) {
      throw Exception('Failed to set notifications: $e');
    }
  }

  // App Configuration
  static int get appConfigVersion => _prefs?.getInt(appConfigVersionKey) ?? 1;
  static Future<void> setAppConfigVersion(int version) async {
    try {
      await _prefs?.setInt(appConfigVersionKey, version);
    } catch (e) {
      throw Exception('Failed to set config version: $e');
    }
  }

  // Migration Support
  static Future<void> migrate({required int fromVersion, required int toVersion}) async {
    if (fromVersion == toVersion) return;
    // Example migration logic
    if (fromVersion < 2 && toVersion >= 2) {
      // Migrate settings for version 2
      await setNotificationsEnabled(true); // Set default for new setting
    }
    await setAppConfigVersion(toVersion);
  }

  // Clear all preferences (for logout/reset)
  static Future<void> clearAll() async {
    try {
      await _prefs?.clear();
    } catch (e) {
      throw Exception('Failed to clear preferences: $e');
    }
  }
}
