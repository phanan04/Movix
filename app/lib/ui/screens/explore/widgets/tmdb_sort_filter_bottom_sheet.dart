import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TmdbSortFilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;
  final Function(Map<String, dynamic> filters)? onApply;

  const TmdbSortFilterBottomSheet({
    super.key,
    this.initialFilters,
    this.onApply,
  });

  static void show(
    BuildContext context, {
    Map<String, dynamic>? initialFilters,
    Function(Map<String, dynamic> filters)? onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TmdbSortFilterBottomSheet(
        initialFilters: initialFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<TmdbSortFilterBottomSheet> createState() => _TmdbSortFilterBottomSheetState();
}

class _TmdbSortFilterBottomSheetState extends State<TmdbSortFilterBottomSheet> {
  late String _selectedMediaType;
  late String _selectedSortBy;
  late String _selectedGenre;
  late String _selectedLanguage;
  late String _selectedYear;
  late double _selectedMinRating;

  bool _isGenreExpanded = false;

  // 1. Loại phương tiện TMDb
  final List<Map<String, String>> _mediaTypes = [
    {'name': 'Phim Điện Ảnh', 'id': 'movie'},
    {'name': 'Series / Phim Bộ', 'id': 'tv'},
  ];

  // 2. Tiêu chí sắp xếp TMDb Discover
  final List<Map<String, String>> _sortOptions = [
    {'name': 'Phổ biến nhất', 'id': 'popularity.desc'},
    {'name': 'Đánh giá cao nhất', 'id': 'vote_average.desc'},
    {'name': 'Nhiều bình chọn', 'id': 'vote_count.desc'},
    {'name': 'Mới phát hành', 'id': 'primary_release_date.desc'},
    {'name': 'Doanh thu cao', 'id': 'revenue.desc'},
  ];

  // 3. Toàn bộ 19 thể loại chuẩn TMDb
  final List<Map<String, String>> _genres = [
    {'name': 'Tất cả', 'id': 'all'},
    {'name': 'Hành Động', 'id': '28'},
    {'name': 'Phiêu Lưu', 'id': '12'},
    {'name': 'Hoạt Hình', 'id': '16'},
    {'name': 'Hài Hước', 'id': '35'},
    {'name': 'Tội Phạm', 'id': '80'},
    {'name': 'Tài Liệu', 'id': '99'},
    {'name': 'Chính Kịch', 'id': '18'},
    {'name': 'Gia Đình', 'id': '10751'},
    {'name': 'Giả Tưởng', 'id': '14'},
    {'name': 'Lịch Sử', 'id': '36'},
    {'name': 'Kinh Dị', 'id': '27'},
    {'name': 'Âm Nhạc', 'id': '10402'},
    {'name': 'Bí Ẩn', 'id': '9648'},
    {'name': 'Lãng Mạn', 'id': '10749'},
    {'name': 'Khoa Học Viễn Tưởng', 'id': '878'},
    {'name': 'Giật Gân', 'id': '53'},
    {'name': 'Chiến Tranh', 'id': '10752'},
    {'name': 'Miền Tây', 'id': '37'},
  ];

  // 4. Quốc gia / Ngôn ngữ gốc
  final List<Map<String, String>> _languages = [
    {'name': 'Tất cả', 'id': 'all'},
    {'name': 'Âu Mỹ (US/UK)', 'id': 'en'},
    {'name': 'Hàn Quốc', 'id': 'ko'},
    {'name': 'Nhật Bản', 'id': 'ja'},
    {'name': 'Trung Quốc', 'id': 'zh'},
    {'name': 'Thái Lan', 'id': 'th'},
    {'name': 'Pháp', 'id': 'fr'},
    {'name': 'Tây Ban Nha', 'id': 'es'},
    {'name': 'Đức', 'id': 'de'},
    {'name': 'Ấn Độ', 'id': 'hi'},
    {'name': 'Việt Nam', 'id': 'vi'},
  ];

  // 5. Năm phát hành
  final List<String> _years = [
    'all',
    '2026',
    '2025',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
    '2018',
    '2015',
    '2010',
    '2000',
    '1990',
  ];

  // 6. Điểm đánh giá tối thiểu
  final List<Map<String, dynamic>> _ratings = [
    {'name': 'Tất cả', 'val': 0.0},
    {'name': '8.0+ ★', 'val': 8.0},
    {'name': '7.0+ ★', 'val': 7.0},
    {'name': '6.0+ ★', 'val': 6.0},
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilters ?? {};
    _selectedMediaType = f['media_type']?.toString() ?? 'movie';
    _selectedSortBy = f['sort_by']?.toString() ?? 'popularity.desc';
    _selectedGenre = f['genre']?.toString() ?? 'all';
    _selectedLanguage = f['language']?.toString() ?? 'all';
    _selectedYear = f['year']?.toString() ?? 'all';
    _selectedMinRating = (f['min_rating'] is num) ? (f['min_rating'] as num).toDouble() : 0.0;
  }

  void _reset() {
    setState(() {
      _selectedMediaType = 'movie';
      _selectedSortBy = 'popularity.desc';
      _selectedGenre = 'all';
      _selectedLanguage = 'all';
      _selectedYear = 'all';
      _selectedMinRating = 0.0;
    });
  }

  void _apply() {
    widget.onApply?.call({
      'media_type': _selectedMediaType,
      'sort_by': _selectedSortBy,
      'genre': _selectedGenre,
      'language': _selectedLanguage,
      'year': _selectedYear,
      'min_rating': _selectedMinRating,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bộ Lọc TMDb Quốc Tế',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Filter Content Scrollable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              physics: const BouncingScrollPhysics(),
              children: [
                // 1. Loại phương tiện
                _buildSectionTitle('Loại hình'),
                _buildChipGroup<String>(
                  items: _mediaTypes,
                  selectedId: _selectedMediaType,
                  onSelected: (id) => setState(() => _selectedMediaType = id),
                ),
                const SizedBox(height: 18),

                // 2. Sắp xếp
                _buildSectionTitle('Sắp xếp theo'),
                _buildChipGroup<String>(
                  items: _sortOptions,
                  selectedId: _selectedSortBy,
                  onSelected: (id) => setState(() => _selectedSortBy = id),
                ),
                const SizedBox(height: 18),

                // 3. Thể loại
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Thể loại TMDb'),
                    InkWell(
                      onTap: () => setState(() => _isGenreExpanded = !_isGenreExpanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          _isGenreExpanded ? 'Thu gọn' : 'Xem thêm',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildChipGroup<String>(
                  items: _isGenreExpanded ? _genres : _genres.take(8).toList(),
                  selectedId: _selectedGenre,
                  onSelected: (id) => setState(() => _selectedGenre = id),
                ),
                const SizedBox(height: 18),

                // 4. Quốc gia / Ngôn ngữ
                _buildSectionTitle('Quốc gia / Ngôn ngữ'),
                _buildChipGroup<String>(
                  items: _languages,
                  selectedId: _selectedLanguage,
                  onSelected: (id) => setState(() => _selectedLanguage = id),
                ),
                const SizedBox(height: 18),

                // 5. Năm phát hành
                _buildSectionTitle('Năm phát hành'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _years.map((y) {
                      final isSelected = _selectedYear == y;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(y == 'all' ? 'Tất cả' : (y.endsWith('0') && int.parse(y) < 2010 ? '${y}s' : y)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedYear = y),
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                              width: 0.8,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // 6. Điểm đánh giá tối thiểu
                _buildSectionTitle('Điểm đánh giá tối thiểu'),
                Row(
                  children: _ratings.map((r) {
                    final val = r['val'] as double;
                    final isSelected = _selectedMinRating == val;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(r['name'].toString()),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedMinRating = val),
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                            width: 0.8,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 0.8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Đặt lại',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Áp dụng bộ lọc',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildChipGroup<T>({
    required List<Map<String, String>> items,
    required String selectedId,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final id = item['id']!;
        final name = item['name']!;
        final isSelected = selectedId == id;

        return ChoiceChip(
          label: Text(name),
          selected: isSelected,
          onSelected: (_) => onSelected(id),
          selectedColor: AppColors.primary,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
              width: 0.8,
            ),
          ),
        );
      }).toList(),
    );
  }
}
