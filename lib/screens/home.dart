import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:totp/totp.dart';
import 'package:totp_app/classes/totp_class.dart';
import 'package:totp_app/helpers/database.dart';

class Home extends StatefulWidget {
  final ValueNotifier<List<int?>> selectedIdNotifier;

  const Home({super.key, required this.selectedIdNotifier});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  late Future<List<TotpClass>> _totpsFuture;
  Timer? _timer;
  int _remainingSeconds = 0;

  Future<List<TotpClass>> _fetchTotps() async {
    final database = DatabaseWrapper();
    return await database.getAllTotps();
  }

  @override
  void initState() {
    super.initState();
    _totpsFuture = _fetchTotps();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      int currentSeconds = DateTime
          .now()
          .second % 30;
      int remaining = 30 - currentSeconds;

      setState(() {
        _remainingSeconds = remaining;
      });
    });
  }

  void refresh() {
    setState(() {
      _totpsFuture = _fetchTotps();
    });
  }

  String _time(String secret, int digits, int period) {
    try {
      final List<int> secretBytes = base32.decode(secret.toUpperCase().trim());

      final totp = Totp(
        algorithm: Algorithm.sha1,
        secret: secretBytes,
        digits: digits,
        period: period,
      );
      final datetime = DateTime.now().toUtc();
      return totp.generate(datetime);
    } catch (e) {
      return "------";
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleSelection(int id) {
    HapticFeedback.lightImpact();

    final List<int?> currentList = List<int?>.from(
        widget.selectedIdNotifier.value);
    if (currentList.contains(id)) {
      currentList.remove(id);
    } else {
      currentList.add(id);
    }

    widget.selectedIdNotifier.value = currentList;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _totpsFuture,
      builder: (BuildContext context, AsyncSnapshot<List<TotpClass>> snapshot) {
        if (snapshot.hasData) {
          List<TotpClass>? data = snapshot.data;
          if (data != null) {
            if (data.isEmpty) {
              return Center(child: const Text("No TOTPs"));
            }

            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                String code = _time(
                  data[index].secret,
                  data[index].digits,
                  data[index].period,
                );
                final item = data[index];

                return ListenableBuilder(
                  listenable: widget.selectedIdNotifier,
                  builder: (context, child) {
                    final isSelected = widget.selectedIdNotifier.value.contains(
                      item.id,
                    );

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () async {
                          if (widget.selectedIdNotifier.value.isNotEmpty) {
                            _toggleSelection(item.id!);
                          } else {
                            await Clipboard.setData(ClipboardData(text: code));
                            HapticFeedback.mediumImpact();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "The code has been copied to clipboard.",
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        onLongPress: () {
                          _toggleSelection(item.id!);
                        },
                        child: Card(
                          elevation: isSelected ? 8 : 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme
                                  .of(context)
                                  .colorScheme
                                  .outline
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data[index].label,
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        Text(
                                          data[index].issuer,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(_remainingSeconds.toString()),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      code,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          } else {
            return Center(child: const Text("Something went wrong"));
          }
        } else if (snapshot.hasError) {
          return const Text("Error while loading data");
        } else {
          return Center(child: const CircularProgressIndicator());
        }
      },
    );
  }
}
