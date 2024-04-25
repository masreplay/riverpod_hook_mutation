import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'async_snapshot.dart';

/// A custom hook that provides a [ValueNotifier] for managing asynchronous state.
///
/// The [useAsyncState] hook can be used to create a [ValueNotifier] that holds an [AsyncSnapshot] of type [T].
/// It takes an optional [data] parameter and an optional [state] parameter.
/// Only one of them can be provided at a time.
///
/// If [data] is provided, it creates an [AsyncSnapshot] with the provided data and [ConnectionState.done].
/// If [state] is provided, it uses the provided [AsyncSnapshot].
/// If neither [data] nor [state] is provided, it creates an [AsyncSnapshot] with [ConnectionState.none].
///
/// Example usage:
/// ```dart
/// final snapshot = useAsyncState<int>(data: 42);
/// ```
ValueNotifier<AsyncSnapshot<T>> useAsyncState<T>({
  T? data,
  AsyncSnapshot<T>? state,
}) {
  assert(
    data == null || state == null,
    'You can only provide either data or state',
  );

  final dataState = data == null
      ? null
      : AsyncSnapshot<T>.withData(ConnectionState.done, data);

  return useState<AsyncSnapshot<T>>(
    dataState ?? state ?? const AsyncSnapshot.nothing(),
  );
}

extension ValueNotifierAsyncSnapshot<T> on ValueNotifier<AsyncSnapshot<T>> {
  /// Resets the value of the [ValueNotifier] to an [AsyncSnapshot] with [ConnectionState.none].
  void reset() {
    value = AsyncSnapshot<T>.nothing();
  }

  /// Executes a [Future] and updates the value of the [ValueNotifier] accordingly.
  ///
  /// The [call] method sets the value of the [ValueNotifier] to [AsyncSnapshot.waiting()],
  /// then waits for the [future] to complete.
  /// If the [future] completes successfully, it sets the value of the [ValueNotifier] to
  /// [AsyncSnapshot.withData(ConnectionState.done, data)].
  /// If the [future] throws an error, it sets the value of the [ValueNotifier] to
  /// [AsyncSnapshot.withError(ConnectionState.done, error, stackTrace)].
  ///
  /// Example usage:
  /// ```dart
  /// final snapshot = useAsyncState<int>();
  /// snapshot.call(fetchData());
  /// ```
  Future<void> call(Future<T> future) async {
    value = AsyncSnapshot<T>.waiting();

    await future.then<void>(
      (data) {
        value = AsyncSnapshot<T>.withData(
          ConnectionState.done,
          data,
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        value = AsyncSnapshot<T>.withError(
          ConnectionState.done,
          error,
          stackTrace,
        );
      },
    );
  }

  /// Executes a [Future] and returns the result based on the current value of the [ValueNotifier].
  ///
  /// The [execute] method calls the [call] method with the provided [future],
  /// then returns the result of calling [value.whenOrNull] with the provided [data] and [error] callbacks.
  ///
  /// Example usage:
  /// ```dart
  /// final snapshot = useAsyncState<int>();
  /// final result = await snapshot.execute(fetchData(), data: (data) => data.toString());
  /// ```
  Future<R?> execute<R>(
    Future<T> future, {
    required AsyncDataCallback<R?, T>? data,
    required AsyncErrorCallback<R?>? error,
  }) async {
    await call(future);
    return value.whenOrNull(data: data, error: error);
  }

  /// Returns `true` if the current state of the [ValueNotifier] is [ConnectionState.waiting].
  bool get isLoading => value.isLoading;

  /// Returns the result of calling [value.whenOrNull] with the provided callbacks.
  ///
  /// The [whenOrNull] method returns the result of calling the appropriate callback based on the current state of the [ValueNotifier].
  /// If the state is [ConnectionState.none], it calls the [idle] callback.
  /// If the state is [ConnectionState.done] and the data is not `null`, it calls the [data] callback.
  /// If the state is [ConnectionState.done] and the error is not `null`, it calls the [error] callback.
  /// If the state is [ConnectionState.waiting], it calls the [loading] callback.
  ///
  /// Example usage:
  /// ```dart
  /// final snapshot = useAsyncState<int>();
  /// final result = snapshot.whenOrNull(
  ///   data: (data) => data.toString(),
  ///   error: (error, stackTrace) => 'Error: $error',
  /// );
  /// ```
  R? whenOrNull<R>({
    AsyncIdleCallback<R?>? idle,
    AsyncDataCallback<R?, T>? data,
    AsyncErrorCallback<R?>? error,
    AsyncLoadingCallback<R?>? loading,
  }) {
    return value.whenOrNull(
      idle: idle,
      data: data,
      error: error,
      loading: loading,
    );
  }

  /// Returns the result of calling [value.whenOrNull] with the provided [data] and [error] callbacks.
  ///
  /// The [whenDataOrError] method returns the result of calling the [data] callback if the state is [ConnectionState.done] and the data is not `null`,
  /// or the result of calling the [error] callback if the state is [ConnectionState.done] and the error is not `null`.
  ///
  /// Example usage:
  /// ```dart
  /// final snapshot = useAsyncState<int>();
  /// final result = snapshot.whenDataOrError(
  ///   data: (data) => data.toString(),
  ///   error: (error, stackTrace) => 'Error: $error',
  /// );
  /// ```
  R? whenDataOrError<R>({
    required AsyncDataCallback<R?, T>? data,
    required AsyncErrorCallback<R?>? error,
  }) {
    return value.whenOrNull(data: data, error: error);
  }
}
