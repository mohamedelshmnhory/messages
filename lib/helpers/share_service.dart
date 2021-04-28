import 'package:flutter/services.dart';

/// This service is responsible for talking with the OS to see if anything was
/// shared with the application.
class ShareService {
  void Function(String) onDataReceived;

  ShareService() {
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg?.contains("resumed") ?? false) {
        getSharedData().then((String data) {
          if (data.isEmpty) {
            return;
          }
          onDataReceived?.call(data);
        });
      }
      return;
    });
  }

  Future<String> getSharedData() async {
    return await MethodChannel('com.nasser.messages')
            .invokeMethod("getSharedData") ??
        "";
  }
}
