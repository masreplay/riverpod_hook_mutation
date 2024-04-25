import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'async_snapshot.dart';



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

extension AsyncSnapshotValueNotifier<T> on ValueNotifier<AsyncSnapshot<T>> {
  void reset() {
    value = AsyncSnapshot<T>.nothing();
  }

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

  Future<R?> execute<R>(
    Future<T> future, {
    required AsyncDataCallback<R?, T>? data,
    required AsyncErrorCallback<R?>? error,
  }) async {
    await call(future);
    return value.whenOrNull(data: data, error: error);
  }

  bool get isLoading => value.isLoading;
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

  R? whenDataOrError<R>({
    required AsyncDataCallback<R?, T>? data,
    required AsyncErrorCallback<R?>? error,
  }) {
    return value.whenOrNull(data: data, error: error);
  }
}
