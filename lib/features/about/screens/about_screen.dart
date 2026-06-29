import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';
import 'package:organization_app_starter/shared/services/analytics_service.dart';
import 'package:organization_app_starter/shared/services/url_launcher_service.dart';
import 'package:organization_app_starter/features/about/models/about_data.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = OrgInfo.defaultInfo;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 32, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Learn more about our organization',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  _OrgHeader(name: info.name),
                  const SizedBox(height: 16),
                  _Description(text: info.description),
                  if (info.hasContact) ...[
                    const SizedBox(height: 32),
                    _SectionHeader(title: 'Contact'),
                    const SizedBox(height: 8),
                    if (info.contactEmail != null)
                      _ActionRow(
                        icon: Icons.mail_outline_rounded,
                        label: info.contactEmail!,
                        onTap: () => _openUrl(
                          'mailto:${info.contactEmail}',
                          info.contactEmail!,
                          ref,
                        ),
                      ),
                    if (info.websiteUrl != null)
                      _ActionRow(
                        icon: Icons.language_rounded,
                        label: info.websiteUrl!,
                        onTap: () => _openUrl(
                          info.websiteUrl!,
                          info.websiteUrl!,
                          ref,
                        ),
                      ),
                  ],
                  if (info.links.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _SectionHeader(title: 'Links'),
                    const SizedBox(height: 8),
                    ...info.links.map(
                      (link) => _ActionRow(
                        icon: Icons.link_rounded,
                        label: link.label,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.gray400,
                        ),
                        onTap: () => _openUrl(
                          link.url,
                          link.label,
                          ref,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(
    String url,
    String label,
    WidgetRef ref,
  ) async {
    AnalyticsService.trackResourceOpened(url: url, label: label);
    await UrlLauncherService.launch(url);
  }
}

class _OrgHeader extends StatelessWidget {
  final String name;
  const _OrgHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            size: 40,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _Description extends StatelessWidget {
  final String text;
  const _Description({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: AppColors.white,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.gray100,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: AppColors.textSecondary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
