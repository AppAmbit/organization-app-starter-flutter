import 'package:flutter/material.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _items = <({IconData icon, String label})>[
    (icon: Icons.language, label: 'Language'),
    (icon: Icons.child_care, label: 'Kids Mode'),
    (icon: Icons.info_outline, label: 'About and Legal'),
    (icon: Icons.help_outline, label: 'Help'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _items.length,
                separatorBuilder: (_, _) =>
                    Divider(color: AppColors.gray300, height: 1),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, size: 20, color: AppColors.gray600),
                    ),
                    title: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.gray400,
                      size: 22,
                    ),
                    onTap: () {},
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.gray400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Signout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'App version 0.1',
                style: TextStyle(fontSize: 12, color: AppColors.gray500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
