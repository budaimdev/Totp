import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totp_app/classes/appsettings.dart';

class LocalStorage {
  static late final SharedPreferences prefs;
  static late AppSettings settings;

  static late final ValueNotifier<AppSettings> settingsNotifier;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    settings = AppSettings.load(prefs);
    settingsNotifier = ValueNotifier(settings);
  }
}
