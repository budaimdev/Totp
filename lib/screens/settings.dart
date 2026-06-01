import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:totp_app/classes/appsettings.dart';
import 'package:totp_app/helpers/local_storage.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
        body: ListView(
        children: [
          ListTile(
            title: const Text("Theme"),
            trailing: DropdownButton(
              value: LocalStorage.settings.brightness,
              items: Brightness.values.map<DropdownMenuItem<Brightness>>((
                  Brightness value) {
                return DropdownMenuItem(
                    value: value, child: Text(value.name.capitalize));
              }).toList(),
              onChanged: (value) {
                LocalStorage.prefs.setString("theme", value?.name ?? "light");
                setState(() {
                  LocalStorage.settings = Appsettings.load(LocalStorage.prefs);
                  LocalStorage.settingsNotifier.value = LocalStorage.settings;
                });
              },
            ),
          ),
        ],
        )
    );
  }
}