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
  Future<void> openColorPicker(BuildContext context) async {
    final Color newColor = await showColorPickerDialog(
      context,
      LocalStorage.settings.color,

      title: Text(
        'Nastavení barvy',
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
        dialogOkButtonLabel: 'Uložit',
        dialogCancelButtonLabel: 'Zrušit',
      ),
    );

    if (newColor != LocalStorage.settings.color) {
      LocalStorage.prefs.setInt("app_color", newColor.toARGB32());
      setState(() {
          LocalStorage.settings = Appsettings.load(LocalStorage.prefs);
          LocalStorage.settingsNotifier.value = LocalStorage.settings;
      });
    }
  }

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
          ListTile(
            title: const Text("App color"),
            trailing: ElevatedButton(onPressed: () => openColorPicker(context), child: const Text("Chang app color"))
          )
        ],
        )
    );
  }
}

