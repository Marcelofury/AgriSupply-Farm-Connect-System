import 'dart:io';

import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  // Get all products with filters
  Future<List<ProductModel>> getProducts({
    final int page = 1,
    final int pageSize = 20,
    final String? category,
    final String? region,
    final double? minPrice,
    final double? maxPrice,
    final bool? organicOnly,
    final String sortBy = 'newest',
  }) async {
    try {
      // Build query parameters
      final params = <String, String>{
        'page': page.toString(),
        'limit': pageSize.toString(),
        'status': 'active',
      };

      if (category != null) params['category'] = category;
      if (region != null) params['region'] = region;
      if (minPrice != null) params['min_price'] = minPrice.toString();
      if (maxPrice != null) params['max_price'] = maxPrice.toString();
      if (organicOnly ?? false) params['organic'] = 'true';
      params['sort'] = sortBy;

      final response = await _apiService.get('/products', queryParams: params);
      final data = (response['data'] ?? response) as List;

      return data.map((final json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Get featured products
  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      final response = await _apiService.get('/products/featured');
      final data = (response['data'] ?? response) as List;

      return data.map((final json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch featured products: $e');
    }
  }

  // Get products by farmer
  Future<List<ProductModel>> getProductsByFarmer(final String farmerId) async {
    try {
      final data = await _apiService.query(
        'products',
        filters: {'farmer_id': farmerId},
        orderBy: 'created_at',
      );

      return data.map(ProductModel.fromJson).toList();
    } catch (e) {
      throw Exception('Failed to fetch farmer products: $e');
    }
  }

  // Get product by ID
  Future<ProductModel> getProductById(final String productId) async {
    try {
      final data = await _apiService.getById('products', productId);
      if (data == null) {
        throw Exception('Product not found');
      }
      return ProductModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  // Search products
  Future<List<ProductModel>> searchProducts(final String query) async {
    try {
      final response = await _apiService.get(
        '/products/search',
        queryParams: {'q': query},
      );
      final data = (response['data'] ?? response) as List;

      return data.map((final json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Create product
  Future<ProductModel> createProduct(
    final ProductModel product,
    final List<File> imageFiles,
  ) async {
    try {
      final files = <http.MultipartFile>[];
      
      // Add image files
      for (var i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final bytes = await file.readAsBytes();
        final filename = file.path.split('/').last;
        
        files.add(
          http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: filename,
          ),
        );
      }

      // Prepare form fields
      final fields = <String, String>{
        'name': product.name,
        'description': product.description,
        'category': product.category,
        'price': product.price.toString(),
        'unit': product.unit,
        'quantity': product.quantity.toString(),
        'isOrganic': product.isOrganic.toString(),
        if (product.harvestDate != null) 
          'harvestDate': product.harvestDate!.toIso8601String(),
        if (product.expiryDate != null) 
          'expiryDate': product.expiryDate!.toIso8601String(),
      };

      final response = await _apiService.postMultipart('/products', fields, files: files);
      final data = response['data'] ?? response;
      return ProductModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  // Update product
  Future<ProductModel> updateProduct(final ProductModel product) async {
    try {
      final data = await _apiService.update(
        'products',
        product.id,
        product.toJson(),
      );
      return ProductModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(final String productId) async {
    try {
      await _apiService.deleteRecord('products', productId);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Update product status
  Future<void> updateProductStatus(final String productId, final String status) async {
    try {
      await _apiService.update('products', productId, {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update product status: $e');
    }
  }

  // Upload product images
  Future<List<String>> uploadImages(final String productId, final List<String> imagePaths) async {
    try {
      final imageUrls = <String>[];

      for (var i = 0; i < imagePaths.length; i++) {
        final file = File(imagePaths[i]);
        final bytes = await file.readAsBytes();
        final extension = imagePaths[i].split('.').last;
        final path = 'products/$productId/image_$i.$extension';

        final url = await _apiService.uploadFile(
          bucket: 'products',
          path: path,
          fileBytes: bytes,
          contentType: 'image/$extension',
        );

        imageUrls.add(url);
      }

      // Update product with new image URLs
      await _apiService.update('products', productId, {
        'images': imageUrls,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return imageUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // Delete product image
  Future<void> deleteImage(final String productId, final String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('products');
      if (bucketIndex >= 0) {
        final path = pathSegments.sublist(bucketIndex).join('/');
        await _apiService.deleteFile(bucket: 'products', path: path);
      }

      // Get current product
      final product = await getProductById(productId);
      final updatedImages = product.images.where((final img) => img != imageUrl).toList();

      // Update product
      await _apiService.update('products', productId, {
        'images': updatedImages,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Get product categories with counts
  Future<Map<String, int>> getCategoryCounts() async {
    try {
      final response = await _apiService.get('/products/categories');
      return Map<String, int>.from(response as Map);
    } catch (e) {
      throw Exception('Failed to fetch category counts: $e');
    }
  }

  // Update product quantity (after order)
  Future<void> updateQuantity(final String productId, final int soldQuantity) async {
    try {
      final product = await getProductById(productId);
      final newQuantity = product.availableQuantity - soldQuantity;

      final updates = {
        'available_quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // If quantity is 0, mark as out of stock
      if (newQuantity <= 0) {
        updates['status'] = 'out_of_stock';
      }

      await _apiService.update('products', productId, updates);
    } catch (e) {
      throw Exception('Failed to update quantity: $e');
    }
  }

  // Increment view count
  Future<void> incrementViews(final String productId) async {
    try {
      await _apiService.post('/products/$productId/view');
    } catch (e) {
      // Silent fail for view count
    }
  }

  // Get similar products
  Future<List<ProductModel>> getSimilarProducts(
    final String productId,
    final String category,
  ) async {
    try {
      final response = await _apiService.get(
        '/products/$productId/similar',
        queryParams: {'category': category, 'limit': '6'},
      );
      final data = (response['data'] ?? response) as List;

      return data.map((final json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch similar products: $e');
    }
  }

  // Add product review
  Future<void> addReview(
    final String productId, {
    required final String userId,
    required final double rating,
    final String? comment,
  }) async {
    try {
      await _apiService.insert('product_reviews', {
        'product_id': productId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update product average rating
      await _updateProductRating(productId);
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  Future<void> _updateProductRating(final String productId) async {
    try {
      final reviews = await _apiService.query(
        'product_reviews',
        filters: {'product_id': productId},
      );

      if (reviews.isNotEmpty) {
        final totalRating = reviews.fold<double>(
          0,
          (final sum, final review) => sum + (review['rating'] as num).toDouble(),
        );
        final avgRating = totalRating / reviews.length;

        await _apiService.update('products', productId, {
          'rating': avgRating,
          'review_count': reviews.length,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Silent fail for rating update
    }
  }

  // Get product reviews
  Future<List<Map<String, dynamic>>> getProductReviews(final String productId) async {
    try {
      final reviews = await _apiService.query(
        'product_reviews',
        select: '*, users(full_name, photo_url)',
        filters: {'product_id': productId},
        orderBy: 'created_at',
      );
      return reviews;
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }
}
