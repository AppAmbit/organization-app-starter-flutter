import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomBarVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void show() => state = true;
  void hide() => state = false;
}

final bottomBarVisibleProvider =
    NotifierProvider<BottomBarVisibleNotifier, bool>(
        BottomBarVisibleNotifier.new);
