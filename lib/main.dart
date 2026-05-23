import 'package:flutter/material.dart';
import 'package:totp/screens/add.dart';
import 'package:totp/screens/home.dart';
import 'package:totp/screens/settings.dart';

void main() {
  runApp(const TotpApp());
}

class TotpApp extends StatelessWidget {
  const TotpApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOTP',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TOTP"),
        actions: [
          IconButton(
              onPressed: () => {}, icon: Icon(Icons.refresh))
        ],
      ),
      drawer: Sidebar(),
      body: Home(),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const Add())
            ),
        child: Icon(Icons.add),
      ),
    );
  }
}