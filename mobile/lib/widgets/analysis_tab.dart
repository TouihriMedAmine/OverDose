import 'package:flutter/material.dart';

class AnalysisTab extends StatelessWidget {
  const AnalysisTab({
    super.key,
    required this.data,
    required this.lastQuery,
    required this.onSearchNow,
  });

  final Map<String, dynamic>? data;
  final String? lastQuery;
  final VoidCallback onSearchNow;

  @override
  Widget build(BuildContext context) {
    final products = (data?['products'] as List<dynamic>?) ?? const [];
    final summary = data?['summary']?.toString();
    final scopeNote = data?['search_scope_note']?.toString();
    final searchLinks = (data?['search_links'] as List<dynamic>?) ?? const [];
    final favoriteBrands = (data?['brand_loyalty'] is Map)
        ? ((data!['brand_loyalty'] as Map)['favorite_brands'] as List<dynamic>?) ?? const []
        : const [];

    final lowCount = _countToxicity(products, 'low');
    final moderateCount = _countToxicity(products, 'moderate');
    final highCount = _countToxicity(products, 'high');
    final topPick = _bestPick(products);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Analysis',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          lastQuery == null ? 'Run a search to generate insights.' : 'Insights for "$lastQuery"',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        if (summary != null || scopeNote != null) ...[
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search snapshot', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (summary != null) ...[
                    const SizedBox(height: 8),
                    Text(summary, style: TextStyle(color: Colors.grey.shade800, height: 1.4)),
                  ],
                  if (scopeNote != null) ...[
                    const SizedBox(height: 8),
                    Text('Scope: $scopeNote', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(child: _statCard(context, 'Products', products.length.toString(), Icons.inventory_2_outlined, const Color(0xFF2563EB))),
            const SizedBox(width: 12),
            Expanded(child: _statCard(context, 'Low risk', lowCount.toString(), Icons.eco_rounded, const Color(0xFF2E7D32))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCard(context, 'Moderate', moderateCount.toString(), Icons.warning_amber_rounded, const Color(0xFFE65100))),
            const SizedBox(width: 12),
            Expanded(child: _statCard(context, 'High risk', highCount.toString(), Icons.dangerous_rounded, const Color(0xFFC62828))),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best available pick', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  topPick ?? 'Search a product to see a recommended option here.',
                  style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (favoriteBrands.isNotEmpty) ...[
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your frequent brands', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: favoriteBrands.map((raw) {
                      final brand = raw as Map<String, dynamic>;
                      final name = brand['brand']?.toString() ?? '';
                      final score = brand['score'];
                      return Chip(
                        label: Text('$name (${score is num ? score.toStringAsFixed(2) : score})'),
                        backgroundColor: const Color(0xFFF7F8FA),
                        side: BorderSide(color: Colors.grey.shade300),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (searchLinks.isNotEmpty) ...[
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('External links', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('${searchLinks.length} link(s) were included in the latest search response.', style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: onSearchNow,
          icon: const Icon(Icons.search_rounded),
          label: const Text('Start a new search'),
        ),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  int _countToxicity(List<dynamic> products, String target) {
    return products.where((raw) {
      final item = raw as Map<String, dynamic>;
      final label = item['toxicity_label']?.toString().trim().toLowerCase() ?? '';
      return label == target;
    }).length;
  }

  String? _bestPick(List<dynamic> products) {
    if (products.isEmpty) return null;
    final ranked = products.map((raw) {
      final item = raw as Map<String, dynamic>;
      final title = item['title']?.toString() ?? 'Unknown product';
      final label = item['toxicity_label']?.toString().trim().toLowerCase() ?? '';
      final score = switch (label) {
        'low' => 0,
        'moderate' => 1,
        'high' => 2,
        _ => 1,
      };
      return (title: title, score: score, price: item['price']?.toString() ?? '—');
    }).toList()
      ..sort((a, b) => a.score.compareTo(b.score));

    final pick = ranked.first;
    final safety = switch (pick.score) {
      0 => 'low risk',
      1 => 'moderate risk',
      _ => 'high risk',
    };
    return '${pick.title} is currently the strongest match from the latest results, with $safety and a price of ${pick.price}.';
  }
}
