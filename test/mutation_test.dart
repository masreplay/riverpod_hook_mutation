import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_hook_mutation/riverpod_hook_mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('use Mutation ', () {
    testWidgets('create mutation with noting state as initial value ',
        (tester) async {
      Widget build() {
        return ProviderScope(
          child: HookConsumer(
            builder: (c, ref, child) {
              final mutation = useMutation();
              return Text(
                mutation.value.connectionState.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        );
      }

      await tester.pumpWidget(build());

      expect(find.text('ConnectionState.none'), findsOneWidget);
    });

    testWidgets('create mutation with data as initial value ', (tester) async {
      Widget build() {
        return ProviderScope(
          child: HookConsumer(
            builder: (c, ref, child) {
              final mutation = useMutation(data: 42);
              return Text(
                mutation.value.connectionState.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        );
      }

      await tester.pumpWidget(build());

      expect(find.text('ConnectionState.done'), findsOneWidget);
    });

    testWidgets('create mutation with data as initial state', (tester) async {
      Widget build() {
        return ProviderScope(
          child: HookConsumer(
            builder: (c, ref, child) {
              final mutation = useMutation(
                  state:
                      const AsyncSnapshot.withData(ConnectionState.done, 42));
              return Text(
                mutation.value.connectionState.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        );
      }

      await tester.pumpWidget(build());

      expect(find.text('ConnectionState.done'), findsOneWidget);
    });

    testWidgets('create mutation with error as initial state ', (tester) async {
      Widget build() {
        return ProviderScope(
          child: HookConsumer(
            builder: (c, ref, child) {
              final mutation = useMutation(
                state: AsyncSnapshot.withError(
                  ConnectionState.done,
                  'error',
                  StackTrace.current,
                ),
              );
              return Text(
                '${mutation.value.connectionState} - ${mutation.value.error}',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        );
      }

      await tester.pumpWidget(build());

      expect(find.text('ConnectionState.done - error'), findsOneWidget);
    });

    testWidgets('create mutation with loading as initial state',
        (tester) async {
      Widget build() {
        return ProviderScope(
          child: HookConsumer(
            builder: (c, ref, child) {
              final mutation =
                  useMutation(state: const AsyncSnapshot.waiting());
              return mutation.isLoading
                  ? const Text(
                      'loading',
                      textDirection: TextDirection.ltr,
                    )
                  : const Text(
                      'done',
                      textDirection: TextDirection.ltr,
                    );
            },
          ),
        );
      }

      await tester.pumpWidget(build());

      expect(find.text('loading'), findsOneWidget);
    });
  });
  
}
