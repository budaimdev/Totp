import 'package:flutter/material.dart';
import 'package:totp/classes/totp.dart';
import 'package:totp/helpers/database.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  late Future<List<Totp>> _totpsFuture;

  Future<List<Totp>> _fetchTotps() async {
    final database = DatabaseWrapper();
    return await database.getAllTotps();
  }

  @override
  void initState() {
    super.initState();
    _totpsFuture = _fetchTotps();
  }

  void refresh() {
    setState(() {
      _totpsFuture = _fetchTotps();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _totpsFuture,
        builder: (BuildContext context, AsyncSnapshot<List<Totp>> snapshot) {
          if (snapshot.hasData) {
            List<Totp>? data = snapshot.data;
            if (data != null) {
              if (data.isEmpty) {
                return Center(
                  child: const Text("No TOTPs"),
                );
              }

              return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(data[index].label,
                                        style: TextStyle(fontSize: 20),),
                                      Text(data[index].issuer, style: TextStyle(
                                          fontSize: 15, color: Colors.grey),),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
              );
            } else {
              return Center(
                child: const Text("Something went wrong"),
              );
            }
          } else if (snapshot.hasError) {
            return const Text("Error while loading data");
          } else {
            return const CircularProgressIndicator();
          }
        }
    );
  }
}