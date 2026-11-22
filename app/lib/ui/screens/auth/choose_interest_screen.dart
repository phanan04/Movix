import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'fill_profile_screen.dart';

class ChooseInterestScreen extends StatefulWidget {
  const ChooseInterestScreen({super.key});

  @override
  State<ChooseInterestScreen> createState() => _ChooseInterestScreenState();
}

class _ChooseInterestScreenState extends State<ChooseInterestScreen> {
  final List<String> _interests = [
    'Hành Động',
    'Phiêu Lưu',
    'Hài Hước',
    'Kinh Dị',
    'Viễn Tưởng',
    'Tình Cảm',
    'Hoạt Hình',
    'Cổ Trang',
    'Võ Thuật',
    'Tâm Lý',
    'Chiến Tranh',
    'Hình Sự',
    'Tài Liệu',
    'Thể Thao',
    'Âm Nhạc',
    'Thần Thoại',
    'Bí Ẩn',
    'Chính Kịch',
    'Gia Đình',
    'Học Đường',
    'Khoa Học',
    'Kinh Điển',
    'Lịch Sử',
    'Miền Tây',
    'Phim 18+',
    'Phim Ngắn',
    'Trẻ Em',
  ];

  final Set<String> _selected = {'Hành Động', 'Viễn Tưởng', 'Hoạt Hình'};

  void _onNext() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FillProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Chọn thể loại yêu thích',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hãy chọn ít nhất 3 thể loại bạn quan tâm nhất để Movix đề xuất phim chuẩn xác cho bạn.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Wrap of Interest Chips
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: _interests.map((interest) {
                      final isSelected = _selected.contains(interest);
                      return FilterChip(
                        label: Text(interest),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selected.add(interest);
                            } else {
                              _selected.remove(interest);
                            }
                          });
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Bottom Buttons: Skip & Continue
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _onNext,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: const Text('Bỏ qua', style: TextStyle(color: Colors.white, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Tiếp tục', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
