import 'package:flutter/material.dart';
import '../utils/theme.dart';

class LoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message;

  const LoadingAnimation({
    super.key,
    this.size = 50.0,
    this.color,
    this.message,
  });

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Outer ring
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: _animation.value,
                      strokeWidth: 3,
                      backgroundColor: (widget.color ?? AppTheme.primaryBlue).withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.color ?? AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  // Inner pulsing dot
                  Center(
                    child: Container(
                      width: widget.size * 0.3,
                      height: widget.size * 0.3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (widget.color ?? AppTheme.primaryBlue).withValues(
                          alpha: 0.3 + (0.7 * _animation.value),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: TextStyle(
              color: widget.color ?? AppTheme.primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class PulseLoadingDots extends StatefulWidget {
  final int dotCount;
  final double dotSize;
  final Color? color;
  final Duration duration;

  const PulseLoadingDots({
    super.key,
    this.dotCount = 3,
    this.dotSize = 8.0,
    this.color,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<PulseLoadingDots> createState() => _PulseLoadingDotsState();
}

class _PulseLoadingDotsState extends State<PulseLoadingDots>
    with TickerProviderStateMixin {
  List<AnimationController> _controllers = [];
  List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.dotCount,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Start animations with staggered delay
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primaryBlue;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.dotCount, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.dotSize * 0.2),
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: _animations[index].value),
              ),
            );
          },
        );
      }),
    );
  }
}

class SpinningLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const SpinningLoader({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  State<SpinningLoader> createState() => _SpinningLoaderState();
}

class _SpinningLoaderState extends State<SpinningLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * 3.14159,
            child: CircularProgressIndicator(
              strokeWidth: widget.strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.color ?? AppTheme.primaryBlue,
              ),
            ),
          );
        },
      ),
    );
  }
}