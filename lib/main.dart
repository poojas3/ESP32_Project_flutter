import 'package:esp32_project_flutter_app/screens/ml_home.dart';
import 'package:flutter/material.dart';
import 'package:esp32_project_flutter_app/screens/ultrasolic_screen.dart';

void main() => runApp(FlashChat());

class FlashChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: UltraScreen.id,
      routes: {
        UltraScreen.id: (context) => UltraScreen(), //Ultrasonic sensor display
        MLHome.id: (context) =>
            MLHome(), //use machine learning kit to do image labeling
      },
    );
  }
}
