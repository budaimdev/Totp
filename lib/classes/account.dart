import 'dart:convert';

import 'package:totp_app/helpers/local_storage.dart';

class Account {
  late String url;
  late String token;

  Account({required this.url, required this.token});

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      url: json["url"],
      token: json["token"],
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'token': token};
  }

  static Future<Account?> getAccount() async {
    final secureStorage = LocalStorage.secureStorage;
    String? accountJson = await secureStorage.read(key: "account");

    if (accountJson == null || accountJson.isEmpty) {
      return null;
    }

    return jsonDecode(accountJson);
  }

  static Future<void> setAccount(String token,
    String url,
  ) async {
    Account account = Account(url: url, token: token);

    String dataInJson = jsonEncode(account);

    final secureStorage = LocalStorage.secureStorage;
    await secureStorage.write(key: "account", value: dataInJson);
  }

  static Future<void> removeAccount(String url) async {
    final secureStorage = LocalStorage.secureStorage;
    await secureStorage.delete(key: "account");
  }
}
