# Flutter Package README Template

[![Pub](https://img.shields.io/pub/v/riverpod_mutation.svg)](https://pub.dev/packages/riverpod_mutation)
[![GitHub stars](https://img.shields.io/github/stars/masreplay/riverpod_mutation.svg?style=social)](https://github.com/masreplay/riverpod_mutation)

A package that provides a simple way to manage mutations in Riverpod

## inspiration
Fix the issue of riverpod mutation https://github.com/rrousselGit/riverpod/issues/1660

## Features
- [x] Mutation with hooks
- [x] Mutation with provider
- [x] uses flutter [ValueNotifier] with [AsyncSnapshot] to notify the state change

## Getting Started

In order to use this package, you need to add `riverpod_mutation` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  riverpod_mutation: ^0.0.1
```

Then, run `flutter pub get` to fetch the package.

## Usage

```dart
import 'package:riverpod_mutation/riverpod_mutation.dart';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation/riverpod_mutation.dart';

part 'main.g.dart';

void main(List<String> args) {
  runApp(
    const ProviderScope(
      child: MaterialApp(home: ExampleScreen()),
    ),
  );
}

class Repository {
  static final Repository _instance = Repository._internal();

  factory Repository() => _instance;

  Repository._internal();

  final _todos = [
    TODO(
      title: 'Buy milk',
      completed: false,
    ),
    TODO(
      title: 'Buy eggs',
      completed: true,
    ),
    TODO(
      title: 'Buy bread',
      completed: false,
    ),
  ];

  Future<List<TODO>> fetchTodos() async {
    await Future.delayed(const Duration(seconds: 1));
    return _todos;
  }

  Future<TODO> createTodo() async {
    return Future.delayed(const Duration(seconds: 1), () {
      if (Random().nextBool()) {
        throw Exception('Failed to create todo');
      } else {
        final todo = TODO(
          title: 'Buy cheese ${Random().nextInt(1000000)}',
          completed: false,
        );
        _todos.add(todo);
        return todo;
      }
    });
  }
}

class TODO {
  final String title;
  final bool completed;

  TODO({
    required this.title,
    required this.completed,
  });
}

@riverpod
class Example extends _$Example {
  @override
  Future<List<TODO>> build() {
    return Repository().fetchTodos();
  }

  Future<TODO> addTodo() async {
    final result = await Repository().createTodo();
    ref.invalidateSelf();
    return result;
  }
}

class ExampleScreen extends HookConsumerWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = exampleProvider;
    final todos = ref.watch(provider);

    final addTodo = useMutation<TODO>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: addTodo.maybeWhen(
          loading: () => const CircularProgressIndicator(),
          orElse: () => const Icon(Icons.add),
        ),
        onPressed: () {
          final notifier = ref.read(provider.notifier);

          addTodo.future(
            notifier.addTodo(),
            data: (data) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Created todo: ${data.title}'),
                ),
              );
            },
            error: (error, stackTrace) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create todo: $error'),
                ),
              );
            },
          );
        },
      ),
      body: todos.when(
        data: (data) {
          return RefreshIndicator(
            onRefresh: () => ref.read(provider.future),
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final todo = data[index];
                return ListTile(
                  title: Text(todo.title),
                );
              },
            ),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Text('Error: $error'),
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}

```

## Documentation

For more details, check out the [documentation](https://pub.dev/riverpod_mutation).

## Contributing

Contributions are welcome! If you find any issues or have suggestions, please create a new issue or submit a pull request.

## License

This project is licensed under the [MIT License](./LICENSE).
