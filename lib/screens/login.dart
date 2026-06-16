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
  final TextEditingController _urlController = TextEditingController(
      text: "https://");
  bool uriError = false;

  String? pollToken;
  String? pollEndpoint;
  Timer? _timer;
  String? statusText;
  bool _isCheckingAuth = false;

  Account? _account;

  bool checkForValidUrl() {
    String text = _urlController.text;
    Uri? uri = Uri.tryParse(text);

    return uri != null && (uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (mounted && !_isCheckingAuth) {
        _isCheckingAuth = true;
        try {
          bool authed = await checkForAuth();
          if (authed) {
            _timer?.cancel();

            Account? account = _account;
            if (account != null) {
              stopTimer();
              setState(() {
                statusText = "Authenticated successfully";
              });
            }
          }
        } finally {
          _isCheckingAuth = false;
        }
      }
    });
  }

  void stopTimer() {
    _timer = null;
  }

  Future<bool> checkForAuth() async {
    String? endpoint = pollEndpoint;
    String? token = pollToken;

    if (endpoint == null || token == null) return false;

    _isCheckingAuth = true;

    final headers = {
      HttpHeaders.userAgentHeader: "FlutterTotpApp",
      HttpHeaders.contentTypeHeader: "application/x-www-form-urlencoded",
    };

    final bodyData = {
      "token": token
    };

    final response = await http.post(
        Uri.parse(endpoint), headers: headers, body: bodyData);

    if (response.statusCode == 200) {
      final responseDecoded = jsonDecode(response.body) as Map<String, dynamic>;

      _account = Account(url: responseDecoded["server"],
          appPassword: responseDecoded["appPassword"],
          loginName: responseDecoded["loginName"]);

      _isCheckingAuth = false;
      return true;
    }

    _isCheckingAuth = false;
    return false;
  }

  void startTheProcess() async {
    setState(() {
      statusText = "Connecting to server...";
    });
    try {
      final response = await http.post(
          Uri.parse("${_urlController.text}/index.php/login/v2"),
          headers: {HttpHeaders.userAgentHeader: "FlutterTotpApp"});

      if (response.statusCode != 200) {
        setState(() {
          statusText =
          "Failed to connect: Server returned status ${response.statusCode}";
        });
        return;
      }

      final responseDecoded = jsonDecode(response.body) as Map<String, dynamic>;

      pollToken = responseDecoded["poll"]["token"];
      pollEndpoint = responseDecoded["poll"]["endpoint"];

      String loginUrl = responseDecoded["login"];

      if (await canLaunchUrl(Uri.parse(loginUrl))) {
        await launchUrl(
            Uri.parse(loginUrl), mode: LaunchMode.externalApplication);
        setState(() {
          statusText = "Please log in via your browser...";
        });
        startTimer();
      } else {
        setState(() {
          statusText = "Could not open login URL in browser.";
        });
      }
    } catch (e) {
      setState(() {
        statusText = "An error occurred: ${e.toString()}";
      });
    }
  }

  void _save() async {
    final account = _account;

    if (account == null) return;

    LocalStorage.settings.account = account;
    await Account.setAccount(
        account.appPassword, account.url, account.loginName);
    LocalStorage.settingsNotifier.value = LocalStorage.settings;
    if (mounted) {
      Navigator.of(context).pop();
    }
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
              keyboardType: TextInputType.url,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: false,
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
            ListTile(
              trailing: FilledButton(
                onPressed: uriError == true || _urlController.text.isEmpty
                    ? null
                    : () {
                  startTheProcess();
                },
                child: const Text("Log In"),
              ),
            ),
            ListTile(
              title: const Text("Status"),
              trailing: _timer == null && _account == null ? Text(
                  "No progress yet") : _account == null
                  ? CircularProgressIndicator()
                  : Text(statusText ?? ""),
            ),
            FilledButton(
                onPressed: _account == null ? null : _save,
                child: const Text("Save")
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _timer?.cancel();
    super.dispose();
  }


}
