import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  String? pollToken;
  String? pollEndpoint;
  bool uriError = false;

  bool checkForValidUrl() {
    String text = _urlController.text;
    Uri? uri = Uri.tryParse(text);

    return uri != null && (uri.scheme == 'https') && uri.host.isNotEmpty;
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

    //Start check every 2s for successful auth using timer

    await launchUrl(Uri.parse(loginUrl));
    print("Done");

    //Check for successful auth using timer

    //If nothing happened, wait for 6 second (3 retries), if i got something, show green text, if not, show red one
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
            FilledButton(
              onPressed: () {
                startTheProcess();
              },
              child: const Text("Log In"),
            ),
          ],
        ),
      ),
    );
  }
}
