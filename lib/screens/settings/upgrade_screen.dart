import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/core.dart';
import '../../models/models.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Upgrade Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Choose the best plan for your shop',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: BrandPalette.navy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildPlanCard(
              context,
              name: 'FREE',
              price: '₹0',
              period: 'Forever',
              description: 'Perfect for small shops starting out.',
              features: [
                'Unlimited Bills',
                'Digital Khata (Ledger)',
                'Daily Reports',
                'Cash/Bank Tracking',
              ],
              color: Colors.grey.shade600,
              isCurrent: true,
            ),
            const SizedBox(height: 24),
            _buildPlanCard(
              context,
              name: 'BASIC',
              price: '₹1,999',
              period: '/ year',
              description: 'Grow your business with professional tools.',
              features: [
                'All FREE features',
                'WhatsApp Invoice Alerts',
                'GST Reports (Excel/JSON)',
                'Staff Accounts (Up to 2)',
                'Dynamic QR Code on Bills',
              ],
              color: BrandPalette.teal,
              isPopular: true,
            ),
            const SizedBox(height: 24),
            _buildPlanCard(
              context,
              name: 'PREMIUM',
              price: '₹4,999',
              period: '/ year',
              description: 'Full automation for busy businesses.',
              features: [
                'All BASIC features',
                'AI Google Business Manager',
                'Google Review Automation',
                'Unlimited Staff Accounts',
                'Priority Support',
                'Inventory Low Stock Alerts',
              ],
              color: BrandPalette.sun,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String name,
    required String price,
    required String period,
    required String description,
    required List<String> features,
    required Color color,
    bool isPopular = false,
    bool isCurrent = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular ? color : color.withOpacity(0.1),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: const Text(
                'MOST POPULAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Current Plan',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: BrandPalette.navy,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        period,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                ),
                const Divider(height: 32),
                ...features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: color, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isCurrent ? null : () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: isCurrent ? Colors.grey.shade300 : color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(isCurrent ? 'Active' : 'Upgrade Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
