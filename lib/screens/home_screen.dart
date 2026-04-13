import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  static const _channel = MethodChannel('com.example.pdf_launcher_demo/launcher');
  List<Map<String, dynamic>> _allApps = [];
  List<Map<String, dynamic>> _dockApps = [];
  List<Map<String, dynamic>> _homeApps = [];
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
      final apps = (result as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) {
        final dock = _findDockApps(apps);
        final dockPkgs = dock.map((a) => a['packageName']).toSet();
        setState(() {
          _allApps = apps;
          _dockApps = dock;
          _homeApps = apps.where((a) => !dockPkgs.contains(a['packageName'])).take(8).toList();
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

  void _showAppDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppDrawer(
        apps: _allApps,
        onLaunch: _launchApp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Swipe up to open app drawer
        if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
          _showAppDrawer();
        }
      },
      // Transparent background - system wallpaper shows through natively
      child: Container(
        color: Colors.transparent,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),

              // PDF Widget bar at top (like One PDF Home)
              _buildPdfWidget(),

              // Spacer - wallpaper visible area (real device wallpaper behind)
              const Spacer(),

              // Home apps (2 rows of 4)
              if (!_loading && _homeApps.isNotEmpty) _buildHomeApps(),
              const SizedBox(height: 16),

              // Swipe up hint
              _buildSwipeUpHint(),
              const SizedBox(height: 6),

              // Dock at bottom
              if (!_loading) _buildDock(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Date/time + menu
          Row(
            children: [
              const _DateTimeWidget(),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Icon(Icons.more_horiz,
                    color: Colors.white.withValues(alpha: 0.7), size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _toolBtn('Read File', Icons.description, const Color(0xFFE91E4C)),
              _toolBtn('Recent', Icons.access_time_filled, const Color(0xFFFFC107)),
              _toolBtn('Favorite', Icons.favorite, const Color(0xFF00BCD4)),
              _toolBtn('Options', Icons.grid_view, const Color(0xFF4CAF50)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolBtn(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 5),
          Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 11,
              shadows: [Shadow(blurRadius: 3, color: Colors.black87)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeApps() {
    final rows = <List<Map<String, dynamic>>>[];
    for (var i = 0; i < _homeApps.length; i += 4) {
      final end = (i + 4 > _homeApps.length) ? _homeApps.length : i + 4;
      rows.add(_homeApps.sublist(i, end));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: row.length == 4
                  ? MainAxisAlignment.spaceEvenly
                  : MainAxisAlignment.start,
              children: row.map((app) {
                return SizedBox(
                  width: 76,
                  child: GestureDetector(
                    onTap: () => _launchApp(app['packageName'] as String? ?? ''),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 58, height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _iconImg(app['icon'] as String? ?? '', 58),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          app['label'] as String? ?? '',
                          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.white,
                            shadows: [Shadow(blurRadius: 8, color: Colors.black87), Shadow(blurRadius: 3, color: Colors.black54)]),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSwipeUpHint() {
    return Column(
      children: [
        Icon(Icons.keyboard_arrow_up,
            color: Colors.white.withValues(alpha: 0.5), size: 28),
        Text('Swipe up for apps',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDock() {
    if (_dockApps.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _dockApps.map((app) {
          return GestureDetector(
            onTap: () => _launchApp(app['packageName'] as String? ?? ''),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
              clipBehavior: Clip.antiAlias,
              child: _iconImg(app['icon'] as String? ?? '', 54),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _iconImg(String base64, double size) {
    if (base64.isNotEmpty) {
      try {
        return Image.memory(base64Decode(base64),
            width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true);
      } catch (_) {}
    }
    return Container(
      color: Colors.grey.shade700,
      child: Icon(Icons.android, color: Colors.white, size: size * 0.6),
    );
  }

  List<Map<String, dynamic>> _findDockApps(List<Map<String, dynamic>> apps) {
    final patterns = [
      ['dialer', 'phone', 'call', 'incallui'],
      ['messaging', 'sms', 'mms', 'messages'],
      ['chrome', 'browser'],
      ['camera'],
    ];
    final result = <Map<String, dynamic>>[];
    for (final group in patterns) {
      for (final p in group) {
        final found = apps.cast<Map<String, dynamic>?>().firstWhere(
          (a) => (a?['packageName'] as String?)?.toLowerCase().contains(p) == true,
          orElse: () => null,
        );
        if (found != null) { result.add(found); break; }
      }
    }
    while (result.length < 4 && apps.length > result.length) {
      for (final a in apps) {
        if (!result.contains(a)) { result.add(a); break; }
      }
    }
    return result;
  }
}

// ============================================================
// App Drawer - slides up from bottom, shows all installed apps
// ============================================================
class _AppDrawer extends StatelessWidget {
  final List<Map<String, dynamic>> apps;
  final Function(String) onLaunch;

  const _AppDrawer({required this.apps, required this.onLaunch});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 14),
                      Icon(Icons.search, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text('Search apps', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // App grid
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    final icon = app['icon'] as String? ?? '';
                    final label = app['label'] as String? ?? '';
                    final pkg = app['packageName'] as String? ?? '';

                    Widget iconWidget;
                    if (icon.isNotEmpty) {
                      try {
                        iconWidget = Image.memory(base64Decode(icon),
                            width: 52, height: 52, fit: BoxFit.cover, gaplessPlayback: true);
                      } catch (_) {
                        iconWidget = const Icon(Icons.android, color: Colors.white, size: 40);
                      }
                    } else {
                      iconWidget = const Icon(Icons.android, color: Colors.white, size: 40);
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onLaunch(pkg);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14)),
                            clipBehavior: Clip.antiAlias,
                            child: iconWidget,
                          ),
                          const SizedBox(height: 5),
                          Text(label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateTimeWidget extends StatelessWidget {
  const _DateTimeWidget();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 30)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final s = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')} '
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        return Text(s,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        );
      },
    );
  }
}
