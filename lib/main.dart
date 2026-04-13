import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/set_default_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pdf_reader_screen.dart';
import 'screens/pdf_files_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Launcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE91E4C)),
        useMaterial3: true,
      ),
      home: const LauncherHome(),
    );
  }
}

class LauncherHome extends StatefulWidget {
  const LauncherHome({super.key});

  @override
  State<LauncherHome> createState() => _LauncherHomeState();
}

class _LauncherHomeState extends State<LauncherHome> with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.example.pdf_launcher_demo/launcher');
  bool _isDefault = false;
  bool _loading = true;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDefaultLauncher();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDefaultLauncher();
    }
  }

  Future<void> _checkDefaultLauncher() async {
    try {
      final isDefault = await _channel.invokeMethod<bool>('isDefaultLauncher') ?? false;
      if (mounted) {
        setState(() {
          _isDefault = isDefault;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE91E4C),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_isDefault || _skipped) {
      return const LauncherPageView();
    }

    return SetDefaultScreen(
      onComplete: () => setState(() => _skipped = true),
    );
  }
}

/// 3-page swipeable launcher
class LauncherPageView extends StatefulWidget {
  const LauncherPageView({super.key});

  @override
  State<LauncherPageView> createState() => _LauncherPageViewState();
}

class _LauncherPageViewState extends State<LauncherPageView> {
  late final PageController _pageController;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    // Start on the center page (Home)
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: const [
              // Page 0: PDF Tools (swipe left to see)
              PdfReaderScreen(),
              // Page 1: Home Screen (center - default)
              HomeScreen(),
              // Page 2: PDF Files (swipe right to see)
              PdfFilesScreen(),
            ],
          ),
          // Page indicator dots
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
