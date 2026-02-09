import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons_flutter.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfReaderView extends StatefulWidget {
  final String filePath;
  final bool isAsset;
  final String? title;
  final Color? primaryColor;
  final bool showAppBar;
  final bool showBottomBar;
  final VoidCallback? onBack;

  const PdfReaderView({
    super.key,
    required this.filePath,
    this.isAsset = false,
    this.title,
    this.primaryColor,
    this.showAppBar = true,
    this.showBottomBar = true,
    this.onBack,
  });

  @override
  State<PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends State<PdfReaderView> {
  final countController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isDark = false;
  double _zoomLevel = 1.0;

  @override
  void dispose() {
    countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = widget.primaryColor ?? theme.primaryColor;
    final backgroundColor = _isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7);
    final surfaceColor = _isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Theme(
      data: theme.copyWith(
        textTheme: GoogleFonts.interTextTheme(theme.textTheme),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: widget.showAppBar
            ? AppBar(
                backgroundColor: surfaceColor,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(LucideIcons.chevronLeft, color: theme.iconTheme.color),
                  onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                ),
                title: Text(
                  widget.title ?? widget.filePath.split('/').last,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _isDark ? Colors.white : Colors.black87,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(_isDark ? LucideIcons.sun : LucideIcons.moon, size: 20),
                    onPressed: () => setState(() => _isDark = !_isDark),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.share2, size: 20),
                    onPressed: () async {
                      String path = widget.filePath;
                      if (widget.isAsset) {
                        // Copy asset to temp file for sharing
                        final byteData = await DefaultAssetBundle.of(context).load(widget.filePath);
                        final tempDir = await getTemporaryDirectory();
                        final tempFile = File('${tempDir.path}/shared_doc.pdf');
                        await tempFile.writeAsBytes(byteData.buffer.asUint8List());
                        path = tempFile.path;
                      }
                      await Share.shareXFiles([XFile(path)]);
                    },
                  ),
                ],
              )
            : null,
        body: Stack(
          children: [
            widget.isAsset
                ? PdfViewer.asset(
                    widget.filePath,
                    controller: countController,
                    params: _buildParams(backgroundColor),
                  )
                : PdfViewer.file(
                    widget.filePath,
                    controller: countController,
                    params: _buildParams(backgroundColor),
                  ),
            if (widget.showBottomBar)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: surfaceColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: LucideIcons.minus,
                          onPressed: () => countController.zoomOut(),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        Text(
                          'Page $_currentPage of $_totalPages',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        _buildActionButton(
                          icon: LucideIcons.plus,
                          onPressed: () => countController.zoomIn(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PdfViewerParams _buildParams(Color backgroundColor) {
    return PdfViewerParams(
      backgroundColor: backgroundColor,
      onDocumentChanged: (document) {
        setState(() {
          _totalPages = document?.pages.length ?? 0;
        });
      },
      onPageChanged: (pageNumber) {
        setState(() {
          _currentPage = pageNumber ?? 1;
        });
      },
      enableTextSelection: true,
      maxScale: 5.0,
      onLinkTap: (url) => launchUrl(Uri.parse(url!)),
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 18, color: _isDark ? Colors.white70 : Colors.black54),
        ),
      ),
    );
  }
}
