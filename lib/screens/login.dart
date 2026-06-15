import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:totp_app/classes/account.dart';
import 'package:totp_app/helpers/local_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  bool uriError = false;

  String? pollToken;
  String? pollEndpoint;
  Timer? _timer;
  int tries = 0;
  String? statusText;

  Account? _account;

  bool checkForValidUrl() {
    String text = _urlController.text;
    Uri? uri = Uri.tryParse(text);

    return uri != null && (uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (mounted) {
        if (tries < 3 && _account == null) {
          bool authed = await checkForAuth();
          if (authed) {
            _timer?.cancel();

            Account? account = _account;
            if (account != null) {
              LocalStorage.settings.account = _account;
              Account.setAccount(
                  account.appPassword, account.url, account.loginName);
              stopTimer();
              if (mounted) {
                Navigator.of(context).pop();
              }
              setState(() {
                statusText = "Authenticated successfully";
              });
            }
          }
        } else if (tries == 3 && _account == null) {
          setState(() {
            statusText = "Failed to authenticate";
          });
        }
      }
    });
  }

  void stopTimer() {
    _timer = null;
    tries = 0;
  }

  Future<bool> checkForAuth() async {
    String? endpoint = pollEndpoint;
    String? token = pollToken;

    if (endpoint == null || token == null) return false;

    final headers = {
      HttpHeaders.userAgentHeader: "FlutterTotpApp",
      HttpHeaders.contentTypeHeader: ContentType.json.value,
      "token": token
    };

    final response = await http.post(Uri.parse(endpoint), headers: headers);

    if (response.statusCode == 200) {
      final responseDecoded = jsonDecode(response.body) as Map<String, dynamic>;

      _account = Account(url: responseDecoded["server"],
          appPassword: responseDecoded["appPassword"],
          loginName: responseDecoded["loginName"]);
      return true;
    }

    return false;
  }

  void startTheProcess() async {
    //Firstly get the initial stuff - poll {poll_token and url} and login url
    final response = await http.post(
        Uri.parse("${_urlController.text}/index.php/login/v2"),
        headers: {HttpHeaders.userAgentHeader: "FlutterTotpApp"});
    final responseDecoded = jsonDecode(response.body) as Map<String, dynamic>;

    pollToken = responseDecoded["poll"]["token"];
    pollEndpoint = responseDecoded["poll"]["endpoint"];

    String loginUrl = responseDecoded["login"];

    await launchUrl(Uri.parse(loginUrl));
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add a new account")),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          spacing: 16.0,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: "Nextcloud server address (HTTPS)",
                border: OutlineInputBorder(),
                errorText: uriError != true
                    ? null
                    : "Entered URL is not a valid URL",
              ),
              onChanged: (value) {
                setState(() {
                  _urlController.text = value;
                  uriError = !checkForValidUrl();
                });
              },
            ),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                hintText: "Nickname for this Nextcloud connection",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _nicknameController.text = value;
                });
              },
            ),
            ListTile(
              trailing: FilledButton(
                onPressed: () {
                  startTheProcess();
                },
                child: const Text("Log In"),
              ),
            ),
            ListTile(
              title: const Text("Status"),
              trailing: Text(statusText ?? ""),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }


}
