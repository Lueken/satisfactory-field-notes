import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';

const _wikiBase = 'https://satisfactory.wiki.gg/wiki';

class WikiScreen extends StatefulWidget {
  const WikiScreen({super.key});

  @override
  State<WikiScreen> createState() => _WikiScreenState();
}

class _WikiScreenState extends State<WikiScreen> {
  final _controller = TextEditingController();
  late final WebViewController _webView;
  bool _loading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _webView = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) {
          setState(() => _loading = false);
          // Hide wiki nav, ads, footer to focus on content
          _webView.runJavaScript('''
            document.querySelector('.global-navigation')?.remove();
            document.querySelector('.page-footer')?.remove();
            document.querySelector('.fandom-sticky-header')?.remove();
            document.querySelectorAll('.ad-slot, .top-ads-container, [id*="ads"], [class*="ad-"]').forEach(e => e.remove());
            document.querySelector('.page-header__actions')?.remove();
            document.querySelector('.page-side-tools')?.remove();
          ''');
        },
      ));
  }

  void _search() {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    final url = '$_wikiBase/${Uri.encodeComponent(q.replaceAll(' ', '_'))}';
    _webView.loadRequest(Uri.parse(url));
    setState(() => _hasSearched = true);
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _search(),
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'item, building, or recipe...',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _search,
                  style: FilledButton.styleFrom(
                    backgroundColor: ficsitAmber,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Go',
                      style: TextStyle(fontFamily: 'ShareTechMono')),
                ),
              ),
            ],
          ),
        ),

        if (_loading)
          const LinearProgressIndicator(color: ficsitAmber, minHeight: 2),

        // WebView or empty state
        Expanded(
          child: _hasSearched
              ? WebViewWidget(controller: _webView)
              : _buildEmpty(),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    final examples = [
      'Reinforced Iron Plate',
      'Coal Generator',
      'Assembler',
      'Fuel Generator',
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text('Look up any item, building, or recipe.',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 16),
          for (final ex in examples)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _controller.text = ex;
                    _search();
                  },
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    side: const BorderSide(
                        color: Color(0xFFE7E5E4), width: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(ex,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280))),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
