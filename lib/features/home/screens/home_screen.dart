import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../core/styles/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';
import '../providers/home_feed_providers.dart';
import '../widgets/home_feed_module_section.dart';
import '../../../main.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check connectivity first — only shown once at open
    final connectivityAsync = ref.watch(connectivityProvider);
    final sectionsAsync = ref.watch(homeFeedSectionsProvider);

    return Scaffold(
      body: connectivityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _buildFeedContent(context, ref, sectionsAsync),
        data: (hasConnection) {
          if (!hasConnection) {
            return _NoInternetView(
              onRetry: () {
                ref.invalidate(connectivityProvider);
                ref.invalidate(homeFeedSectionsProvider);
              },
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
      error: (error, stack) => _ErrorView(
        onRetry: () => ref.invalidate(homeFeedSectionsProvider),
      ),
      data: (sections) {
        if (sections.isEmpty) return const _EmptyFeedView();

        return NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            final isVisible = ref.read(bottomBarVisibleProvider);
            if (notification.direction == ScrollDirection.reverse) {
              if (isVisible) ref.read(bottomBarVisibleProvider.notifier).hide();
            } else if (notification.direction == ScrollDirection.forward) {
              if (!isVisible) ref.read(bottomBarVisibleProvider.notifier).show();
            }
            return false; // let the notification bubble up
          },
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(homeFeedSectionsProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverAppBar(
                  floating: true,
                  title: Text('KavaUp'),
                  backgroundColor: AppColors.white,
                  elevation: 0,
                  centerTitle: true,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => HomeFeedModuleSection(section: sections[index]),
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

/// ─── No Internet ────────────────────────────────────────────────────────────

class _NoInternetView extends StatelessWidget {
  final VoidCallback onRetry;
  const _NoInternetView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 72,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 20),
            Text(
              'No Internet Connection',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Error ──────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t load the feed. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Empty Feed ─────────────────────────────────────────────────────────────

class _EmptyFeedView extends StatelessWidget {
  const _EmptyFeedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.movie_filter_outlined, size: 72, color: AppColors.gray300),
            const SizedBox(height: 20),
            Text(
              'Nothing here yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Content will appear here once it\'s published.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
