import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totp_app/classes/account.dart';
import 'package:totp_app/classes/appsettings.dart';
import 'package:totp_app/classes/webdav.dart';

class LocalStorage {
  static late final SharedPreferences prefs;
  static late final FlutterSecureStorage secureStorage;
  static late AppSettings settings;
  static late final ValueNotifier<AppSettings> settingsNotifier;
  static late final Webdav webdavClient;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    secureStorage = FlutterSecureStorage();
    settings = AppSettings.load(prefs);
    settings.account = await Account.getAccount();
    settingsNotifier = ValueNotifier(settings);
  }
}
