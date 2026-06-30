import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organization_app_starter/features/home/providers/connectivity_provider.dart';
import 'package:organization_app_starter/features/home/providers/home_feed_providers.dart';
import 'package:organization_app_starter/features/home/widgets/home_feed_module_section.dart';
import 'package:organization_app_starter/shared/widgets/oiwi_logo.dart';
import 'package:organization_app_starter/app/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final sectionsAsync = ref.watch(homeFeedSectionsProvider);

    return Scaffold(
      body: connectivityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _buildFeedContent(context, ref, sectionsAsync),
        data: (hasConnection) {
          if (!hasConnection) {
            return _FeedStateView(
              icon: Icons.wifi_off_rounded,
              iconSize: 72,
              title: 'No Internet Connection',
              subtitle: 'Check your connection and try again.',
              onRetry: () {
                ref.invalidate(connectivityProvider);
                ref.invalidate(homeFeedSectionsProvider);
              },
              retryLabel: 'Try Again',
            );
          }
          return _buildFeedContent(context, ref, sectionsAsync);
        },
      ),
    );
  }

  Widget _buildFeedContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue sectionsAsync,
  ) {
    return sectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _FeedStateView(
        icon: Icons.error_outline_rounded,
        iconSize: 64,
        title: 'Something went wrong',
        subtitle: "We couldn't load the feed. Please try again.",
        onRetry: () => ref.invalidate(homeFeedSectionsProvider),
        retryLabel: 'Retry',
      ),
      data: (sections) {
        if (sections.isEmpty) {
          return const _FeedStateView(
            icon: Icons.movie_filter_outlined,
            iconSize: 72,
            title: 'Nothing here yet',
            subtitle: 'Content will appear here once it\'s published.',
          );
        }

        return NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            final isVisible = ref.read(bottomBarVisibleProvider);
            if (notification.direction == ScrollDirection.reverse) {
              if (isVisible) ref.read(bottomBarVisibleProvider.notifier).hide();
            } else if (notification.direction == ScrollDirection.forward) {
              if (!isVisible) ref.read(bottomBarVisibleProvider.notifier).show();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(homeFeedSectionsProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: const OiwiLogo(),
                  backgroundColor: AppColors.surface,
                  elevation: 0,
                  centerTitle: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.cast, color: AppColors.textPrimary),
                      onPressed: () {},
                    ),
                  ],
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        HomeFeedModuleSection(section: sections[index]),
                    childCount: sections.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shared empty/error state widget — icon + title + subtitle + optional retry.
class _FeedStateView extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const _FeedStateView({
    required this.icon,
    required this.iconSize,
    required this.title,
    required this.subtitle,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: AppColors.gray400),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray500, fontSize: 14),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
