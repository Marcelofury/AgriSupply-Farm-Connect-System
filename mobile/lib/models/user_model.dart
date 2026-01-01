class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final String userType; // 'farmer', 'buyer', 'admin'
  final String? profileImage;
  final String? address;
  final String? region;
  final String? district;
  final double? latitude;
  final double? longitude;
  final bool isVerified;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final double rating;
  final int totalRatings;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.fullName,
    required this.userType,
    this.profileImage,
    this.address,
    this.region,
    this.district,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.rating = 0.0,
    this.totalRatings = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String,
      userType: json['user_type'] as String,
      profileImage: json['profile_image'] as String?,
      address: json['address'] as String?,
      region: json['region'] as String?,
      district: json['district'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      isVerified: json['is_verified'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      premiumExpiresAt: json['premium_expires_at'] != null
          ? DateTime.parse(json['premium_expires_at'] as String)
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'user_type': userType,
      'profile_image': profileImage,
      'address': address,
      'region': region,
      'district': district,
      'latitude': latitude,
      'longitude': longitude,
      'is_verified': isVerified,
      'is_premium': isPremium,
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'rating': rating,
      'total_ratings': totalRatings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? userType,
    String? profileImage,
    String? address,
    String? region,
    String? district,
    double? latitude,
    double? longitude,
    bool? isVerified,
    bool? isPremium,
    DateTime? premiumExpiresAt,
    double? rating,
    int? totalRatings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      userType: userType ?? this.userType,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      region: region ?? this.region,
      district: district ?? this.district,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isFarmer => userType == 'farmer';
  bool get isBuyer => userType == 'buyer';
  bool get isAdmin => userType == 'admin';
}
