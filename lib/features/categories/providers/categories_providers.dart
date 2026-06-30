import 'package:flutter/foundation.dart' show debugPrint;
import 'package:appambit_sdk_flutter/appambit_cms.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organization_app_starter/core/constants.dart';
import 'package:organization_app_starter/features/categories/models/category.dart';
import 'package:organization_app_starter/features/categories/models/show.dart';

/// All browse categories (genres), sorted by display_order.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  try {
    final list = await AppAmbitCms.content<Category>(
      CmsContentType.categories,
      fromJson: (json) => Category.fromMap(json),
    ).getList();
    final sorted = [...list]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return sorted;
  } catch (e, st) {
    debugPrint('[Categories] ERROR loading categories: $e\n$st');
    rethrow;
  }
});

/// All shows (series), sorted by display_order.
final showsProvider = FutureProvider<List<Show>>((ref) async {
  try {
    final list = await AppAmbitCms.content<Show>(
      CmsContentType.shows,
      fromJson: (json) => Show.fromMap(json),
    ).getList();
    final sorted = [...list]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return sorted;
  } catch (e, st) {
    debugPrint('[Categories] ERROR loading shows: $e\n$st');
    rethrow;
  }
});

/// Shows filtered by a category slug — ties Categories to Home/Live TV content.
final showsByCategoryProvider =
    FutureProvider.family<List<Show>, String>((ref, categorySlug) async {
  final shows = await ref.watch(showsProvider.future);
  return shows.where((s) => s.category == categorySlug).toList();
});
