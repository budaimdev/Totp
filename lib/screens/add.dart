
import 'package:flutter/material.dart';
import 'package:totp/classes/totp.dart';
import 'package:totp/helpers/database.dart';
import 'package:totp/screens/scanner.dart';

class Add extends StatefulWidget {
  const Add({super.key});

  @override
  State<StatefulWidget> createState() => _Add();
}

class _Add extends State<Add> {
  final TextEditingController label = TextEditingController();
  final TextEditingController issuer = TextEditingController();
  final TextEditingController secret = TextEditingController();
  String rawValue = "";
  String? _errorText;
  bool _isSavingDisabled = true;


  @override
  void initState() {
    super.initState();
    label.addListener(_validateForm);
    issuer.addListener(_validateForm);
    secret.addListener(_validateForm);
  }

  void _processScannedQr() {
    Uri uri = Uri.parse(rawValue);

    if (uri.scheme != "otpauth") {
      setState(() {
        _errorText = "Scanned QR code, but not a valid 2FA code.";
      });
      return;
    }

    var pathSegments = uri.pathSegments[0].split(":");
    String? labelText = pathSegments[0];
    String? secretText = uri.queryParameters["secret"];
    String? issuerText = uri.queryParameters["issuer"];

    setState(() {
      label.text = labelText;
      issuer.text = issuerText ?? "";
      secret.text = secretText ?? "";
    });
  }

  void _validateForm() {
    final bool isFormValid = label.text.isNotEmpty &&
        issuer.text.isNotEmpty &&
        secret.text.isNotEmpty;

    if (_isSavingDisabled == isFormValid) {
      setState(() {
        _isSavingDisabled = !isFormValid;
      });
    }
  }

  @override
  void dispose() {
    label.dispose();
    issuer.dispose();
    secret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add new TOTP"),
        actions: [
          IconButton(
            onPressed: _isSavingDisabled ? null : () async {
              final db = DatabaseWrapper();
              Totp newTotp = Totp(
                  issuer: issuer.text,
                  secret: secret.text,
                  label: label.text,
                  digits: 6
              );
              int id = await db.addTotp(newTotp);
              if (context.mounted) {
                Navigator.of(context).pop(id);
              }
            },
            icon: Icon(Icons.save),

          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          spacing: 10.0,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("TOTP Label"),
            TextField(
              controller: label,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const Text("TOTP Issuer"),
            TextField(
              controller: issuer,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const Text("TOTP Secret"),
            TextField(
              controller: secret,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                //const Text("OR you can scan a QR code to fill in the secret automatically"),
                FilledButton(
                  onPressed: () async {
                    final String? result = await Navigator.of(context).push<
                        String>(
                      MaterialPageRoute(builder: (context) => const Scanner()),
                    );

                    if (result != null && mounted) {
                      setState(() {
                        _errorText = null;
                        rawValue = result;
                      });
                    }
                    _processScannedQr();
                  },
                  child: const Text("Scan"),
                )
              ],
            ),
            if (_errorText != null) Text(
              _errorText!, style: TextStyle(color: Colors.red),)
          ],
        ),
      ),
    );
  }
}