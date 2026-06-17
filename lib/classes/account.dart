import 'dart:convert';

import 'package:totp_app/helpers/local_storage.dart';

class Account {
  final String url;
  final String appPassword;
  final String loginName;

  Account(
      {required this.url, required this.appPassword, required this.loginName});

  factory Account.fromJson(Map<String, dynamic> json) {
    String? url = json["url"];
    String? appPassword = json["appPassword"];
    String? loginName = json["loginName"];

    if (url == null || appPassword == null || loginName == null) {
      throw FormatException("Invalid JSON");
    }

    return Account(
      url: url,
      appPassword: appPassword,
      loginName: loginName,
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'appPassword': appPassword, "loginName": loginName};
  }

  static Future<Account?> getAccount() async {
    final secureStorage = LocalStorage.secureStorage;

    try {
      String? accountJson = await secureStorage.read(key: "account");

      if (accountJson == null || accountJson.isEmpty) {
        return null;
      }

      return Account.fromJson(jsonDecode(accountJson));
    } catch (e) {
      await secureStorage.delete(key: "account");
      return null;
    }
  }

  static Future<void> setAccount(String appPassword,
      String url, String loginName
  ) async {
    Account account = Account(
        url: url, appPassword: appPassword, loginName: loginName);

    String dataInJson = jsonEncode(account);

    final secureStorage = LocalStorage.secureStorage;
    await secureStorage.write(key: "account", value: dataInJson);
  }

  static Future<void> removeAccount() async {
    final secureStorage = LocalStorage.secureStorage;
    await secureStorage.delete(key: "account");
  }
}
