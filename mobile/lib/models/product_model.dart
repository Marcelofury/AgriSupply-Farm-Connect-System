class ProductModel {
  final String id;
  final String farmerId;
  final String farmerName;
  final String? farmerImage;
  final double farmerRating;
  final String name;
  final String description;
  final String category;
  final double price;
  final String unit; // kg, bunch, piece, etc.
  final double quantity;
  final double availableQuantity;
  final List<String> images;
  final String? region;
  final String? district;
  final bool isOrganic;
  final bool isFeatured;
  final bool isActive;
  final DateTime harvestDate;
  final DateTime? expiryDate;
  final double rating;
  final int totalRatings;
  final int totalSold;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    this.farmerImage,
    this.farmerRating = 0.0,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.availableQuantity,
    required this.images,
    this.region,
    this.district,
    this.isOrganic = false,
    this.isFeatured = false,
    this.isActive = true,
    required this.harvestDate,
    this.expiryDate,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.totalSold = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      farmerName: json['farmer_name'] as String? ?? 'Unknown Farmer',
      farmerImage: json['farmer_image'] as String?,
      farmerRating: (json['farmer_rating'] as num?)?.toDouble() ?? 0.0,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      availableQuantity: (json['available_quantity'] as num).toDouble(),
      images: List<String>.from(json['images'] ?? []),
      region: json['region'] as String?,
      district: json['district'] as String?,
      isOrganic: json['is_organic'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      harvestDate: DateTime.parse(json['harvest_date'] as String),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      totalSold: json['total_sold'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'farmer_image': farmerImage,
      'farmer_rating': farmerRating,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'available_quantity': availableQuantity,
      'images': images,
      'region': region,
      'district': district,
      'is_organic': isOrganic,
      'is_featured': isFeatured,
      'is_active': isActive,
      'harvest_date': harvestDate.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'rating': rating,
      'total_ratings': totalRatings,
      'total_sold': totalSold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Alias for farmerImage for backward compatibility
  String? get farmerPhoto => farmerImage;

  ProductModel copyWith({
    String? id,
    String? farmerId,
    String? farmerName,
    String? farmerImage,
    double? farmerRating,
    String? name,
    String? description,
    String? category,
    double? price,
    String? unit,
    double? quantity,
    double? availableQuantity,
    List<String>? images,
    String? region,
    String? district,
    bool? isOrganic,
    bool? isFeatured,
    bool? isActive,
    DateTime? harvestDate,
    DateTime? expiryDate,
    double? rating,
    int? totalRatings,
    int? totalSold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      farmerImage: farmerImage ?? this.farmerImage,
      farmerRating: farmerRating ?? this.farmerRating,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      images: images ?? this.images,
      region: region ?? this.region,
      district: district ?? this.district,
      isOrganic: isOrganic ?? this.isOrganic,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      harvestDate: harvestDate ?? this.harvestDate,
      expiryDate: expiryDate ?? this.expiryDate,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalSold: totalSold ?? this.totalSold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayPrice => 'UGX ${price.toStringAsFixed(0)}/$unit';
  bool get isAvailable => availableQuantity > 0 && isActive;
  String get primaryImage => images.isNotEmpty ? images.first : '';
}

class ProductCategory {
  static const String vegetables = 'Vegetables';
  static const String fruits = 'Fruits';
  static const String grains = 'Grains & Cereals';
  static const String legumes = 'Legumes';
  static const String tubers = 'Tubers & Roots';
  static const String dairy = 'Dairy Products';
  static const String poultry = 'Poultry & Eggs';
  static const String meat = 'Meat';
  static const String fish = 'Fish & Seafood';
  static const String herbs = 'Herbs & Spices';
  static const String nuts = 'Nuts & Seeds';
  static const String honey = 'Honey & Bee Products';
  static const String beverages = 'Beverages';
  static const String other = 'Other';

  static List<String> get all => [
        vegetables,
        fruits,
        grains,
        legumes,
        tubers,
        dairy,
        poultry,
        meat,
        fish,
        herbs,
        nuts,
        honey,
        beverages,
        other,
      ];

  static String getIcon(String category) {
    switch (category) {
      case vegetables:
        return '🥬';
      case fruits:
        return '🍎';
      case grains:
        return '🌾';
      case legumes:
        return '🫘';
      case tubers:
        return '🥔';
      case dairy:
        return '🥛';
      case poultry:
        return '🥚';
      case meat:
        return '🥩';
      case fish:
        return '🐟';
      case herbs:
        return '🌿';
      case nuts:
        return '🥜';
      case honey:
        return '🍯';
      case beverages:
        return '🧃';
      default:
        return '📦';
    }
  }
}

class ProductUnit {
  static const String kg = 'kg';
  static const String gram = 'g';
  static const String piece = 'piece';
  static const String bunch = 'bunch';
  static const String basket = 'basket';
  static const String bag = 'bag';
  static const String crate = 'crate';
  static const String liter = 'liter';
  static const String dozen = 'dozen';
  static const String tray = 'tray';

  static List<String> get all => [
        kg,
        gram,
        piece,
        bunch,
        basket,
        bag,
        crate,
        liter,
        dozen,
        tray,
      ];
}

class ProductStatus {
  static const String active = 'active';
  static const String inactive = 'inactive';
  static const String outOfStock = 'out_of_stock';
  static const String pending = 'pending';
  static const String rejected = 'rejected';

  static List<String> get all => [
        active,
        inactive,
        outOfStock,
        pending,
        rejected,
      ];
}
