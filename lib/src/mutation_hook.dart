import 'dart:async';

import 'package:flutter/foundation.dart';
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
  Future<T> call(
    Future<T> future, {
    required bool Function() mounted,
  }) async {
    value = AsyncSnapshot<T>.waiting();

    try {
      final result = await future;

      if (kDebugMode) print('[riverpod_hook_mutation] Data: $result');

      if (!mounted()) return result;

      value = AsyncSnapshot<T>.withData(
        ConnectionState.done,
        result,
      );
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) print('[riverpod_hook_mutation] Error: $e');

      if (!mounted()) rethrow;

      value = AsyncSnapshot<T>.withError(
        ConnectionState.done,
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<R?> mutate<R>(
    Future<T> future, {
    required bool Function() mounted,
    R Function()? loading,
    AsyncDataCallback<R?, T>? data,
    AsyncErrorCallback<R?>? error,
  }) async {
    value = AsyncSnapshot<T>.waiting();
    loading?.call();

    try {
      final result = await future;

      if (kDebugMode) print('[riverpod_hook_mutation] Data: $result');

      if (!mounted()) return null;

      value = AsyncSnapshot<T>.withData(
        ConnectionState.done,
        result,
      );

      return data?.call(result);
    } catch (e, stackTrace) {
      if (kDebugMode) print('[riverpod_hook_mutation] Error: $e');

      if (!mounted()) return null;

      value = AsyncSnapshot<T>.withError(
        ConnectionState.done,
        e,
        stackTrace,
      );
      return error?.call(e, stackTrace);
    }
  }

  /// [AsyncSnapshot] extension methods.
  ConnectionState get connectionState => value.connectionState;

  /// Returns `true` if the [AsyncSnapshot] has data.
  bool get hasError => value.hasError;

  /// Returns the error of the [AsyncSnapshot].
  Object? get error => value.error;

  /// Returns the stack trace of the [AsyncSnapshot].
  StackTrace? get stackTrace => value.stackTrace;

  /// Returns the data of the [AsyncSnapshot].
  T? get data => value.data;

  /// Returns `true` if the [AsyncSnapshot] is in the `waiting` state.
  bool get isLoading => connectionState == ConnectionState.waiting;

  /// Returns `true` if the [AsyncSnapshot] is in the `none` state.
  bool get isIdle => connectionState == ConnectionState.none;

  /// Returns `true` if the [AsyncSnapshot] is in the `done` state and has data.
  bool get isData => connectionState == ConnectionState.done && !hasError;

  /// Returns `true` if the [AsyncSnapshot] is in the `done` state and has an error.
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

  /// Calls the provided callbacks based on the state of the mutation.
  ///
  /// The [data] callback is called when the mutation has completed successfully and contains the resulting data.
  /// The [error] callback is called when the mutation has encountered an error and contains the error and stack trace.
  ///
  /// Throws an exception if called before the mutation is done, indicating that this function can only be called after the mutation is done and is used for data or error handling.
  /// Example:
  /// ```dart
  /// final mutation = useMutation<String>();
  ///
  /// mutation.mutate('data');
  ///
  /// final result = whenMutated<String>(
  ///   data: (data) {
  ///     print('Mutation completed successfully. Result: $data');
  ///     return 'Success';
  ///   },
  ///   error: (error) {
  ///     print('Mutation encountered an error: $error');
  ///     return 'Error';
  ///   },
  /// );
  /// ```
  R whenMutated<R>({
    required AsyncDataCallback<R, T> data,
    required AsyncErrorCallback<R> error,
  }) {
    return maybeWhen<R>(
      orElse: () {
        throw Exception('Cannot call whenMutated before the mutation is done.');
      },
      data: data,
      error: error,
    );
  }
}
