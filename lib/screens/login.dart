import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  String? token;
  bool uriError = false;

  bool checkForValidUrl() {
    String text = _urlController.text;
    Uri? uri = Uri.tryParse(text);

    return uri != null && (uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  void startTheProcess() async {}

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
