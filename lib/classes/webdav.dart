import 'dart:convert';
import 'dart:typed_data';

import 'package:webdav_plus/webdav_plus.dart';

class Webdav {
  late WebdavClient _client;

  static final Webdav _instance = Webdav._internal();

  Webdav._internal();

  factory Webdav() {
    return _instance;
  }

  void init(String username, String password, String baseUrl) {
    _client = WebdavClient.withCredentials(
      username,
      password,
      baseUrl: baseUrl,
    );
  }

  Future<List<DavResource>> listResources(String url) async {
    return await _client.list(url);
  }

  Future<void> createDirectory(String url) async {
    await _client.createDirectory(url);
  }

  Future<void> uploadFile(String url, String data) async {
    Uint8List convertedData = Uint8List.fromList(utf8.encode(data));
    await _client.put(url, convertedData);
  }

  Future<void> deleteFile(String url) async {
    await _client.delete(url);
  }
}
