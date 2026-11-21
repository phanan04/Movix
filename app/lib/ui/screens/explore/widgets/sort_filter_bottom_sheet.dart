import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SortFilterBottomSheet extends StatefulWidget {
  final Function(Map<String, String> filters)? onApply;

  const SortFilterBottomSheet({super.key, this.onApply});

  static void show(BuildContext context, {Function(Map<String, String> filters)? onApply}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SortFilterBottomSheet(onApply: onApply),
    );
  }

  @override
  State<SortFilterBottomSheet> createState() => _SortFilterBottomSheetState();
}

class _SortFilterBottomSheetState extends State<SortFilterBottomSheet> {
  String _selectedSort = 'latest';
  String _selectedType = 'all';
  String _selectedCategory = 'all';
  String _selectedRegion = 'all';
  String _selectedYear = 'all';

  final List<Map<String, String>> _types = [
    {'name': 'Tất cả', 'slug': 'all'},
    {'name': 'Phim Lẻ', 'slug': 'phim-le'},
    {'name': 'Phim Bộ', 'slug': 'phim-bo'},
    {'name': 'Phim Chiếu Rạp', 'slug': 'phim-chieu-rap'},
    {'name': 'Hoạt Hình', 'slug': 'hoat-hinh'},
    {'name': 'TV Shows', 'slug': 'tv-shows'},
  ];

  final List<Map<String, String>> _categories = [
    {'name': 'Tất cả', 'slug': 'all'},
    {'name': 'Hành Động', 'slug': 'hanh-dong'},
    {'name': 'Cổ Trang', 'slug': 'co-trang'},
    {'name': 'Viễn Tưởng', 'slug': 'vien-tuong'},
    {'name': 'Kinh Dị', 'slug': 'kinh-di'},
    {'name': 'Tình Cảm', 'slug': 'tinh-cam'},
    {'name': 'Hài Hước', 'slug': 'hai-huoc'},
    {'name': 'Hoạt Hình', 'slug': 'hoat-hinh'},
    {'name': 'Tâm Lý', 'slug': 'tam-ly'},
    {'name': 'Võ Thuật', 'slug': 'vo-thuat'},
    {'name': 'Phiêu Lưu', 'slug': 'phieu-luu'},
    {'name': 'Thần Thoại', 'slug': 'than-thoai'},
    {'name': 'Học Đường', 'slug': 'hoc-duong'},
    {'name': 'Gia Đình', 'slug': 'gia-dinh'},
    {'name': 'Tài Liệu', 'slug': 'tai-lieu'},
    {'name': 'Bí Ẩn', 'slug': 'bi-an'},
  ];

  final List<Map<String, String>> _regions = [
    {'name': 'Tất cả', 'slug': 'all'},
    {'name': 'Hàn Quốc', 'slug': 'han-quoc'},
    {'name': 'Trung Quốc', 'slug': 'trung-quoc'},
    {'name': 'Âu Mỹ', 'slug': 'au-my'},
    {'name': 'Việt Nam', 'slug': 'viet-nam'},
    {'name': 'Nhật Bản', 'slug': 'nhat-ban'},
  ];

  final List<String> _years = [
    'Tất cả',
    '2026',
    '2025',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
    'Trước 2019',
  ];

  final List<Map<String, String>> _sortOptions = [
    {'name': 'Mới cập nhật', 'id': 'latest'},
    {'name': 'Phổ biến nhất', 'id': 'popular'},
    {'name': 'Điểm đánh giá cao', 'id': 'rating'},
  ];

  void _reset() {
    setState(() {
      _selectedSort = 'latest';
      _selectedType = 'all';
      _selectedCategory = 'all';
      _selectedRegion = 'all';
      _selectedYear = 'all';
    });
  }

  void _apply() {
    Navigator.pop(context);
    widget.onApply?.call({
      'sort': _selectedSort,
      'type': _selectedType,
      'category': _selectedCategory,
      'region': _selectedRegion,
      'year': _selectedYear,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã áp dụng bộ lọc phim')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sắp xếp & Bộ lọc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: _reset,
                child: const Text(
                  'Đặt lại',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 14),
                // 1. Sort By
                _buildSectionTitle('Sắp xếp theo'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sortOptions.map((opt) {
                    final isSel = _selectedSort == opt['id'];
                    return _buildChip(opt['name']!, isSel, () {
                      setState(() => _selectedSort = opt['id']!);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 1.5. Movie Type (Định dạng / Loại phim)
                _buildSectionTitle('Loại phim & Định dạng'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types.map((type) {
                    final isSel = _selectedType == type['slug'];
                    return _buildChip(type['name']!, isSel, () {
                      setState(() => _selectedType = type['slug']!);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 2. Categories
                _buildSectionTitle('Thể loại phim'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSel = _selectedCategory == cat['slug'];
                    return _buildChip(cat['name']!, isSel, () {
                      setState(() => _selectedCategory = cat['slug']!);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 3. Regions
                _buildSectionTitle('Quốc gia & Khu vực'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _regions.map((reg) {
                    final isSel = _selectedRegion == reg['slug'];
                    return _buildChip(reg['name']!, isSel, () {
                      setState(() => _selectedRegion = reg['slug']!);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 4. Years
                _buildSectionTitle('Năm phát hành'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _years.map((yr) {
                    final isSel = _selectedYear == yr;
                    return _buildChip(yr, isSel, () {
                      setState(() => _selectedYear = yr);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: const Text(
                'Áp dụng bộ lọc',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
