import 'package:async_hook/async_hook.dart';
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
    final state = useAsyncState<String>();

    return Column(
      children: [
        if (state.isLoading) const LinearProgressIndicator(),
        state.value.when(
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
          onPressed: () async {
            // TODO(you): write loading state here

            await state(_greeting());

            state.whenDataOrError(
              data: (data) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Data: $data')),
                );
              },
              error: (error, stackTrace) {
                ScaffoldMessenger.of(context).showSnackBar(
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
