import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SortFilterBottomSheet extends StatefulWidget {
  final Map<String, String>? initialFilters;
  final Function(Map<String, String> filters)? onApply;

  const SortFilterBottomSheet({
    super.key,
    this.initialFilters,
    this.onApply,
  });

  static void show(
    BuildContext context, {
    Map<String, String>? initialFilters,
    Function(Map<String, String> filters)? onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SortFilterBottomSheet(
        initialFilters: initialFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<SortFilterBottomSheet> createState() => _SortFilterBottomSheetState();
}

class _SortFilterBottomSheetState extends State<SortFilterBottomSheet> {
  late String _selectedSortField;
  late String _selectedSortType;
  late String _selectedLang;
  late String _selectedType;
  late String _selectedCategory;
  late String _selectedRegion;
  late String _selectedYear;

  bool _isCategoryExpanded = false;

  // 1. Tiêu chí sắp xếp chuẩn KKPhim + Movix
  final List<Map<String, String>> _sortFields = [
    {'name': 'Thời gian cập nhật', 'id': 'modified.time'},
    {'name': 'Thời gian đăng', 'id': '_id'},
    {'name': 'Năm sản xuất', 'id': 'year'},
    {'name': 'Phổ biến nhất', 'id': 'popular'},
    {'name': 'Điểm đánh giá cao', 'id': 'rating'},
  ];

  // 2. Ngôn ngữ / Định dạng chuẩn KKPhim
  final List<Map<String, String>> _languages = [
    {'name': 'Tất cả', 'slug': 'all'},
    {'name': 'Vietsub', 'slug': 'vietsub'},
    {'name': 'Thuyết minh', 'slug': 'thuyet-minh'},
    {'name': 'Lồng tiếng', 'slug': 'long-tieng'},
  ];

  // 3. Loại danh sách phim KKPhim
  final List<Map<String, String>> _types = [
    {'name': 'Tất cả', 'slug': 'all'},
    {'name': 'Phim Lẻ', 'slug': 'phim-le'},
    {'name': 'Phim Bộ', 'slug': 'phim-bo'},
    {'name': 'Phim Chiếu Rạp', 'slug': 'phim-chieu-rap'},
    {'name': 'Hoạt Hình', 'slug': 'hoat-hinh'},
    {'name': 'TV Shows', 'slug': 'tv-shows'},
  ];

  // 4. Đầy đủ 26 thể loại chuẩn KKPhim
  final List<Map<String, String>> _categories = [
    {'name': 'Tất cả', 'slug': 'all'},
    {'name': 'Âm Nhạc', 'slug': 'am-nhac'},
    {'name': 'Bí Ẩn', 'slug': 'bi-an'},
    {'name': 'Chiến Tranh', 'slug': 'chien-tranh'},
    {'name': 'Chính Kịch', 'slug': 'chinh-kich'},
    {'name': 'Cổ Trang', 'slug': 'co-trang'},
    {'name': 'Gia Đình', 'slug': 'gia-dinh'},
    {'name': 'Hài Hước', 'slug': 'hai-huoc'},
    {'name': 'Hành Động', 'slug': 'hanh-dong'},
    {'name': 'Hình Sự', 'slug': 'hinh-su'},
    {'name': 'Học Đường', 'slug': 'hoc-duong'},
    {'name': 'Khoa Học', 'slug': 'khoa-hoc'},
    {'name': 'Kinh Dị', 'slug': 'kinh-di'},
    {'name': 'Kinh Điển', 'slug': 'kinh-dien'},
    {'name': 'Lịch Sử', 'slug': 'lich-su'},
    {'name': 'Miền Tây', 'slug': 'mien-tay'},
    {'name': 'Phim 18+', 'slug': 'phim-18'},
    {'name': 'Phim Ngắn', 'slug': 'phim-ngan'},
    {'name': 'Phiêu Lưu', 'slug': 'phieu-luu'},
    {'name': 'Tài Liệu', 'slug': 'tai-lieu'},
    {'name': 'Tâm Lý', 'slug': 'tam-ly'},
    {'name': 'Thần Thoại', 'slug': 'than-thoai'},
    {'name': 'Thể Thao', 'slug': 'the-thao'},
    {'name': 'Tình Cảm', 'slug': 'tinh-cam'},
    {'name': 'Trẻ Em', 'slug': 'tre-em'},
    {'name': 'Viễn Tưởng', 'slug': 'vien-tuong'},
    {'name': 'Võ Thuật', 'slug': 'vo-thuat'},
  ];

  // 5. Đầy đủ 36 quốc gia chuẩn KKPhim
  final List<Map<String, String>> _regions = [
    {'name': 'Tất cả', 'slug': 'all'},
    {'name': 'Anh', 'slug': 'anh'},
    {'name': 'Ba Lan', 'slug': 'ba-lan'},
    {'name': 'Brazil', 'slug': 'brazil'},
    {'name': 'Bồ Đào Nha', 'slug': 'bo-dao-nha'},
    {'name': 'Canada', 'slug': 'canada'},
    {'name': 'Châu Phi', 'slug': 'chau-phi'},
    {'name': 'Hà Lan', 'slug': 'ha-lan'},
    {'name': 'Hàn Quốc', 'slug': 'han-quoc'},
    {'name': 'Hồng Kông', 'slug': 'hong-kong'},
    {'name': 'Indonesia', 'slug': 'indonesia'},
    {'name': 'Malaysia', 'slug': 'malaysia'},
    {'name': 'Mexico', 'slug': 'mexico'},
    {'name': 'Na Uy', 'slug': 'na-uy'},
    {'name': 'Nam Phi', 'slug': 'nam-phi'},
    {'name': 'Nga', 'slug': 'nga'},
    {'name': 'Nhật Bản', 'slug': 'nhat-ban'},
    {'name': 'Philippines', 'slug': 'philippines'},
    {'name': 'Pháp', 'slug': 'phap'},
    {'name': 'Quốc Gia Khác', 'slug': 'quoc-gia-khac'},
    {'name': 'Thái Lan', 'slug': 'thai-lan'},
    {'name': 'Thổ Nhĩ Kỳ', 'slug': 'tho-nhi-ky'},
    {'name': 'Thụy Sĩ', 'slug': 'thuy-si'},
    {'name': 'Thụy Điển', 'slug': 'thuy-dien'},
    {'name': 'Trung Quốc', 'slug': 'trung-quoc'},
    {'name': 'Tây Ban Nha', 'slug': 'tay-ban-nha'},
    {'name': 'UAE', 'slug': 'uae'},
    {'name': 'Ukraina', 'slug': 'ukraina'},
    {'name': 'Việt Nam', 'slug': 'viet-nam'},
    {'name': 'Âu Mỹ', 'slug': 'au-my'},
    {'name': 'Úc', 'slug': 'uc'},
    {'name': 'Ý', 'slug': 'y'},
    {'name': 'Đan Mạch', 'slug': 'dan-mach'},
    {'name': 'Đài Loan', 'slug': 'dai-loan'},
    {'name': 'Đức', 'slug': 'duc'},
    {'name': 'Ả Rập Xê Út', 'slug': 'a-rap-xe-ut'},
    {'name': 'Ấn Độ', 'slug': 'an-do'},
  ];

  // 6. Đầy đủ các năm từ 2026 về 1970
  static final List<String> _years = [
    'Tất cả',
    for (int y = 2026; y >= 1970; y--) y.toString(),
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialFilters ?? {};
    _selectedSortField = init['sort_field'] ?? 'modified.time';
    _selectedSortType = init['sort_type'] ?? 'desc';
    _selectedLang = init['lang'] ?? 'all';
    _selectedType = init['type'] ?? 'all';
    _selectedCategory = init['category'] ?? 'all';
    _selectedRegion = init['region'] ?? 'all';
    _selectedYear = init['year'] ?? 'all';
  }

  void _reset() {
    setState(() {
      _selectedSortField = 'modified.time';
      _selectedSortType = 'desc';
      _selectedLang = 'all';
      _selectedType = 'all';
      _selectedCategory = 'all';
      _selectedRegion = 'all';
      _selectedYear = 'all';
    });
  }

  void _apply() {
    Navigator.pop(context);
    widget.onApply?.call({
      'sort_field': _selectedSortField,
      'sort_type': _selectedSortType,
      'lang': _selectedLang,
      'type': _selectedType,
      'category': _selectedCategory,
      'region': _selectedRegion,
      'year': _selectedYear,
    });
  }

  @override
  Widget build(BuildContext context) {
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
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                'Lọc Phim (Chuẩn KKPhim)',
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

                // 1. Sắp xếp: Radio field + Dropdown sort order (Mới nhất / Cũ nhất)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Sắp xếp'),
                    // Dropdown Mới nhất / Cũ nhất
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSortType,
                          isDense: true,
                          dropdownColor: AppColors.surface,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 20),
                          items: const [
                            DropdownMenuItem(
                              value: 'desc',
                              child: Text('Mới nhất', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            DropdownMenuItem(
                              value: 'asc',
                              child: Text('Cũ nhất', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSortType = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildHorizontalChips(
                  _sortFields.map((field) {
                    final isSel = _selectedSortField == field['id'];
                    return _buildRadioChip(field['name']!, isSel, () {
                      setState(() => _selectedSortField = field['id']!);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 2. Ngôn ngữ / Định dạng
                _buildSectionTitle('Ngôn ngữ'),
                _buildHorizontalChips(
                  _languages.map((lang) {
                    final isSel = _selectedLang == lang['slug'];
                    return _buildChip(lang['name']!, isSel, () {
                      setState(() => _selectedLang = lang['slug']!);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 3. Loại danh mục phim
                _buildSectionTitle('Loại phim'),
                _buildHorizontalChips(
                  _types.map((type) {
                    final isSel = _selectedType == type['slug'];
                    return _buildChip(type['name']!, isSel, () {
                      setState(() => _selectedType = type['slug']!);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 4. Thể loại phim (26 thể loại)
                _buildSectionTitle('Thể loại (26 thể loại)'),
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
                      return _buildChip(
                        isExpanded ? 'Thu gọn' : '+ Xem thêm (${_categories.length - defaultVisibleCount})',
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
                const SizedBox(height: 16),

                // 5. Quốc gia & Khu vực (36 quốc gia)
                _buildSectionTitle('Quốc gia (36 quốc gia)'),
                _buildHorizontalChips(
                  _regions.map((reg) {
                    final isSel = _selectedRegion == reg['slug'];
                    return _buildChip(reg['name']!, isSel, () {
                      setState(() => _selectedRegion = reg['slug']!);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 6. Năm sản xuất (1970 - 2026)
                _buildSectionTitle('Năm sản xuất (1970 - 2026)'),
                _buildHorizontalChips(
                  _years.map((yr) {
                    final isSel = _selectedYear == yr;
                    return _buildChip(yr, isSel, () {
                      setState(() => _selectedYear = yr);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Bottom Action Buttons: Đóng & Lọc (Đúng như ảnh KKPhim)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Lọc',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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

  Widget _buildRadioChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 15,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
