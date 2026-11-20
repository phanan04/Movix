import 'package:flutter/material.dart';
import '../../core/models/movie_model.dart';
import '../../core/theme/app_colors.dart';

class EpisodeGridWidget extends StatefulWidget {
  final List<EpisodeItem> episodes;
  final String? currentEpisodeSlug;
  final void Function(EpisodeItem episode) onEpisodeSelected;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const EpisodeGridWidget({
    super.key,
    required this.episodes,
    this.currentEpisodeSlug,
    required this.onEpisodeSelected,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  State<EpisodeGridWidget> createState() => _EpisodeGridWidgetState();
}

class _EpisodeGridWidgetState extends State<EpisodeGridWidget> {
  int _selectedRangeIndex = 0;
  static const int _chunkSize = 30;

  String _formatEpisodeName(String name) {
    final clean = name.trim();
    if (clean.toLowerCase().startsWith('tập')) {
      final numPart = clean.replaceAll(RegExp(r'[^0-9]'), '');
      if (numPart.isNotEmpty) {
        final n = int.tryParse(numPart);
        if (n != null) {
          return 'Tập ${n.toString().padLeft(2, '0')}';
        }
      }
      return clean;
    }
    final n = int.tryParse(clean);
    if (n != null) {
      return 'Tập ${n.toString().padLeft(2, '0')}';
    }
    return 'Tập $clean';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.episodes.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalEpisodes = widget.episodes.length;
    final hasChunks = totalEpisodes > _chunkSize;
    final chunkCount = (totalEpisodes / _chunkSize).ceil();

    final startIndex = hasChunks ? _selectedRangeIndex * _chunkSize : 0;
    final endIndex = hasChunks
        ? (startIndex + _chunkSize > totalEpisodes ? totalEpisodes : startIndex + _chunkSize)
        : totalEpisodes;

    final displayedEpisodes = widget.episodes.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Row: "Danh sách tập" and total count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Danh sách tập',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Text(
                '$totalEpisodes tập',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),

        // Range Selector Tabs if more than 30 episodes (e.g. 1 - 30, 31 - 60)
        if (hasChunks) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chunkCount,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final start = i * _chunkSize + 1;
                final end = (i + 1) * _chunkSize > totalEpisodes
                    ? totalEpisodes
                    : (i + 1) * _chunkSize;
                final isSelected = _selectedRangeIndex == i;

                return ChoiceChip(
                  label: Text('Tập $start - $end'),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedRangeIndex = i;
                    });
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 0.8,
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Responsive Episode Grid
        LayoutBuilder(
          builder: (context, constraints) {
            // 6 columns if wide enough (>= 500px), 4 columns if narrow mobile (< 500px)
            final crossAxisCount = constraints.maxWidth >= 500 ? 6 : (constraints.maxWidth >= 380 ? 4 : 3);
            
            return GridView.builder(
              shrinkWrap: widget.shrinkWrap,
              physics: widget.physics,
              itemCount: displayedEpisodes.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.1,
              ),
              itemBuilder: (context, idx) {
                final ep = displayedEpisodes[idx];
                final isCurrent = widget.currentEpisodeSlug == ep.slug;
                final label = _formatEpisodeName(ep.name);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onEpisodeSelected(ep),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primary
                            : const Color(0xFF1E232E), // Dark slate matching reference
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
