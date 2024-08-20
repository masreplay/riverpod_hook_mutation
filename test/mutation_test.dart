import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_hook_mutation/riverpod_hook_mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('use Mutation ', () {
    Widget build<T>({
      AsyncSnapshot<T>? state,
      T? data,
    }) {
      return ProviderScope(
        child: HookConsumer(
          builder: (c, ref, child) {
            final mutation = useMutation(
              state: state,
              data: data,
            );
            return Column(
              children: [
                Text(
                  mutation.value.connectionState.toString(),
                  textDirection: TextDirection.ltr,
                ),
                if (mutation.isData)
                  Text(
                    mutation.value.data.toString(),
                    textDirection: TextDirection.ltr,
                  ),
                if (mutation.hasError)
                  Text(
                    mutation.value.error.toString(),
                    textDirection: TextDirection.ltr,
                  ),
              ],
            );
          },
        ),
      );
    }

    testWidgets('create mutation with noting state as initial value ',
        (tester) async {
      ///when
      await tester.pumpWidget(build());

      ///then
      expect(find.text('ConnectionState.none'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('create mutation with data as initial value ', (tester) async {
      ///given
      const data = 42;

      ///when
      await tester.pumpWidget(build(
        data: 42,
      ));

      ///then
      expect(find.text('ConnectionState.done'), findsOneWidget);
      expect(find.text(data.toString()), findsOneWidget);
    });

    testWidgets('create mutation with data as initial state', (tester) async {
      ///given
      const data = 42;

      ///when
      await tester.pumpWidget(
        build(
          state: const AsyncSnapshot.withData(
            ConnectionState.done,
            data,
          ),
        ),
      );

      ///then
      expect(find.text('ConnectionState.done'), findsOneWidget);
      expect(find.text(data.toString()), findsOneWidget);
    });

    testWidgets('create mutation with error as initial state ', (tester) async {
      ///given
      const error = 'error';

      ///when
      await tester.pumpWidget(build(
        state: AsyncSnapshot.withError(
          ConnectionState.done,
          error,
          StackTrace.current,
        ),
      ));

      ///then
      expect(find.text('ConnectionState.done'), findsOneWidget);
      expect(find.text(error), findsOneWidget);
    });

    testWidgets('create mutation with loading as initial state',
        (tester) async {
      ///when
      await tester.pumpWidget(build(
        state: const AsyncSnapshot<int>.waiting(),
      ));

      ///then
      expect(find.text('ConnectionState.waiting'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('Reload Function', () {
    Widget reloadWidget<T>(
      Function(AsyncSnapshot<T>) onStateChanged, {
      T? initialData,
      AsyncSnapshot<T>? state,
    }) {
      return ProviderScope(
        child: HookConsumer(
          builder: (c, ref, child) {
            final mutation = useMutation(data: initialData, state: state);

            useEffect(() {
              onStateChanged(mutation.value);

              listener() {
                onStateChanged(mutation.value);
              }

              mutation.addListener(listener);
              return () => mutation.removeListener(listener);
            });

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

    testWidgets('when initial state is data expected nothing', (tester) async {
      ///given
      const initialData = 42;
      AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();

      await tester.pumpWidget(reloadWidget(
        initialData: initialData,
        (value) {
          snapshot = value;
        },
      ));

      expect(
        snapshot,
        const AsyncSnapshot.withData(ConnectionState.done, initialData),
      );

      ///when
      await tester.tap(find.byIcon(Icons.clear));

      await tester.pump();

      ///then
      expect(snapshot, const AsyncSnapshot.nothing());
    });

    testWidgets('when initial data is error expected nothing', (tester) async {
      /// given
      AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();

      await tester.pumpWidget(reloadWidget(
        state: const AsyncSnapshot<int>.withError(
          ConnectionState.done,
          'error',
        ),
        (value) {
          snapshot = value;
        },
      ));

      expect(snapshot,
          const AsyncSnapshot.withError(ConnectionState.done, 'error'));

      ///when
      await tester.tap(find.byIcon(Icons.clear));

      await tester.pump();

      ///then
      expect(snapshot, const AsyncSnapshot.nothing());
    });

    testWidgets('when initial state is loading expected loading',
        (tester) async {
      /// given
      AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();

      await tester.pumpWidget(reloadWidget(
        state: const AsyncSnapshot<int>.waiting(),
        (value) {
          snapshot = value;
        },
      ));
      expect(snapshot.connectionState, ConnectionState.waiting);

      ///when
      await tester.tap(find.byIcon(Icons.clear));

      await tester.pump();

      ///then
      expect(snapshot, const AsyncSnapshot.nothing());
    });
  });

  group('call function', () {
    Widget callWidget<T>(
      Future<T> Function() onAddPressed,
      Function(AsyncSnapshot<T>) onStateChanged, {
      T? initialData,
      AsyncSnapshot<T>? state,
      Function(T?)? onResult,
    }) {
      return ProviderScope(
        child: HookConsumer(
          builder: (c, ref, child) {
            final mutation = useMutation(data: initialData, state: state);

            useEffect(() {
              onStateChanged(mutation.value);

              listener() {
                onStateChanged(mutation.value);
              }

              mutation.addListener(listener);
              return () => mutation.removeListener(listener);
            });

            return Row(
              textDirection: TextDirection.ltr,
              children: [
                GestureDetector(
                  onTap: () async {
                    final result = await mutation(
                      onAddPressed(),
                      mounted: () => c.mounted,
                    )
                        .then(
                      (value) => value ?? null as T?,
                    )
                        .catchError((error, stackTrace) {
                      expect(error, isA<UnimplementedError>());
                      return null;
                    });
                    onResult?.call(result);
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

    testWidgets('when value is none and call success expected done with data',
        (tester) async {
      ///given
      const expectedData = 42;
      AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();

      fetchNumber() async {
        await Future.delayed(const Duration(seconds: 4));
        return expectedData;
      }

      await tester.pumpWidget(
        callWidget(
          fetchNumber,
          (value) {
            snapshot = value;
          },
        ),
      );

      ///Check the initial state
      expect(snapshot.connectionState, ConnectionState.none);

      //when
      await tester.tap(find.byIcon(Icons.add));

      ///then
      await tester.pump(
        const Duration(seconds: 1),
      );

      ///Check the state after the function is called and before the data is returned
      expect(snapshot.connectionState, ConnectionState.waiting);

      await tester.pump(
        const Duration(seconds: 3),
      );

      ///Check the state after the data is returned
      expect(snapshot.data, expectedData);
      expect(snapshot.connectionState, ConnectionState.done);
    });

    testWidgets(
        'when value is none and call has error expected done with error',
        (tester) async {
      ///given
      const expectedError = 'error';
      AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();

      Future<int> fetchNumber() async {
        await Future.delayed(const Duration(seconds: 5));
        throw UnimplementedError(expectedError);
      }

      await tester.pumpWidget(
        callWidget(
          fetchNumber,
          (value) {
            snapshot = value;
          },
        ),
      );

      ///Check the initial state
      expect(snapshot.connectionState, ConnectionState.none);

      //when
      await tester.tap(find.byIcon(Icons.add));

      await tester.pump(
        const Duration(seconds: 1),
      );

      ///Check the state after the function is called and before the data is returned
      /// the state should be waiting
      expect(snapshot.connectionState, ConnectionState.waiting);

      await tester.pump(
        const Duration(seconds: 4),
      );

      ///Check the state after the data is returned
      expect(snapshot.error, isA<UnimplementedError>());
      expect(snapshot.connectionState, ConnectionState.done);
    });

    testWidgets(
        'should still waiting if the context is not mounted when the data is returned',
        (tester) async {
      AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();

      ///given
      const expectedData = 42;

      //when
      fetchNumber() async {
        await Future.delayed(const Duration(seconds: 7));
        return expectedData;
      }

      await tester.pumpWidget(
        callWidget(
          fetchNumber,
          (value) {
            snapshot = value;
          },
          onResult: (result) {
            expect(result, expectedData);
          },
        ),
      );

      ///Check the initial state
      expect(snapshot.connectionState, ConnectionState.none);

      await tester.tap(find.byIcon(Icons.add));

      await tester.pump(
        const Duration(seconds: 1),
      );

      ///Check the state after the function is called and before the data is returned
      expect(snapshot.connectionState, ConnectionState.waiting);

      ///Dispose the widget make the context not mounted
      await tester.pumpWidget(Container());

      await tester.pump(
        const Duration(seconds: 6),
      );

      /// there are no widget of text because the context is not mounted
      expect(snapshot.connectionState, ConnectionState.waiting);

      expect(find.byType(Text), findsNothing);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets(
        'should still waiting if the context is not mounted when the null is returned',
        (tester) async {
      ///given
      const expectedError = 'error';
      AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();

      //when
      Future<int> fetchNumber() async {
        await Future.delayed(const Duration(seconds: 5));
        throw UnimplementedError(expectedError);
      }

      await tester.pumpWidget(
        callWidget(
          fetchNumber,
          (value) {
            snapshot = value;
          },
          onResult: (result) {
            expect(result, null);
          },
        ),
      );

      ///Check the initial state
      expect(snapshot.connectionState, ConnectionState.none);

      await tester.tap(find.byIcon(Icons.add));

      await tester.pump(
        const Duration(seconds: 1),
      );

      ///Check the state after the function is called and before the data is returned
      expect(snapshot.connectionState, ConnectionState.waiting);

      ///Dispose the widget make the context not mounted
      await tester.pumpWidget(Container());

      await tester.pump(
        const Duration(seconds: 4),
      );

      /// there are no widget of text because the context is not mounted
      expect(find.byType(Text), findsNothing);
      expect(find.byType(Container), findsOneWidget);

      /// the value should be waiting and never updated because the context is not mounted
      expect(snapshot.connectionState, ConnectionState.waiting);
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

    testWidgets(
        'mutate function expected data  but context will not be mounted',
        (tester) async {
      ///given
      const expectedData = 42;

      bool isLoadingCalled = false;
      bool isDataCalled = false;
      bool isErrorCalled = false;

      ConnectionState value = ConnectionState.none;

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
                      value = mutation.value.connectionState;
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

      await tester.pumpWidget(
        Container(),
      );

      await tester.pump(
        const Duration(seconds: 6),
      );

      expect(isDataCalled, false);
      expect(isErrorCalled, false);
      expect(value, ConnectionState.waiting);
    });

    testWidgets(
        'mutate function expected error  but context will not be mounted',
        (tester) async {
      ///given
      const expectedError = 'error';

      bool isLoadingCalled = false;
      bool isDataCalled = false;
      bool isErrorCalled = false;

      ConnectionState value = ConnectionState.none;

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
                      value = mutation.value.connectionState;
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

      await tester.pumpWidget(
        Container(),
      );

      await tester.pump(
        const Duration(seconds: 6),
      );

      expect(isDataCalled, false);
      expect(isErrorCalled, false);
      expect(value, ConnectionState.waiting);
    });
  });
}
