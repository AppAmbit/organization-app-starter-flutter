import 'dart:async';

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

    // Featured carousel (the first row) shows no title header — its cards carry
    // their own overlay labels.
    final showHeader = section.isCollection &&
        section.title != null &&
        section.cardType != CardType.featured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
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
          autoScrollSeconds: section.autoScrollSeconds,
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LargeCard(
                  data: items.first,
                  width: singleWidth,
                  margin: EdgeInsets.zero,
                  onTap: () => NavigationService.openContentDetail(context, items.first),
                ),
              ),
            ),
          );
        }

        final double cardHeight = defaultCardWidth * 0.6;
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
        final double cardHeight = (cardWidth * 9 / 16) + 84;

        if (items.length == 1) {
          return SizedBox(
            height: cardHeight,
            width: double.infinity,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SmallCard(
                  data: items.first,
                  margin: EdgeInsets.zero,
                  onTap: () => NavigationService.openContentDetail(context, items.first),
                ),
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
  final int? autoScrollSeconds;
  final void Function(CollectionItem item)? onTap;

  const _FeaturedCarousel({
    required this.items,
    this.autoScrollSeconds,
    this.onTap,
  });

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    // Only auto-advance when there is more than one slide.
    if (widget.items.length <= 1) return;
    final seconds = widget.autoScrollSeconds ?? 5;
    if (seconds <= 0) return;
    _autoScrollTimer = Timer.periodic(Duration(seconds: seconds), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_currentPage + 1) % widget.items.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = screenWidth * 10 / 16;
    final totalHeight = imageHeight + 74;

    return Column(
      children: [
        SizedBox(
          height: totalHeight,
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
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.carouselDotActive
                        : AppColors.carouselDotInactive,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}
