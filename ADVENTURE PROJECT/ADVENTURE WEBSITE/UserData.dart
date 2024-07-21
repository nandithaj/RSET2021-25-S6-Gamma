import 'package:flutter/foundation.dart';

class UserData extends ChangeNotifier {
  int? _userId;
  bool _isSuperAdmin = true;

  int? get userId => _userId;

  set userId(int? value) {
    _userId = value;
    notifyListeners(); // Notify listeners of the change
  }

  bool get isSuperAdmin => _isSuperAdmin;
  set isSuperAdmin(bool value) {
    _isSuperAdmin = value;
    notifyListeners();
  }
}
