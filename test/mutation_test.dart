import 'dart:async';
import 'dart:math';

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
                  : Text(
                      mutation.connectionState.toString(),
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

  group('reload value notifier state', () {
    testWidgets('current state data', (tester) async {
      Widget build() {
        return ProviderScope(
          child: HookConsumer(
            builder: (c, ref, child) {
              final mutation = useMutation(data: 42);
              return Row(
                textDirection: TextDirection.ltr,
                children: [
                  GestureDetector(
                    onTap: mutation.reload,
                    child: const Icon(
                      Icons.clear,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  Text(
                    mutation.value.connectionState.toString(),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              );
            },
          ),
        );
      }

      await tester.pumpWidget(build());

      expect(find.text('ConnectionState.done'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));

      await tester.pump();

      expect(find.text('ConnectionState.none'), findsOneWidget);
    });

    testWidgets('current state error', (tester) async {
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
              return Row(
                textDirection: TextDirection.ltr,
                children: [
                  GestureDetector(
                    onTap: mutation.reload,
                    child: const Icon(
                      Icons.clear,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  Text(
                    '${mutation.value.connectionState} - ${mutation.value.error}',
                    textDirection: TextDirection.ltr,
                  ),
                ],
              );
            },
          ),
        );
      }

      await tester.pumpWidget(build());

      expect(find.text('ConnectionState.done - error'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));

      await tester.pump();

      expect(find.text('ConnectionState.none - null'), findsOneWidget);
    });

    testWidgets('current state loading', (tester) async {
      Widget build() {
        return ProviderScope(
          child: HookConsumer(
            builder: (c, ref, child) {
              final mutation = useMutation(
                state: const AsyncSnapshot.waiting(),
              );
              return Row(
                textDirection: TextDirection.ltr,
                children: [
                  GestureDetector(
                    onTap: mutation.reload,
                    child: const Icon(
                      Icons.clear,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  mutation.isLoading
                      ? const Text(
                          'loading',
                          textDirection: TextDirection.ltr,
                        )
                      : Text(
                          mutation.value.connectionState.toString(),
                          textDirection: TextDirection.ltr,
                        ),
                ],
              );
            },
          ),
        );
      }

      await tester.pumpWidget(build());

      expect(find.text('loading'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));

      await tester.pump();

      expect(find.text('ConnectionState.none'), findsOneWidget);
    });
  });

  group('call function', () {
    testWidgets('call function expected data ', (tester) async {
      ///given
      const expectedData = 42;

      //when
      fetchNumber() async {
        await Future.delayed(const Duration(seconds: 7));
        return expectedData;
      }

      Widget build() {
        return ProviderScope(
          child: HookConsumer(
            builder: (c, ref, child) {
              final mutation = useMutation<int>();
              return Row(
                textDirection: TextDirection.ltr,
                children: [
                  GestureDetector(
                    onTap: () {
                      mutation(
                        fetchNumber(),
                        mounted: () => c.mounted,
                      );
                    },
                    child: const Icon(
                      Icons.add,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  Text(
                    mutation.value.connectionState.toString(),
                    textDirection: TextDirection.ltr,
                  ),
                  if (mutation.isData)
                    Text(
                      mutation.value.data.toString(),
                      textDirection: TextDirection.ltr,
                    )
                ],
              );
            },
          ),
        );
      }

      await tester.pumpWidget(build());

      expect(find.text('ConnectionState.none'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));

      await tester.pump(
        const Duration(seconds: 1),
      );

      expect(find.text('ConnectionState.waiting'), findsOneWidget);

      await tester.pump(
        const Duration(seconds: 6),
      );

      expect(find.text('ConnectionState.done'), findsOneWidget);

      expect(find.text(expectedData.toString()), findsOneWidget);
    });

    testWidgets('call function expected error ', (tester) async {
      ///given
      const expectedError = 'error';

      //when
      Future<int> fetchNumber() async {
        await Future.delayed(const Duration(seconds: 7));
        throw UnimplementedError(expectedError);
      }

      Widget build() {
        return ProviderScope(
          child: HookConsumer(
            builder: (c, ref, child) {
              final mutation = useMutation<int>();
              return Row(
                textDirection: TextDirection.ltr,
                children: [
                  GestureDetector(
                    onTap: () {
                      mutation(
                        fetchNumber(),
                        mounted: () => c.mounted,
                      ).then((value) => null).onError((error, stackTrace) {
                        expect(error, isA<UnimplementedError>());
                      });
                    },
                    child: const Icon(
                      Icons.add,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  Text(
                    mutation.value.connectionState.toString(),
                    textDirection: TextDirection.ltr,
                  ),
                  if (mutation.hasError)
                    Text(
                      mutation.value.error.toString(),
                      textDirection: TextDirection.ltr,
                    )
                ],
              );
            },
          ),
        );
      }

      await tester.pumpWidget(build());

      expect(find.text('ConnectionState.none'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));

      await tester.pump(
        const Duration(seconds: 1),
      );

      expect(find.text('ConnectionState.waiting'), findsOneWidget);

      await tester.pump(
        const Duration(seconds: 6),
      );

      expect(find.text('ConnectionState.done'), findsOneWidget);
    });
  });

  group('mutate function', () {
    testWidgets('mutate function expected data ', (tester) async {
      ///given
      const expectedData = 42;

      bool isLoadingCalled = false;
      bool isDataCalled = false;
      bool isErrorCalled = false;

      //when
      fetchNumber() async {
        await Future.delayed(const Duration(seconds: 7));
        return expectedData;
      }

      Widget build() {
        return ProviderScope(
          child: HookConsumer(
            builder: (c, ref, child) {
              final mutation = useMutation<int>();
              return Row(
                textDirection: TextDirection.ltr,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await mutation.mutate(
                        fetchNumber(),
                        mounted: () => c.mounted,
                        loading: () {
                          isLoadingCalled = true;
                        },
                        data: (data) {
                          isDataCalled = true;
                        },
                        error: (error, stackTrace) {
                          isErrorCalled = true;
                        },
                      );
                    },
                    child: const Icon(
                      Icons.add,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  Text(
                    mutation.value.connectionState.toString(),
                    textDirection: TextDirection.ltr,
                  ),
                  if (mutation.isData)
                    Text(
                      mutation.value.data.toString(),
                      textDirection: TextDirection.ltr,
                    )
                ],
              );
            },
          ),
        );
      }

      expect(isDataCalled, false);
      expect(isLoadingCalled, false);
      expect(isErrorCalled, false);

      await tester.pumpWidget(build());

      expect(find.text('ConnectionState.none'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(
        const Duration(seconds: 1),
      );
      expect(find.text('ConnectionState.waiting'), findsOneWidget);
      expect(isLoadingCalled, true);

      await tester.pump(
        const Duration(seconds: 6),
      );

      expect(find.text('ConnectionState.done'), findsOneWidget);
      expect(find.text(expectedData.toString()), findsOneWidget);

      expect(isDataCalled, true);
      expect(isErrorCalled, false);
    });

    testWidgets('mutate function expected error ', (tester) async {
      ///given
      const expectedError = 'error';
      bool isLoadingCalled = false;
      bool isDataCalled = false;
      bool isErrorCalled = false;

      //when
      Future<int> fetchNumber() async {
        await Future.delayed(const Duration(seconds: 7));
        throw UnimplementedError(expectedError);
      }

      Widget build() {
        return ProviderScope(
          child: HookConsumer(
            builder: (c, ref, child) {
              final mutation = useMutation<int>();
              return Row(
                textDirection: TextDirection.ltr,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await mutation.mutate(
                        fetchNumber(),
                        mounted: () => c.mounted,
                        loading: () {
                          isLoadingCalled = true;
                        },
                        data: (data) {
                          isDataCalled = true;
                        },
                        error: (error, stackTrace) {
                          isErrorCalled = true;
                          expect(error, isA<UnimplementedError>());
                        },
                      );
                    },
                    child: const Icon(
                      Icons.add,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  Text(
                    mutation.value.connectionState.toString(),
                    textDirection: TextDirection.ltr,
                  ),
                  if (mutation.hasError)
                    Text(
                      mutation.value.error.toString(),
                      textDirection: TextDirection.ltr,
                    )
                ],
              );
            },
          ),
        );
      }

      expect(isDataCalled, false);
      expect(isLoadingCalled, false);
      expect(isErrorCalled, false);

      await tester.pumpWidget(build());

      expect(find.text('ConnectionState.none'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));

      await tester.pump(
        const Duration(seconds: 1),
      );

      expect(find.text('ConnectionState.waiting'), findsOneWidget);

      expect(isLoadingCalled, true);
      await tester.pump(
        const Duration(seconds: 6),
      );

      expect(find.text('ConnectionState.done'), findsOneWidget);
      expect(isDataCalled, false);
      expect(isErrorCalled, true);
    });
  });
}
