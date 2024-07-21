// In a separate file (e.g., user_data.dart)
import 'package:flutter/foundation.dart';

class UserData extends ChangeNotifier {
  int? _userId;

  int? get userId => _userId;

  set userId(int? value) {
    _userId = value;
    notifyListeners(); // Notify listeners of the change
  }
}
