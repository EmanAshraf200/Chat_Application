import 'package:flutter/material.dart';
import 'package:scholar_chat/Screens/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login_Page()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
                "assets/images/3d-smartphone-function-icon-illustration-png.webp"),
            Text(
              'Talky',
              style: TextStyle(
                  fontSize: 35, color: Colors.black, fontFamily: 'Pacifico'),
            ),
          ],
        ),
      ),
    );
  }
}
