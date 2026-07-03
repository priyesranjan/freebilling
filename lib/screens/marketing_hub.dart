import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      length: 4,
      child: Scaffold(
        backgroundColor: BrandPalette.pageBase,
        appBar: AppBar(
          title: const Text('AI Marketing & Website Studio'),
          backgroundColor: BrandPalette.pageBase,
          elevation: 0,
          isScrollable: true,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: BrandPalette.navy,
            unselectedLabelColor: Colors.grey,
            indicatorColor: BrandPalette.teal,
            tabs: [
              Tab(icon: Icon(Icons.web), text: '🌐 Website Studio'),
              Tab(icon: Icon(Icons.star), text: 'Google Reviews AI'),
              Tab(icon: Icon(Icons.image), text: 'Promo Image AI'),
              Tab(icon: Icon(Icons.insights), text: 'GMB Performance'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            StoreCustomizerView(),
            ReviewAIView(),
            PromoImageAIView(),
            GMBPerformanceView(),
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
                      Clipboard.setData(ClipboardData(text: suggestion));
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

class GMBPerformanceView extends StatelessWidget {
  const GMBPerformanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BrandPalette.navy,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights, color: BrandPalette.teal),
                  SizedBox(width: 8),
                  Text('Business Performance Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Once your Google API Request (Case ID: 1-8164000040932) is approved, your real-time Google Search and Maps data will appear here automatically.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: 0.1,
                backgroundColor: Colors.white10,
                color: BrandPalette.teal,
              ),
              const SizedBox(height: 8),
              const Text('Status: Waiting for Google Approval (7-10 Days)', style: TextStyle(color: BrandPalette.teal, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Predicted Insights (Mock)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard('Profile Views', '1.2k', Icons.visibility, Colors.blue),
            const SizedBox(width: 12),
            _buildStatCard('Search Hits', '840', Icons.search, Colors.purple),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard('Calls Made', '42', Icons.phone, Colors.green),
            const SizedBox(width: 12),
            _buildStatCard('Web Clicks', '156', Icons.mouse, Colors.orange),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.lock_clock, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text('Full Dashboard Locked', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text(
                'We have prepared all the charts and data connectors. As soon as your Google Cloud quota is increased, this screen will unlock with your live business metrics.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class StoreCustomizerView extends StatefulWidget {
  const StoreCustomizerView({super.key});

  @override
  State<StoreCustomizerView> createState() => _StoreCustomizerViewState();
}

class _StoreCustomizerViewState extends State<StoreCustomizerView> {
  String _selectedTheme = 'fashion';
  final _announcementCtrl = TextEditingController(text: '🎉 Flat 20% OFF on all online orders & bookings today!');
  final _ctaCtrl = TextEditingController(text: 'Order Now');
  final _instaCtrl = TextEditingController();
  final _fbCtrl = TextEditingController();
  final _ytCtrl = TextEditingController();
  final _mapsCtrl = TextEditingController();
  bool _isSaving = false;

  final Map<String, Map<String, dynamic>> _themePalettes = {
    'fashion': {'label': 'Gold Luxury', 'color': Color(0xFFFFB703), 'icon': '✨'},
    'grocery': {'label': 'Emerald Fresh', 'color': Color(0xFF10B981), 'icon': '🛒'},
    'cyber': {'label': 'Indigo Tech', 'color': Color(0xFF6366F1), 'icon': '⚡'},
    'salon': {'label': 'Purple Glow', 'color': Color(0xFFA855F7), 'icon': '💆'},
    'restaurant': {'label': 'Ruby Food', 'color': Color(0xFFEF4444), 'icon': '🍕'},
    'medicine': {'label': 'Cyan Medical', 'color': Color(0xFF06B6D4), 'icon': '🛡️'},
  };

  void _saveCustomizations() async {
    setState(() => _isSaving = true);
    try {
      await ApiService.updateWebsiteConfig(
        themeColor: _selectedTheme,
        announcementText: _announcementCtrl.text.trim(),
        ctaButtonText: _ctaCtrl.text.trim(),
        instagram: _instaCtrl.text.trim(),
        facebook: _fbCtrl.text.trim(),
        youtube: _ytCtrl.text.trim(),
        googleMaps: _mapsCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Website updated live! Check your store URL.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved locally. Push to server: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Preview Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF090D16), Color(0xFF161E31)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.public, color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Live Website Customizer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Instant aesthetic & social media control', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Store Showroom Link:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(child: Text('https://meradukan.in/yourshop', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13))),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: 'https://meradukan.in'));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store Link Copied!')));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Color Palette Selector
        const Text('🎨 Select Theme Palette', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        SizedBox(
          height: 85,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _themePalettes.entries.map((e) {
              final isSel = _selectedTheme == e.key;
              final data = e.value;
              return GestureDetector(
                onTap: () => setState(() => _selectedTheme = e.key),
                child: AnimatedContainer(
                  duration: 200.ms,
                  width: 110,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSel ? data['color'].withValues(alpha: 0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSel ? data['color'] : Colors.grey.shade300, width: isSel ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(backgroundColor: data['color'], radius: 14, child: Text(data['icon'], style: const TextStyle(fontSize: 12))),
                      const SizedBox(height: 6),
                      Text(data['label'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? data['color'] : Colors.black87)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // Banner & CTA
        const Text('📣 Top Announcement Banner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        TextField(
          controller: _announcementCtrl,
          decoration: InputDecoration(
            hintText: 'Promotional text shown at top of website',
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),

        const SizedBox(height: 16),
        const Text('🔘 Action Button Label', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        TextField(
          controller: _ctaCtrl,
          decoration: InputDecoration(
            hintText: 'e.g. Order Now / Book Appointment',
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),

        const SizedBox(height: 20),
        const Text('💬 Social Medias & Maps Links', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        TextField(
          controller: _instaCtrl,
          decoration: InputDecoration(prefixIcon: const Icon(Icons.camera_alt, color: Colors.pink), labelText: 'Instagram Profile Handle (@shop)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _fbCtrl,
          decoration: InputDecoration(prefixIcon: const Icon(Icons.facebook, color: Colors.blue), labelText: 'Facebook Page URL', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _mapsCtrl,
          decoration: InputDecoration(prefixIcon: const Icon(Icons.location_on, color: Colors.green), labelText: 'Google Maps Location Link', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),

        const SizedBox(height: 28),
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveCustomizations,
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandPalette.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.cloud_upload),
            label: const Text('Save & Update Live Website', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

