import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PdfFilesScreen extends StatefulWidget {
  const PdfFilesScreen({super.key});

  @override
  State<PdfFilesScreen> createState() => _PdfFilesScreenState();
}

class _PdfFilesScreenState extends State<PdfFilesScreen> with AutomaticKeepAliveClientMixin {
  static const _channel = MethodChannel('com.example.pdf_launcher_demo/launcher');
  List<Map<String, dynamic>> _files = [];
  List<Map<String, dynamic>> _filteredFiles = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
    _searchController.addListener(_filterFiles);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    try {
      final result = await _channel.invokeMethod('getPdfFiles');
      final files = (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (mounted) {
        setState(() {
          _files = files;
          _filteredFiles = files;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterFiles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFiles = _files;
      } else {
        _filteredFiles = _files
            .where((f) => (f['name'] as String).toLowerCase().contains(query))
            .toList();
      }
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: Colors.grey.shade50,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'PDF Files',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search PDF files...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            // File count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                '${_filteredFiles.length} files found',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
            // File list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredFiles.isEmpty
                      ? _buildEmptyState()
                      : _buildFileList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No PDF files found'
                : 'No matching files',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          if (_searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Grant storage permission to scan files',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredFiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final file = _filteredFiles[index];
        return _buildFileItem(file);
      },
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file) {
    final name = file['name'] as String? ?? 'Unknown';
    final size = file['size'] as int? ?? 0;
    final lastModified = file['lastModified'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // PDF icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf, color: Color(0xFFE91E4C), size: 24),
          ),
          const SizedBox(width: 12),
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(lastModified)}  •  ${_formatFileSize(size)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // More button
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
            onPressed: () {},
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
