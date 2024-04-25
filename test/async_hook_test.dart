import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_async_hook/flutter_async_hook.dart';

// TODO(masreplay): implement integration real test
void main() {
  test('useAsyncState', () {
    final state = useAsyncState();
    expect(state(Future.value(42)), 42);
  });
}
