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

            useEffect(() {
              onStateChange(mutation.value);

              listener() {
                onStateChange(mutation.value);
              }

              mutation.addListener(listener);
              return () => mutation.removeListener(listener);
            });
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

    testWidgets('when call mutate should expect done state with value',
        (tester) async {
      ///given
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
    });

    testWidgets('when call mutate should expect done state with error',
        (tester) async {
      ///given
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

      ///when
      await tester.tap(find.byIcon(Icons.add));

      ///then
      await tester.pump(
        const Duration(seconds: 1),
      );

      ///Check if state is waiting and loading is called
      expect(snapshot.connectionState, ConnectionState.waiting);
      expect(isLoadingCalled, true);

      await tester.pump(
        const Duration(seconds: 6),
      );

      ///Check if state is done and error is called and data is not called
      expect(snapshot.connectionState, ConnectionState.done);
      expect(snapshot.error, isA<UnimplementedError>());
      expect(isDataCalled, false);
      expect(isErrorCalled, true);
    });

    testWidgets(
        'when call mutate and context is not mounted should expect waiting state',
        (tester) async {
      ///given
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

      ///when
      await tester.tap(find.byIcon(Icons.add));

      ///then
      await tester.pump(
        const Duration(seconds: 1),
      );

      ///Check if state is waiting and loading is called
      expect(snapshot.connectionState, ConnectionState.waiting);
      expect(isLoadingCalled, true);

      ///Dispose the widget make the context not mounted
      await tester.pumpWidget(
        Container(),
      );

      /// ensure the widget is disposed and the context is not mounted
      expect(find.byType(Container), findsOneWidget);
      expect(find.byType(Text), findsNothing);

      await tester.pump(
        const Duration(seconds: 6),
      );

      ///State still loading
      expect(snapshot.connectionState, ConnectionState.waiting);

      ///Check if data and error is not called
      expect(isDataCalled, false);
      expect(isErrorCalled, false);
    });

    testWidgets(
        'when call mutate with error and context is not mounted should expect waiting state',
        (tester) async {
      ///given
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

      ///when
      await tester.tap(find.byIcon(Icons.add));

      ///then
      await tester.pump(
        const Duration(seconds: 1),
      );

      expect(snapshot.connectionState, ConnectionState.waiting);

      expect(isLoadingCalled, true);

      ///Dispose the widget make the context not mounted
      await tester.pumpWidget(
        Container(),
      );

      /// ensure the widget is disposed and the context is not mounted
      expect(find.byType(Container), findsOneWidget);
      expect(find.byType(Text), findsNothing);

      await tester.pump(
        const Duration(seconds: 6),
      );

      expect(snapshot.connectionState, ConnectionState.waiting);
      expect(isDataCalled, false);
      expect(isErrorCalled, false);
    });
  });

  group('when functions', () {
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

    group('when', () {
      testWidgets('should execute idle function only', (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsOneWidget);
        expect(find.text(ConnectionState.done.name), findsNothing);
        expect(find.text(ConnectionState.waiting.name), findsNothing);
      });

      testWidgets('should execute data function only', (widgetTester) async {
        ///given
        const data = 42;

        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot.withData(
              ConnectionState.done,
              data,
            ),
          ),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsOneWidget);
        expect(find.text(ConnectionState.waiting.name), findsNothing);
      });

      testWidgets('should execute error function only', (widgetTester) async {
        ///given
        const error = 'error';

        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: AsyncSnapshot.withError(
              ConnectionState.done,
              error,
              StackTrace.current,
            ),
          ),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsOneWidget);
        expect(find.text(ConnectionState.waiting.name), findsNothing);
      });

      testWidgets('should execute loading function only', (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot<int>.waiting(),
          ),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsNothing);
        expect(find.text(ConnectionState.waiting.name), findsOneWidget);
      });

      //case noting -> click icon -> loading -> done
      testWidgets('should execute loading then done ', (widgetTester) async {
        ///given
        const data = 42;

        ///when
        await widgetTester.pumpWidget(
          build(
            onPressed: () async {
              await Future.delayed(const Duration(seconds: 5));
              return data;
            },
          ),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsOneWidget);
        expect(find.text(ConnectionState.done.name), findsNothing);
        expect(find.text(ConnectionState.waiting.name), findsNothing);

        ///when
        await widgetTester.tap(find.byIcon(Icons.add));

        await widgetTester.pump(
          const Duration(seconds: 1),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsNothing);
        expect(find.text(ConnectionState.waiting.name), findsOneWidget);

        await widgetTester.pump(
          const Duration(seconds: 5),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.waiting.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsOneWidget);
      });

      //case noting -> click icon -> loading -> error
      testWidgets('should execute loading then error', (widgetTester) async {
        ///given
        const error = 'error';

        ///when
        await widgetTester.pumpWidget(
          build(
            onPressed: () async {
              await Future.delayed(const Duration(seconds: 5));
              throw UnimplementedError(error);
            },
          ),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsOneWidget);
        expect(find.text(ConnectionState.done.name), findsNothing);
        expect(find.text(ConnectionState.waiting.name), findsNothing);

        ///when
        await widgetTester.tap(find.byIcon(Icons.add));

        await widgetTester.pump(
          const Duration(seconds: 1),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsNothing);
        expect(find.text(ConnectionState.waiting.name), findsOneWidget);

        await widgetTester.pump(
          const Duration(seconds: 5),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.waiting.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsOneWidget);
      });
    });

    group('when or null', () {
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

      testWidgets('should execute idle function', (widgetTester) async {
        ///when
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

        ///then
        expect(find.text(ConnectionState.none.name), findsOneWidget);
        expect(find.text(ConnectionState.done.name), findsNothing);
        expect(find.text(ConnectionState.waiting.name), findsNothing);
        expect(find.text('null'), findsNothing);
      });

      testWidgets('should execute data function', (widgetTester) async {
        ///given
        const data = 42;

        ///when
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

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsOneWidget);
        expect(find.text(ConnectionState.waiting.name), findsNothing);
        expect(find.text('null'), findsNothing);
      });

      testWidgets('should execute error function', (widgetTester) async {
        ///given
        const error = 'error';

        ///when
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

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsOneWidget);
        expect(find.text(ConnectionState.waiting.name), findsNothing);
        expect(find.text('null'), findsNothing);
      });

      testWidgets('should execute loading function', (widgetTester) async {
        ///when
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

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsNothing);
        expect(find.text(ConnectionState.waiting.name), findsOneWidget);
        expect(find.text('null'), findsNothing);
      });

      testWidgets('should return null', (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot<int>.nothing(),
          ),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsNothing);
        expect(find.text(ConnectionState.waiting.name), findsNothing);
        expect(find.text('null'), findsOneWidget);
      });
    });

    group('maybe when', () {
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

      testWidgets('should execute idle function', (widgetTester) async {
        ///when
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

        ///then
        expect(find.text(ConnectionState.none.name), findsOneWidget);
        expect(find.text(ConnectionState.done.name), findsNothing);
        expect(find.text(ConnectionState.waiting.name), findsNothing);
        expect(find.byType(Container), findsNothing);
      });

      testWidgets('should execute data function', (widgetTester) async {
        ///given
        const data = 42;

        ///when
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

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsOneWidget);
        expect(find.text(ConnectionState.waiting.name), findsNothing);
        expect(find.byType(Container), findsNothing);
      });

      testWidgets('should execute error function', (widgetTester) async {
        ///given
        const error = 'error';

        ///when
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

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsOneWidget);
        expect(find.text(ConnectionState.waiting.name), findsNothing);
        expect(find.byType(Container), findsNothing);
      });

      testWidgets('should execute loading function', (widgetTester) async {
        ///when
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

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsNothing);
        expect(find.text(ConnectionState.waiting.name), findsOneWidget);
        expect(find.byType(Container), findsNothing);
      });

      testWidgets('should return Container', (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot<int>.nothing(),
          ),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.text(ConnectionState.done.name), findsNothing);
        expect(find.text(ConnectionState.waiting.name), findsNothing);
        expect(find.byType(Container), findsOneWidget);
      });
    });

    group('when Data', () {
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

      testWidgets('should execute data function', (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot.withData(
              ConnectionState.done,
              data,
            ),
          ),
        );

        ///then
        expect(find.text('${ConnectionState.done.name} $data'), findsOneWidget);
        expect(find.byType(Container), findsNothing);
      });

      testWidgets('should return Container when initial state is noting',
          (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot<int>.nothing(),
          ),
        );

        ///then
        expect(find.text('${ConnectionState.done.name} $data'), findsNothing);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should return Container when initial state is waiting ',
          (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot<int>.waiting(),
          ),
        );

        ///then
        expect(find.text('${ConnectionState.done.name} $data'), findsNothing);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should return Container when initial state is error',
          (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: AsyncSnapshot.withError(
              ConnectionState.done,
              'error',
              StackTrace.current,
            ),
          ),
        );

        ///then
        expect(find.text('${ConnectionState.done.name} $data'), findsNothing);
        expect(find.byType(Container), findsOneWidget);
      });
    });

    group('when error', () {
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

      testWidgets('should execute error function', (widgetTester) async {
        ///given

        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: AsyncSnapshot.withError(
              ConnectionState.done,
              error,
              StackTrace.current,
            ),
          ),
        );

        ///then
        expect(find.text(ConnectionState.done.name + error), findsOneWidget);
        expect(find.byType(Container), findsNothing);
      });

      testWidgets('should return Container when initial state is noting',
          (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot<int>.nothing(),
          ),
        );

        ///then
        expect(find.text(ConnectionState.done.name + error), findsNothing);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should return Container when initial state is waiting ',
          (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot<int>.waiting(),
          ),
        );

        ///then
        expect(find.text(ConnectionState.done.name + error), findsNothing);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should return Container when initial state is data',
          (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot.withData(
              ConnectionState.done,
              42,
            ),
          ),
        );

        ///then
        expect(find.text(ConnectionState.done.name + error), findsNothing);
        expect(find.byType(Container), findsOneWidget);
      });
    });

    group('when loading', () {
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

      testWidgets('should execute loading function', (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot<int>.waiting(),
          ),
        );

        ///then
        expect(find.text(ConnectionState.waiting.name), findsOneWidget);
        expect(find.byType(Container), findsNothing);
      });

      testWidgets('should return Container when initial state is noting',
          (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot<int>.nothing(),
          ),
        );

        ///then
        expect(find.text(ConnectionState.waiting.name), findsNothing);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should return Container when initial state is data',
          (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot.withData(
              ConnectionState.done,
              42,
            ),
          ),
        );

        ///then
        expect(find.text(ConnectionState.waiting.name), findsNothing);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should return Container when initial state is error',
          (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: AsyncSnapshot.withError(
              ConnectionState.done,
              'error',
              StackTrace.current,
            ),
          ),
        );

        ///then
        expect(find.text(ConnectionState.waiting.name), findsNothing);
        expect(find.byType(Container), findsOneWidget);
      });
    });

    group('when idle', () {
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

      testWidgets('should execute idle function', (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot<int>.nothing(),
          ),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsOneWidget);
        expect(find.byType(Container), findsNothing);
      });

      testWidgets('should return Container when initial state is data',
          (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot.withData(
              ConnectionState.done,
              42,
            ),
          ),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should return Container when initial state is error',
          (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: AsyncSnapshot.withError(
              ConnectionState.done,
              'error',
              StackTrace.current,
            ),
          ),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should return Container when initial state is waiting',
          (widgetTester) async {
        ///when
        await widgetTester.pumpWidget(
          build(
            initialState: const AsyncSnapshot<int>.waiting(),
          ),
        );

        ///then
        expect(find.text(ConnectionState.none.name), findsNothing);
        expect(find.byType(Container), findsOneWidget);
      });
    });
  });
}
