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

  bool _isCategoryExpanded = false;

  // Loại phim & Định dạng (Đã loại bỏ chip 'Hoạt Hình' trùng lặp)
  final List<Map<String, String>> _types = [
    {'name': 'Tất cả', 'slug': 'all'},
    {'name': 'Phim Lẻ', 'slug': 'phim-le'},
    {'name': 'Phim Bộ', 'slug': 'phim-bo'},
    {'name': 'Phim Chiếu Rạp', 'slug': 'phim-chieu-rap'},
    {'name': 'TV Shows', 'slug': 'tv-shows'},
  ];

  // Thể loại phim (Đã sắp xếp thứ tự A-Z sau nút 'Tất cả')
  final List<Map<String, String>> _categories = [
    {'name': 'Tất cả', 'slug': 'all'},
    {'name': 'Bí Ẩn', 'slug': 'bi-an'},
    {'name': 'Cổ Trang', 'slug': 'co-trang'},
    {'name': 'Gia Đình', 'slug': 'gia-dinh'},
    {'name': 'Hài Hước', 'slug': 'hai-huoc'},
    {'name': 'Hành Động', 'slug': 'hanh-dong'},
    {'name': 'Hoạt Hình', 'slug': 'hoat-hinh'},
    {'name': 'Học Đường', 'slug': 'hoc-duong'},
    {'name': 'Kinh Dị', 'slug': 'kinh-di'},
    {'name': 'Phiêu Lưu', 'slug': 'phieu-luu'},
    {'name': 'Tài Liệu', 'slug': 'tai-lieu'},
    {'name': 'Tâm Lý', 'slug': 'tam-ly'},
    {'name': 'Thần Thoại', 'slug': 'than-thoai'},
    {'name': 'Tình Cảm', 'slug': 'tinh-cam'},
    {'name': 'Viễn Tưởng', 'slug': 'vien-tuong'},
    {'name': 'Võ Thuật', 'slug': 'vo-thuat'},
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
  }

  @override
  Widget build(BuildContext context) {
    // Categories display slice: 2 rows in 3 columns (5 items + 1 Xem thêm = 6 cells) or all
    const defaultVisibleCount = 5;
    final isSelectedBeyondVisible = !_isCategoryExpanded &&
        _selectedCategory != 'all' &&
        _categories.indexWhere((c) => c['slug'] == _selectedCategory) >= defaultVisibleCount;

    final isExpanded = _isCategoryExpanded || isSelectedBeyondVisible;
    final visibleCategories = isExpanded
        ? _categories
        : _categories.take(defaultVisibleCount).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

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
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 14),

                // 1. Sort By (1 hàng cuộn ngang - SingleChildScrollView Axis.horizontal)
                _buildSectionTitle('Sắp xếp theo'),
                _buildHorizontalChips(
                  _sortOptions.map((opt) {
                    final isSel = _selectedSort == opt['id'];
                    return _buildChip(opt['name']!, isSel, () {
                      setState(() => _selectedSort = opt['id']!);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // 2. Movie Type (1 hàng cuộn ngang, đã xóa Hoạt hình)
                _buildSectionTitle('Loại phim & Định dạng'),
                _buildHorizontalChips(
                  _types.map((type) {
                    final isSel = _selectedType == type['slug'];
                    return _buildChip(type['name']!, isSel, () {
                      setState(() => _selectedType = type['slug']!);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // 3. Categories (Grid 3 cột, sắp xếp A-Z, mặc định 2 hàng + chip Xem thêm)
                _buildSectionTitle('Thể loại phim'),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisExtent: 34,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: visibleCategories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == visibleCategories.length) {
                      // Nút "+ Xem thêm" / "Thu gọn"
                      return _buildChip(
                        isExpanded ? 'Thu gọn' : '+ Xem thêm',
                        false,
                        () {
                          setState(() {
                            _isCategoryExpanded = !isExpanded;
                          });
                        },
                        isAction: true,
                        inGrid: true,
                        icon: isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                      );
                    }

                    final cat = visibleCategories[index];
                    final isSel = _selectedCategory == cat['slug'];
                    return _buildChip(
                      cat['name']!,
                      isSel,
                      () {
                        setState(() => _selectedCategory = cat['slug']!);
                      },
                      inGrid: true,
                    );
                  },
                ),
                const SizedBox(height: 18),

                // 4. Regions (1 hàng cuộn ngang - SingleChildScrollView Axis.horizontal)
                _buildSectionTitle('Quốc gia & Khu vực'),
                _buildHorizontalChips(
                  _regions.map((reg) {
                    final isSel = _selectedRegion == reg['slug'];
                    return _buildChip(reg['name']!, isSel, () {
                      setState(() => _selectedRegion = reg['slug']!);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // 5. Years (1 hàng cuộn ngang - SingleChildScrollView Axis.horizontal)
                _buildSectionTitle('Năm phát hành'),
                _buildHorizontalChips(
                  _years.map((yr) {
                    final isSel = _selectedYear == yr;
                    return _buildChip(yr, isSel, () {
                      setState(() => _selectedYear = yr);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 18),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  /// 1 hàng cuộn ngang duy nhất với khoảng cách giữa các chip là 8px
  Widget _buildHorizontalChips(List<Widget> chips) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: chips.asMap().entries.map((entry) {
          final isLast = entry.key == chips.length - 1;
          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: entry.value,
          );
        }).toList(),
      ),
    );
  }

  /// Đồng bộ chiều cao tất cả các chip là 34px, padding ngang 14px (hoặc 8px khi trong grid), bo góc 20px
  Widget _buildChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    bool isAction = false,
    IconData? icon,
    bool inGrid = false,
  }) {
    final textWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isAction
            ? AppColors.primary
            : (isSelected ? Colors.white : AppColors.textSecondary),
        fontSize: 12,
        fontWeight: isSelected || isAction ? FontWeight.bold : FontWeight.w500,
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 34,
        padding: EdgeInsets.symmetric(horizontal: inGrid ? 8 : 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isAction
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isSelected ? AppColors.primary : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAction
                ? AppColors.primary.withValues(alpha: 0.6)
                : (isSelected ? AppColors.primary : AppColors.border),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: inGrid ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (inGrid)
              Flexible(child: textWidget)
            else
              textWidget,
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(
                icon,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
