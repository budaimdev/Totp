import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totp_app/helpers/local_storage.dart';

class AppSettings {
  Brightness brightness;
  Color color;
  bool useDynamicColors;

  AppSettings(
      {required this.brightness, required this.color, required this.useDynamicColors});

  factory AppSettings.load(SharedPreferences prefs) {
    final String theme = prefs.getString("theme") ?? "light";
    final int? colorValue = prefs.getInt("app_color");
    final Color color = colorValue != null ? Color(colorValue) : Colors.deepPurple;

    return AppSettings(
        brightness: theme == "dark" ? Brightness.dark : Brightness.light,
        color: color,
        useDynamicColors: prefs.getBool("dynamic_colors") ?? false
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setString("theme", brightness.name);
    await prefs.setBool('dynamic_colors', useDynamicColors);
    await prefs.setInt('app_color', color.toARGB32());

    LocalStorage.settingsNotifier.value = AppSettings.load(LocalStorage.prefs);
  }
}
