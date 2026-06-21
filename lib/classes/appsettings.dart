import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totp_app/classes/account.dart';
import 'package:totp_app/helpers/local_storage.dart';

class AppSettings {
  Brightness brightness;
  Color color;
  bool useDynamicColors;
  bool useForAmoled;
  bool canUseBio;
  bool useBio;
  bool useSync;
  Account? account;
  bool syncPass;

  AppSettings(
      {required this.brightness, required this.color, required this.useDynamicColors, required this.useForAmoled, this.canUseBio = false, required this.useBio, required this.useSync, required this.syncPass, this.account});

  factory AppSettings.load(SharedPreferences prefs,
      FlutterSecureStorage secureStorage) {
    final String theme = prefs.getString("theme") ?? "light";
    final int? colorValue = prefs.getInt("app_color");
    final Color color = colorValue != null ? Color(colorValue) : Colors.deepPurple;
    final bool amoled = prefs.getBool("amoled") ?? false;
    final bool canUse = prefs.getBool("can_use_bio") ?? false;
    final bool use = prefs.getBool("use_bio") ?? false;
    final bool useSyncPref = prefs.getBool("use_sync") ?? false;
    final bool useSyncPass = prefs.getBool("use_sync_pass") ?? false;

    return AppSettings(
      brightness: theme == "dark" ? Brightness.dark : Brightness.light,
      color: color,
      useDynamicColors: prefs.getBool("dynamic_colors") ?? false,
      useForAmoled: amoled,
      canUseBio: canUse,
      useBio: use,
      useSync: useSyncPref,
        syncPass: useSyncPass
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setString("theme", brightness.name);
    await prefs.setBool('dynamic_colors', useDynamicColors);
    await prefs.setInt('app_color', color.toARGB32());
    await prefs.setBool("amoled", useForAmoled);
    await prefs.setBool("can_use_bio", canUseBio);
    await prefs.setBool("use_bio", useBio);
    await prefs.setBool("use_sync", useSync);
    await prefs.setBool("use_sync_pass", syncPass);

    LocalStorage.settings =
        AppSettings.load(LocalStorage.prefs, LocalStorage.secureStorage);
    LocalStorage.settings.account = await Account.getAccount();
    LocalStorage.settingsNotifier.value = LocalStorage.settings;
  }

  Future<void> setSyncPass(String password) async {
    LocalStorage.settings.syncPass = true;
    LocalStorage.settingsNotifier.value = LocalStorage.settings;
    await LocalStorage.secureStorage.write(key: "syncPass", value: password);
  }

  Future<String> getSyncPassword() async {
    return await LocalStorage.secureStorage.read(key: "syncPass") ?? "";
  }

  Future<void> deleteSyncPassword() async {
    await LocalStorage.secureStorage.delete(key: "syncPass");
    LocalStorage.settings.syncPass = false;
    LocalStorage.settingsNotifier.value = LocalStorage.settings;
  }
}
