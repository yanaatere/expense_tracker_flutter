import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import '../../../core/theme/app_colors_theme.dart';

// ---------------------------------------------------------------------------
// Categories Screen
// ---------------------------------------------------------------------------

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _type = 'income';

  void _openSubcategories(BuildContext context, String categoryName) {
    final subs = localSubcategories(categoryName, type: _type);
    final color = categoryColor(categoryName, type: _type);
    final iconPath = categoryIconPath(categoryName, type: _type);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubCategorySheet(
        categoryName: categoryName,
        subs: subs,
        color: color,
        iconPath: iconPath,
        type: _type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = localCategories(type: _type);

    return Scaffold(
body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, size: 28),
                    color: context.appColors.labelText,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Categories',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.labelText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Income / Expense toggle ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: context.appColors.cardBg,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: [
                    _ToggleTab(
                      label: 'Income',
                      selected: _type == 'income',
                      onTap: () => setState(() => _type = 'income'),
                    ),
                    _ToggleTab(
                      label: 'Expense',
                      selected: _type == 'expense',
                      onTap: () => setState(() => _type = 'expense'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Category list ────────────────────────────────────────────────
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Text(
                          'Category',
                          style: GoogleFonts.urbanist(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.appColors.labelText,
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 0.5, color: context.appColors.inputBorder),
                      // List
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: categories.length,
                          separatorBuilder: (_, i) => Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 56,
                            color: context.appColors.inputBorder,
                          ),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final name = cat['name'] as String;
                            final color = categoryColor(name, type: _type, fallbackIndex: index);
                            final iconPath = categoryIconPath(name, type: _type);

                            return _CategoryRow(
                              name: name,
                              color: color,
                              iconPath: iconPath,
                              onTap: () => _openSubcategories(context, name),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category row with colored left accent bar
// ---------------------------------------------------------------------------

class _CategoryRow extends StatelessWidget {
  final String name;
  final Color color;
  final String? iconPath;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.name,
    required this.color,
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            // Colored left accent bar
            Container(
              width: 4,
              height: 56,
              color: color,
            ),
            SizedBox(width: 16),
            // Icon
            SizedBox(
              width: 28,
              height: 28,
              child: iconPath != null
                  ? Image.asset(
                      iconPath!,
                      fit: BoxFit.contain,
                      color: color,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (_, e, st) => Icon(
                        Icons.category_rounded,
                        size: 22,
                        color: color,
                      ),
                    )
                  : Icon(Icons.category_rounded, size: 22, color: color),
            ),
            SizedBox(width: 12),
            // Name
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.labelText,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: context.appColors.placeholderText,
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-category bottom sheet
// ---------------------------------------------------------------------------

class _SubCategorySheet extends StatelessWidget {
  final String categoryName;
  final List<Map<String, dynamic>> subs;
  final Color color;
  final String? iconPath;
  final String type;

  const _SubCategorySheet({
    required this.categoryName,
    required this.subs,
    required this.color,
    required this.iconPath,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.appColors.inputBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),

          // Header: icon + category name
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: iconPath != null
                      ? Image.asset(
                          iconPath!,
                          fit: BoxFit.contain,
                          color: color,
                          colorBlendMode: BlendMode.srcIn,
                          errorBuilder: (_, e, st) => Icon(
                            Icons.category_rounded,
                            size: 22,
                            color: color,
                          ),
                        )
                      : Icon(Icons.category_rounded, size: 22, color: color),
                ),
                SizedBox(width: 10),
                Text(
                  categoryName,
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.labelText,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),
          Divider(height: 1, thickness: 0.5, color: context.appColors.inputBorder),

          // Sub-category list
          Flexible(
            child: ListView.separated(
              padding: EdgeInsets.only(bottom: 24),
              shrinkWrap: true,
              itemCount: subs.length,
              separatorBuilder: (_, i) => Divider(
                height: 1,
                thickness: 0.5,
                indent: 56,
                color: context.appColors.inputBorder,
              ),
              itemBuilder: (context, index) {
                final sub = subs[index];
                final name = sub['name'] as String;
                final subIconPath = subCategoryIconPath(name, type: type);

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: subIconPath != null
                            ? Image.asset(
                                subIconPath,
                                fit: BoxFit.contain,
                                color: color,
                                colorBlendMode: BlendMode.srcIn,
                                errorBuilder: (_, e, st) => Icon(
                                  Icons.label_rounded,
                                  size: 20,
                                  color: color,
                                ),
                              )
                            : Icon(
                                Icons.label_rounded,
                                size: 20,
                                color: color,
                              ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        name,
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: context.appColors.labelText,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle tab
// ---------------------------------------------------------------------------

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(36),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : context.appColors.placeholderText,
            ),
          ),
        ),
      ),
    );
  }
}
