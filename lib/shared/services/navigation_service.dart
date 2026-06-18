import 'package:flutter/material.dart';
import 'package:organization_app_starter/features/home/models/collection_item.dart';

import 'package:organization_app_starter/features/home/screens/content_detail_screen.dart';

class NavigationService {
  static Route<void> contentDetailRoute(CollectionItem item) =>
      MaterialPageRoute(
        builder: (_) => ContentDetailScreen(item: item),
        fullscreenDialog: true,
      );

  static Future<void> openContentDetail(
          BuildContext context, CollectionItem item) =>
      Navigator.of(context).push(contentDetailRoute(item));
}
