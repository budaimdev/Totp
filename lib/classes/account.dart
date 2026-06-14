import 'dart:convert';

import 'package:totp_app/helpers/local_storage.dart';

class Account {
  late String username;
  late String password;
  late String url;

  Account({required this.username, required this.password, required this.url});

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      username: json["username"],
      password: json["password"],
      url: json["url"],
    );
  }

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password, 'url': url};
  }

  static Future<List<Account>> getAccounts() async {
    String? accountsJson = await getData("accounts");
    if (accountsJson == null || accountsJson.isEmpty) {
      return [];
    }

    final List<dynamic> rawList = jsonDecode(accountsJson);
    return rawList.map((item) => Account.fromJson(item)).toList();
  }

  static Future<void> addAccount(
    String username,
    String password,
    String url,
  ) async {
    List<Account> currentAccounts = await getAccounts();
    Account account = Account(username: username, password: password, url: url);
    currentAccounts.add(account);
    await saveChangesJson("accounts", currentAccounts);
  }

  static Future<void> removeAccount(String username) async {
    List<Account> currentAccounts = await getAccounts();
    currentAccounts.removeWhere((account) => account.username == username);
    await saveChangesJson("accounts", currentAccounts);
  }

  static Future<String?> getData(String key) async {
    final secureStorage = LocalStorage.secureStorage;
    return await secureStorage.read(key: key);
  }

  static Future<void> saveChangesJson(String key, dynamic rawData) async {
    String dataInJson = jsonEncode(rawData);
    await saveChanges(key, dataInJson);
  }

  static Future<void> saveChanges(String key, dynamic value) async {
    final secureStorage = LocalStorage.secureStorage;
    await secureStorage.write(key: key, value: value);
  }
}
