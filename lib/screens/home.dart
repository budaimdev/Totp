import 'package:flutter/material.dart';
import 'package:totp/classes/totp.dart';

class Home extends StatelessWidget {
  Home({super.key});

  final List<Totp> totps = [
    Totp(id: 0,
        issuer: "Google",
        secret: "secret",
        label: "Google",
        digits: 6),
    Totp(id: 1,
        issuer: "Facebook",
        secret: "secret",
        label: "Facebook",
        digits: 6),
  ];

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(totps[index].label, style: TextStyle(fontSize: 30)),
                      Text(totps[index].issuer,
                        style: TextStyle(fontSize: 20, color: Colors.grey),)
                    ],
                  ),
                  Text(totps[index].secret)
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}