import 'dart:async';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:totp_app/classes/account.dart';
import 'package:totp_app/classes/appsettings.dart';
import 'package:totp_app/classes/webdav.dart';
import 'package:totp_app/helpers/local_storage.dart';
import 'package:totp_app/screens/login.dart';
import 'package:url_launcher/url_launcher.dart';

const String githubUrl = "https://github.com/budaimdev/totp";

enum AccountActions {
  delete("Delete", Icons.delete);

  final String name;
  final IconData icon;

  const AccountActions(this.name, this.icon);

  void execute(BuildContext context, VoidCallback delete) {
    switch (this) {
      case AccountActions.delete:
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Delete account?"),
              content: Text(
                  "Do you really want to delete this account?"
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () {
                    delete();
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Delete"),
                ),
              ],
            );
          },
        );
        break;
    }
  }
}

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  AccountActions? selectedItem;

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

  void _setupAuth() async {
    Account? account = await Account.getAccount();
    if (account == null) return;
    LocalStorage.webdavClient =
        Webdav().init(account.loginName, account.appPassword, account.url);
  }

  void delete() async {
    try {
      await Account.removeAccount();
      LocalStorage.settings.account = null;
      LocalStorage.settingsNotifier.value = LocalStorage.settings;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text("Removed user successfully.")
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text("Failed to remove user.")
        ));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final LocalAuthentication auth = LocalAuthentication();
    bool canUseBio;
    try {
      canUseBio = await auth.canCheckBiometrics;
    } on PlatformException catch (_) {
      canUseBio = false;
    }

    if (!mounted) return;
    setState(() {
      LocalStorage.settings.canUseBio = canUseBio;
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
        biometricOnly: true,
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
            title: const Text("General", style: TextStyle(fontSize: 20)),
          ),
          ListTile(
            leading: Icon(Icons.palette),
            title: const Text("Theme"),
            trailing: DropdownButton(
              value: LocalStorage.settings.brightness,
              items: Brightness.values.map<DropdownMenuItem<Brightness>>((
                  Brightness value,) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(
                    value.name[0].toUpperCase() + value.name.substring(1),
                  ),
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
            onChanged: !LocalStorage.settings.canUseBio
                ? null
                : (value) async {
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
            },
          ),
          Divider(),
          ListTile(
            title: const Text(
              "Synchronization",
              style: TextStyle(fontSize: 20),
            ),
          ),
          SwitchListTile(
            title: const Text("Use Nextcloud sync"),
            value: LocalStorage.settings.useSync,
            onChanged: (value) async {
              if (value) {
                setState(() {
                  LocalStorage.settings.useSync = true;
                });
                _setupAuth();
                await LocalStorage.settings.save(LocalStorage.prefs);
              } else {
                setState(() {
                  LocalStorage.settings.useSync = false;
                });
                await LocalStorage.settings.save(LocalStorage.prefs);
              }
            },
          ),
          ValueListenableBuilder<AppSettings>(
            valueListenable: LocalStorage.settingsNotifier,
            builder: (context, value, child) {
              return ListTile(
                  title: const Text("Account"),
                  trailing: LocalStorage.settings.useSync ? LocalStorage
                      .settings.account == null
                      ? IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => Login(),
                        ),
                      );
                    },
                    icon: Icon(Icons.add),
                  )
                      : MenuAnchor(
                    builder:
                        (BuildContext context,
                        MenuController controller,
                        Widget? child,) {
                      return GestureDetector(
                        onTap: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Theme
                                    .of(context)
                                    .colorScheme
                                    .primary,
                                Theme
                                    .of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Theme
                                  .of(
                                context,
                              )
                                  .colorScheme
                                  .primaryContainer,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            LocalStorage.settings.account!.loginName.isNotEmpty
                                ?
                            LocalStorage.settings.account!.loginName[0]
                                .toUpperCase()
                                : "?",
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      );
                    },
                    menuChildren: AccountActions.values.map((
                        AccountActions action,) {
                      return MenuItemButton(
                        leadingIcon: Icon(action.icon),
                        child: Text(action.name),
                        onPressed: () {
                          action.execute(context, delete);

                          setState(() {
                            selectedItem = action;
                          });
                        },
                      );
                    }).toList(),
                  ) : const Text("Disabled")
              );
            },
          ),
          Divider(),
          ListTile(
            trailing: Text(
              "© ${DateTime
                  .now()
                  .year} Michal Budai (budaimdev)",
              style: TextStyle(fontSize: 10),
            ),
          ),
          ListTile(
            trailing: IconButton.outlined(
              onPressed: () async {
                final Uri url = Uri.parse(githubUrl);

                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Failed to open GitHub.'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: const Duration(seconds: 3),
                        action: SnackBarAction(
                          label: 'Close',
                          textColor: Colors.white,
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          },
                        ),
                      ),
                    );
                  }
                }
              },
              icon: Icon(Icons.code),
            ),
          ),
        ],
      ),
    );
  }
}
