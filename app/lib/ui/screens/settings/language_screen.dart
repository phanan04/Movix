import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLang = 'vi';

  final List<Map<String, String>> _languages = [
    {'code': 'vi', 'name': 'Tiếng Việt', 'subtitle': 'Ngôn ngữ hiển thị chính'},
    {'code': 'en_us', 'name': 'English (US)', 'subtitle': 'United States'},
    {'code': 'en_uk', 'name': 'English (UK)', 'subtitle': 'United Kingdom'},
    {'code': 'zh_cn', 'name': 'Chữ Hán giản thể', 'subtitle': '简体中文'},
    {'code': 'zh_tw', 'name': 'Chữ Hán phồn thể', 'subtitle': '繁體中文'},
    {'code': 'ko', 'name': 'Tiếng Hàn', 'subtitle': '한국어'},
    {'code': 'ja', 'name': 'Tiếng Nhật', 'subtitle': '日本語'},
    {'code': 'fr', 'name': 'Tiếng Pháp', 'subtitle': 'Français'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chọn ngôn ngữ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _languages.length,
        separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
        itemBuilder: (context, index) {
          final l = _languages[index];
          final isSelected = _selectedLang == l['code'];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            title: Text(
              l['name']!,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              l['subtitle']!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: isSelected
                ? const Icon(Icons.radio_button_checked, color: AppColors.primary)
                : const Icon(Icons.radio_button_off, color: AppColors.textMuted),
            onTap: () {
              setState(() {
                _selectedLang = l['code']!;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã chọn ngôn ngữ: ${l['name']}')),
              );
            },
          );
        },
      ),
    );
  }
}
