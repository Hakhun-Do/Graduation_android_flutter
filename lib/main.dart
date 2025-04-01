import 'package:flutter/material.dart';
import 'package:graduation_project/login_page.dart';
import 'package:graduation_project/mainpage.dart';
import 'package:graduation_project/register_page.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:graduation_project/src/home.dart';

InAppLocalhostServer server = InAppLocalhostServer(port: 8080);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await server.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
        debugShowCheckedModeBanner: false, //DEBUG 표시 없애는 코드
        initialRoute: '/',
        routes: {
          '/': (context) => LoginPage(),
          '/r': (context) => RegisterPage(),
          '/m': (context) => MainPage(),
          '/h': (context) => Home()
        }
    );
  }
}
