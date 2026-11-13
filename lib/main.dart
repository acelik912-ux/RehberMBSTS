import 'package:flutter/material.dart';

import 'app_state.dart';
import 'content.dart';
import 'screens/home_screen.dart';
import 'widgets/player_bar.dart';
import 'widgets/read_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  content = await Content.load();
  await store.load();
  store.prune(entryExists);
  runApp(const RehberApp());
}

class RehberApp extends StatelessWidget {
  const RehberApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0F5C63);
    return MaterialApp(
      title: 'Rehber MBSTS',
      debugShowCheckedModeBanner: false,
      navigatorKey: navKey,
      navigatorObservers: [readRegistry],
      builder: (context, child) => AppFrame(player: const PlayerBar(), child: child ?? const SizedBox()),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F5F0),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
