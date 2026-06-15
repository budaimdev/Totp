import 'dart:convert';

import 'package:totp_app/helpers/local_storage.dart';

class Account {
  late String url;
  late String appPassword;
  late String loginName;

  Account(
      {required this.url, required this.appPassword, required this.loginName});

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      url: json["url"],
      appPassword: json["appPassword"],
      loginName: json["loginName"],
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'appPassword': appPassword, "loginName": loginName};
  }

  static Future<Account?> getAccount() async {
    final secureStorage = LocalStorage.secureStorage;
    String? accountJson = await secureStorage.read(key: "account");

    if (accountJson == null || accountJson.isEmpty) {
      return null;
    }

    return jsonDecode(accountJson);
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

  static Future<void> removeAccount(String url) async {
    final secureStorage = LocalStorage.secureStorage;
    await secureStorage.delete(key: "account");
  }
}
