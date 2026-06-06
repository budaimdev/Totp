import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:totp_app/classes/appsettings.dart';
import 'package:totp_app/helpers/database.dart';
import 'package:totp_app/helpers/local_storage.dart';
import 'package:totp_app/screens/editor.dart';
import 'package:totp_app/screens/home.dart';
import 'package:totp_app/screens/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseWrapper().initDatabase();
  await LocalStorage.init();
  final LocalAuthentication auth = LocalAuthentication();

  try {
    LocalStorage.settings.canUseBio = await auth.canCheckBiometrics;
  } catch (_) {
    LocalStorage.settings.canUseBio = false;
  }

  runApp(TotpApp());
}

enum Actions { edit, delete }

class TotpApp extends StatelessWidget {
  const TotpApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: LocalStorage.settingsNotifier,
      builder: (context, settings, child) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            final ColorScheme lightColorScheme =
                settings.useDynamicColors && lightDynamic != null
                ? lightDynamic
                : ColorScheme.fromSeed(
                    brightness: Brightness.light,
                    seedColor: settings.color,
                  );

            final ColorScheme darkColorScheme =
                settings.useDynamicColors && darkDynamic != null
                ? darkDynamic
                : ColorScheme.fromSeed(
                    brightness: Brightness.dark,
                    seedColor: settings.color,
                  );

            return MaterialApp(
              title: 'TOTP',
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: lightColorScheme,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: settings.useForAmoled
                    ? darkColorScheme.copyWith(surface: Colors.black)
                    : darkColorScheme,
              ),
              home: const NavigationStuff(),
              themeMode: settings.brightness == Brightness.light
                  ? ThemeMode.light
                  : ThemeMode.dark,
            );
          },
        );
      },
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(child: const Text("Menu")),
          ListTile(
            leading: Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (context) => Settings()));
            },
          ),
        ],
      ),
    );
  }
}

class NavigationStuff extends StatefulWidget {
  const NavigationStuff({super.key});

  @override
  State<StatefulWidget> createState() => _NavigationStuffState();
}

class _NavigationStuffState extends State<NavigationStuff> {
  final GlobalKey<HomeState> _homeKey = GlobalKey<HomeState>();
  bool _isLocked =
      LocalStorage.settings.canUseBio && LocalStorage.settings.useBio;
  final ValueNotifier<List<int?>> selectedIdNotifier =
      ValueNotifier<List<int?>>([]);

  @override
  void initState() {
    super.initState();
    if (_isLocked) {
      _checkLock();
    }
  }

  @override
  void dispose() {
    selectedIdNotifier.dispose();
    super.dispose();
  }

  void delete() async {
    DatabaseWrapper db = DatabaseWrapper();
    if (selectedIdNotifier.value.isNotEmpty) {
      for (var id in selectedIdNotifier.value) {
        await db.removeTotp(id!);
      }
      selectedIdNotifier.value = [];
      _homeKey.currentState?.refresh();
    }
  }

  Future<void> _checkLock() async {
    if (LocalStorage.settings.canUseBio && LocalStorage.settings.useBio) {
      LocalAuthentication auth = LocalAuthentication();
      try {
        bool isAuthenticated = await auth.authenticate(
          localizedReason:
              "You have to authenticate to access the contents of this app",
          persistAcrossBackgrounding: true,
          biometricOnly: true,
        );

        if (isAuthenticated && mounted) {
          setState(() {
            _isLocked = false;
          });
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isLocked = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkLock,
                child: const Text("Unlock app"),
              ),
            ],
          ),
        ),
      );
    }

    return ValueListenableBuilder(
      valueListenable: selectedIdNotifier,
      builder: (context, value, child) {
        return Scaffold(
          appBar: AppBar(
            title: selectedIdNotifier.value.isEmpty
                ? const Text("Totp")
                : Text("Selected ${selectedIdNotifier.value.length}"),
            leading: value.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      selectedIdNotifier.value = [];
                    },
                    icon: Icon(Icons.arrow_back),
                  ),
            actions: [
              if (selectedIdNotifier.value.isEmpty)
                IconButton(
                  onPressed: () => _homeKey.currentState?.refresh(),
                  icon: Icon(Icons.refresh),
                )
              else
                PopupMenuButton<Actions>(
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<Actions>>[
                        PopupMenuItem<Actions>(
                          child: TextButton(
                            onPressed: selectedIdNotifier.value.length > 1
                                ? null
                                : () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      Editor(
                                          totpClassId: selectedIdNotifier.value
                                              .first)));
                              _homeKey.currentState?.refresh();
                            },
                            child: Text(Actions.edit.name.capitalize),
                          ),
                        ),
                        PopupMenuItem<Actions>(
                          child: TextButton(
                            child: Text(Actions.delete.name.capitalize),
                            onPressed: () {
                              Navigator.of(context).pop();
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Delete TOTP?"),
                                    content: Text(
                                        "Do you really want to permanently delete ${selectedIdNotifier
                                            .value.length} TOTP(s)?"),
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
                                        style: ButtonStyle(
                                            backgroundColor: WidgetStateProperty
                                                .all(Colors.red)
                                        ),
                                        child: Text("Delete",
                                          style: TextStyle(color: Theme
                                              .of(context)
                                              .colorScheme
                                              .primary),),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                ),
            ],
          ),
          drawer: Sidebar(),
          body: Home(key: _homeKey, selectedIdNotifier: selectedIdNotifier),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              selectedIdNotifier.value = [];
              final int? newId = await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => const Editor()));

              if (newId != null) {
                _homeKey.currentState?.refresh();
              }
            },
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}
