import 'dart:async';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:totp_app/helpers/local_storage.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  Future<void> openColorPicker(BuildContext context) async {
    final Color newColor = await showColorPickerDialog(
      context,
      LocalStorage.settings.color,

      title: Text(
        'Color settings',
        style: Theme.of(context).textTheme.titleLarge,
      ),

      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: false,
        ColorPickerType.accent: false,
        ColorPickerType.bw: false,
        ColorPickerType.custom: false,
        ColorPickerType.wheel: true,
      },
      enableOpacity: true,
      showColorCode: true,
      showColorValue: true,
      showRecentColors: true,
      maxRecentColors: 5,
      wheelDiameter: 230,

      actionButtons: const ColorPickerActionButtons(
        dialogOkButtonLabel: 'Save',
        dialogCancelButtonLabel: 'Cancel',
      ),
    );

    if (!mounted) return;

    if (newColor != LocalStorage.settingsNotifier.value.color) {
      setState(() {
        LocalStorage.settings.color = newColor;
      });
      await LocalStorage.settings.save(LocalStorage.prefs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Theme"),
            trailing: DropdownButton(
              value: LocalStorage.settings.brightness,
              items: Brightness.values.map<DropdownMenuItem<Brightness>>((
                  Brightness value,) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value.name
                      .capitalize), //Provided by package:flex_color_picker/src/color_picker_extensions.dart
                );
              }).toList(),
              onChanged: (value) async {
                setState(() {
                  LocalStorage.settings.brightness = value!;
                });
                await LocalStorage.settings.save(LocalStorage.prefs);
              },
            ),
          ),
          ListTile(
            title: const Text("App color"),
            trailing: ElevatedButton(
              onPressed: () => openColorPicker(context),
              child: const Text("Change app color"),
            ),
          ),
          SwitchListTile(
            title: const Text("Use dynamic colors"),
            value: LocalStorage.settings.useDynamicColors,
            onChanged: (value) async {
              setState(() {
                LocalStorage.settings.useDynamicColors = value;
              });
              await LocalStorage.settings.save(LocalStorage.prefs);
            },
          ),
          SwitchListTile(
            title: const Text("Mode for AMOLED displays"),
            value: LocalStorage.settings.useForAmoled,
            onChanged: LocalStorage.settings.brightness == Brightness.light
                ? null
                : (value) async {
              setState(() {
                LocalStorage.settings.useForAmoled = value;
              });
              await LocalStorage.settings.save(LocalStorage.prefs);
            },
          ),
        ],
      ),
    );
  }
}
