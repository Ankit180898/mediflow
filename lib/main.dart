import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:mediflow/views/chat_screen.dart';
import 'controllers/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AppController());

    return GetMaterialApp(
      title: 'Medical Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),
      home: ChatScreen(),
    );
  }
}
