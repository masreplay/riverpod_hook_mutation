// import 'package:flutter/material.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';

// part 'main.g.dart';

// class Repository {
//   static final Repository _instance = Repository._internal();

//   factory Repository() => _instance;

//   Repository._internal();

//   final _todos = [
//     TODO(
//       title: 'Buy milk',
//       completed: false,
//     ),
//     TODO(
//       title: 'Buy eggs',
//       completed: true,
//     ),
//     TODO(
//       title: 'Buy bread',
//       completed: false,
//     ),
//   ];

//   Future<List<TODO>> fetchTodos() async {
//     await Future.delayed(const Duration(seconds: 1));
//     return _todos;
//   }
// }

// class TODO {
//   final String title;
//   final bool completed;

//   TODO({
//     required this.title,
//     required this.completed,
//   });
// }

// @riverpod
// Future<List<TODO>> example(ExampleRef ref) {
//   return Repository().fetchTodos();
// }

// class ExampleScreen extends ConsumerWidget {
//   const ExampleScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final todos = ref.watch(exampleProvider);

//     return Scaffold(
//       body: todos.when(
//         data: (data) {
//           return ListView.builder(
//             itemCount: data.length,
//             itemBuilder: (context, index) {
//               final todo = data[index];
//               return ListTile(
//                 title: Text(todo.title),
//               );
//             },
//           );
//         },
//         error: (error, stackTrace) {
//           return Center(
//             child: Text('Error: $error'),
//           );
//         },
//         loading: () {
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         },
//       ),
//     );
//   }
// }
