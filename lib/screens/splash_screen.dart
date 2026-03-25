import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _stoneController;
  late final AnimationController _fadeController;
  late final List<Animation<double>> _stoneAnimations;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _fadeOut;

  static const int _stoneCount = 4;

  @override
  void initState() {
    super.initState();

    _stoneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Bottom stone first → top stone last
    _stoneAnimations = List.generate(_stoneCount, (i) {
      final start = i * 0.18;
      final end = (start + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _stoneController,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      ).drive(Tween(begin: 0.0, end: 1.0));
    });

    _titleOpacity = CurvedAnimation(
      parent: _stoneController,
      curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeOut = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _stoneController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    await _fadeController.forward();
    widget.onComplete();
  }

  @override
  void dispose() {
    _stoneController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _fadeOut,
      builder: (context, child) => Opacity(
        opacity: _fadeOut.value,
        child: Scaffold(
          backgroundColor: colors.surface,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 160,
                  height: 110,
                  child: AnimatedBuilder(
                    animation: _stoneController,
                    builder: (context, _) => CustomPaint(
                      painter: _CairnLogoPainter(
                        stoneProgress: List.generate(
                          _stoneCount,
                          (i) => _stoneAnimations[i].value,
                        ),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, 0),
                  child: FadeTransition(
                    opacity: _titleOpacity,
                    child: SizedBox(
                      width: 160,
                      child: SvgPicture.asset(
                        'assets/logo/zairn_text.svg',
                        colorFilter: ColorFilter.mode(
                          colors.onSurface,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the actual cairn logo paths from the SVG, animated per-stone.
class _CairnLogoPainter extends CustomPainter {
  final List<double> stoneProgress; // [0]=bottom .. [3]=top

  _CairnLogoPainter({required this.stoneProgress});

  // Original SVG viewBox after transforms: approx 186..838 x 181..844
  // We normalize to 0..652 x 0..663
  static const double _svgW = 652.0;
  static const double _offsetX = 186.0;
  static const double _offsetY = 131.0;  // shift paths down by rendering from higher
  static const double _scaleY = 0.983638;
  static const double _txX = 11.889695 - 12.127798;
  static const double _txY = 7.914887;

  // The 4 stone path strings from the SVG (bottom to top)
  static final List<Path> _rawPaths = [
    // Stone 0 (bottom) — pink-orange
    _parseSvgPath('M375.864,588.214C397.646,585.736 428.558,590.966 449.93,594.131C482.33,598.929 515.245,606.387 547.196,613.638C596.747,624.544 646.112,636.28 695.27,648.843C724.967,656.333 756.075,663.148 785.189,672.938C794.45,676.052 808.78,685.805 815.789,692.586C829.998,706.263 838.097,725.088 838.257,744.809C838.591,765.701 830.765,787.041 816.15,802.083C796.556,822.252 769.532,828.354 742.709,831.856C710.684,836.038 677.58,839.058 645.263,839.547C622.636,840.591 599.997,841.341 577.35,841.796C519.976,843.239 462.586,843.936 405.194,843.887C375.233,844.039 345.272,843.707 315.322,842.89C266.924,841.523 170.434,842.466 188.413,765.17C197.598,725.685 223.691,684.448 249.459,653.487C282.586,613.684 323.896,591.741 375.864,588.214Z'),
    // Stone 1 (second) — teal-cyan gradient
    _parseSvgPath('M760.231,449.201L760.658,449.167C770.924,448.455 780.321,450.927 788.159,457.856C804.274,471.963 802.451,498.633 798.21,517.455C785.79,572.569 744.205,638.673 678.521,624.159C667.457,621.714 656.399,618.918 645.362,616.234L591.91,603.092C557.375,594.661 518.396,585.521 483.647,579.093C442.341,571.324 400.276,568.343 358.287,570.209C342.453,570.958 327.679,573.204 312.125,573.981C284.985,574.742 228.656,571.277 224.156,535.489C221.239,512.294 246.564,493.767 265.948,486.493C303.932,472.239 344.929,477.743 384.314,480.886C411.548,482.837 439.243,485.009 466.561,486.267C511.252,488.75 556.065,487.916 600.633,483.775C629.217,480.904 658.327,476.585 686.073,468.986C698.693,465.458 711.285,461.834 723.85,458.115C736.211,454.421 747.286,450.41 760.231,449.201Z'),
    // Stone 2 (third) — cyan
    _parseSvgPath('M665.33,272.199C668.912,271.907 672.513,271.937 676.09,272.287C690.752,273.83 703.107,281.917 712.212,293.303C729.283,314.654 733.458,350.528 730.929,376.995C728.736,399.135 719.368,421.784 701.476,435.723C677.456,454.437 645.441,458.701 616.084,462.267C562.989,468.717 509.368,468.514 455.994,467.036C424.611,466.166 394.65,464.655 363.411,461.031C343.022,457.829 319.551,454.095 302.597,441.459C287.738,430.383 283.264,409.329 295.762,394.578C310.955,376.648 334.642,373.357 356.315,368.794C393.154,360.966 430.584,357.378 467.223,348.545C479.57,345.586 490.973,342.024 503.071,338.197C526.364,330.897 549.298,322.496 571.795,313.023C587.901,306.093 603.791,298.67 619.442,290.763C635.484,282.561 646.873,274.144 665.33,272.199Z'),
    // Stone 3 (top) — amber
    _parseSvgPath('M549.25,181.215C571.352,180.102 596.534,183.57 615.787,194.964C626.162,201.104 635.598,210.131 638.593,222.183C640.849,231.257 639.009,240.594 634.134,248.503C609.96,287.725 505.525,320.026 462.279,330.592C451.839,332.758 439.225,336.763 428.913,337.484C415.752,338.176 399.31,334.466 389.387,325.425C363.837,302.143 384.436,267.661 403.3,247.866C440.629,208.694 495.314,183.811 549.25,181.215Z'),
  ];

  // Colors: gradient pairs per stone
  static const _stoneGradients = [
    [Color(0xFFFF2D78), Color(0xFFFF9800)],   // bottom: pink→orange
    [Color(0xFF00E5CC), Color(0xFF009688)],    // second: cyan→teal
    [Color(0xFF00E5CC), Color(0xFF00E5CC)],    // third: cyan
    [Color(0xFFFFAB00), Color(0xFFFFAB00)],    // top: amber
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _svgW;

    canvas.save();
    canvas.scale(scale, scale);

    for (int i = 0; i < 4; i++) {
      final progress = stoneProgress[i];
      if (progress <= 0) continue;

      // Get the transformed path
      final svgPath = _rawPaths[i];

      // Apply SVG transforms: translate then scaleY
      final matrix = Matrix4.identity()
        ..translate(_txX - _offsetX, _txY - _offsetY)
        ..scale(1.0, _scaleY);
      final transformedPath = svgPath.transform(matrix.storage);

      // Get bounds for gradient and animation
      final bounds = transformedPath.getBounds();

      // Animate: scale from center + drop from above
      final animMatrix = Matrix4.identity()
        ..translate(bounds.center.dx, bounds.center.dy)
        ..scale(progress, progress)
        ..translate(-bounds.center.dx, -bounds.center.dy + (1 - progress) * -40);

      canvas.save();
      canvas.transform(animMatrix.storage);

      final paint = Paint()
        ..shader = ui.Gradient.linear(
          bounds.centerLeft,
          bounds.centerRight,
          _stoneGradients[i],
        );

      canvas.drawPath(transformedPath, paint);
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CairnLogoPainter old) => true;

  /// Minimal SVG path parser supporting M, L, C, Z commands.
  static Path _parseSvgPath(String d) {
    final path = Path();
    final re = RegExp(r'([MLCZmlcz])|(-?\d+\.?\d*)');
    final matches = re.allMatches(d).toList();

    var i = 0;
    double cx = 0, cy = 0;

    double nextNum() {
      while (i < matches.length && matches[i].group(1) != null) {
        i++;
      }
      if (i >= matches.length) return 0;
      final v = double.parse(matches[i].group(0)!);
      i++;
      return v;
    }

    while (i < matches.length) {
      final cmd = matches[i].group(1);
      if (cmd == null) {
        i++;
        continue;
      }
      i++;

      switch (cmd) {
        case 'M':
          cx = nextNum();
          cy = nextNum();
          path.moveTo(cx, cy);
        case 'L':
          cx = nextNum();
          cy = nextNum();
          path.lineTo(cx, cy);
        case 'C':
          final x1 = nextNum(), y1 = nextNum();
          final x2 = nextNum(), y2 = nextNum();
          cx = nextNum();
          cy = nextNum();
          path.cubicTo(x1, y1, x2, y2, cx, cy);
        case 'Z' || 'z':
          path.close();
      }
    }
    return path;
  }
}
