import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  static const _channel = MethodChannel('com.example.pdf_launcher_demo/launcher');
  List<Map<String, dynamic>> _apps = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      final apps = (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (mounted) {
        setState(() {
          _apps = apps;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _launchApp(String packageName) async {
    try {
      await _channel.invokeMethod('launchApp', {'packageName': packageName});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildClock(),
            const SizedBox(height: 24),
            // App grid
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white54))
                  : _buildAppGrid(),
            ),
            // Dock
            _buildDock(),
          ],
        ),
      ),
    );
  }

  Widget _buildClock() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final hour = now.hour.toString().padLeft(2, '0');
        final minute = now.minute.toString().padLeft(2, '0');
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final dateStr = '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

        return Column(
          children: [
            Text(
              '$hour:$minute',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w200,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _apps.length,
      itemBuilder: (context, index) {
        final app = _apps[index];
        return _buildAppIcon(app);
      },
    );
  }

  Widget _buildAppIcon(Map<String, dynamic> app) {
    final iconBase64 = app['icon'] as String? ?? '';
    final label = app['label'] as String? ?? '';
    final packageName = app['packageName'] as String? ?? '';

    Widget iconWidget;
    if (iconBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(iconBase64);
        iconWidget = Image.memory(
          bytes,
          width: 48,
          height: 48,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );
      } catch (_) {
        iconWidget = const Icon(Icons.android, color: Colors.white, size: 48);
      }
    } else {
      iconWidget = const Icon(Icons.android, color: Colors.white, size: 48);
    }

    return GestureDetector(
      onTap: () => _launchApp(packageName),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: iconWidget,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDock() {
    // Find common dock apps by package name patterns
    final dockApps = _findDockApps();

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: dockApps.map((app) {
          final iconBase64 = app['icon'] as String? ?? '';
          final packageName = app['packageName'] as String? ?? '';

          Widget iconWidget;
          if (iconBase64.isNotEmpty) {
            try {
              final bytes = base64Decode(iconBase64);
              iconWidget = Image.memory(bytes, width: 44, height: 44, fit: BoxFit.contain);
            } catch (_) {
              iconWidget = const Icon(Icons.apps, color: Colors.white, size: 44);
            }
          } else {
            iconWidget = const Icon(Icons.apps, color: Colors.white, size: 44);
          }

          return GestureDetector(
            onTap: () => _launchApp(packageName),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
              clipBehavior: Clip.antiAlias,
              child: iconWidget,
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _findDockApps() {
    // Try to find Phone, Messages, Camera, Browser
    final dockPatterns = [
      ['dialer', 'phone', 'call'],
      ['messaging', 'sms', 'mms', 'messages'],
      ['camera'],
      ['chrome', 'browser', 'webview'],
    ];

    final dockApps = <Map<String, dynamic>>[];
    for (final patterns in dockPatterns) {
      Map<String, dynamic>? found;
      for (final pattern in patterns) {
        found = _apps.cast<Map<String, dynamic>?>().firstWhere(
          (app) =>
              (app?['packageName'] as String?)?.toLowerCase().contains(pattern) == true ||
              (app?['label'] as String?)?.toLowerCase().contains(pattern) == true,
          orElse: () => null,
        );
        if (found != null) break;
      }
      if (found != null) {
        dockApps.add(found);
      }
    }

    // If we couldn't find 4 dock apps, fill with first available apps
    if (dockApps.length < 4 && _apps.isNotEmpty) {
      for (final app in _apps) {
        if (dockApps.length >= 4) break;
        if (!dockApps.contains(app)) {
          dockApps.add(app);
        }
      }
    }

    return dockApps;
  }
}
