import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';
import 'package:organization_app_starter/features/categories/models/category.dart';
import 'package:organization_app_starter/features/categories/providers/categories_providers.dart';
import 'package:organization_app_starter/features/categories/screens/category_shows_screen.dart';
import 'package:organization_app_starter/shared/widgets/app_network_image.dart';
import 'package:organization_app_starter/shared/widgets/oiwi_logo.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: categoriesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            onRetry: () => ref.invalidate(categoriesProvider),
          ),
          data: (categories) {
            if (categories.isEmpty) {
              return const Center(
                child: Text(
                  'No categories yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.5,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _CategoryTile(category: categories[index]),
                      childCount: categories.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 4, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const OiwiLogo(),
              IconButton(
                icon: const Icon(Icons.cast, color: AppColors.textPrimary),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'All Categories',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoryShowsScreen(category: category),
        ),
      ),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (category.imageUrl != null)
              AppNetworkImage(url: category.imageUrl!)
            else
              Container(color: AppColors.gray100),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.black.withValues(alpha: 0.1),
                    AppColors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category.hawaiianName != null)
                    Text(
                      category.hawaiianName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.gray400),
          const SizedBox(height: 16),
          const Text(
            "Couldn't load categories",
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
