import 'package:flutter/material.dart';
import 'package:organization_app_starter/core/constants.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';
import 'package:organization_app_starter/shared/services/navigation_service.dart';
import 'package:organization_app_starter/features/home/models/feed_collection.dart';
import 'package:organization_app_starter/features/home/models/collection_item.dart';
import 'featured_card.dart';
import 'large_card.dart';
import 'small_card.dart';

/// Renders a single Home Feed section — section header + horizontal carousel.
///
/// Receives a [FeedCollection] and uses [FeedCollection.items] directly:
/// - `is_collection: true`  → child items from `collection[]`
/// - `is_collection: false` → the parent itself wrapped as a single item
class HomeFeedModuleSection extends StatelessWidget {
  final FeedCollection section;

  const HomeFeedModuleSection({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final items = section.items;
    if (items.isEmpty) return const SizedBox.shrink();

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

  Widget _buildCarousel(BuildContext context, List<CollectionItem> items) {
    final screenWidth = MediaQuery.of(context).size.width;

    switch (section.cardType) {
      case CardType.featured:
        return _FeaturedCarousel(
          items: items,
          onTap: (item) => NavigationService.openContentDetail(context, item),
        );
      case CardType.large:
        final bool isTablet = screenWidth >= AppLayout.tabletBreakpoint;
        final double defaultCardWidth = isTablet ? 400.0 : screenWidth * 0.85;

        if (items.length == 1) {
          final double singleWidth = screenWidth - 40;
          final double cardHeight = singleWidth * 0.6;
          return SizedBox(
            height: cardHeight + 20,
            width: double.infinity,
            child: Center(
              child: LargeCard(
                data: items.first,
                width: singleWidth,
                margin: EdgeInsets.zero,
                onTap: () => NavigationService.openContentDetail(context, items.first),
              ),
            ),
          );
        }

        final double cardHeight = defaultCardWidth * 0.6;

        // Center cards when all fit without scrolling (avoids empty trailing space on tablet)
        final double totalLargeWidth = items.length * (defaultCardWidth + 16) + 40;
        if (totalLargeWidth <= screenWidth) {
          return SizedBox(
            height: cardHeight + 20,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: items
                    .map((item) => LargeCard(
                          data: item,
                          width: defaultCardWidth,
                          onTap: () => NavigationService.openContentDetail(context, item),
                        ))
                    .toList(),
              ),
            ),
          );
        }

        return SizedBox(
          height: cardHeight + 20,
          child: ListView.builder(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => LargeCard(
              data: items[index],
              width: defaultCardWidth,
              onTap: () => NavigationService.openContentDetail(context, items[index]),
            ),
          ),
        );
      case CardType.small:
        final bool isTablet = screenWidth >= AppLayout.tabletBreakpoint;
        final double cardWidth = isTablet ? 220.0 : 160.0;
        final double cardHeight = (cardWidth * 9 / 16) + 70;

        if (items.length == 1) {
          return SizedBox(
            height: cardHeight,
            width: double.infinity,
            child: Center(
              child: SmallCard(
                data: items.first,
                margin: EdgeInsets.zero,
                onTap: () => NavigationService.openContentDetail(context, items.first),
              ),
            ),
          );
        }

        // Center cards when all fit without scrolling (avoids empty trailing space on tablet)
        final double totalSmallWidth = items.length * (cardWidth + 16) + 40;
        if (totalSmallWidth <= screenWidth) {
          return SizedBox(
            height: cardHeight,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: items
                    .map((item) => SmallCard(
                          data: item,
                          onTap: () => NavigationService.openContentDetail(context, item),
                        ))
                    .toList(),
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
              onTap: () => NavigationService.openContentDetail(context, items[index]),
            ),
          ),
        );
    }
  }
}

class _FeaturedCarousel extends StatefulWidget {
  final List<CollectionItem> items;
  final void Function(CollectionItem item)? onTap;

  const _FeaturedCarousel({required this.items, this.onTap});

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  final PageController _controller = PageController();
  final ValueNotifier<int> _currentPage = ValueNotifier(0);

  @override
  void dispose() {
    _controller.dispose();
    _currentPage.dispose();
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
            onPageChanged: (index) => _currentPage.value = index,
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
          ListenableBuilder(
            listenable: _currentPage,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.items.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage.value == index
                          ? AppColors.carouselDotActive
                          : AppColors.carouselDotInactive,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ],
    );
  }
}
