import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totp_app/helpers/database.dart';
import 'package:totp_app/screens/add.dart';
import 'package:totp_app/screens/home.dart';
import 'package:totp_app/screens/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseWrapper().initDatabase();
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(TotpApp(prefs: prefs,));
}

class TotpApp extends StatelessWidget {
  final SharedPreferences prefs;
  const TotpApp({super.key, required this.prefs});



  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOTP',
      theme: ThemeData(
        useSystemColors: true,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark
        )
      ),
      home: const NavigationStuff(),
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
                      builder: (context) => const Settings(),
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