import 'package:flutter/material.dart';

import 'package:organization_app_starter/core/styles/app_colors.dart';

enum AuthButtonVariant { primary, ghost, destructive }

class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AuthButtonVariant variant;
  final bool loading;
  final bool disabled;

  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AuthButtonVariant.primary,
    this.loading = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = !loading && !disabled;

    switch (variant) {
      case AuthButtonVariant.primary:
      case AuthButtonVariant.destructive:
        final bg = variant == AuthButtonVariant.destructive
            ? AppColors.accentRed
            : AppColors.accent;
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: isActive ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: bg,
              disabledBackgroundColor: bg.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.white),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
          ),
        );
      case AuthButtonVariant.ghost:
        return SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: isActive ? onPressed : null,
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.accent : AppColors.gray400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
    }
  }
}
