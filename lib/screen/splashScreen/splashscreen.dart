import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/driver_logo.png',
              width: 130,
              height: 130,
            ),
            const SizedBox(height: 10),
            const Text(
              'Welcome to Gari for Driver',
              style: TextStyle(
                fontSize: 25,
                color: Colors.black54,

                fontStyle: FontStyle.italic,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: Divider(),
            ),
          ],
        ),
      ),
    );
  }
}
