import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppAnimations {
  AppAnimations._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration stepTransition = Duration(milliseconds: 300);
  static const Duration scaleIn = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration heroEntrance = Duration(milliseconds: 450);
  static const Duration shimmer = Duration(milliseconds: 1500);
  static const Duration countUp = Duration(milliseconds: 800);

  static const Curve stepCurve = Curves.easeOutCubic;
  static const Curve fadeCurve = Curves.easeOut;
  static const Curve scaleCurve = Curves.easeOutBack;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve sheetSpring = Curves.easeOutQuint;
  static const Curve smoothDecel = Curves.decelerate;
  static const Curve snappy = Cubic(0.2, 0.8, 0.2, 1.0);

  static const double slideOffset = 0.25;
  static const double parallaxOffset = 0.4;

  static Widget stepTransitionBuilder(
    Widget child,
    Animation<double> animation, {
    bool forward = true,
  }) {
    final offsetBegin = Offset(forward ? slideOffset : -slideOffset, 0);
    return SlideTransition(
      position: Tween<Offset>(begin: offsetBegin, end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: stepCurve),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: fadeCurve),
        child: child,
      ),
    );
  }

  static Widget fadeInBuilder(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: fadeCurve),
      child: child,
    );
  }

  static Widget scaleInBuilder(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: scaleCurve),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: fadeCurve),
        child: child,
      ),
    );
  }

  static Widget pageTransitionBuilder(
    Widget child,
    Animation<double> animation,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: fadeCurve),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: snappy),
        ),
        child: child,
      ),
    );
  }

  static Widget slideUpBuilder(
    Widget child,
    Animation<double> animation,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: sheetSpring)),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: fadeCurve),
        child: child,
      ),
    );
  }

  static Widget staggeredFadeIn({
    required Widget child,
    required int index,
    int delayMs = 40,
    Duration duration = const Duration(milliseconds: 250),
  }) {
    final totalDelay = Duration(milliseconds: index * delayMs);
    return _DelayedFadeSlide(
      delay: totalDelay,
      duration: duration,
      slideOffset: 8,
      child: child,
    );
  }

  static Widget entrance({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 300),
    Offset slideFrom = const Offset(0, 0.03),
  }) {
    return _DelayedFadeSlide(
      delay: delay,
      duration: duration,
      slideOffset: slideFrom.dy * 80,
      child: child,
    );
  }
}

class _DelayedFadeSlide extends StatefulWidget {
  const _DelayedFadeSlide({
    required this.child,
    required this.delay,
    required this.duration,
    this.slideOffset = 8,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slideOffset;

  @override
  State<_DelayedFadeSlide> createState() => _DelayedFadeSlideState();
}

class _DelayedFadeSlideState extends State<_DelayedFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.fadeCurve,
    );
    _offset = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.snappy,
    ));

    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _offset.value,
          child: child,
        );
      },
      child: FadeTransition(
        opacity: _opacity,
        child: widget.child,
      ),
    );
  }
}

class HapticHelper {
  HapticHelper._();

  static void tap() => HapticFeedback.lightImpact();
  static void selection() => HapticFeedback.selectionClick();
  static void success() => HapticFeedback.mediumImpact();
  static void error() => HapticFeedback.heavyImpact();
  static void impact() => HapticFeedback.heavyImpact();
  static void keyPress() => HapticFeedback.selectionClick();
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double screenHorizontal = 20;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: screenHorizontal, vertical: md);

  static const EdgeInsets screenH =
      EdgeInsets.symmetric(horizontal: screenHorizontal);
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;

  static const double button = 14;
  static const double card = 20;
  static const double sheet = 28;
  static const double input = 14;

  static final BorderRadius borderSm = BorderRadius.circular(sm);
  static final BorderRadius borderMd = BorderRadius.circular(md);
  static final BorderRadius borderLg = BorderRadius.circular(lg);
  static final BorderRadius borderXl = BorderRadius.circular(xl);
  static final BorderRadius borderXxl = BorderRadius.circular(xxl);
  static final BorderRadius borderCard = BorderRadius.circular(card);
  static final BorderRadius borderButton = BorderRadius.circular(button);
  static final BorderRadius borderInput = BorderRadius.circular(input);

  static const BorderRadius sheetRadius =
      BorderRadius.vertical(top: Radius.circular(sheet));
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.97,
    this.duration = const Duration(milliseconds: 100),
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;
  final bool haptic;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (widget.haptic) HapticHelper.tap();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
