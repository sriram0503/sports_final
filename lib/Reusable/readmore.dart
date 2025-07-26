import 'package:flutter/material.dart';

class ReadMore extends StatelessWidget {
  const ReadMore({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Read More Example")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Read More is clicked!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.purple,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          child: const Text("Read More"),
        ),
      ),
    );
  }
}
