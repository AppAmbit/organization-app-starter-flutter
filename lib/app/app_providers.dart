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

class _SelectedTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void select(int index) => state = index;
}

final selectedTabIndexProvider =
    NotifierProvider<_SelectedTabIndexNotifier, int>(
        _SelectedTabIndexNotifier.new);
