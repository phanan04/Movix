import 'package:flutter/material.dart';
import '../../../../core/cache/user_storage.dart';
import '../../../../core/theme/app_colors.dart';

class MovieCommentsWidget extends StatefulWidget {
  final String movieSlug;

  const MovieCommentsWidget({super.key, required this.movieSlug});

  @override
  State<MovieCommentsWidget> createState() => _MovieCommentsWidgetState();
}

class _MovieCommentsWidgetState extends State<MovieCommentsWidget> {
  final TextEditingController _commentController = TextEditingController();
  final UserStorage _userStorage = UserStorage();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
      await _userStorage.addComment(
        movieSlug: widget.movieSlug,
        content: text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi bình luận của bạn')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments List
        ValueListenableBuilder<List<UserCommentItem>>(
          valueListenable: _userStorage.commentsNotifier,
          builder: (context, allComments, _) {
            final movieComments = allComments.where((c) => c.movieSlug == widget.movieSlug).toList();

            if (movieComments.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textSecondary, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chưa có bình luận nào cho phim này. Hãy là người đầu tiên chia sẻ cảm nghĩ nhé!',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movieComments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = movieComments[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.surfaceLight,
                            backgroundImage: c.userAvatar.isNotEmpty ? NetworkImage(c.userAvatar) : null,
                            child: c.userAvatar.isEmpty
                                ? const Icon(Icons.person, color: Colors.white70, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.userName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  c.timeText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            iconSize: 18,
                            icon: Icon(
                              c.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: c.isLiked ? AppColors.primary : AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                c.isLiked = !c.isLiked;
                                c.likes += c.isLiked ? 1 : -1;
                              });
                            },
                          ),
                          Text(
                            '${c.likes}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.content,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 16),

        // Input Field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Viết bình luận cảm nghĩ về phim...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
                onPressed: _sendComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
