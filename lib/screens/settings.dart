import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: const Text("Theme")
              ),

            ],
          )
        ],
      ),
    );
  }
}