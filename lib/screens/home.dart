import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:base32/base32.dart' as base32lib;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<List<TotpClass>> _fetchTotps() async {
    final database = DatabaseWrapper();
    return await database.getAllTotps();
  }

  @override
  void initState() {
    super.initState();
    _totpsFuture = _fetchTotps();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void refresh() {
    setState(() {
      _totpsFuture = _fetchTotps();
    });
  }


  String generateTotp(List<int> secretBytes,
      {int digits = 6, int period = 30}) {
    final counter = DateTime
        .now()
        .toUtc()
        .millisecondsSinceEpoch ~/ 1000 ~/ period;

    final counterBytes = ByteData(8)
      ..setUint64(0, counter, Endian.big);

    final hmac = Hmac(sha1, secretBytes);
    final hash = hmac
        .convert(counterBytes.buffer.asUint8List())
        .bytes;

    final offset = hash[hash.length - 1] & 0x0f;
    final binCode = (hash[offset] & 0x7f) << 24 |
    (hash[offset + 1] & 0xff) << 16 |
    (hash[offset + 2] & 0xff) << 8 |
    (hash[offset + 3] & 0xff);

    final otp = binCode % pow(10, digits).toInt();
    return otp.toString().padLeft(digits, '0');
  }

  String _time(String secret, int digits, int period) {
    try {
      final List<int> secretBytes = base32lib.base32.decode(
          secret.toUpperCase().trim());
      return generateTotp(secretBytes, digits: digits, period: period);
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
                            final id = item.id;
                            if (id != null) {
                              _toggleSelection(id);
                            }
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
                          final id = item.id;
                          if (id != null) {
                            _toggleSelection(id);
                          }
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
                                    Text('${item.period - ((DateTime
                                        .now()
                                        .millisecondsSinceEpoch ~/ 1000) %
                                        item.period)}'),
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
