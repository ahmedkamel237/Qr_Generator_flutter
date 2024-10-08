import 'package:flutter/material.dart';
import 'package:generate_qr_code_flutter/scanner/qr_code_generate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Generate Qr Page',
      theme: ThemeData(
        scaffoldBackgroundColor:Colors.white,
        appBarTheme:const AppBarTheme(
            color: Colors.white
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GeneratorQrPage(),
    );
  }
}
