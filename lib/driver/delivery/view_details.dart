import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class DeliveryViewDetailsPage extends StatelessWidget {
  const DeliveryViewDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color kText = Color(0xFF111111);
    const Color kMuted = Color(0xFF606060);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Symbols.arrow_back,
            color: kText,
            fill: 1,
            weight: 300,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(
                  child: _TopMeta(
                    title: '21 Nov 2025',
                    subtitle: 'Delivered',
                    titleFontSize: 26,
                    subtitleFontSize: 13,
                  ),
                ),
                Expanded(
                  child: _TopMeta(
                    title: '12:30 PM',
                    subtitle: 'Time',
                    titleFontSize: 26,
                    subtitleFontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _TransactionBadge(),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _TopMeta(
                    title: '30 km',
                    subtitle: 'Distance',
                    titleFontSize: 18,
                    subtitleFontSize: 12,
                  ),
                ),
                Expanded(
                  child: _TopMeta(
                    title: '20 min',
                    subtitle: 'Travel time',
                    titleFontSize: 18,
                    subtitleFontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: const Color(0xFFD9D9D9),
            ),
            const SizedBox(height: 10),
            const Text(
              'Customer',
              style: TextStyle(
                color: kMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Alme Fe Pepania',
              style: TextStyle(
                color: kText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Delivered address:',
              style: TextStyle(
                color: kMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ACLC College of Mandaue, Briones St., Maguikay,\nMandaue City, Cebu',
              style: TextStyle(
                color: kText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  _InfoRow(label: 'Quantity:', value: '1'),
                  _InfoRow(label: 'Gallon:', value: '2 Gal'),
                  _InfoRow(label: 'Flavor:', value: 'Strawberry'),
                  _InfoRow(label: 'Flavor Type:', value: 'Special Flavor'),
                  _InfoRow(label: 'Cost:', value: '₱1,900'),
                  _InfoRow(label: 'Amount:', value: '₱1,900'),
                  _InfoRow(label: 'Customer Number:', value: '09123456789'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Proof of Delivery:',
              style: TextStyle(
                color: kText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  'https://images.unsplash.com/photo-1521791136064-7986c2920216?auto=format&fit=crop&w=1200&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE1E1E1),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_outlined,
                      color: Color(0xFF8B8B8B),
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopMeta extends StatelessWidget {
  const _TopMeta({
    required this.title,
    required this.subtitle,
    this.titleFontSize = 26,
    this.subtitleFontSize = 13,
  });

  final String title;
  final String subtitle;
  final double titleFontSize;
  final double subtitleFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: titleFontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: Color(0xFF606060),
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TransactionBadge extends StatelessWidget {
  const _TransactionBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEFEFEF),
            ),
            child: const Icon(
              Symbols.deployed_code,
              color: Color(0xFF2A2A2A),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#32456124',
                style: TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Transaction ID',
                style: TextStyle(
                  color: Color(0xFF606060),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF606060),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
