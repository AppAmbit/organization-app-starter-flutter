import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';
import 'package:organization_app_starter/features/categories/models/category.dart';
import 'package:organization_app_starter/features/categories/models/show.dart';
import 'package:organization_app_starter/features/categories/providers/categories_providers.dart';
import 'package:organization_app_starter/shared/services/analytics_service.dart';
import 'package:organization_app_starter/shared/services/url_launcher_service.dart';
import 'package:organization_app_starter/shared/widgets/app_network_image.dart';

/// Lists every [Show] tied to a [Category] — the Categories ↔ Home/Live TV link.
class CategoryShowsScreen extends ConsumerWidget {
  final Category category;

  const CategoryShowsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showsAsync = ref.watch(showsByCategoryProvider(category.slug));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(category.name),
        backgroundColor: AppColors.surface,
      ),
      body: showsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            "Couldn't load shows",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (shows) {
          if (shows.isEmpty) {
            return Center(
              child: Text(
                'No shows in ${category.name} yet',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: shows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _ShowRow(show: shows[i]),
          );
        },
      ),
    );
  }
}

class _ShowRow extends StatelessWidget {
  final Show show;
  const _ShowRow({required this.show});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final url = show.watchUrl;
        if (url == null || url.isEmpty) return;
        AnalyticsService.trackResourceOpened(url: url, label: show.title);
        UrlLauncherService.launch(url);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 130,
              height: 84,
              child: show.imageUrl != null
                  ? AppNetworkImage(url: show.imageUrl!)
                  : Container(color: AppColors.gray300),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      show.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (show.episodeCount != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${show.episodeCount} episodes',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.play_circle_outline,
                  color: AppColors.accent, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}
