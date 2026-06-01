import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:totp_app/classes/appsettings.dart';
import 'package:totp_app/helpers/database.dart';
import 'package:totp_app/helpers/local_storage.dart';
import 'package:totp_app/screens/add.dart';
import 'package:totp_app/screens/home.dart';
import 'package:totp_app/screens/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseWrapper().initDatabase();
  await LocalStorage.init();
  //TODO: Check if I can authenticate

  runApp(TotpApp());
}
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
              final ColorScheme lightColorScheme = settings.useDynamicColors &&
                  lightDynamic != null
                  ? lightDynamic
                  : ColorScheme.fromSeed(
                  brightness: Brightness.light, seedColor: settings.color);

              final ColorScheme darkColorScheme = settings.useDynamicColors &&
                  darkDynamic != null
                  ? darkDynamic
                  : ColorScheme.fromSeed(
                  brightness: Brightness.dark, seedColor: settings.color);

              return MaterialApp(
                title: 'TOTP',
                theme: ThemeData(
                    useMaterial3: true,
                    colorScheme: lightColorScheme
                ),
                darkTheme: ThemeData(
                    useMaterial3: true,
                    colorScheme: settings.useForAmoled ? darkColorScheme
                        .copyWith(surface: Colors.black) : darkColorScheme
                ),
                home: const NavigationStuff(),
                themeMode: settings.brightness == Brightness.light ? ThemeMode
                    .light : ThemeMode.dark,
              );
            }
        );
      }
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
                Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => Settings(),
                    )
                );
              }
          )
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TOTP"),
        actions: [
          IconButton(
              onPressed: () => _homeKey.currentState?.refresh(),
              icon: Icon(Icons.refresh))
        ],
      ),
      drawer: Sidebar(),
      body: Home(key: _homeKey,),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final int? newId = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const Add())
          );

          if (newId != null) {
            _homeKey.currentState?.refresh();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}