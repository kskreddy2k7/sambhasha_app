import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConfigErrorScreen extends StatelessWidget {
  const ConfigErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF0F172A)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 80, color: Colors.orangeAccent),
            const SizedBox(height: 24),
            const Text(
              "Configuration Required",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Firebase is not yet configured for this platform. To fix the white screen loop, please run the following command in your terminal:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "flutterfire configure",
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.grey),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: "flutterfire configure"));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Command copied to clipboard!")),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              "After running the command, I will be able to fully initialize your real-time chat infrastructure.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 64),
            ElevatedButton(
              onPressed: () {
                // In a real app, we might restart or re-check
              },
              child: const Text("I've finished configuration"),
            ),
          ],
        ),
      ),
    );
  }
}

