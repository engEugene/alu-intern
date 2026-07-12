import 'package:flutter_riverpod/flutter_riverpod.dart';

final class PageLimitNotifier extends Notifier<int> {
  @override
  int build() => 10;

  void loadMore() => state += 10;
  void reset() => state = 10;
}
