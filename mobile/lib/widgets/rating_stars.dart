import 'package:flutter/material.dart';

import '../config/theme.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showValue;
  final int? reviewCount;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.activeColor,
    this.inactiveColor,
    this.showValue = false,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          IconData icon;
          Color color;

          if (rating >= starValue) {
            icon = Icons.star;
            color = activeColor ?? AppColors.warning;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half;
            color = activeColor ?? AppColors.warning;
          } else {
            icon = Icons.star_border;
            color = inactiveColor ?? AppColors.grey300;
          }

          return Icon(icon, size: size, color: color);
        }),
        if (showValue) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
        ],
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: size * 0.7,
              color: AppColors.grey500,
            ),
          ),
        ],
      ],
    );
  }
}

class RatingInput extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool allowHalf;

  const RatingInput({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 36,
    this.activeColor,
    this.inactiveColor,
    this.allowHalf = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        final isActive = rating >= starValue;
        final isHalf = allowHalf && rating >= starValue - 0.5 && rating < starValue;

        return GestureDetector(
          onTap: () => onRatingChanged(starValue),
          onHorizontalDragUpdate: allowHalf
              ? (details) {
                  final halfWidth = size / 2;
                  final isLeftHalf = details.localPosition.dx < halfWidth;
                  onRatingChanged(isLeftHalf ? starValue - 0.5 : starValue);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isActive
                  ? Icons.star
                  : isHalf
                      ? Icons.star_half
                      : Icons.star_border,
              size: size,
              color: isActive || isHalf
                  ? activeColor ?? AppColors.warning
                  : inactiveColor ?? AppColors.grey300,
            ),
          ),
        );
      }),
    );
  }
}

class RatingBar extends StatelessWidget {
  final int starNumber;
  final double percentage;
  final int count;
  final Color? barColor;

  const RatingBar({
    super.key,
    required this.starNumber,
    required this.percentage,
    this.count = 0,
    this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            '$starNumber',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
        ),
        const Icon(Icons.star, size: 12, color: AppColors.warning),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage.clamp(0, 1),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: barColor ?? AppColors.warning,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class RatingBreakdown extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingCounts;

  const RatingBreakdown({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average Rating
        Column(
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            RatingStars(rating: averageRating, size: 18),
            const SizedBox(height: 4),
            Text(
              '$totalReviews reviews',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),

        // Breakdown Bars
        Expanded(
          child: Column(
            children: List.generate(5, (index) {
              final starNumber = 5 - index;
              final count = ratingCounts[starNumber] ?? 0;
              final percentage = totalReviews > 0 ? count / totalReviews : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: RatingBar(
                  starNumber: starNumber,
                  percentage: percentage,
                  count: count,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class RatingCard extends StatelessWidget {
  final String userName;
  final String? userPhoto;
  final double rating;
  final DateTime date;
  final String? comment;
  final List<String>? images;
  final VoidCallback? onReport;

  const RatingCard({
    super.key,
    required this.userName,
    this.userPhoto,
    required this.rating,
    required this.date,
    this.comment,
    this.images,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.grey200,
                backgroundImage:
                    userPhoto != null ? NetworkImage(userPhoto!) : null,
                child: userPhoto == null
                    ? Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        RatingStars(rating: rating, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onReport != null)
                IconButton(
                  onPressed: onReport,
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColors.grey500,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (comment != null && comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment!,
              style: TextStyle(
                color: AppColors.grey700,
                height: 1.4,
              ),
            ),
          ],
          if (images != null && images!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images!.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      images![index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }
}

class QuickRating extends StatelessWidget {
  final double rating;
  final Color? color;
  final bool showStar;

  const QuickRating({
    super.key,
    required this.rating,
    this.color,
    this.showStar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? AppColors.warning).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStar) ...[
            Icon(
              Icons.star,
              size: 12,
              color: color ?? AppColors.warning,
            ),
            const SizedBox(width: 2),
          ],
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
