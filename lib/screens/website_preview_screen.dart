import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/core.dart';
import '../models/models.dart';

class WebsitePreviewScreen extends StatelessWidget {
  const WebsitePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final businessName = settings.businessName.isEmpty ? 'My Business' : settings.businessName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Digital Catalog'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: BrandPalette.teal),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing catalog link...')));
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: BrandPalette.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.language, size: 80, color: BrandPalette.teal),
              ),
              const SizedBox(height: 32),
              Text(
                'Your Digital Store is Ready!',
                style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: BrandPalette.navy),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Share your catalog link with customers on WhatsApp so they can browse your products and place orders directly.',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'mydukan.link/${businessName.toLowerCase().replaceAll(' ', '')}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: BrandPalette.navy),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
                      },
                      child: const Text('COPY', style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening WhatsApp...')));
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share on WhatsApp'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
