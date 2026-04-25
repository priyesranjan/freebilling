import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/core.dart';
import '../models/models.dart';
import 'screens.dart';
import '../services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form Controllers
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _slugController = TextEditingController();
  
  bool _isCheckingSlug = false;
  bool? _isSlugAvailable;

  String _selectedType = 'Retail Shop';
  final List<String> _businessTypes = [
    'Retail Shop',
    'Wholesale',
    'Distributor',
    'Pharmacy',
    'Restaurant',
    'Services / Freelancer',
    'Manufacturing',
    'Electronics / Mobile',
    'Other'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  void _onBusinessNameChanged(String val) {
    if (_slugController.text.isEmpty || _slugController.text == _generateSlug(_businessNameController.text)) {
      _slugController.text = _generateSlug(val);
      _checkSlugAvailability(_slugController.text);
    }
  }

  String _generateSlug(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
  }

  Future<void> _checkSlugAvailability(String slug) async {
    if (slug.isEmpty) {
      setState(() => _isSlugAvailable = null);
      return;
    }
    setState(() {
      _isCheckingSlug = true;
      _isSlugAvailable = null;
    });
    
    // Simulate API call to check availability
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (mounted) {
      setState(() {
        _isCheckingSlug = false;
        _isSlugAvailable = true; // In demo, everything is available
      });
    }
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_businessNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business Name is required')));
        return;
      }
    }

    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      // Finish Onboarding and save to DB
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isCheckingSlug = true);
    try {
      await ApiService.updateOnboarding(
        name: _businessNameController.text.trim(),
        businessType: _selectedType,
        websiteSlug: _slugController.text.trim(),
      );
      
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PlatformShell()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingSlug = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Step 1 of 2', style: const TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Set Up Your Business', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Get your MNC-level digital identity in seconds.', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            
            const Text('Business Type', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _businessTypes.map((String type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) setState(() => _selectedType = newValue);
              },
            ),
            const SizedBox(height: 24),
            
            const Text('Business Name', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _businessNameController,
              onChanged: _onBusinessNameChanged,
              decoration: const InputDecoration(
                hintText: 'e.g. Sarthi Grocery',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store_outlined),
              ),
            ),
            const SizedBox(height: 32),
            
            // Website Generation Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BrandPalette.navy.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BrandPalette.navy.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, color: BrandPalette.teal, size: 20),
                      const SizedBox(width: 8),
                      Text('Your Business Website', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: BrandPalette.navy)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Customize your URL for customers to find you online:', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _slugController,
                    onChanged: _checkSlugAvailability,
                    decoration: InputDecoration(
                      prefixText: 'erpbill.com/',
                      prefixStyle: const TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold),
                      suffixIcon: _isCheckingSlug 
                        ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                        : _isSlugAvailable == true 
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : _isSlugAvailable == false 
                            ? const Icon(Icons.error, color: BrandPalette.coral)
                            : null,
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  if (_isSlugAvailable == true) 
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('✅ URL is available!', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 2 of 2', style: const TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Welcome to the Future', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          
          _buildFeatureRow(Icons.sync, 'Real-Time Multi-Device Sync', 'Access your data from any phone or computer instantly.'),
          const SizedBox(height: 24),
          _buildFeatureRow(Icons.qr_code_scanner, 'Smart Inventory', 'Track MRP, Selling Price, and stock levels automatically.'),
          const SizedBox(height: 24),
          _buildFeatureRow(Icons.share, 'Online Presence', 'Your website is ready at erpbill.com/${_slugController.text}'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: BrandPalette.mint.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.verified, color: BrandPalette.teal),
                SizedBox(width: 12),
                Expanded(child: Text('You are now part of our MNC Level ERP platform.', style: TextStyle(fontWeight: FontWeight.bold, color: BrandPalette.teal))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: BrandPalette.navy.withValues(alpha: 0.05), shape: BoxShape.circle),
          child: Icon(icon, color: BrandPalette.navy),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: _currentPage > 0 
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: BrandPalette.navy),
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                setState(() => _currentPage--);
              },
            )
          : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: BrandPalette.navy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_currentPage == 1 ? 'Go to Dashboard' : 'Continue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
