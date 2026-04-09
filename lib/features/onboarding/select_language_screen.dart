import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/storage/local_storage.dart';
import '../../service_locator.dart';
import '../../shared/widgets/primary_button.dart';

class SelectLanguageScreen extends StatefulWidget {
  const SelectLanguageScreen({super.key});

  @override
  State<SelectLanguageScreen> createState() => _SelectLanguageScreenState();
}

class _SelectLanguageScreenState extends State<SelectLanguageScreen> {
  String _selectedCode = 'en';

  static const _languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'id', 'label': 'Bahasa Indonesia'},
  ];

  Future<void> _onLanguageChanged(String? code) async {
    if (code == null) return;
    setState(() => _selectedCode = code);
    ServiceLocator.localeNotifier.value = Locale(code);
    await LocalStorage.saveLocale(code);
  }

  @override
  void initState() {
    super.initState();
    _selectedCode = ServiceLocator.localeNotifier.value.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(l10n.selectLanguage, style: AppTextStyles.heading),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                initialValue: _selectedCode,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _languages
                    .map((lang) => DropdownMenuItem<String>(
                          value: lang['code'],
                          child: Text(lang['label']!),
                        ))
                    .toList(),
                onChanged: _onLanguageChanged,
              ),
              const Spacer(),
              PrimaryButton(
                label: l10n.next,
                onPressed: () => context.go('/onboarding/wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
