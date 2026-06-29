import 'package:flutter/material.dart';

import 'package:organization_app_starter/core/styles/app_colors.dart';

class AuthInput extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? Function(String?)? validator;

  const AuthInput({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
    this.keyboardType,
    this.maxLength,
    this.validator,
  });

  @override
  State<AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<AuthInput> {
  late final ValueNotifier<bool> _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = ValueNotifier(widget.obscureText);
  }

  @override
  void dispose() {
    _obscured.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          ListenableBuilder(
            listenable: _obscured,
              builder: (context, _) => TextField(
              controller: widget.controller,
              obscureText: _obscured.value,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              focusNode: widget.focusNode,
              keyboardType: widget.keyboardType,
              maxLength: widget.maxLength,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon: Icon(widget.icon, color: AppColors.gray400),
                suffixIcon: widget.obscureText
                    ? IconButton(
                        icon: Icon(
                          _obscured.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.gray400,
                        ),
                        onPressed: () =>
                            _obscured.value = !_obscured.value,
                      )
                    : null,
                errorText: widget.errorText,
                errorStyle:
                    const TextStyle(color: AppColors.accentRed, fontSize: 12),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gray300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gray300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accentRed),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.accentRed, width: 2),
                ),
                filled: true,
                fillColor: AppColors.gray100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
