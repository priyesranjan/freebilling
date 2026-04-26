import 'package:flutter/material.dart';
import '../core/core.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MarketingHubScreen extends StatefulWidget {
  const MarketingHubScreen({super.key});

  @override
  State<MarketingHubScreen> createState() => _MarketingHubScreenState();
}

class _MarketingHubScreenState extends State<MarketingHubScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: BrandPalette.pageBase,
        appBar: AppBar(
          title: const Text('AI Marketing Hub'),
          backgroundColor: BrandPalette.pageBase,
          elevation: 0,
          bottom: const TabBar(
            labelColor: BrandPalette.navy,
            unselectedLabelColor: Colors.grey,
            indicatorColor: BrandPalette.teal,
            tabs: [
              Tab(icon: Icon(Icons.star), text: 'Google Reviews AI'),
              Tab(icon: Icon(Icons.image), text: 'Promo Image AI'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ReviewAIView(),
            PromoImageAIView(),
          ],
        ),
      ),
    );
  }
}

class ReviewAIView extends StatefulWidget {
  const ReviewAIView({super.key});

  @override
  State<ReviewAIView> createState() => _ReviewAIViewState();
}

class _ReviewAIViewState extends State<ReviewAIView> {
  final _reviewCtrl = TextEditingController();
  bool _isGenerating = false;
  List<String> _suggestions = [];

  void _generateReplies() async {
    if (_reviewCtrl.text.isEmpty) return;
    
    setState(() {
      _isGenerating = true;
      _suggestions = [];
    });

    // Mock API Delay
    await Future.delayed(const Duration(seconds: 2));

    final isPositive = _reviewCtrl.text.toLowerCase().contains('good') || _reviewCtrl.text.toLowerCase().contains('great');
    
    setState(() {
      _isGenerating = false;
      if (isPositive) {
        _suggestions = [
          "Thank you so much for your kind words! We're thrilled to hear you had a great experience. Looking forward to serving you again soon!",
          "We truly appreciate your 5-star review! Our team works hard to provide the best service, and your feedback makes it all worth it.",
          "Thanks for visiting! It was a pleasure having you. Let us know if there's anything else we can do for you next time."
        ];
      } else {
        _suggestions = [
          "We are so sorry to hear about your experience. This is not the standard we strive for. Please contact us directly at support@ourbusiness.com so we can make this right.",
          "Thank you for bringing this to our attention. We apologize for the inconvenience and would love the chance to discuss this further to resolve your concerns.",
          "We appreciate your honest feedback. We take all reviews seriously and will use this to improve our services. Please reach out so we can look into this."
        ];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.language, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Google My Business Auto-Reply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Paste a customer review below, and our AI will instantly generate 3 professional, tailored responses for you to copy and post.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: _reviewCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Paste customer review here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isGenerating ? null : _generateReplies,
                  icon: _isGenerating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                  label: Text(_isGenerating ? 'Generating Magic...' : 'Generate AI Replies'),
                  style: FilledButton.styleFrom(backgroundColor: BrandPalette.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_suggestions.isNotEmpty) ...[
          const Text('AI Suggestions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ..._suggestions.map((suggestion) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: BrandPalette.mint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: BrandPalette.teal.withValues(alpha: 0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard! Paste it on Google My Business.')));
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy to GMB'),
                    style: TextButton.styleFrom(foregroundColor: BrandPalette.navy),
                  ),
                )
              ],
            ),
          )).toList().animate().fadeIn().slideY(begin: 0.2, end: 0),
        ]
      ],
    );
  }
}

class PromoImageAIView extends StatefulWidget {
  const PromoImageAIView({super.key});

  @override
  State<PromoImageAIView> createState() => _PromoImageAIViewState();
}

class _PromoImageAIViewState extends State<PromoImageAIView> {
  final _promptCtrl = TextEditingController();
  bool _isGenerating = false;
  bool _showImage = false;

  void _generateImage() async {
    if (_promptCtrl.text.isEmpty) return;
    
    setState(() {
      _isGenerating = true;
      _showImage = false;
    });

    // Mock API Delay
    await Future.delayed(const Duration(seconds: 4));

    setState(() {
      _isGenerating = false;
      _showImage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.campaign, color: BrandPalette.coral),
                  SizedBox(width: 8),
                  Text('Social Media Promo Generator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Describe an image for your next Instagram or WhatsApp promotion. Our AI will generate a high-quality visual.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: _promptCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'E.g., A delicious glowing cheese burger on a dark wooden table with cinematic lighting...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isGenerating ? null : _generateImage,
                  icon: _isGenerating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.brush),
                  label: Text(_isGenerating ? 'Painting Canvas...' : 'Generate AI Image'),
                  style: FilledButton.styleFrom(backgroundColor: BrandPalette.navy, padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_showImage)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://picsum.photos/seed/${_promptCtrl.text.hashCode}/800/800',
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download),
                        label: const Text('Save to Gallery'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.share),
                        label: const Text('Share to Insta'),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE1306C)), // Instagram Pink
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
      ],
    );
  }
}
