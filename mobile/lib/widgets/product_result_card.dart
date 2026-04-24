import 'package:flutter/material.dart';

/// Product row matching the mobile results mock: image left, title + price, toxicity strip, brand.
class ProductResultCard extends StatelessWidget {
  const ProductResultCard({
    super.key,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.brand,
    required this.toxicityLabel,
    this.onTap,
  });

  final String title;
  final String price;
  final String? imageUrl;
  final String brand;
  final String? toxicityLabel;
  final VoidCallback? onTap;

  static ({String text, Color color, IconData icon}) _toxicityStyle(String? raw) {
    final l = (raw ?? '').toLowerCase().trim();
    if (l == 'low') {
      return (text: 'LOW', color: const Color(0xFF2E7D32), icon: Icons.eco_rounded);
    }
    if (l == 'high') {
      return (text: 'HIGH', color: const Color(0xFFC62828), icon: Icons.dangerous_rounded);
    }
    return (text: 'MODERATE', color: const Color(0xFFE65100), icon: Icons.warning_amber_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final tox = _toxicityStyle(toxicityLabel);

    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderThumb(),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            width: 80,
                            height: 80,
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : _placeholderThumb(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              height: 1.25,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          price,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(tox.icon, size: 18, color: tox.color),
                        const SizedBox(width: 6),
                        Text(
                          'Toxicity: ${tox.text}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            letterSpacing: 0.3,
                            color: tox.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 8),
                    Text(
                      brand.isEmpty ? '—' : brand,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 80,
      height: 80,
      color: const Color(0xFFEEEEEE),
      child: Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade400, size: 32),
    );
  }
}
