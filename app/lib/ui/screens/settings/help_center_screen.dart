import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _faqs = [
    {
      'q': 'Movix là ứng dụng gì?',
      'a': 'Movix là ứng dụng giải trí xem phim trực tuyến chất lượng cao, cung cấp hàng ngàn bộ phim lẻ, phim bộ, phim chiếu rạp và anime hoàn toàn miễn phí với máy chủ tốc độ cao.',
    },
    {
      'q': 'Làm thế nào để tải phim xem ngoại tuyến?',
      'a': 'Tại trang chi tiết phim, bạn nhấn vào nút "Tải xuống" và chọn chất lượng video mong muốn (720p hoặc 1080p). Phim sẽ được lưu trữ an toàn trong mục "Tải xuống" của bạn.',
    },
    {
      'q': 'Tôi bị giật lag khi xem phim thì phải làm sao?',
      'a': 'Bạn có thể chuyển đổi giữa các máy chủ phát (Server HLS Siêu Tốc hoặc Server Dự Phòng) ở phần danh sách tập của phim, hoặc vào mục "Cá nhân" chọn "Dọn dẹp bộ nhớ đệm (Cache)".',
    },
    {
      'q': 'Làm sao để tiếp tục xem tập đang dở?',
      'a': 'Movix tự động ghi nhớ chính xác đến từng giây vị trí bạn đang xem. Bạn chỉ cần vào tab "Danh sách" -> mục "Lịch sử xem" hoặc bấm "Tiếp tục xem" tại trang chi tiết phim.',
    },
    {
      'q': 'Ứng dụng xem phim có mất phí không?',
      'a': 'Toàn bộ phim trên Movix đều hoàn toàn miễn phí chất lượng cao cho tất cả thành viên.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trung tâm trợ giúp'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Câu hỏi thường gặp (FAQ)'),
            Tab(text: 'Liên hệ hỗ trợ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqTab(),
          _buildContactTab(),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm câu hỏi thắc mắc...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ..._faqs.map((faq) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: ExpansionTile(
              shape: const Border(),
              title: Text(
                faq['q']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faq['a']!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContactTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildContactTile(
          icon: Icons.headset_mic_rounded,
          title: 'Tổng đài chăm sóc khách hàng',
          subtitle: '1900 6868 (Hỗ trợ 24/7 miễn phí)',
        ),
        const SizedBox(height: 12),
        _buildContactTile(
          icon: Icons.email_outlined,
          title: 'Hỗ trợ kỹ thuật qua Email',
          subtitle: 'support@movix.app',
        ),
        const SizedBox(height: 12),
        _buildContactTile(
          icon: Icons.language_rounded,
          title: 'Trang web cộng đồng',
          subtitle: 'https://github.com/phanan04/Movix',
        ),
        const SizedBox(height: 12),
        _buildContactTile(
          icon: Icons.facebook,
          title: 'Fanpage chính thức',
          subtitle: 'facebook.com/movix.official',
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
