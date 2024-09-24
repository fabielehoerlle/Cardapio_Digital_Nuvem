import 'package:dreamsdocesev/menu_categories.dart';
import 'package:flutter/material.dart';
import 'app_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';
import 'package:logging/logging.dart'; // Added logging
import 'pedidos.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  Logger.root.level = Level.ALL; // Set root level to ALL
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  await Supabase.initialize(
    url: Constants.SUPABASE_URL,
    anonKey: Constants.SUPABASE_ANON_KEY,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, String> userData = {"phone": ""};
  String view = 'home'; // home, pedidos

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Column(
          children: [
            AppHeader(onChangeView: (p0) => setState(() => view = p0)),
            view == 'home'
                ? MenuCategories(setView: (p0) => setState(() => view = p0))
                : const Pedidos(),
          ],
        ),
      ),
    );
  }
}
