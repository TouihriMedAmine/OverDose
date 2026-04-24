import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/search_service.dart';
import '../widgets/editable_profile_tab.dart';
import '../widgets/product_result_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.auth,
    required this.onLogout,
    required this.onProfileSaved,
  });

  final UserModel user;
  final AuthService auth;
  final VoidCallback onLogout;
  final Future<void> Function() onProfileSaved;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _qCtrl = TextEditingController();
  final _search = SearchService();
  String _category = 'auto';
  bool _fallback = true;
  bool _loyalty = true;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;
  int _navIndex = 0;

  static const _bg = Color(0xFFF2F2F7);

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _qCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _error = null;
      _loading = true;
      _data = null;
    });
    try {
      final json = await _search.search(
        q: q,
        category: _category,
        fallback: _fallback,
        useLoyalty: _loyalty,
      );
      setState(() => _data = json);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUrl(String? url, String title) async {
    if (url == null || url.isEmpty || url == '#') return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await _search.recordClick(title);
    if (!mounted) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openFiltersSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Search options', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'auto', child: Text('Auto (from keywords)')),
                      DropdownMenuItem(value: 'all', child: Text('All stores')),
                      DropdownMenuItem(value: 'food', child: Text('Food & grocery')),
                      DropdownMenuItem(value: 'cosmetics', child: Text('Cosmetics & beauty')),
                      DropdownMenuItem(value: 'pharmacy', child: Text('Pharmacy & health')),
                      DropdownMenuItem(value: 'electronics', child: Text('Electronics & appliances')),
                    ],
                    onChanged: (v) => setModal(() => _category = v ?? 'auto'),
                  ),
                  SwitchListTile(
                    title: const Text('Web search fallback'),
                    value: _fallback,
                    onChanged: (v) => setModal(() => _fallback = v),
                  ),
                  SwitchListTile(
                    title: const Text('Boost brands I click often'),
                    value: _loyalty,
                    onChanged: (v) => setModal(() => _loyalty = v),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _brandLine(Map<String, dynamic> p) {
    final g = p['brand_guess']?.toString().trim();
    if (g != null && g.isNotEmpty) return g;
    return p['store_name']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: [
            _buildDiscoverTab(),
            _buildPlaceholderTab('Scan', 'Product scanning coming soon.'),
            _buildPlaceholderTab('Saved', 'Your saved items will appear here.'),
            EditableProfileTab(
              key: ValueKey<Object>('${u.id}-${u.email}-${u.diseases}'),
              user: u,
              auth: widget.auth,
              onProfileSaved: widget.onProfileSaved,
              onLogout: widget.onLogout,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8F5E9),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    final products = (_data?['products'] as List<dynamic>?) ?? [];
    final searchLinks = (_data?['search_links'] as List<dynamic>?) ?? [];
    final favBrands = (_data?['brand_loyalty'] is Map)
        ? ((_data!['brand_loyalty'] as Map)['favorite_brands'] as List<dynamic>?) ?? []
        : <dynamic>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _qCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search products…',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _runSearch(),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Filters',
                onPressed: _openFiltersSheet,
                icon: Icon(Icons.tune_rounded, color: Colors.grey.shade800),
              ),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (favBrands.isNotEmpty) ...[
                Text('Your top brands', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: favBrands.map((b) {
                    final m = b as Map<String, dynamic>;
                    final name = m['brand']?.toString() ?? '';
                    final score = m['score'];
                    return Chip(
                      label: Text('$name (${score is num ? score.toStringAsFixed(2) : score})'),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              if (_data != null) ...[
                if (_data!['summary'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _data!['summary'].toString(),
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ),
                if (_data!['search_scope_note'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Scope: ${_data!['search_scope_note']}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
              ],
              ...products.map((raw) {
                final p = raw as Map<String, dynamic>;
                final title = p['title']?.toString() ?? '';
                final url = p['url']?.toString();
                final price = p['price']?.toString() ?? '—';
                final tox = p['toxicity_label']?.toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProductResultCard(
                    title: title,
                    price: price,
                    imageUrl: p['image_url']?.toString(),
                    brand: _brandLine(p),
                    toxicityLabel: tox,
                    onTap: () => _openUrl(url, title),
                  ),
                );
              }),
              if (_data != null && products.isEmpty && !_loading)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No products in this response. Try another query.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              if (searchLinks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('More links (Tunisia)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                const SizedBox(height: 8),
                ...searchLinks.map((raw) {
                  final l = raw as Map<String, dynamic>;
                  final t = l['title']?.toString() ?? l['url']?.toString() ?? '';
                  final url = l['url']?.toString();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t, style: const TextStyle(color: Color(0xFF1565C0), fontSize: 14)),
                    onTap: () => _openUrl(url, t),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderTab(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

}
