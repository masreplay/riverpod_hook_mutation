import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_hook_mutation/riverpod_hook_mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Widget _build<T>({AsyncSnapshot<T>? state, T? data}) {
  return ProviderScope(
    child: HookConsumer(
      builder: (context, ref, child) {
        final mutation = useMutation(state: state, data: data);

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

Widget _reloadWidget<T>(
  Function(AsyncSnapshot<T>) onStateChanged, {
  T? initialData,
  AsyncSnapshot<T>? state,
}) {
  return ProviderScope(
    child: HookConsumer(
      builder: (c, ref, child) {
        final mutation = useMutation(data: initialData, state: state);

        useEffect(
          () {
            onStateChanged(mutation.value);

            listener() => onStateChanged(mutation.value);

            mutation.addListener(listener);
            return () => mutation.removeListener(listener);
          },
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
              mutation.value.connectionState.toString(),
              textDirection: TextDirection.ltr,
            ),
          ],
        );
      },
    ),
  );
}

Widget _callWidget<T>(
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

        useEffect(
          () {
            onStateChanged(mutation.value);

            listener() {
              onStateChanged(mutation.value);
            }

            mutation.addListener(listener);
            return () => mutation.removeListener(listener);
          },
        );

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
                    .catchError(
                  (error, stackTrace) {
                    expect(error, isA<UnimplementedError>());
                    return null;
                  },
                );
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

void main() {
  group(
    'use Mutation ',
    () {
      testWidgets(
        'create mutation with noting state as initial value ',
        (tester) async {
          await tester.pumpWidget(_build());

          expect(find.text('ConnectionState.none'), findsOneWidget);
          expect(find.byType(Text), findsOneWidget);
        },
      );

      testWidgets(
        'create mutation with data as initial value ',
        (tester) async {
          const int data = 42;

          await tester.pumpWidget(_build(data: data));

          expect(find.text('ConnectionState.done'), findsOneWidget);
          expect(find.text(data.toString()), findsOneWidget);
        },
      );

      testWidgets(
        'create mutation with data as initial state',
        (tester) async {
          const data = 42;

          await tester.pumpWidget(
            _build(
              state: const AsyncSnapshot.withData(
                ConnectionState.done,
                data,
              ),
            ),
          );

          expect(find.text('ConnectionState.done'), findsOneWidget);
          expect(find.text(data.toString()), findsOneWidget);
        },
      );

      testWidgets(
        'create mutation with error as initial state ',
        (tester) async {
          const error = 'error';

          await tester.pumpWidget(_build(
            state: AsyncSnapshot.withError(
              ConnectionState.done,
              error,
              StackTrace.current,
            ),
          ));

          expect(find.text('ConnectionState.done'), findsOneWidget);
          expect(find.text(error), findsOneWidget);
        },
      );

      testWidgets(
        'create mutation with loading as initial state',
        (tester) async {
          await tester.pumpWidget(_build(
            state: const AsyncSnapshot<int>.waiting(),
          ));

          expect(find.text('ConnectionState.waiting'), findsOneWidget);
          expect(find.byType(Text), findsOneWidget);
        },
      );
    },
  );

  group(
    'Reload Function',
    () {
      testWidgets(
        'when initial state is data expected nothing',
        (tester) async {
          const initialData = 42;
          AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();

          await tester.pumpWidget(
            _reloadWidget(
              initialData: initialData,
              (value) => snapshot = value,
            ),
          );

          expect(
            snapshot,
            const AsyncSnapshot.withData(ConnectionState.done, initialData),
          );

          await tester.tap(find.byIcon(Icons.clear));
          await tester.pump();

          expect(snapshot, const AsyncSnapshot.nothing());
        },
      );

      testWidgets(
        'when initial data is error expected nothing',
        (tester) async {
          const initialState = AsyncSnapshot<int>.withError(
            ConnectionState.done,
            'error',
          );

          var snapshot = const AsyncSnapshot<int>.nothing();

          await tester.pumpWidget(
            _reloadWidget(
              state: initialState,
              (value) => snapshot = value,
            ),
          );

          expect(snapshot, initialState);

          await tester.tap(find.byIcon(Icons.clear));
          await tester.pump();

          expect(snapshot, const AsyncSnapshot.nothing());
        },
      );

      testWidgets(
        'when initial state is loading expected loading',
        (tester) async {
          var snapshot = const AsyncSnapshot<int>.nothing();

          await tester.pumpWidget(
            _reloadWidget(
              state: const AsyncSnapshot<int>.waiting(),
              (value) => snapshot = value,
            ),
          );
          expect(snapshot.connectionState, ConnectionState.waiting);

          await tester.tap(find.byIcon(Icons.clear));
          await tester.pump();

          expect(snapshot, const AsyncSnapshot.nothing());
        },
      );
    },
  );

  group(
    'call function',
    () {
      testWidgets(
        'when value is none and call success expected done with data',
        (tester) async {
          const expectedData = 42;
          AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();

          fetchNumber() async {
            await Future.delayed(const Duration(seconds: 4));
            return expectedData;
          }

          await tester.pumpWidget(
            _callWidget(
              fetchNumber,
              (value) {
                snapshot = value;
              },
            ),
          );

          expect(snapshot.connectionState, ConnectionState.none);

          //when
          await tester.tap(find.byIcon(Icons.add));

          await tester.pump(
            const Duration(seconds: 1),
          );

          expect(snapshot.connectionState, ConnectionState.waiting);

          await tester.pump(
            const Duration(seconds: 3),
          );

          expect(snapshot.data, expectedData);
          expect(snapshot.connectionState, ConnectionState.done);
        },
      );

      testWidgets(
        'when value is none and call has error expected done with error',
        (tester) async {
          const expectedError = 'error';
          AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();

          Future<int> fetchNumber() async {
            await Future.delayed(const Duration(seconds: 5));
            throw UnimplementedError(expectedError);
          }

          await tester.pumpWidget(
            _callWidget(
              fetchNumber,
              (value) {
                snapshot = value;
              },
            ),
          );

          expect(snapshot.connectionState, ConnectionState.none);

          //when
          await tester.tap(find.byIcon(Icons.add));

          await tester.pump(
            const Duration(seconds: 1),
          );

          expect(snapshot.connectionState, ConnectionState.waiting);

          await tester.pump(
            const Duration(seconds: 4),
          );

          expect(snapshot.error, isA<UnimplementedError>());
          expect(snapshot.connectionState, ConnectionState.done);
        },
      );

      testWidgets(
        'should still waiting if the context is not mounted when the data is returned',
        (tester) async {
          AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();

          const expectedData = 42;

          //when
          fetchNumber() async {
            await Future.delayed(const Duration(seconds: 7));
            return expectedData;
          }

          await tester.pumpWidget(
            _callWidget(
              fetchNumber,
              (value) {
                snapshot = value;
              },
              onResult: (result) {
                expect(result, expectedData);
              },
            ),
          );

          expect(snapshot.connectionState, ConnectionState.none);

          await tester.tap(find.byIcon(Icons.add));

          await tester.pump(
            const Duration(seconds: 1),
          );

          expect(snapshot.connectionState, ConnectionState.waiting);

          await tester.pumpWidget(Container());

          await tester.pump(
            const Duration(seconds: 6),
          );

          expect(snapshot.connectionState, ConnectionState.waiting);

          expect(find.byType(Text), findsNothing);
          expect(find.byType(Container), findsOneWidget);
        },
      );

      testWidgets(
        'should still waiting if the context is not mounted when the null is returned',
        (tester) async {
          const expectedError = 'error';
          AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();

          //when
          Future<int> fetchNumber() async {
            await Future.delayed(const Duration(seconds: 5));
            throw UnimplementedError(expectedError);
          }

          await tester.pumpWidget(
            _callWidget(
              fetchNumber,
              (value) {
                snapshot = value;
              },
              onResult: (result) {
                expect(result, null);
              },
            ),
          );

          expect(snapshot.connectionState, ConnectionState.none);

          await tester.tap(find.byIcon(Icons.add));

          await tester.pump(
            const Duration(seconds: 1),
          );

          expect(snapshot.connectionState, ConnectionState.waiting);

          await tester.pumpWidget(Container());

          await tester.pump(
            const Duration(seconds: 4),
          );

          expect(find.byType(Text), findsNothing);
          expect(find.byType(Container), findsOneWidget);

          expect(snapshot.connectionState, ConnectionState.waiting);
        },
      );
    },
  );

  group(
    'mutate function',
    () {
      Widget build<T, R>({
        required Future<T> Function() fetchNumber,
        required R Function() whenLoadingCalled,
        required R? Function() whenDataCalled,
        required R? Function() whenErrorCalled,
        required R? Function(AsyncSnapshot<T>) onStateChange,
        Function(R?)? onResult,
        T? initialData,
        AsyncSnapshot<T>? state,
      }) {
        return ProviderScope(
          child: HookConsumer(
            builder: (c, ref, child) {
              final mutation = useMutation<T>();

              useEffect(
                () {
                  onStateChange(mutation.value);

                  listener() {
                    onStateChange(mutation.value);
                  }

                  mutation.addListener(listener);
                  return () => mutation.removeListener(listener);
                },
              );
              return Row(
                textDirection: TextDirection.ltr,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final result = await mutation.mutate<R>(
                        fetchNumber(),
                        mounted: () => c.mounted,
                        loading: () {
                          return whenLoadingCalled();
                        },
                        data: (data) {
                          return whenDataCalled();
                        },
                        error: (error, stackTrace) {
                          return whenErrorCalled();
                        },
                      );
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
                ],
              );
            },
          ),
        );
      }

      testWidgets(
        'when call mutate should expect done state with value',
        (tester) async {
          AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();
          const expectedData = 42;

          bool isLoadingCalled = false;
          bool isDataCalled = false;
          bool isErrorCalled = false;

          //when
          fetchNumber() async {
            await Future.delayed(const Duration(seconds: 5));
            return expectedData;
          }

          expect(isDataCalled, false);
          expect(isLoadingCalled, false);
          expect(isErrorCalled, false);

          await tester.pumpWidget(
            build(
              fetchNumber: fetchNumber,
              whenLoadingCalled: () {
                isLoadingCalled = true;
              },
              whenDataCalled: () {
                isDataCalled = true;
              },
              whenErrorCalled: () {
                isErrorCalled = true;
              },
              onStateChange: (value) {
                snapshot = value;
              },
            ),
          );

          expect(snapshot.connectionState, ConnectionState.none);

          await tester.tap(find.byIcon(Icons.add));

          await tester.pump(
            const Duration(seconds: 1),
          );

          expect(snapshot.connectionState, ConnectionState.waiting);
          expect(isLoadingCalled, true);

          await tester.pump(
            const Duration(seconds: 4),
          );

          expect(snapshot.connectionState, ConnectionState.done);
          expect(snapshot.data, expectedData);

          expect(isDataCalled, true);
          expect(isErrorCalled, false);
        },
      );

      testWidgets(
        'when call mutate should expect done state with error',
        (tester) async {
          AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();
          const expectedError = 'error';
          bool isLoadingCalled = false;
          bool isDataCalled = false;
          bool isErrorCalled = false;

          //when
          Future<int> fetchNumber() async {
            await Future.delayed(const Duration(seconds: 7));
            throw UnimplementedError(expectedError);
          }

          await tester.pumpWidget(
            build(
              fetchNumber: fetchNumber,
              whenLoadingCalled: () {
                isLoadingCalled = true;
              },
              whenDataCalled: () {
                isDataCalled = true;
              },
              whenErrorCalled: () {
                isErrorCalled = true;
              },
              onStateChange: (value) {
                snapshot = value;
              },
            ),
          );

          expect(isDataCalled, false);
          expect(isLoadingCalled, false);
          expect(isErrorCalled, false);

          expect(snapshot.connectionState, ConnectionState.none);

          await tester.tap(find.byIcon(Icons.add));

          await tester.pump(
            const Duration(seconds: 1),
          );

          expect(snapshot.connectionState, ConnectionState.waiting);
          expect(isLoadingCalled, true);

          await tester.pump(
            const Duration(seconds: 6),
          );

          expect(snapshot.connectionState, ConnectionState.done);
          expect(snapshot.error, isA<UnimplementedError>());
          expect(isDataCalled, false);
          expect(isErrorCalled, true);
        },
      );

      testWidgets(
        'when call mutate and context is not mounted should expect waiting state',
        (tester) async {
          AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();
          const expectedData = 42;

          bool isLoadingCalled = false;
          bool isDataCalled = false;
          bool isErrorCalled = false;

          //when
          fetchNumber() async {
            await Future.delayed(const Duration(seconds: 7));
            return expectedData;
          }

          await tester.pumpWidget(
            build(
              fetchNumber: fetchNumber,
              whenLoadingCalled: () {
                isLoadingCalled = true;
              },
              whenDataCalled: () {
                isDataCalled = true;
              },
              whenErrorCalled: () {
                isErrorCalled = true;
              },
              onStateChange: (value) {
                snapshot = value;
              },
              onResult: (value) {
                expect(value, null);
              },
            ),
          );

          expect(isDataCalled, false);
          expect(isLoadingCalled, false);
          expect(isErrorCalled, false);

          expect(snapshot.connectionState, ConnectionState.none);

          await tester.tap(find.byIcon(Icons.add));

          await tester.pump(
            const Duration(seconds: 1),
          );

          expect(snapshot.connectionState, ConnectionState.waiting);
          expect(isLoadingCalled, true);

          await tester.pumpWidget(
            Container(),
          );

          expect(find.byType(Container), findsOneWidget);
          expect(find.byType(Text), findsNothing);

          await tester.pump(
            const Duration(seconds: 6),
          );

          expect(snapshot.connectionState, ConnectionState.waiting);

          expect(isDataCalled, false);
          expect(isErrorCalled, false);
        },
      );

      testWidgets(
        'when call mutate with error and context is not mounted should expect waiting state',
        (tester) async {
          AsyncSnapshot<int> snapshot = const AsyncSnapshot.nothing();

          const expectedError = 'error';

          bool isLoadingCalled = false;
          bool isDataCalled = false;
          bool isErrorCalled = false;

          //when
          Future<int> fetchNumber() async {
            await Future.delayed(const Duration(seconds: 7));
            throw UnimplementedError(expectedError);
          }

          await tester.pumpWidget(
            build(
              fetchNumber: fetchNumber,
              whenLoadingCalled: () {
                isLoadingCalled = true;
              },
              whenDataCalled: () {
                isDataCalled = true;
              },
              whenErrorCalled: () {
                isErrorCalled = true;
              },
              onStateChange: (value) {
                snapshot = value;
              },
              onResult: (value) {
                expect(value, null);
              },
            ),
          );

          expect(isDataCalled, false);
          expect(isLoadingCalled, false);
          expect(isErrorCalled, false);

          expect(snapshot.connectionState, ConnectionState.none);

          await tester.tap(find.byIcon(Icons.add));

          await tester.pump(
            const Duration(seconds: 1),
          );

          expect(snapshot.connectionState, ConnectionState.waiting);

          expect(isLoadingCalled, true);

          await tester.pumpWidget(
            Container(),
          );

          expect(find.byType(Container), findsOneWidget);
          expect(find.byType(Text), findsNothing);

          await tester.pump(
            const Duration(seconds: 6),
          );

          expect(snapshot.connectionState, ConnectionState.waiting);
          expect(isDataCalled, false);
          expect(isErrorCalled, false);
        },
      );
    },
  );

  group(
    'when functions',
    () {
      group(
        'when',
        () {
          Widget build<T>({
            AsyncSnapshot<T>? initialState,
            Future<T> Function()? onPressed,
          }) {
            return ProviderScope(
              child: HookConsumer(
                builder: (c, ref, child) {
                  final mutation = useMutation(
                    state: initialState,
                  );
                  return Column(
                    textDirection: TextDirection.ltr,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (onPressed != null) {
                            mutation.mutate<int>(
                              onPressed(),
                              mounted: () => c.mounted,
                            );
                          }
                        },
                        child: const Icon(
                          Icons.add,
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                      mutation.when(
                        idle: () {
                          return Text(
                            ConnectionState.none.name,
                            textDirection: TextDirection.ltr,
                          );
                        },
                        data: (data) {
                          return Text(
                            ConnectionState.done.name,
                            textDirection: TextDirection.ltr,
                          );
                        },
                        error: (error, _) {
                          return Text(
                            ConnectionState.done.name,
                            textDirection: TextDirection.ltr,
                          );
                        },
                        loading: () {
                          return Text(
                            ConnectionState.waiting.name,
                            textDirection: TextDirection.ltr,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            );
          }

          testWidgets(
            'should execute idle function only',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(),
              );

              expect(find.text(ConnectionState.none.name), findsOneWidget);
              expect(find.text(ConnectionState.done.name), findsNothing);
              expect(find.text(ConnectionState.waiting.name), findsNothing);
            },
          );

          testWidgets(
            'should execute data function only',
            (widgetTester) async {
              const data = 42;

              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot.withData(
                    ConnectionState.done,
                    data,
                  ),
                ),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsOneWidget);
              expect(find.text(ConnectionState.waiting.name), findsNothing);
            },
          );

          testWidgets(
            'should execute error function only',
            (widgetTester) async {
              const error = 'error';

              await widgetTester.pumpWidget(
                build(
                  initialState: AsyncSnapshot.withError(
                    ConnectionState.done,
                    error,
                    StackTrace.current,
                  ),
                ),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsOneWidget);
              expect(find.text(ConnectionState.waiting.name), findsNothing);
            },
          );

          testWidgets(
            'should execute loading function only',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.waiting(),
                ),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsNothing);
              expect(find.text(ConnectionState.waiting.name), findsOneWidget);
            },
          );

          //case noting -> click icon -> loading -> done
          testWidgets(
            'should execute loading then done ',
            (widgetTester) async {
              const data = 42;

              await widgetTester.pumpWidget(
                build(
                  onPressed: () async {
                    await Future.delayed(const Duration(seconds: 5));
                    return data;
                  },
                ),
              );

              expect(find.text(ConnectionState.none.name), findsOneWidget);
              expect(find.text(ConnectionState.done.name), findsNothing);
              expect(find.text(ConnectionState.waiting.name), findsNothing);

              await widgetTester.tap(find.byIcon(Icons.add));

              await widgetTester.pump(
                const Duration(seconds: 1),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsNothing);
              expect(find.text(ConnectionState.waiting.name), findsOneWidget);

              await widgetTester.pump(
                const Duration(seconds: 5),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.waiting.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsOneWidget);
            },
          );

          //case noting -> click icon -> loading -> error
          testWidgets(
            'should execute loading then error',
            (widgetTester) async {
              const error = 'error';

              await widgetTester.pumpWidget(
                build(
                  onPressed: () async {
                    await Future.delayed(const Duration(seconds: 5));
                    throw UnimplementedError(error);
                  },
                ),
              );

              expect(find.text(ConnectionState.none.name), findsOneWidget);
              expect(find.text(ConnectionState.done.name), findsNothing);
              expect(find.text(ConnectionState.waiting.name), findsNothing);

              await widgetTester.tap(find.byIcon(Icons.add));

              await widgetTester.pump(
                const Duration(seconds: 1),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsNothing);
              expect(find.text(ConnectionState.waiting.name), findsOneWidget);

              await widgetTester.pump(
                const Duration(seconds: 5),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.waiting.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsOneWidget);
            },
          );
        },
      );

      group(
        'when or null',
        () {
          Widget build<T, R extends Widget>({
            required AsyncSnapshot<T> initialState,
            AsyncIdleCallback<R?>? idle,
            AsyncDataCallback<R?, T>? data,
            AsyncErrorCallback<R?>? error,
            AsyncLoadingCallback<R?>? loading,
          }) {
            return ProviderScope(
              child: HookConsumer(
                builder: (c, ref, child) {
                  final mutation = useMutation(
                    state: initialState,
                  );
                  return mutation.whenOrNull(
                        idle: idle,
                        data: data,
                        error: error,
                        loading: loading,
                      ) ??
                      const Text(
                        'null',
                        textDirection: TextDirection.ltr,
                      );
                },
              ),
            );
          }

          testWidgets(
            'should execute idle function',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.nothing(),
                  idle: () {
                    return Text(
                      ConnectionState.none.name,
                      textDirection: TextDirection.ltr,
                    );
                  },
                ),
              );

              expect(find.text(ConnectionState.none.name), findsOneWidget);
              expect(find.text(ConnectionState.done.name), findsNothing);
              expect(find.text(ConnectionState.waiting.name), findsNothing);
              expect(find.text('null'), findsNothing);
            },
          );

          testWidgets(
            'should execute data function',
            (widgetTester) async {
              const data = 42;

              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot.withData(
                    ConnectionState.done,
                    data,
                  ),
                  data: (data) {
                    return Text(
                      ConnectionState.done.name,
                      textDirection: TextDirection.ltr,
                    );
                  },
                ),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsOneWidget);
              expect(find.text(ConnectionState.waiting.name), findsNothing);
              expect(find.text('null'), findsNothing);
            },
          );

          testWidgets(
            'should execute error function',
            (widgetTester) async {
              const error = 'error';

              await widgetTester.pumpWidget(
                build(
                  initialState: AsyncSnapshot.withError(
                    ConnectionState.done,
                    error,
                    StackTrace.current,
                  ),
                  error: (error, _) {
                    return Text(
                      ConnectionState.done.name,
                      textDirection: TextDirection.ltr,
                    );
                  },
                ),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsOneWidget);
              expect(find.text(ConnectionState.waiting.name), findsNothing);
              expect(find.text('null'), findsNothing);
            },
          );

          testWidgets(
            'should execute loading function',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.waiting(),
                  loading: () {
                    return Text(
                      ConnectionState.waiting.name,
                      textDirection: TextDirection.ltr,
                    );
                  },
                ),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsNothing);
              expect(find.text(ConnectionState.waiting.name), findsOneWidget);
              expect(find.text('null'), findsNothing);
            },
          );

          testWidgets(
            'should return null',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.nothing(),
                ),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsNothing);
              expect(find.text(ConnectionState.waiting.name), findsNothing);
              expect(find.text('null'), findsOneWidget);
            },
          );
        },
      );

      group(
        'maybe when',
        () {
          Widget build<T, R extends Widget>({
            required AsyncSnapshot<T> initialState,
            AsyncIdleCallback<R>? idle,
            AsyncDataCallback<R, T>? data,
            AsyncErrorCallback<R>? error,
            AsyncLoadingCallback<R>? loading,
          }) {
            return ProviderScope(
              child: HookConsumer(
                builder: (c, ref, child) {
                  final mutation = useMutation(
                    state: initialState,
                  );
                  return mutation.maybeWhen(
                    idle: idle,
                    data: data,
                    error: error,
                    loading: loading,
                    orElse: () {
                      return Container();
                    },
                  );
                },
              ),
            );
          }

          testWidgets(
            'should execute idle function',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.nothing(),
                  idle: () {
                    return Text(
                      ConnectionState.none.name,
                      textDirection: TextDirection.ltr,
                    );
                  },
                ),
              );

              expect(find.text(ConnectionState.none.name), findsOneWidget);
              expect(find.text(ConnectionState.done.name), findsNothing);
              expect(find.text(ConnectionState.waiting.name), findsNothing);
              expect(find.byType(Container), findsNothing);
            },
          );

          testWidgets(
            'should execute data function',
            (widgetTester) async {
              const data = 42;

              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot.withData(
                    ConnectionState.done,
                    data,
                  ),
                  data: (data) {
                    return Text(
                      ConnectionState.done.name,
                      textDirection: TextDirection.ltr,
                    );
                  },
                ),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsOneWidget);
              expect(find.text(ConnectionState.waiting.name), findsNothing);
              expect(find.byType(Container), findsNothing);
            },
          );

          testWidgets(
            'should execute error function',
            (widgetTester) async {
              const error = 'error';

              await widgetTester.pumpWidget(
                build(
                  initialState: AsyncSnapshot.withError(
                    ConnectionState.done,
                    error,
                    StackTrace.current,
                  ),
                  error: (error, _) {
                    return Text(
                      ConnectionState.done.name,
                      textDirection: TextDirection.ltr,
                    );
                  },
                ),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsOneWidget);
              expect(find.text(ConnectionState.waiting.name), findsNothing);
              expect(find.byType(Container), findsNothing);
            },
          );

          testWidgets(
            'should execute loading function',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.waiting(),
                  loading: () {
                    return Text(
                      ConnectionState.waiting.name,
                      textDirection: TextDirection.ltr,
                    );
                  },
                ),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsNothing);
              expect(find.text(ConnectionState.waiting.name), findsOneWidget);
              expect(find.byType(Container), findsNothing);
            },
          );

          testWidgets(
            'should return Container',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.nothing(),
                ),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.text(ConnectionState.done.name), findsNothing);
              expect(find.text(ConnectionState.waiting.name), findsNothing);
              expect(find.byType(Container), findsOneWidget);
            },
          );
        },
      );

      group(
        'when Data',
        () {
          const data = 42;
          Widget build<R extends Widget>({
            required AsyncSnapshot<int> initialState,
          }) {
            return ProviderScope(
              child: HookConsumer(
                builder: (c, ref, child) {
                  final mutation = useMutation(
                    state: initialState,
                  );
                  return mutation.whenData(
                        (data) {
                          return Text(
                            '${ConnectionState.done.name} $data',
                            textDirection: TextDirection.ltr,
                          );
                        },
                      ) ??
                      Container();
                },
              ),
            );
          }

          testWidgets(
            'should execute data function',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot.withData(
                    ConnectionState.done,
                    data,
                  ),
                ),
              );

              expect(find.text('${ConnectionState.done.name} $data'),
                  findsOneWidget);
              expect(find.byType(Container), findsNothing);
            },
          );

          testWidgets(
            'should return Container when initial state is noting',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.nothing(),
                ),
              );

              expect(find.text('${ConnectionState.done.name} $data'),
                  findsNothing);
              expect(find.byType(Container), findsOneWidget);
            },
          );

          testWidgets(
            'should return Container when initial state is waiting ',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.waiting(),
                ),
              );

              expect(find.text('${ConnectionState.done.name} $data'),
                  findsNothing);
              expect(find.byType(Container), findsOneWidget);
            },
          );

          testWidgets(
            'should return Container when initial state is error',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: AsyncSnapshot.withError(
                    ConnectionState.done,
                    'error',
                    StackTrace.current,
                  ),
                ),
              );

              expect(find.text('${ConnectionState.done.name} $data'),
                  findsNothing);
              expect(find.byType(Container), findsOneWidget);
            },
          );
        },
      );

      group(
        'when error',
        () {
          const error = 'error';

          Widget build<T, R extends Widget>({
            required AsyncSnapshot<T> initialState,
          }) {
            return ProviderScope(
              child: HookConsumer(
                builder: (c, ref, child) {
                  final mutation = useMutation(
                    state: initialState,
                  );
                  return mutation.whenError((error, _) {
                        return Text(
                          ConnectionState.done.name + error.toString(),
                          textDirection: TextDirection.ltr,
                        );
                      }) ??
                      Container();
                },
              ),
            );
          }

          testWidgets(
            'should execute error function',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: AsyncSnapshot.withError(
                    ConnectionState.done,
                    error,
                    StackTrace.current,
                  ),
                ),
              );

              expect(
                  find.text(ConnectionState.done.name + error), findsOneWidget);
              expect(find.byType(Container), findsNothing);
            },
          );

          testWidgets(
            'should return Container when initial state is noting',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.nothing(),
                ),
              );

              expect(
                  find.text(ConnectionState.done.name + error), findsNothing);
              expect(find.byType(Container), findsOneWidget);
            },
          );

          testWidgets(
            'should return Container when initial state is waiting ',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.waiting(),
                ),
              );

              expect(
                  find.text(ConnectionState.done.name + error), findsNothing);
              expect(find.byType(Container), findsOneWidget);
            },
          );

          testWidgets(
            'should return Container when initial state is data',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot.withData(
                    ConnectionState.done,
                    42,
                  ),
                ),
              );

              expect(
                  find.text(ConnectionState.done.name + error), findsNothing);
              expect(find.byType(Container), findsOneWidget);
            },
          );
        },
      );

      group(
        'when loading',
        () {
          Widget build<T, R extends Widget>({
            required AsyncSnapshot<T> initialState,
          }) {
            return ProviderScope(
              child: HookConsumer(
                builder: (c, ref, child) {
                  final mutation = useMutation(
                    state: initialState,
                  );
                  return mutation.whenLoading(
                        () => Text(
                          ConnectionState.waiting.name,
                          textDirection: TextDirection.ltr,
                        ),
                      ) ??
                      Container();
                },
              ),
            );
          }

          testWidgets(
            'should execute loading function',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.waiting(),
                ),
              );

              expect(find.text(ConnectionState.waiting.name), findsOneWidget);
              expect(find.byType(Container), findsNothing);
            },
          );

          testWidgets(
            'should return Container when initial state is noting',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.nothing(),
                ),
              );

              expect(find.text(ConnectionState.waiting.name), findsNothing);
              expect(find.byType(Container), findsOneWidget);
            },
          );

          testWidgets(
            'should return Container when initial state is data',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot.withData(
                    ConnectionState.done,
                    42,
                  ),
                ),
              );

              expect(find.text(ConnectionState.waiting.name), findsNothing);
              expect(find.byType(Container), findsOneWidget);
            },
          );

          testWidgets(
            'should return Container when initial state is error',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: AsyncSnapshot.withError(
                    ConnectionState.done,
                    'error',
                    StackTrace.current,
                  ),
                ),
              );

              expect(find.text(ConnectionState.waiting.name), findsNothing);
              expect(find.byType(Container), findsOneWidget);
            },
          );
        },
      );

      group(
        'when idle',
        () {
          Widget build<T, R extends Widget>({
            required AsyncSnapshot<T> initialState,
          }) {
            return ProviderScope(
              child: HookConsumer(
                builder: (c, ref, child) {
                  final mutation = useMutation(
                    state: initialState,
                  );
                  return mutation.whenIdle(
                        () => Text(
                          ConnectionState.none.name,
                          textDirection: TextDirection.ltr,
                        ),
                      ) ??
                      Container();
                },
              ),
            );
          }

          testWidgets(
            'should execute idle function',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.nothing(),
                ),
              );

              expect(find.text(ConnectionState.none.name), findsOneWidget);
              expect(find.byType(Container), findsNothing);
            },
          );

          testWidgets(
            'should return Container when initial state is data',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot.withData(
                    ConnectionState.done,
                    42,
                  ),
                ),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.byType(Container), findsOneWidget);
            },
          );

          testWidgets(
            'should return Container when initial state is error',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: AsyncSnapshot.withError(
                    ConnectionState.done,
                    'error',
                    StackTrace.current,
                  ),
                ),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.byType(Container), findsOneWidget);
            },
          );

          testWidgets(
            'should return Container when initial state is waiting',
            (widgetTester) async {
              await widgetTester.pumpWidget(
                build(
                  initialState: const AsyncSnapshot<int>.waiting(),
                ),
              );

              expect(find.text(ConnectionState.none.name), findsNothing);
              expect(find.byType(Container), findsOneWidget);
            },
          );
        },
      );

      group(
        'when mutate ',
        () {
          testWidgets(
            'should flag still false when await mutate completed and context is mounted',
            (widgetTester) async {
              bool throwException = false;

              Widget build<T, R extends Widget>({
                required Future<T> Function() onPressed,
              }) {
                return ProviderScope(
                  child: HookConsumer(
                    builder: (c, ref, child) {
                      final mutation = useMutation<T>();
                      return GestureDetector(
                        onTap: () async {
                          final result = await mutation.mutate<R>(
                            onPressed(),
                            mounted: () => c.mounted,
                          );

                          if (result == null) return;
                          try {
                            mutation.whenMutated(
                              data: (data) {},
                              error: (error, stackTrace) {},
                            );
                          } catch (e) {
                            throwException = true;
                          }
                        },
                        child: const Icon(
                          Icons.add,
                          textDirection: TextDirection.ltr,
                        ),
                      );
                    },
                  ),
                );
              }

              await widgetTester.pumpWidget(
                build(
                  onPressed: () async {
                    await Future.delayed(const Duration(seconds: 5));
                    return 32;
                  },
                ),
              );

              await widgetTester.tap(find.byIcon(Icons.add));

              await widgetTester.pump(
                const Duration(seconds: 1),
              );

              expect(throwException, false);

              await widgetTester.pump(
                const Duration(seconds: 5),
              );

              expect(throwException, false);
            },
          );

          testWidgets(
            'should throw exception when call `whenMutate` directly',
            (widgetTester) async {
              bool throwException = false;

              Widget build<T, R extends Widget>({
                required Future<T> Function() onPressed,
              }) {
                return ProviderScope(
                  child: HookConsumer(
                    builder: (c, ref, child) {
                      final mutation = useMutation<T>();
                      return GestureDetector(
                        onTap: () async {
                          mutation.mutate<R>(
                            onPressed(),
                            mounted: () => c.mounted,
                          );

                          try {
                            mutation.whenMutated(
                              data: (data) {},
                              error: (error, stackTrace) {},
                            );
                          } catch (e) {
                            throwException = true;
                          }
                        },
                        child: const Icon(
                          Icons.add,
                          textDirection: TextDirection.ltr,
                        ),
                      );
                    },
                  ),
                );
              }

              await widgetTester.pumpWidget(
                build(
                  onPressed: () async {
                    await Future.delayed(const Duration(seconds: 5));
                    return 32;
                  },
                ),
              );

              await widgetTester.tap(find.byIcon(Icons.add));

              await widgetTester.pump(
                const Duration(seconds: 5),
              );

              expect(throwException, true);
            },
          );
          testWidgets(
            'should `throwException` and context be unmounted  still false when await mutate completed',
            (widgetTester) async {
              bool throwException = false;

              Widget build<T, R extends Widget>({
                required Future<T> Function() onPressed,
              }) {
                return ProviderScope(
                  child: HookConsumer(
                    builder: (c, ref, child) {
                      final mutation = useMutation<T>();
                      return GestureDetector(
                        onTap: () async {
                          await mutation.mutate<R>(
                            onPressed(),
                            mounted: () => c.mounted,
                          );

                          try {
                            mutation.whenMutated(
                              data: (data) {},
                              error: (error, stackTrace) {},
                            );
                          } catch (e) {
                            throwException = true;
                          }
                        },
                        child: const Icon(
                          Icons.add,
                          textDirection: TextDirection.ltr,
                        ),
                      );
                    },
                  ),
                );
              }

              await widgetTester.pumpWidget(
                build(
                  onPressed: () async {
                    await Future.delayed(const Duration(seconds: 5));
                    throw UnimplementedError('error');
                    // return 32;
                  },
                ),
              );

              await widgetTester.tap(find.byIcon(Icons.add));

              await widgetTester.pump(
                const Duration(seconds: 1),
              );

              expect(throwException, false);

              await widgetTester.pumpWidget(
                Container(),
              );

              expect(find.byType(Container), findsOneWidget);
              expect(find.byType(GestureDetector), findsNothing);

              await widgetTester.pump(
                const Duration(seconds: 5),
              );

              expect(throwException, true);
            },
          );
        },
      );
    },
  );
}
