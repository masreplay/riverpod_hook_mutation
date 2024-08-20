import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_hook_mutation/riverpod_hook_mutation.dart';

part 'main.g.dart';

Future<void> main() async {
  runApp(
    const ProviderScope(
      child: MaterialApp(
        home: TodosScreen(),
      ),
    ),
  );
}

class TodoRepository {
  static final TodoRepository _instance = TodoRepository._internal();

  factory TodoRepository() => _instance;

  TodoRepository._internal();

  final _todos = [
    TodoModel(
      title: 'Buy milk',
      completed: false,
    ),
    TodoModel(
      title: 'Buy eggs',
      completed: true,
    ),
    TodoModel(
      title: 'Buy bread',
      completed: false,
    ),
  ];

  Future<List<TodoModel>> fetchTodos() async {
    await Future.delayed(const Duration(seconds: 3));
    return _todos;
  }

  Future<TodoModel> createTodo() async {
    return Future.delayed(const Duration(seconds: 3), () {
      final todo = TodoModel(
        title: 'Buy cheese ${Random().nextInt(1000000)}',
        completed: false,
      );
      _todos.add(todo);
      return todo;
    });
  }
}

class TodoModel {
  final String title;
  final bool completed;

  TodoModel({
    required this.title,
    required this.completed,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'completed': completed,
    };
  }
}

@riverpod
class Todos extends _$Todos {
  TodoRepository get _repository => TodoRepository();

  @override
  Future<List<TodoModel>> build() {
    return _repository.fetchTodos();
  }

  Future<TodoModel> addTodo() async {
    final result = await _repository.createTodo();
    ref.invalidateSelf();

    if (kDebugMode) print(result.toJson());
    return result;
  }
}

class TodosScreen extends HookConsumerWidget {
  const TodosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = todosProvider;
    final todos = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          FloatingActionButton.small(
            heroTag: null,
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) {
                    return const ItemAddScreen();
                  },
                ),
              );
            },
          )
        ],
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

class ItemAddScreen extends HookConsumerWidget {
  const ItemAddScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addTodo = useMutation<TodoModel>();

    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          addTodo.when(
            idle: () {
              return const Icon(Icons.add);
            },
            data: (data) {
              return const Icon(Icons.add);
            },
            error: (error, stackTrace) {
              return const Icon(Icons.error);
            },
            loading: CircularProgressIndicator.new,
          ),
          FilledButton(
            child: const Text('Add .call'),
            onPressed: () {
              Navigator.of(context).pop();

              final notifier = ref.read(todosProvider.notifier);
              addTodo(
                notifier.addTodo(),
                mounted: () => context.mounted,
              );
            },
          ),
          FilledButton(
            child: const Text('Add .mutate'),
            onPressed: () async {
              final notifier = ref.read(todosProvider.notifier);

              await addTodo.mutate(
                notifier.addTodo(),
                mounted: () => context.mounted,
                loading: Navigator.of(context).pop,
                data: (data) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Todo added: ${data.title}'),
                    ),
                  );
                },
                error: (error, stackTrace) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $error'),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
