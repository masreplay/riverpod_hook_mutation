import 'package:flutter/material.dart';

typedef AsyncErrorCallback<R> = R Function(
  Object? error,
  StackTrace? stackTrace,
);

typedef AsyncDataCallback<R, T> = R Function(T data);

typedef AsyncIdleCallback<R> = R Function();
typedef AsyncLoadingCallback<R> = R Function();

extension AsyncSnapshotExtension<T> on AsyncSnapshot<T> {
  /// Returns the [ConnectionState] of the [AsyncSnapshot].
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
    switch (connectionState) {
      case ConnectionState.none:
        return idle.call();
      case ConnectionState.waiting:
        return loading.call();
      case ConnectionState.active:
      case ConnectionState.done:
        if (hasError) {
          return error.call(this.error, stackTrace);
        } else {
          return data.call(this.data as T);
        }
    }
  }

  R? whenOrNull<R>({
    AsyncIdleCallback<R?>? idle,
    AsyncDataCallback<R?, T>? data,
    AsyncErrorCallback<R?>? error,
    AsyncLoadingCallback<R?>? loading,
  }) {
    switch (connectionState) {
      case ConnectionState.none:
        return idle?.call();
      case ConnectionState.waiting:
        return loading?.call();
      case ConnectionState.active:
      case ConnectionState.done:
        if (hasError) {
          return error?.call(this.error, stackTrace);
        } else {
          return data?.call(this.data as T);
        }
    }
  }

  R maybeWhen<R>({
    AsyncIdleCallback<R>? idle,
    AsyncDataCallback<R, T>? data,
    AsyncErrorCallback<R>? error,
    AsyncLoadingCallback<R>? loading,
    required R Function() orElse,
  }) {
    switch (connectionState) {
      case ConnectionState.none:
        return (idle ?? orElse).call();
      case ConnectionState.waiting:
        return (loading ?? orElse).call();
      case ConnectionState.active:
      case ConnectionState.done:
        if (hasError) {
          if (error == null) return orElse.call();
          return error.call(this.error, stackTrace);
        } else {
          if (data == null) return orElse.call();
          return data.call(this.data as T);
        }
    }
  }

  R? whenError<R>(AsyncErrorCallback<R?>? error) {
    return whenOrNull(error: error);
  }

  R? whenData<R>(AsyncDataCallback<R?, T>? data) {
    return whenOrNull(data: data);
  }

  R? whenIdle<R>(AsyncIdleCallback<R?>? idle) {
    return whenOrNull(idle: idle);
  }

  R? whenLoading<R>(AsyncLoadingCallback<R?>? loading) {
    return whenOrNull(loading: loading);
  }
}
