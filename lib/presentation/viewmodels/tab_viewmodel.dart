import 'package:flutter/material.dart';

class TabViewModel extends ChangeNotifier {
  int _index = 0;
  bool _isConnected = false;
  String _connectedLocation = 'Russia';
  String _connectedDetails = 'Not connected';

  int get index => _index;
  bool get isConnected => _isConnected;
  String get connectedLocation => _connectedLocation;
  String get connectedDetails => _connectedDetails;

  void changeTab(int value) {
    if (_index == value) return;
    _index = value;
    notifyListeners();
  }

  void setConnection({
    required bool isConnected,
    required String location,
    required String details,
  }) {
    _isConnected = isConnected;
    _connectedLocation = location;
    _connectedDetails = details;
    notifyListeners();
  }
}
