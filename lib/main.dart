import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:device_preview/device_preview.dart';
import 'package:garifordriver/infoHandler/app_info.dart';
import 'package:garifordriver/screens/Home/homescreen.dart';
import 'package:garifordriver/screens/Home/precisepickuplocation.dart';
import 'package:garifordriver/screens/Home/searchplaces.dart';
import 'package:garifordriver/screens/forgot_password.dart';
import 'package:garifordriver/screens/login_screen.dart';
import 'package:garifordriver/screens/main_page.dart';
import 'package:garifordriver/screens/register_screen.dart';
import 'package:garifordriver/splashscreen/splash_screen.dart';
import 'package:provider/provider.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
  print("Firebase initializing...");
  await Firebase.initializeApp();
  print("Firebase initialized successfully.");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppInfo(),
      child: MaterialApp(
        useInheritedMediaQuery: true,
        debugShowCheckedModeBanner: false,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        title: 'Flutter Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const SplashScreen(),
        routes: {
          '/searchplaces': (context) => const SearchPlacesScreen(),
          '/mainscreen': (context) => const MainPage(),
          '/forgotpassword': (context) => const ForgotPasswordScreen(),
          '/loginscreen': (context) => const LoginScreen(),
          '/registerscreen': (context) => const RegisterScreen(),
          '/homescreen': (context) => const HomeScreen(),
          '/precisepickuplocation': (context) => const PrecisePickUpScreen(),
        },
      ),
    );
  }
}
