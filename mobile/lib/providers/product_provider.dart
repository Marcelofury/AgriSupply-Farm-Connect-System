import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

enum ProductsStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  ProductsStatus _status = ProductsStatus.initial;
  List<ProductModel> _products = [];
  List<ProductModel> _featuredProducts = [];
  List<ProductModel> _farmerProducts = [];
  List<ProductModel> _searchResults = [];
  ProductModel? _selectedProduct;
  String? _errorMessage;
  
  // Filters
  String? _selectedCategory;
  String? _selectedRegion;
  double? _minPrice;
  double? _maxPrice;
  bool? _organicOnly;
  String _sortBy = 'newest';
  
  // Pagination
  int _currentPage = 1;
  bool _hasMoreProducts = true;
  static const int _pageSize = 20;

  // Getters
  ProductsStatus get status => _status;
  List<ProductModel> get products => _products;
  List<ProductModel> get featuredProducts => _featuredProducts;
  List<ProductModel> get farmerProducts => _farmerProducts;
  List<ProductModel> get searchResults => _searchResults;
  ProductModel? get selectedProduct => _selectedProduct;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  String? get selectedRegion => _selectedRegion;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  bool? get organicOnly => _organicOnly;
  String get sortBy => _sortBy;
  bool get hasMoreProducts => _hasMoreProducts;
  bool get isLoading => _status == ProductsStatus.loading;
  bool get isLoadingMore => _status == ProductsStatus.loadingMore;

  // Category counts
  Map<String, int> get categoryCounts {
    final counts = <String, int>{};
    for (final product in _products) {
      counts[product.category] = (counts[product.category] ?? 0) + 1;
    }
    return counts;
  }

  // Fetch all products with optional filters
  Future<void> fetchProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreProducts = true;
    }

    if (_status == ProductsStatus.loading) return;

    _status = refresh ? ProductsStatus.loading : ProductsStatus.loadingMore;
    if (refresh) _products.clear();
    _errorMessage = null;
    notifyListeners();

    try {
      final newProducts = await _productService.getProducts(
        page: _currentPage,
        pageSize: _pageSize,
        category: _selectedCategory,
        region: _selectedRegion,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        organicOnly: _organicOnly,
        sortBy: _sortBy,
      );

      if (newProducts.length < _pageSize) {
        _hasMoreProducts = false;
      }

      _products.addAll(newProducts);
      _currentPage++;
      _status = ProductsStatus.loaded;
    } catch (e) {
      _status = ProductsStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Fetch featured products
  Future<void> fetchFeaturedProducts() async {
    try {
      _featuredProducts = await _productService.getFeaturedProducts();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Fetch products by farmer ID
  Future<void> fetchFarmerProducts(String farmerId) async {
    _status = ProductsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _farmerProducts = await _productService.getProductsByFarmer(farmerId);
      _status = ProductsStatus.loaded;
    } catch (e) {
      _status = ProductsStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Fetch single product by ID
  Future<void> fetchProductById(String productId) async {
    _status = ProductsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedProduct = await _productService.getProductById(productId);
      _status = ProductsStatus.loaded;
    } catch (e) {
      _status = ProductsStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Search products
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    _status = ProductsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _productService.searchProducts(query);
      _status = ProductsStatus.loaded;
    } catch (e) {
      _status = ProductsStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Create new product
  Future<ProductModel?> createProduct(ProductModel product) async {
    _errorMessage = null;

    try {
      final createdProduct = await _productService.createProduct(product);
      _farmerProducts.insert(0, createdProduct);
      notifyListeners();
      return createdProduct;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update product
  Future<bool> updateProduct(ProductModel product) async {
    _errorMessage = null;

    try {
      final updatedProduct = await _productService.updateProduct(product);
      
      // Update in farmer products list
      final farmerIndex = _farmerProducts.indexWhere((p) => p.id == product.id);
      if (farmerIndex >= 0) {
        _farmerProducts[farmerIndex] = updatedProduct;
      }
      
      // Update in all products list
      final allIndex = _products.indexWhere((p) => p.id == product.id);
      if (allIndex >= 0) {
        _products[allIndex] = updatedProduct;
      }
      
      // Update selected product if same
      if (_selectedProduct?.id == product.id) {
        _selectedProduct = updatedProduct;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    _errorMessage = null;

    try {
      await _productService.deleteProduct(productId);
      
      _farmerProducts.removeWhere((p) => p.id == productId);
      _products.removeWhere((p) => p.id == productId);
      
      if (_selectedProduct?.id == productId) {
        _selectedProduct = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update product status
  Future<bool> updateProductStatus(String productId, String status) async {
    _errorMessage = null;

    try {
      await _productService.updateProductStatus(productId, status);
      
      // Update locally
      final farmerIndex = _farmerProducts.indexWhere((p) => p.id == productId);
      if (farmerIndex >= 0) {
        _farmerProducts[farmerIndex] = _farmerProducts[farmerIndex].copyWith(
          status: status,
        );
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Upload product images
  Future<List<String>> uploadImages(String productId, List<String> imagePaths) async {
    try {
      return await _productService.uploadImages(productId, imagePaths);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Filter setters
  void setCategory(String? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category == 'All' ? null : category;
      fetchProducts(refresh: true);
    }
  }

  void setRegion(String? region) {
    if (_selectedRegion != region) {
      _selectedRegion = region;
      fetchProducts(refresh: true);
    }
  }

  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    fetchProducts(refresh: true);
  }

  void setOrganicOnly(bool? value) {
    if (_organicOnly != value) {
      _organicOnly = value;
      fetchProducts(refresh: true);
    }
  }

  void setSortBy(String sortBy) {
    if (_sortBy != sortBy) {
      _sortBy = sortBy;
      fetchProducts(refresh: true);
    }
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedRegion = null;
    _minPrice = null;
    _maxPrice = null;
    _organicOnly = null;
    _sortBy = 'newest';
    fetchProducts(refresh: true);
  }

  void clearSearchResults() {
    _searchResults.clear();
    notifyListeners();
  }

  void setSelectedProduct(ProductModel? product) {
    _selectedProduct = product;
    notifyListeners();
  }

  // Load more products for infinite scroll
  Future<void> loadMoreProducts() async {
    if (_hasMoreProducts && _status != ProductsStatus.loadingMore) {
      await fetchProducts();
    }
  }

  // Get products by category for home screen
  List<ProductModel> getProductsByCategory(String category) {
    return _products.where((p) => p.category == category).toList();
  }

  // Get filtered farmer products by status
  List<ProductModel> getFarmerProductsByStatus(String status) {
    return _farmerProducts.where((p) => p.status == status).toList();
  }

  // Get product by ID from local lists or fetch from service
  Future<ProductModel?> getProductById(String productId) async {
    // First check local lists
    ProductModel? product = _products.where((p) => p.id == productId).firstOrNull;
    product ??= _farmerProducts.where((p) => p.id == productId).firstOrNull;
    product ??= _featuredProducts.where((p) => p.id == productId).firstOrNull;
    
    if (product != null) return product;
    
    // If not found locally, fetch from service
    try {
      return await _productService.getProductById(productId);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  // Load farmer products (alias for fetchFarmerProducts)
  Future<void> loadFarmerProducts(String farmerId) async {
    await fetchFarmerProducts(farmerId);
  }

  // Fetch products by category
  Future<List<ProductModel>> fetchProductsByCategory(String category) async {
    try {
      final products = await _productService.getProducts(
        page: 1,
        pageSize: 50,
        category: category,
      );
      return products;
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }
}
