import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class CustomInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? suffixWidget;
  final VoidCallback? onSuffixIconPressed;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool readOnly;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius;

  const CustomInput({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixWidget,
    this.onSuffixIconPressed,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.contentPadding,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: AppTheme.textSecondary,
              )
            : null,
        suffixIcon: suffixWidget ?? (suffixIcon != null
            ? IconButton(
                icon: Icon(
                  suffixIcon,
                  color: AppTheme.textSecondary,
                ),
                onPressed: onSuffixIconPressed,
              )
            : null),
        filled: true,
        fillColor: fillColor ?? Colors.grey[50],
        contentPadding: contentPadding ??
            EdgeInsets.symmetric(
              horizontal: AppConstants.mdSpacing,
              vertical: maxLines != null && maxLines! > 1
                  ? AppConstants.mdSpacing
                  : AppConstants.smSpacing,
            ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppConstants.smRadius,
          ),
          borderSide: BorderSide(
            color: borderColor ?? AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppConstants.smRadius,
          ),
          borderSide: BorderSide(
            color: borderColor ?? AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppConstants.smRadius,
          ),
          borderSide: const BorderSide(
            color: AppTheme.primaryBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppConstants.smRadius,
          ),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppConstants.smRadius,
          ),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppConstants.smRadius,
          ),
          borderSide: BorderSide(
            color: AppTheme.textSecondary.withValues(alpha: 0.1),
          ),
        ),
      ),
    );
  }
}