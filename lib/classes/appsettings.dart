import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totp_app/helpers/local_storage.dart';

class AppSettings {
  Brightness brightness;
  Color color;
  bool useDynamicColors;
  bool useForAmoled;
  bool canUseBio;
  bool useBio;

  AppSettings(
      {required this.brightness, required this.color, required this.useDynamicColors, required this.useForAmoled, this.canUseBio = false, required this.useBio});

  factory AppSettings.load(SharedPreferences prefs) {
    final String theme = prefs.getString("theme") ?? "light";
    final int? colorValue = prefs.getInt("app_color");
    final Color color = colorValue != null ? Color(colorValue) : Colors.deepPurple;
    final bool amoled = prefs.getBool("amoled") ?? false;
    final bool canUse = prefs.getBool("can_use_bio") ?? false;
    final bool use = prefs.getBool("use_bio") ?? false;

    return AppSettings(
        brightness: theme == "dark" ? Brightness.dark : Brightness.light,
        color: color,
        useDynamicColors: prefs.getBool("dynamic_colors") ?? false,
        useForAmoled: amoled,
        canUseBio: canUse,
        useBio: use
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setString("theme", brightness.name);
    await prefs.setBool('dynamic_colors', useDynamicColors);
    await prefs.setInt('app_color', color.toARGB32());
    await prefs.setBool("amoled", useForAmoled);
    await prefs.setBool("can_use_bio", canUseBio);
    await prefs.setBool("use_bio", useBio);

    LocalStorage.settings = AppSettings.load(LocalStorage.prefs);
    LocalStorage.settingsNotifier.value = LocalStorage.settings;
  }
}
