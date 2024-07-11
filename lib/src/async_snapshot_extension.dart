import 'package:flutter/material.dart';

typedef AsyncErrorCallback<R> = R Function(
  Object? error,
  StackTrace? stackTrace,
);

typedef AsyncDataCallback<R, T> = R Function(T data);

typedef AsyncIdleCallback<R> = R Function();
typedef AsyncLoadingCallback<R> = R Function();

extension AsyncSnapshotExtension<T> on AsyncSnapshot<T> {
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
    AsyncIdleCallback<R?>? idle,
    AsyncDataCallback<R?, T>? data,
    AsyncErrorCallback<R?>? error,
    AsyncLoadingCallback<R?>? loading,
    required R Function() orElse,
  }) {
    switch (connectionState) {
      case ConnectionState.none:
        return idle?.call() ?? orElse.call();
      case ConnectionState.waiting:
        return loading?.call() ?? orElse.call();
      case ConnectionState.active:
      case ConnectionState.done:
        if (hasError) {
          return error?.call(this.error, stackTrace) ?? orElse.call();
        } else {
          return data?.call(this.data as T) ?? orElse.call();
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
