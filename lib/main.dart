import 'package:esp32_project_flutter_app/screens/ml_home.dart';
import 'package:esp32_project_flutter_app/screens/ml_label.dart';
import 'package:flutter/material.dart';
import 'package:esp32_project_flutter_app/screens/welcome_screen.dart';
import 'package:esp32_project_flutter_app/screens/login_screen.dart';
import 'package:esp32_project_flutter_app/screens/registration_screen.dart';
import 'package:esp32_project_flutter_app/screens/ultrasolic_screen.dart';

void main() => runApp(FlashChat());

class FlashChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: UltraScreen.id,
      routes: {
        WelcomeScreen.id: (context) => WelcomeScreen(), //'/'
        LoginScreen.id: (context) => LoginScreen(), //'/login'
        RegistrationScreen.id: (context) =>
            RegistrationScreen(), //'registration'
        UltraScreen.id: (context) => UltraScreen(), //
        MLLabel.id: (context) => MLLabel(),
        MLHome.id: (context) => MLHome(),
        //MLDetail.id: (context) => MLDetail(),
      },
    );
  }
}
