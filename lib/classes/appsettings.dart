import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Appsettings {
  final Brightness brightness;
  final Color color;

  Appsettings({required this.brightness, required this.color});

  factory Appsettings.load(SharedPreferences prefs) {
    final String theme = prefs.getString("theme") ?? "system";
    final int? colorValue = prefs.getInt("app_color");
    final Color color = colorValue != null ? Color(colorValue) : Colors.deepPurple;

    return Appsettings(
      brightness: Brightness.values.byName(theme == "system" ? "light" : theme),
      color: color
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setString("theme", brightness.name);
  }
}
