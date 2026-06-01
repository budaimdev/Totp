import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totp_app/classes/appsettings.dart';

class LocalStorage {
  static late final SharedPreferences prefs;
  static late Appsettings settings;

  static late final ValueNotifier<Appsettings> settingsNotifier;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    settings = Appsettings.load(prefs);
    settingsNotifier = ValueNotifier(settings);
  }
}
