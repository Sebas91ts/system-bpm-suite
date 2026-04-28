import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationControllerProvider = ChangeNotifierProvider<NavigationController>((ref) {
  return NavigationController();
});

class NavigationController extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void setIndex(int index) {
    if (_index == index) {
      return;
    }

    _index = index;
    notifyListeners();
  }
}
