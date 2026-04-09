import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import 'cubit/budget_cubit.dart';
import '../../../core/theme/app_colors_theme.dart';

class AddBudgetSheet extends StatefulWidget {
  const AddBudgetSheet({super.key});

  @override
  State<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<AddBudgetSheet> {
  String? _selectedCategory;
  final _amountController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cat = _selectedCategory;
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (cat == null || amount == null || amount <= 0) return;

    setState(() => _saving = true);
    await context.read<BudgetCubit>().add(cat, amount);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = expenseCategories;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomPad),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.inputBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Text(
            'Set Budget',
            style: GoogleFonts.urbanist(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.appColors.labelText,
            ),
          ),
          const SizedBox(height: 20),

          // Category picker
          Text(
            'Category',
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.appColors.placeholderText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: context.appColors.inputBg,
              borderRadius: BorderRadius.circular(40),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                hint: Text(
                  'Select category',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    color: context.appColors.placeholderText,
                  ),
                ),
                isExpanded: true,
                items: categories.map((cat) {
                  final name = cat['name'] as String;
                  final color = categoryColor(name, type: 'expense');
                  final iconPath = categoryIconPath(name, type: 'expense');
                  return DropdownMenuItem(
                    value: name,
                    child: Row(
                      children: [
                        if (iconPath != null) ...[
                          Image.asset(
                            iconPath,
                            width: 20,
                            height: 20,
                            color: color,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          name,
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            color: context.appColors.labelText,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Monthly limit
          Text(
            'Monthly Limit (IDR)',
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.appColors.placeholderText,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.urbanist(fontSize: 14, color: context.appColors.labelText),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: GoogleFonts.urbanist(color: context.appColors.placeholderText),
              filled: true,
              fillColor: context.appColors.inputBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
