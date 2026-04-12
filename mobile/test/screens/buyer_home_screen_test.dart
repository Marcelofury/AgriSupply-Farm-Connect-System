import 'package:agrisupply/providers/auth_provider.dart';
import 'package:agrisupply/providers/cart_provider.dart';
import 'package:agrisupply/providers/product_provider.dart';
import 'package:agrisupply/screens/buyer/buyer_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class StubAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class TrackingProductProvider extends ProductProvider {
  final List<Map<String, dynamic>> regionCalls = [];
  final List<bool> fetchProductsCalls = [];
  int fetchFeaturedCount = 0;

  @override
  void setRegion(String? region, {bool refresh = true}) {
    regionCalls.add({'region': region, 'refresh': refresh});
  }

  @override
  Future<void> fetchProducts({bool refresh = false}) async {
    fetchProductsCalls.add(refresh);
  }

  @override
  Future<void> fetchFeaturedProducts() async {
    fetchFeaturedCount += 1;
  }
}

void main() {
  testWidgets('Buyer home loads products globally (no region filter)', (tester) async {
    final authProvider = StubAuthProvider();
    final trackingProductProvider = TrackingProductProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ProductProvider>.value(value: trackingProductProvider),
          ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ],
        child: const MaterialApp(home: BuyerHomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(trackingProductProvider.regionCalls, isNotEmpty);
    expect(trackingProductProvider.regionCalls.first['region'], isNull);
    expect(trackingProductProvider.regionCalls.first['refresh'], isFalse);
    expect(trackingProductProvider.fetchProductsCalls, contains(true));
    expect(trackingProductProvider.fetchFeaturedCount, 1);
  });
}
