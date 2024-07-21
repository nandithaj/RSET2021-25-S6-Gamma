import 'package:flutter/material.dart';

class ScreenIdProvider extends ChangeNotifier {
  int? _screenId;

  int? get screenId => _screenId;

  void setSelectedScreenId(int? id) {
    _screenId = id;
    notifyListeners();
  }
}
