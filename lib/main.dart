// FocusPal — A Tamagotchi-style screen-time companion.
// Entry point: initialises storage, sets up Provider state,
// and routes to SplashScreen.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/storage_service.dart';
import 'state/chibi_state.dart';
import 'state/focus_state.dart';
import 'state/settings_state.dart';
import 'state/environment_state.dart';
import 'screens/splash_screen.dart';

/// Design-size dimensions used to constrain the app's render area on web.
/// The UI was tuned against ~411 × 870 dp (Pixel-class) — letting it stretch
/// across a desktop browser window broke the Home backdrop's "ground line"
/// alignment with the Chibi position, and shrinking it to a small browser
/// pane clipped fixed-position buttons (e.g. the bottom CTA on Choose-Chibi).
///
/// Strategy on the web `MaterialApp.builder`:
///   • Viewport ≥ design size → AspectRatio frame, scales up proportionally.
///   • Viewport < design size → fixed 411×870 design canvas, vertical scroll
///     enabled so off-screen content is reachable.
const double _phoneDesignWidth = 411;
const double _phoneDesignHeight = 870;
const double _phoneAspectRatio = _phoneDesignWidth / _phoneDesignHeight;

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
        builder: (context, child) {
          if (!kIsWeb || child == null) return child ?? const SizedBox();
          return ColoredBox(
            color: const Color(0xFF0D1535),
            child: LayoutBuilder(
              builder: (ctx, vp) {
                final fitsViewport = vp.maxHeight >= _phoneDesignHeight &&
                    vp.maxWidth >= _phoneDesignWidth;
                if (fitsViewport) {
                  // Big enough — scale a phone-aspect frame to the viewport.
                  return Center(
                    child: AspectRatio(
                      aspectRatio: _phoneAspectRatio,
                      child: ClipRect(child: child),
                    ),
                  );
                }
                // Smaller viewport (short laptop window etc.): render at the
                // exact 411×870 design canvas and let the user scroll if
                // anything extends past the visible area.
                return Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: Center(
                      child: SizedBox(
                        width: _phoneDesignWidth,
                        height: _phoneDesignHeight,
                        child: ClipRect(child: child),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
