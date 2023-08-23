import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:scholar_chat/Screens/chat_page.dart';
import 'package:scholar_chat/Screens/creategroupchatScreen.dart';
import 'package:scholar_chat/Screens/home_page.dart';
import 'package:scholar_chat/Screens/home_page_group.dart';
import 'package:scholar_chat/Screens/login_page.dart';
import 'package:scholar_chat/Screens/navigation_screen.dart';
import 'package:scholar_chat/Screens/regestration_page.dart';
import 'package:scholar_chat/Screens/splash_screen.dart';
import 'package:scholar_chat/firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        'signup': (context) => Regestration_Page(),
        'signin': (context) => Login_Page(),
        'chat': (context) => Chat_Page(),
        'home': (context) => HomePage(),
        'groupchatscreen': (context) => CreateGroupChatScreen(),
        'ChatApp': (context) => BottomNavScreen(),
        'HomePageGroup': (context) => HomePageGroup(),
      },
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
