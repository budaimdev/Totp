import 'package:flutter/material.dart';
import 'package:totp/classes/totp.dart';

class Home extends StatelessWidget {
  Home({super.key});

  final List<Totp> totps = [Totp("Google"), Totp("Facebook")];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: totps.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.all(10),
          elevation: 4,
          child: InkWell(
            onTap: () => {},
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(totps[index].name, style: TextStyle(fontSize: 30)),
            ),
          ),
        );
      },
    );
  }
}