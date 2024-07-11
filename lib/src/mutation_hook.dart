import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'async_snapshot_extension.dart';

/// A custom hook that provides a [ValueNotifier] for managing asynchronous state.
///
/// The [useMutation] hook can be used to create a [ValueNotifier] that holds an [AsyncSnapshot] of type [T].
/// It takes an optional [data] parameter and an optional [state] parameter.
/// Only one of them can be provided at a time.
///
/// If [data] is provided, it creates an [AsyncSnapshot] with the provided data and [ConnectionState.done].
/// If [state] is provided, it uses the provided [AsyncSnapshot].
/// If neither [data] nor [state] is provided, it creates an [AsyncSnapshot] with [ConnectionState.none].
///
/// Example usage:
/// ```dart
/// final snapshot = useAsyncSnapshot<int>(data: 42);
/// ```
ValueNotifier<AsyncSnapshot<T>> useMutation<T>({
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
  void reload() {
    value = AsyncSnapshot<T>.nothing();
  }

  /// futures a [Future] and updates the value of the [ValueNotifier] accordingly.
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
  /// final snapshot = useAsyncSnapshot<int>();
  /// snapshot(fetchData());
  /// ```
  Future<void> call(Future<T> future) async {
    value = AsyncSnapshot<T>.waiting();

    try {
      final result = await future;
      value = AsyncSnapshot<T>.withData(ConnectionState.done, result);
    } catch (e) {
      value = AsyncSnapshot<T>.withError(
        ConnectionState.done,
        e,
        StackTrace.current,
      );
    }
  }

  /// futures a [Future] and returns the result based on the current value of the [ValueNotifier].
  ///
  /// The [future] method calls the [call] method with the provided [future],
  /// then returns the result of calling [value.whenOrNull] with the provided [data] and [error] callbacks.
  ///
  /// Example usage:
  /// ```dart
  /// final snapshot = useAsyncSnapshot<int>();
  /// final result = await snapshot.future(fetchData(), data: (data) => data.toString());
  /// ```
  Future<R?> future<R>(
    Future<T> future, {
    FutureOr<R?> Function()? loading,
    AsyncDataCallback<R?, T>? data,
    AsyncErrorCallback<R?>? error,
  }) async {
    await loading?.call();
    await call(future);
    return value.whenOrNull(data: data, error: error);
  }

  /// [AsyncSnapshot] extension methods.
  ConnectionState get connectionState => value.connectionState;
  bool get hasError => value.hasError;
  Object? get error => value.error;
  StackTrace? get stackTrace => value.stackTrace;
  T? get data => value.data;

  bool get isLoading => connectionState == ConnectionState.waiting;
  bool get isIdle => connectionState == ConnectionState.none;
  bool get isData => connectionState == ConnectionState.done && !hasError;
  bool get isError => connectionState == ConnectionState.done && hasError;

  R when<R>({
    required AsyncIdleCallback<R> idle,
    required AsyncDataCallback<R, T> data,
    required AsyncErrorCallback<R> error,
    required AsyncLoadingCallback<R> loading,
  }) {
    return value.when(
      idle: idle,
      data: data,
      error: error,
      loading: loading,
    );
  }

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

  R maybeWhen<R>({
    AsyncIdleCallback<R?>? idle,
    AsyncDataCallback<R?, T>? data,
    AsyncErrorCallback<R?>? error,
    AsyncLoadingCallback<R?>? loading,
    required R Function() orElse,
  }) {
    return value.maybeWhen(
      idle: idle,
      data: data,
      error: error,
      loading: loading,
      orElse: orElse,
    );
  }

  R? whenError<R>(AsyncErrorCallback<R?>? error) {
    return value.whenError(error);
  }

  R? whenData<R>(AsyncDataCallback<R?, T>? data) {
    return value.whenData(data);
  }

  R? whenIdle<R>(AsyncIdleCallback<R?>? idle) {
    return value.whenIdle(idle);
  }

  R? whenLoading<R>(AsyncLoadingCallback<R?>? loading) {
    return value.whenLoading(loading);
  }
}
