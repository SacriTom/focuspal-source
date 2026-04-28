// FocusPal — A Tamagotchi-style screen-time companion.
// Entry point: initialises storage, sets up Provider state,
// and routes to SplashScreen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/storage_service.dart';
import 'state/chibi_state.dart';
import 'state/focus_state.dart';
import 'state/settings_state.dart';
import 'state/environment_state.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialise local storage (SharedPreferences + SQLite)
  await StorageService.init();

  runApp(const FocusPalApp());
}

class FocusPalApp extends StatelessWidget {
  const FocusPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final settings = SettingsState();
          settings.loadFromStorage();
          return settings;
        }),
        ChangeNotifierProvider(create: (_) => EnvironmentState()),
        ChangeNotifierProvider(create: (ctx) {
          final chibiState = ChibiState();
          // Wire up settings reference for mood thresholds
          final settings = ctx.read<SettingsState>();
          chibiState.setSettings(settings);
          return chibiState;
        }),
        ChangeNotifierProvider(create: (_) => FocusState()),
      ],
      child: MaterialApp(
        title: 'FocusPal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
