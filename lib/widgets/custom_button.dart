import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

enum CustomButtonStyle {
  primary,
  secondary,
  outline,
}

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? text;
  final IconData? icon;
  final CustomButtonStyle? style;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.onPressed,
    this.child,
    this.text,
    this.icon,
    this.style,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine button style
    final buttonStyle = style ?? CustomButtonStyle.primary;
    final isStyleOutlined = buttonStyle == CustomButtonStyle.outline || isOutlined;

    // Build the child widget
    Widget buildChild() {
      if (child != null) {
        return child!;
      }

      if (text != null && icon != null) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(text!),
          ],
        );
      }

      if (text != null) {
        return Text(text!);
      }

      if (icon != null) {
        return Icon(icon, size: 18);
      }

      return const SizedBox.shrink();
    }

    // Get colors based on style
    Color getBackgroundColor() {
      if (backgroundColor != null) return backgroundColor!;
      switch (buttonStyle) {
        case CustomButtonStyle.primary:
          return AppTheme.primaryBlue;
        case CustomButtonStyle.secondary:
          return AppTheme.backgroundLight;
        case CustomButtonStyle.outline:
          return Colors.transparent;
      }
    }

    Color getForegroundColor() {
      if (foregroundColor != null) return foregroundColor!;
      switch (buttonStyle) {
        case CustomButtonStyle.primary:
          return Colors.white;
        case CustomButtonStyle.secondary:
          return AppTheme.primaryBlue;
        case CustomButtonStyle.outline:
          return AppTheme.primaryBlue;
      }
    }

    if (isStyleOutlined) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: getForegroundColor(),
            side: BorderSide(
              color: getForegroundColor(),
              width: 1,
            ),
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: AppConstants.lgSpacing,
              vertical: AppConstants.mdSpacing,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.mdRadius),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(getForegroundColor()),
                  ),
                )
              : buildChild(),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: getBackgroundColor(),
          foregroundColor: getForegroundColor(),
          elevation: buttonStyle == CustomButtonStyle.secondary ? 0 : 2,
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: AppConstants.lgSpacing,
            vertical: AppConstants.mdSpacing,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.mdRadius),
          ),
          side: buttonStyle == CustomButtonStyle.secondary ? BorderSide(
            color: AppTheme.borderLight,
            width: 1,
          ) : null,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(getForegroundColor()),
                ),
              )
            : buildChild(),
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? size;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.size,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.mdRadius),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: foregroundColor ?? AppTheme.textSecondary,
          size: size ?? 24,
        ),
        padding: padding ?? const EdgeInsets.all(AppConstants.smSpacing),
        constraints: const BoxConstraints(),
      ),
    );
  }
}