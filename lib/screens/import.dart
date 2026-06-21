import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:otpauth_migration/generated/GoogleAuthenticatorImport.pbserver.dart';
import 'package:otpauth_migration/otpauth_migration.dart';
import 'package:totp_app/classes/totp_class.dart';
import 'package:totp_app/helpers/database.dart';
import 'package:totp_app/screens/scanner.dart';

class Import extends StatefulWidget {
  const Import({super.key});

  @override
  State<StatefulWidget> createState() => _Import();
}

class _Import extends State<Import> {
  final otpAuthParser = OtpAuthMigration();
  String something = "";

  final List<String> _rfc3548 = [
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
  ];

  String _decodeBase32(List<int> s) {
    //print(s);
    Uint8List ulist = s as Uint8List;
    String result = "";

    var i = 0;
    while (i < ulist.length) {
      var q0 = ulist[i] & 0xF8;
      q0 = q0 >> 3;
      //print(_rfc3548[q0]);
      result += _rfc3548[q0];

      var q1 = ulist[i++] & 0x07;
      q1 = q1 << 2;
      var temp = ulist[i] & 0xC0;
      temp = temp >> 6;
      q1 = q1 + temp;
      //print(_rfc3548[q1]);
      result += _rfc3548[q1];

      var q2 = ulist[i] & 0x3E;
      q2 = q2 >> 1;
      //print(_rfc3548[q2]);
      result += _rfc3548[q2];

      var q3 = ulist[i++] & 0x01;
      q3 = q3 << 4;
      temp = ulist[i] & 0xF0;
      temp = temp >> 4;
      q3 = q3 + temp;
      //print(_rfc3548[q3]);
      result += _rfc3548[q3];

      var q4 = ulist[i++] & 0x0F;
      q4 = q4 << 1;
      temp = ulist[i] & 0x80;
      temp = temp >> 7;
      q4 = q4 + temp;
      //print(_rfc3548[q4]);
      result += _rfc3548[q4];

      var q5 = ulist[i] & 0x7c;
      q5 = q5 >> 2;
      //print(_rfc3548[q5]);
      result += _rfc3548[q5];

      var q6 = ulist[i++] & 0x03;
      q6 = q6 << 3;
      temp = ulist[i] & 0xE0;
      temp = temp >> 5;
      q6 = q6 + temp;
      //print(_rfc3548[q6]);
      result += _rfc3548[q6];

      var q7 = ulist[i++] & 0x1F;
      //print(_rfc3548[q7]);
      result += _rfc3548[q7];
    }

    //print(result);
    return result;
  }

  void _processMigration() async {
    Uri uri = Uri.parse(something);
    String? query = uri.queryParameters["data"];
    if (query != null) {
      DatabaseWrapper wrapper = DatabaseWrapper();
      final gai = GoogleAuthenticatorImport.fromBuffer(base64Decode(query));
      for (var param in gai.otpParameters) {
        String secret = _decodeBase32(param.secret);
        late int digits;

        switch (param.digits) {
          case GoogleAuthenticatorImport_DigitCount.DIGIT_COUNT_EIGHT:
            digits = 8;
            break;
          case GoogleAuthenticatorImport_DigitCount.DIGIT_COUNT_SIX:
            digits = 6;
            break;
          case GoogleAuthenticatorImport_DigitCount.DIGIT_COUNT_UNSPECIFIED:
            digits = 6;
            break;
        }

        TotpClass totp = TotpClass(
          issuer: param.issuer,
          secret: secret,
          label: param.name,
          digits: digits,
            period: 30
        );
        await wrapper.addOrUpdateTotp(totp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Import codes")),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10.0,
          children: [
            const Text(
              "Import TOTP codes",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const Text(
              "This app currently support importing only from Google Authenticator. Better support coming soon.",
              style: TextStyle(fontSize: 15),
            ),
            FilledButton.icon(
              onPressed: () async {
                final String? result = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (context) => const Scanner()),
                );
                if (mounted && result != null) {
                  setState(() {
                    something = result;
                  });

                  _processMigration();
                }
              },
              icon: Icon(Icons.camera_alt),
              label: const Text("Scan"),
            ),
            Text(something),
          ],
        ),
      ),
    );
  }
}
