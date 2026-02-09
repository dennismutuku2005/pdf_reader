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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isDark = false;
  bool _isSearching = false;
  PdfTextSearchResult? _searchResult;
  bool _showUi = true;

  @override
  void dispose() {
    countController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResult = null;
      });
      return;
    }
    
    final result = await countController.searchText(query);
    setState(() {
      _searchResult = result;
    });
  }

  void _showOutlines() async {
    final document = countController.document;
    if (document == null) return;
    
    final outlines = await document.loadOutline();
    if (!mounted) return;

    if (outlines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No outlines found in this document')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: _isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, marginBottom: 16),
              child: Text(
                'Table of Contents',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: outlines.length,
                itemBuilder: (context, index) {
                  final outline = outlines[index];
                  return ListTile(
                    title: Text(
                      outline.title,
                      style: GoogleFonts.inter(
                        color: _isDark ? Colors.white70 : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    onTap: () {
                      if (outline.dest != null) {
                        countController.goToDest(outline.dest!);
                      }
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      countController.goToPage(pageNumber: page);
    }
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
        appBar: widget.showAppBar && _showUi
            ? AppBar(
                backgroundColor: surfaceColor,
                elevation: 0,
                leading: _isSearching
                    ? IconButton(
                        icon: const Icon(LucideIcons.arrowLeft),
                        onPressed: () {
                          setState(() {
                            _isSearching = false;
                            _searchController.clear();
                            _searchResult = null;
                          });
                        },
                      )
                    : IconButton(
                        icon: Icon(LucideIcons.chevronLeft, color: theme.iconTheme.color),
                        onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                      ),
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search in document...',
                          border: InputBorder.none,
                          hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                        ),
                        style: GoogleFonts.inter(
                          color: _isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                        onSubmitted: _handleSearch,
                      )
                    : GestureDetector(
                        onTap: () {
                          // Allow clicking title to go to first page
                          _goToPage(1);
                        },
                        child: Text(
                          widget.title ?? widget.filePath.split('/').last,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                actions: [
                  if (!_isSearching) ...[
                    IconButton(
                      icon: const Icon(LucideIcons.search, size: 20),
                      onPressed: () => setState(() => _isSearching = true),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.list, size: 20),
                      onPressed: _showOutlines,
                    ),
                    IconButton(
                      icon: Icon(_isDark ? LucideIcons.sun : LucideIcons.moon, size: 20),
                      onPressed: () => setState(() => _isDark = !_isDark),
                    ),
                  ] else if (_searchResult != null) ...[
                    Center(
                      child: Text(
                        '${_searchResult!.currentIndex + 1}/${_searchResult!.allMatches.length}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.chevronUp, size: 20),
                      onPressed: () => setState(() {
                        _searchResult!.goToPrev();
                      }),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.chevronDown, size: 20),
                      onPressed: () => setState(() {
                        _searchResult!.goToNext();
                      }),
                    ),
                  ],
                  IconButton(
                    icon: const Icon(LucideIcons.share2, size: 20),
                    onPressed: () async {
                      String path = widget.filePath;
                      if (widget.isAsset) {
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
            GestureDetector(
              onTap: () => setState(() => _showUi = !_showUi),
              child: widget.isAsset
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
            ),
            if (widget.showBottomBar && _showUi)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
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
                        GestureDetector(
                          onTap: () {
                            // Show page selection dialog
                            _showPageSelectionDialog();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_currentPage / $_totalPages',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: primary,
                              ),
                            ),
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

  void _showPageSelectionDialog() {
    final TextEditingController controller = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Go to Page',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: _isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: '1 - $_totalPages',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter a number between 1 and $_totalPages',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null) {
                _goToPage(page);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go'),
          ),
        ],
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

