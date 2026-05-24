import 'package:flutter/material.dart';

class OcrLoadingPage extends StatelessWidget {
  const OcrLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              "Sto leggendo lo scontrino...",
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}