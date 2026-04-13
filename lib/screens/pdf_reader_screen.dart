import 'package:flutter/material.dart';

class PdfReaderScreen extends StatelessWidget {
  const PdfReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE91E4C),
        foregroundColor: Colors.white,
        title: const Text(
          'PDF Reader',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.star_border),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Permission banner
            _buildPermissionBanner(),
            const SizedBox(height: 8),
            // Feature grid
            _buildFeatureGrid(),
            const SizedBox(height: 16),
            // Ad placeholder
            _buildAdPlaceholder(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Folder icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.folder, color: Color(0xFFE91E4C), size: 48),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock, color: Color(0xFFE91E4C), size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'In order to read and edit all your files, please allow to access all your files on your device.',
                  style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E4C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                    ),
                    child: const Text('Allow', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      _FeatureItem('Merge PDF', Icons.add_box_outlined, const Color(0xFFFFEBEE), const Color(0xFFE91E4C)),
      _FeatureItem('Split PDF', Icons.vertical_split, const Color(0xFFE8F5E9), const Color(0xFF4CAF50)),
      _FeatureItem('Image to PDF', Icons.picture_as_pdf, const Color(0xFFFFF8E1), const Color(0xFFFFA000)),
      _FeatureItem('Scan PDF', Icons.camera_alt_outlined, const Color(0xFFE8F5E9), const Color(0xFF66BB6A)),
      _FeatureItem('Lock PDF', Icons.lock_outline, const Color(0xFFF3E5F5), const Color(0xFFAB47BC)),
      _FeatureItem('UnLock PDF', Icons.lock_open, const Color(0xFFFFF3E0), const Color(0xFFFF9800)),
      _FeatureItem('Edit PDF', Icons.edit_note, const Color(0xFFE3F2FD), const Color(0xFF42A5F5)),
      _FeatureItem('Favorite', Icons.favorite_border, const Color(0xFFE8F5E9), const Color(0xFF5C6BC0)),
      _FeatureItem('All File', Icons.folder_copy_outlined, const Color(0xFFE0F7FA), const Color(0xFF26A69A)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          return _buildFeatureCard(feature);
        },
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: feature.bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(feature.icon, color: feature.iconColor, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            feature.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AD',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ad Placeholder',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  _FeatureItem(this.label, this.icon, this.bgColor, this.iconColor);
}
