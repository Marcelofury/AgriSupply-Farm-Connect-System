/// Widget Tests for ProductCard
/// Tests for product card widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock Product model
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String unit;
  final String category;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final bool isOrganic;
  final bool isFavorite;
  final String farmerName;
  final String region;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.category,
    required this.images,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isOrganic = false,
    this.isFavorite = false,
    this.farmerName = 'Unknown Farmer',
    this.region = 'Unknown',
  });
}

// ProductCard widget for testing
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavorite,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: product.images.isNotEmpty
                      ? Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                ),
                // Organic badge
                if (product.isOrganic)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Organic',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    key: const Key('favorite_button'),
                    icon: Icon(
                      product.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: product.isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: onFavorite,
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Price
                  Text(
                    'UGX ${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'per ${product.unit}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        ' (${product.reviewCount})',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Farmer
                  Text(
                    product.farmerName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key('add_to_cart_button'),
                      onPressed: onAddToCart,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('ProductCard Widget', () {
    const testProduct = Product(
      id: 'test-1',
      name: 'Fresh Organic Matooke',
      description: 'Fresh matooke from Mbarara',
      price: 35000,
      unit: 'bunch',
      category: 'fruits_vegetables',
      images: ['https://example.com/matooke.jpg'],
      rating: 4.5,
      reviewCount: 23,
      isOrganic: true,
      isFavorite: false,
      farmerName: 'Jane Farm',
      region: 'Western',
    );

    testWidgets('displays product name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      expect(find.text('Fresh Organic Matooke'), findsOneWidget);
    });

    testWidgets('displays formatted price with currency',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      expect(find.text('UGX 35000'), findsOneWidget);
    });

    testWidgets('displays unit', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      expect(find.text('per bunch'), findsOneWidget);
    });

    testWidgets('displays rating', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      expect(find.text('4.5'), findsOneWidget);
      expect(find.text(' (23)'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('displays farmer name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      expect(find.text('Jane Farm'), findsOneWidget);
    });

    testWidgets('shows organic badge for organic products',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      expect(find.text('Organic'), findsOneWidget);
    });

    testWidgets('hides organic badge for non-organic products',
        (WidgetTester tester) async {
      const nonOrganicProduct = Product(
        id: 'test-2',
        name: 'Regular Matooke',
        description: 'Matooke',
        price: 30000,
        unit: 'bunch',
        category: 'fruits_vegetables',
        images: [],
        isOrganic: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: nonOrganicProduct),
          ),
        ),
      );

      expect(find.text('Organic'), findsNothing);
    });

    testWidgets('shows filled heart for favorite products',
        (WidgetTester tester) async {
      const favoriteProduct = Product(
        id: 'test-3',
        name: 'Favorite Product',
        description: 'A favorite',
        price: 10000,
        unit: 'kg',
        category: 'fruits_vegetables',
        images: [],
        isFavorite: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: favoriteProduct),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('shows outline heart for non-favorite products',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: testProduct,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('calls onFavorite when favorite button is tapped',
        (WidgetTester tester) async {
      bool favoriteTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: testProduct,
              onFavorite: () => favoriteTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('favorite_button')));
      expect(favoriteTapped, isTrue);
    });

    testWidgets('calls onAddToCart when add to cart button is tapped',
        (WidgetTester tester) async {
      bool addedToCart = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: testProduct,
              onAddToCart: () => addedToCart = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('add_to_cart_button')));
      expect(addedToCart, isTrue);
    });

    testWidgets('has add to cart button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows placeholder when no image', (WidgetTester tester) async {
      const noImageProduct = Product(
        id: 'test-4',
        name: 'No Image Product',
        description: 'Product without image',
        price: 5000,
        unit: 'piece',
        category: 'other',
        images: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: noImageProduct),
          ),
        ),
      );

      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });

    testWidgets('truncates long product names', (WidgetTester tester) async {
      const longNameProduct = Product(
        id: 'test-5',
        name:
            'This is a very long product name that should be truncated to fit in one line',
        description: 'Description',
        price: 10000,
        unit: 'kg',
        category: 'fruits_vegetables',
        images: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: ProductCard(product: longNameProduct),
            ),
          ),
        ),
      );

      // The name should still be findable (even if truncated visually)
      final nameFinder = find.text(longNameProduct.name);
      expect(nameFinder, findsOneWidget);
    });

    testWidgets('displays zero rating correctly', (WidgetTester tester) async {
      const zeroRatingProduct = Product(
        id: 'test-6',
        name: 'New Product',
        description: 'Brand new product',
        price: 8000,
        unit: 'kg',
        category: 'grains',
        images: [],
        rating: 0.0,
        reviewCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: zeroRatingProduct),
          ),
        ),
      );

      expect(find.text('0.0'), findsOneWidget);
      expect(find.text(' (0)'), findsOneWidget);
    });

    testWidgets('handles high prices correctly', (WidgetTester tester) async {
      const expensiveProduct = Product(
        id: 'test-7',
        name: 'Expensive Item',
        description: 'Very expensive',
        price: 1500000,
        unit: 'piece',
        category: 'farm_equipment',
        images: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: expensiveProduct),
          ),
        ),
      );

      expect(find.text('UGX 1500000'), findsOneWidget);
    });
  });
}
