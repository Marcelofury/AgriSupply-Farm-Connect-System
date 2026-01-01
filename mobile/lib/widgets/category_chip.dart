import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/product_model.dart';

class CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showIcon;
  final bool isLarge;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
    this.showIcon = true,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 16 : 12,
          vertical: isLarge ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.grey300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Text(
                ProductCategory.getIcon(category),
                style: TextStyle(fontSize: isLarge ? 18 : 14),
              ),
              SizedBox(width: isLarge ? 8 : 6),
            ],
            Text(
              category,
              style: TextStyle(
                fontSize: isLarge ? 14 : 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryChipList extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String>? onCategorySelected;
  final bool showAllOption;
  final bool showIcons;
  final bool isLarge;
  final EdgeInsets padding;

  const CategoryChipList({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.onCategorySelected,
    this.showAllOption = true,
    this.showIcons = true,
    this.isLarge = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final allCategories = showAllOption ? ['All', ...categories] : categories;

    return SizedBox(
      height: isLarge ? 48 : 40,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: allCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isSelected = category == selectedCategory ||
              (selectedCategory == null && category == 'All');

          return CategoryChip(
            category: category,
            isSelected: isSelected,
            showIcon: showIcons && category != 'All',
            isLarge: isLarge,
            onTap: () => onCategorySelected?.call(category),
          );
        },
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String category;
  final VoidCallback? onTap;
  final int productCount;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.productCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                ProductCategory.getIcon(category),
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              category,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (productCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$productCount products',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CategoryGrid extends StatelessWidget {
  final List<String> categories;
  final ValueChanged<String>? onCategorySelected;
  final Map<String, int>? productCounts;
  final int crossAxisCount;
  final double spacing;

  const CategoryGrid({
    super.key,
    required this.categories,
    this.onCategorySelected,
    this.productCounts,
    this.crossAxisCount = 3,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 0.9,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          category: category,
          productCount: productCounts?[category] ?? 0,
          onTap: () => onCategorySelected?.call(category),
        );
      },
    );
  }
}

class FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? selectedColor;

  const FilterChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.primaryGreen;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.grey300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : AppColors.grey600,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : AppColors.grey700,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check,
                size: 14,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onRemove;

  const TagChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: chipColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 14,
                color: chipColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
