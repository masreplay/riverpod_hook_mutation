import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation/riverpod_mutation.dart';

@riverpod
class Example extends _$Example {
  @override
  Future<List<Todo>> build() => fetchTodoList();

  @mutation
  Future<void> addTodo(Todo todo) async {
    await http.post(...., todo.toJson());
  }
}