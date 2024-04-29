import 'package:flutter_async_hook/flutter_async_hook.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useAsyncSnapshot<String>();

    return Column(
      children: [
        if (state.isLoading) const LinearProgressIndicator(),
        if (state.isLoading) const LinearProgressIndicator(),
        state.when(
          idle: () {
            return const Text('Idle');
          },
          data: (data) {
            return Text('Data: $data');
          },
          error: (error, stackTrace) {
            return Text('Error: $error');
          },
          loading: () {
            return const CircularProgressIndicator();
          },
        ),
        FilledButton(
          onPressed: () {
            final messenger = ScaffoldMessenger.of(context);

            state.value.whenData((data) {});

            state.future(
              _greeting(),
              data: (data) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Data: $data')),
                );
              },
              error: (error, stackTrace) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error: $error')),
                );
              },
            );
          },
          child: const Text('Run async'),
        ),
      ],
    );
  }

  Future<String> _greeting() {
    return Future.delayed(const Duration(seconds: 2), () => 'Hello');
  }
}
