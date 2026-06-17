import 'package:flutter/material.dart';
import '../../../../core/styles/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_collection.dart';
import '../models/collection_item.dart';
import '../providers/home_feed_providers.dart';
import 'featured_card.dart';
import 'large_card.dart';

import 'small_card.dart';
import '../screens/content_detail_screen.dart';

/// Renders a single Home Feed section — section header + horizontal carousel.
///
/// Receives a [FeedCollection] (parent record).
/// Uses [sectionItemsProvider] to resolve the renderable [CollectionItem]s:
/// - `is_collection: true`  → child items from `collection[]`
/// - `is_collection: false` → the parent itself wrapped as a single item
class HomeFeedModuleSection extends ConsumerWidget {
  final FeedCollection section;

  const HomeFeedModuleSection({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(sectionItemsProvider(section));
    if (items.isEmpty) return const SizedBox.shrink();

    return _buildSection(context, items);
  }

  Widget _buildSection(BuildContext context, List<CollectionItem> items) {
    final showHeader = section.isCollection && section.title != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                if (section.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    section.subtitle!,
                    style: TextStyle(fontSize: 13, color: AppColors.gray600),
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 10),

        _buildCarousel(context, items),
      ],
    );
  }

  void _handleCardTap(BuildContext context, CollectionItem item) {
    debugPrint('[HomeFeed] Card tapped: ${item.lookupKey} (${item.id})');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(item: item),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildCarousel(BuildContext context, List<CollectionItem> items) {
    final screenWidth = MediaQuery.of(context).size.width;

    switch (section.cardType) {
      case CardType.featured:
        return _FeaturedCarousel(
          items: items,
          onTap: (item) => _handleCardTap(context, item),
        );
      case CardType.large:
        final bool isTablet = screenWidth >= 600;
        final double defaultCardWidth = isTablet ? 400.0 : screenWidth * 0.85;

        if (items.length == 1) {
          final double singleWidth = screenWidth - 40; // Full width minus 20px padding on each side
          final double cardHeight = singleWidth * 0.6; // Horizontal aspect ratio

          return SizedBox(
            height: cardHeight + 20, // Add space for shadow
            width: double.infinity,
            child: Center(
              child: LargeCard(
                data: items.first,
                width: singleWidth,
                margin: EdgeInsets.zero,
                onTap: () => _handleCardTap(context, items.first),
              ),
            ),
          );
        }

        final double cardHeight = defaultCardWidth * 0.6; // Horizontal aspect ratio

        return SizedBox(
          height: cardHeight + 20, // Add space for shadow
          child: ListView.builder(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => LargeCard(
              data: items[index],
              width: defaultCardWidth,
              onTap: () => _handleCardTap(context, items[index]),
            ),
          ),
        );
      case CardType.small:
        final bool isTablet = screenWidth >= 600;
        final double cardWidth = isTablet ? 220.0 : 160.0;
        final double cardHeight = (cardWidth * 9 / 16) + 70; // Image height + text space

        if (items.length == 1) {
          return SizedBox(
            height: cardHeight,
            width: double.infinity,
            child: Center(
              child: SmallCard(
                data: items.first,
                margin: EdgeInsets.zero,
                onTap: () => _handleCardTap(context, items.first),
              ),
            ),
          );
        }

        return SizedBox(
          height: cardHeight,
          child: ListView.builder(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => SmallCard(
              data: items[index],
              onTap: () => _handleCardTap(context, items[index]),
            ),
          ),
        );
    }
  }
}

/// PageView carousel for featured cards with page indicator dots.
class _FeaturedCarousel extends StatefulWidget {
  final List<CollectionItem> items;
  final void Function(CollectionItem item)? onTap;

  const _FeaturedCarousel({required this.items, this.onTap});

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 450,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => FeaturedCard(
              data: widget.items[index],
              onTap: widget.onTap != null
                  ? () => widget.onTap!(widget.items[index])
                  : null,
            ),
          ),
        ),
        if (widget.items.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.items.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color(0xFF4338CA) // Blue/Indigo
                      : AppColors.gray300,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
