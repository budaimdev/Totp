import 'dart:async';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:totp_app/helpers/local_storage.dart';
import 'package:url_launcher/url_launcher.dart';

const String githubUrl = "https://github.com/budaimdev/totp";

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
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final LocalAuthentication auth = LocalAuthentication();
    final canUseBio = await auth.canCheckBiometrics;
    setState(() {
      try {
        LocalStorage.settings.canUseBio = canUseBio;
      } catch (_) {
        LocalStorage.settings.canUseBio = false;
      }
    });
    await LocalStorage.settings.save(LocalStorage.prefs);
  }

  Future<bool> setupAuth() async {
    final LocalAuthentication auth = LocalAuthentication();
    final canUseBio = await auth.canCheckBiometrics;
    if (!canUseBio) return false;

    try {
      return await auth.authenticate(
          localizedReason: "You need to verify yourself to enable auth.",
          persistAcrossBackgrounding: true,
          biometricOnly: true
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.palette),
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
            leading: Icon(Icons.colorize),
            title: const Text("App color"),
            trailing: ElevatedButton(
              onPressed: () => openColorPicker(context),
              child: const Text("Change app color"),
            ),
          ),
          SwitchListTile(
            title: const Text("Use dynamic colors"),
            secondary: Icon(Icons.auto_awesome),
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
            secondary: Icon(Icons.phone_android),
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
          SwitchListTile(
              title: const Text("Enable authentication"),
              secondary: Icon(Icons.lock),
              value: LocalStorage.settings.useBio,
              onChanged: !LocalStorage.settings.canUseBio ? null : (
                  value) async {
                if (value) {
                  if (await setupAuth()) {
                    setState(() {
                      LocalStorage.settings.useBio = true;
                    });
                    await LocalStorage.settings.save(LocalStorage.prefs);
                  }
                } else {
                  setState(() {
                    LocalStorage.settings.useBio = false;
                  });
                  await LocalStorage.settings.save(LocalStorage.prefs);
                }
              }
          ),
          ListTile(
            trailing: Text("© ${DateTime
                .now()
                .year} Michal Budai (budaimdev)",
              style: TextStyle(fontSize: 10),),
          ),
          ListTile(
              trailing:
              IconButton.outlined(onPressed: () async {
                final Uri url = Uri.parse(githubUrl);

                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Nepodařilo se otevřít GitHub.'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: const Duration(seconds: 3),
                        action: SnackBarAction(
                          label: 'Zavřít',
                          textColor: Colors.white,
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          },
                        ),
                      ),
                    );
                  }
                }
              }, icon: Icon(Icons.code))
          )
        ],
      ),
    );
  }
}
