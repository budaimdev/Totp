import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

class Appsettings {
  final Brightness brightness;

  Appsettings({required this.brightness});

  factory Appsettings.load(SharedPreferences prefs) {
    final String theme = prefs.getString("theme") ?? "system";

    return Appsettings(
      brightness: Brightness.values.byName(theme == "system" ? "light" : theme),
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setString("theme", brightness.name);
  }
}
