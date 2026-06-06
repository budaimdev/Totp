
import 'package:flutter/material.dart';
import 'package:totp_app/classes/totp_class.dart';
import 'package:totp_app/helpers/database.dart';
import 'package:totp_app/screens/scanner.dart';

class Editor extends StatefulWidget {
  final int? totpClassId;

  const Editor({super.key, this.totpClassId});

  @override
  State<StatefulWidget> createState() => _Editor();
}

class _Editor extends State<Editor> {
  final TextEditingController label = TextEditingController();
  final TextEditingController issuer = TextEditingController();
  final TextEditingController secret = TextEditingController();
  final TextEditingController digits = TextEditingController();
  final TextEditingController period = TextEditingController();
  String rawValue = "";
  String? _errorText;
  bool _isSavingDisabled = true;
  bool hideSecret = true;
  int? id;
  bool _isLoading = false;
  String? _loadingError;


  @override
  void initState() {
    super.initState();
    label.addListener(_validateForm);
    issuer.addListener(_validateForm);
    secret.addListener(_validateForm);
    digits.addListener(_validateForm);
    period.addListener(_validateForm);

    if (widget.totpClassId != null) {
      _getTotpInfo();
    }
  }

  void _getTotpInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DatabaseWrapper databaseWrapper = DatabaseWrapper();
      TotpClass totp = await databaseWrapper.getOneTotp(widget.totpClassId!);

      if (!mounted) return;

      setState(() {
        id = totp.id;
        label.text = totp.label;
        issuer.text = totp.issuer;
        secret.text = totp.secret;
        digits.text = totp.digits.toString();
        period.text = totp.period.toString();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = "Failed to load data: $e";
        });
      }
    }
  }

  void _processScannedQr() {
    try {
      final uri = Uri.parse(rawValue);

      if (uri.scheme != "otpauth" || uri.pathSegments.isEmpty) {
        setState(() {
          _errorText = "Scanned QR code, but not a valid 2FA code.";
        });
        return;
      }

      final pathSegments = uri.pathSegments[0].split(":");
      final String labelText = pathSegments.isNotEmpty ? pathSegments[0] : "";
      final String? secretText = uri.queryParameters["secret"];
      final String? issuerText = uri.queryParameters["issuer"];
      final String? digitsText = uri.queryParameters["digits"];
      final String? periodText = uri.queryParameters["period"];

      setState(() {
        label.text = labelText;
        issuer.text = issuerText ?? "";
        secret.text = secretText ?? "";
        digits.text = digitsText ?? "6";
        period.text = periodText ?? "30";
      });
    } catch (e) {
      setState(() {
        _errorText = "Failed to parse QR code.";
      });
    }
  }

  void _validateForm() {
    final bool isFormValid = label.text.isNotEmpty &&
        issuer.text.isNotEmpty &&
        secret.text.isNotEmpty &&
        period.text.isNotEmpty &&
        digits.text.isNotEmpty;

    if (_isSavingDisabled == isFormValid) {
      setState(() {
        _isSavingDisabled = !isFormValid;
      });
    }
  }

  void save() async {
    try {
      final db = DatabaseWrapper();
      TotpClass newTotp = TotpClass(
          id: id,
          issuer: issuer.text,
          secret: secret.text,
          label: label.text,
          digits: int.tryParse(digits.text) ?? 6,
          period: int.tryParse(period.text) ?? 30
      );

      id = await db.addOrUpdateTotp(newTotp);

      if (mounted) {
        Navigator.of(context).pop(id);
      }
    } catch (e) {
      _loadingError = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save: $e"))
        );
      }
    }
  }

  @override
  void dispose() {
    label.dispose();
    issuer.dispose();
    secret.dispose();
    period.dispose();
    digits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.totpClassId == null
            ? const Text("Add new TOTP")
            : const Text(
            "Edit totp"),
        actions: [
          IconButton(
            onPressed: _isSavingDisabled ? null : () async {
              save();
            },
            icon: Icon(Icons.save),
          )
        ],
      ),
      body: _isLoading ? CircularProgressIndicator() : _loadingError == null
          ? Padding(
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
              keyboardType: TextInputType.visiblePassword,
              enableSuggestions: false,
              autocorrect: false,
              obscureText: hideSecret,
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(onPressed: () =>
                      setState(() {
                        hideSecret = !hideSecret;
                      }),
                      icon: hideSecret ? Icon(Icons.visibility) : Icon(
                          Icons.visibility_off))
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: digits,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Digits",
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: TextField(
                    controller: period,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Period",
                    ),
                  ),
                ),
              ],
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
                      _processScannedQr();
                    }
                  },
                  child: const Text("Scan"),
                )
              ],
            ),
            if (_errorText != null) Text(
              _errorText!, style: TextStyle(color: Colors.red),)
          ],
        ),
      )
          : Center(child: const Text("Failed to load TOTP")),
    );
  }
}