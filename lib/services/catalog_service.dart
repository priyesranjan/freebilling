import 'package:uuid/uuid.dart';
import '../models/models.dart';

class CatalogService {
  static const uuid = Uuid();

  static List<Product> getCatalogForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'pharmacy':
        return _pharmacyCatalog();
      case 'salon':
        return _salonCatalog();
      case 'food':
        return _foodCatalog();
      case 'studio':
        return _studioCatalog();
      default:
        return [];
    }
  }

  static List<Product> _pharmacyCatalog() {
    return [
      _createProduct('Paracetamol 500mg (Strip of 10)', 15.0, 12.0, 'MED'),
      _createProduct('Ibuprofen 400mg (Strip of 10)', 25.0, 20.0, 'MED'),
      _createProduct('Amoxicillin 250mg (Strip of 10)', 45.0, 38.0, 'MED'),
      _createProduct('Cough Syrup 100ml', 85.0, 65.0, 'MED'),
      _createProduct('First Aid Bandage', 5.0, 3.0, 'MED'),
      _createProduct('Antiseptic Liquid 250ml', 120.0, 95.0, 'MED'),
      _createProduct('Vitamin C Tablets (Strip of 15)', 40.0, 30.0, 'MED'),
      _createProduct('Pain Relief Spray 50g', 150.0, 110.0, 'MED'),
      _createProduct('Thermometer Digital', 250.0, 180.0, 'MED'),
      _createProduct('Hand Sanitizer 100ml', 50.0, 35.0, 'MED'),
    ];
  }

  static List<Product> _salonCatalog() {
    return [
      _createProduct('Men Haircut', 150.0, 150.0, 'SVC'),
      _createProduct('Women Haircut', 350.0, 350.0, 'SVC'),
      _createProduct('Kids Haircut', 100.0, 100.0, 'SVC'),
      _createProduct('Shaving / Beard Trim', 100.0, 100.0, 'SVC'),
      _createProduct('Basic Facial', 500.0, 500.0, 'SVC'),
      _createProduct('Premium Gold Facial', 1200.0, 1200.0, 'SVC'),
      _createProduct('Hair Coloring', 800.0, 800.0, 'SVC'),
      _createProduct('Head Massage (30 mins)', 300.0, 300.0, 'SVC'),
      _createProduct('Threading (Eyebrows)', 50.0, 50.0, 'SVC'),
      _createProduct('Manicure', 400.0, 400.0, 'SVC'),
      _createProduct('Pedicure', 500.0, 500.0, 'SVC'),
    ];
  }

  static List<Product> _foodCatalog() {
    return [
      _createProduct('Aloo Tikki Burger', 50.0, 30.0, 'FOOD'),
      _createProduct('Cheese Burger', 80.0, 45.0, 'FOOD'),
      _createProduct('Veg Pizza (Regular)', 150.0, 80.0, 'FOOD'),
      _createProduct('Paneer Pizza (Medium)', 250.0, 140.0, 'FOOD'),
      _createProduct('Veg Fried Momos (8 pcs)', 60.0, 35.0, 'FOOD'),
      _createProduct('Paneer Steam Momos (8 pcs)', 80.0, 45.0, 'FOOD'),
      _createProduct('French Fries', 70.0, 30.0, 'FOOD'),
      _createProduct('Cold Drink (250ml)', 20.0, 18.0, 'FOOD'),
      _createProduct('Cold Coffee', 90.0, 40.0, 'FOOD'),
      _createProduct('Chocolate Shake', 120.0, 50.0, 'FOOD'),
    ];
  }

  static List<Product> _studioCatalog() {
    return [
      _createProduct('Passport Size Photos (8 pcs)', 100.0, 80.0, 'STD'),
      _createProduct('Pre-Wedding Photography (Per Day)', 15000.0, 15000.0, 'STD'),
      _createProduct('Wedding Photography & Videography', 45000.0, 45000.0, 'STD'),
      _createProduct('Photo Album Printing (Standard)', 3000.0, 2000.0, 'STD'),
      _createProduct('Photo Album Printing (Premium Canvera)', 8000.0, 5000.0, 'STD'),
      _createProduct('Video Mixing & Editing (Per Project)', 5000.0, 5000.0, 'STD'),
      _createProduct('Drone Coverage (Per Day)', 8000.0, 8000.0, 'STD'),
      _createProduct('A4 Photo Framing', 400.0, 250.0, 'STD'),
      _createProduct('LED Wall Screen Setup', 12000.0, 12000.0, 'STD'),
    ];
  }

  static Product _createProduct(String name, double mrp, double sellingPrice, String codePrefix) {
    final randCode = uuid.v4().substring(0, 5).toUpperCase();
    return Product(
      id: uuid.v4(),
      name: name,
      sellingPrice: sellingPrice,
      mrp: mrp,
      codes: ['$codePrefix-$randCode'],
      initialStock: 100, // Default mock stock
    );
  }
}
