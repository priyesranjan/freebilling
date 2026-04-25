import 'package:flutter/material.dart';
import '../core/core.dart';
import '../models/models.dart';
import 'screens.dart';

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _msmeController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  String _selectedCategory = 'General Store';
  final List<String> _categories = [
    'General Store',
    'Pharmacy',
    'Services',
    'Manufacturing',
    'Restaurant',
    'Electronics',
    'Other'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _msmeController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_businessNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business Name is required')),
        );
        return;
      }
    }

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      // Finish Onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PlatformShell()),
      );
    }
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 1 of 3', style: TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Business Details', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Tell us about your business to set up your store.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 32),
          
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Business Category *',
              border: OutlineInputBorder(),
            ),
            items: _categories.map((String category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) setState(() => _selectedCategory = newValue);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Business Name *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 2 of 3', style: TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Legal Details', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('These details are completely optional and can be added later.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 32),
          
          TextField(
            controller: _gstController,
            decoration: const InputDecoration(
              labelText: 'GST Number (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _msmeController,
            decoration: const InputDecoration(
              labelText: 'MSME Number (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _websiteController,
            decoration: const InputDecoration(
              labelText: 'Website (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 3 of 3', style: TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('How to use FreeBilling', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Watch these short guides to get started.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 32),
          
          Expanded(
            child: ListView(
              children: [
                _buildVideoPlaceholder('How to add products', Icons.inventory_2),
                const SizedBox(height: 16),
                _buildVideoPlaceholder('How to generate an invoice', Icons.receipt_long),
                const SizedBox(height: 16),
                _buildVideoPlaceholder('Tracking your Profit', Icons.insights),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder(String title, IconData icon) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: BrandPalette.navy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BrandPalette.navy.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: BrandPalette.teal.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            ),
            child: Center(child: Icon(Icons.play_circle_fill, size: 40, color: BrandPalette.teal)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('1 min video', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _currentPage > 0 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
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
                  _buildStep3(),
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
                  ),
                  child: Text(_currentPage == 2 ? 'Go to Dashboard' : 'Continue'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
