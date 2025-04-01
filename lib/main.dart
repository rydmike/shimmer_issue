import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shader Crash',
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Flutter Shader Issue'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  // Track whether shimmer effect is enabled
  bool _isShimmerEnabled = false;

  // Animation controller for Container 1 scale and shimmer
  late AnimationController _containerAnimationController;
  // Animation controller for Container 2 shimmer
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  // Animation controller for Container 2 scale
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _containerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Both controllers need the same total duration including delay
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ), // total duration including delay
    );

    // Create shimmer animation with 600ms delay, adjusting to new duration
    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Interval(
          500 / 900, // Start at 500ms (normalized to controller duration)
          1.0,
          curve: Curves.linear,
        ),
      ),
    );

    // Controller for Container 2 scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ), // total duration including delay
    );

    // Create a curved animation that starts after 800ms delay
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Interval(
          500 / 900, // Start at 500ms (normalized to controller duration)
          1.0,
          curve: Curves.elasticOut,
        ),
      ),
    );

    // Auto-start container 1 animation (this is already the default for flutter_animate)
    _containerAnimationController.stop();

    // Auto-start container 2 animations
    _shimmerController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _containerAnimationController.dispose();
    _shimmerController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // Helper method to build a gradient similar to the ShimmerEffect
  LinearGradient _buildShimmerGradient(double value) {
    const Color color = Colors.white;
    final Color transparent = color.withAlpha(0);
    final List<Color> colors = [transparent, color, transparent];

    return LinearGradient(
      colors: colors,
      transform: _SweepingGradientTransform(
        ratio: value,
        angle: pi / 12,
        scale: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('This app demos a shader crash issue.'),
              const Text('The issue only happens on Android, when using'),
              const Text('a phone with Android Snapdragon 8 Elite chip.'),

              // Replace KeyedSubtree with direct Container using controller
              _isShimmerEnabled
                  ? Container(
                        width: 200,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Color(0x6B000000),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'Container 1\nflutter_animate',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      .animate(controller: _containerAnimationController)
                      .shimmer(
                        delay: 1000.ms,
                        duration: 400.ms,
                        color: Colors.white,
                        size: 1,
                      )
                      .scale(
                        duration: 400.ms,
                        begin: const Offset(0.0, 0.0),
                        end: const Offset(1, 1),
                        curve: Curves.elasticOut,
                      )
                  : Container(
                        width: 200,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Color(0x6B000000),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'Container 1\nflutter_animate',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      .animate(controller: _containerAnimationController)
                      .scale(
                        delay: 500.ms,
                        duration: 400.ms,
                        begin: const Offset(0.0, 0.0),
                        end: const Offset(1, 1),
                        curve: Curves.elasticOut,
                      ),

              ElevatedButton(
                onPressed: () {
                  // Reset and start all animation controllers
                  _containerAnimationController.reset();
                  _containerAnimationController.forward();
                },
                child: const Text('Animate container 1'),
              ),

              // Container 2 with custom shimmer effect and scale animation
              AnimatedBuilder(
                animation: Listenable.merge([
                  _shimmerAnimation,
                  _scaleAnimation,
                ]),
                builder: (context, child) {
                  Widget containerWidget = Container(
                    width: 200,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Color(0x6B000000),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'Container 2\nVanilla Flutter',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );

                  // Only apply shimmer effect if enabled
                  if (_isShimmerEnabled) {
                    containerWidget = ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback:
                          (bounds) => _buildShimmerGradient(
                            _shimmerAnimation.value,
                          ).createShader(bounds),
                      child: containerWidget,
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(2),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: containerWidget,
                    ),
                  );
                },
              ),

              ElevatedButton(
                onPressed: () {
                  // Reset and start the shimmer animation for Container 2
                  _shimmerController.reset();
                  _shimmerController.forward();
                  // Reset and start the scale animation for Container 2
                  _scaleController.reset();
                  _scaleController.forward();
                },
                child: const Text('Animate container 2'),
              ),
              SwitchListTile(
                title: const Text('Enable shimmer shader effect'),
                value: _isShimmerEnabled,
                onChanged: (value) {
                  setState(() {
                    _isShimmerEnabled = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SweepingGradientTransform extends GradientTransform {
  const _SweepingGradientTransform({
    required this.ratio,
    required this.angle,
    required this.scale,
  });

  final double angle;
  final double ratio;
  final double scale;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // minimum width / height to avoid infinity errors:
    double w = max(0.01, bounds.width), h = max(0.01, bounds.height);

    // calculate the radius of the rect:
    double r = (cos(angle) * w).abs() + (sin(angle) * h).abs();

    // set up the transformation matrices:
    Matrix4 transformMtx =
        Matrix4.identity()
          ..rotateZ(angle)
          ..scale(r / w * scale);

    double range = w * (1 + scale) / scale;
    Matrix4 translateMtx = Matrix4.identity()..translate(range * (ratio - 0.5));

    // Convert from [-1 - +1] to [0 - 1], & find the pixel location of the gradient center:
    Offset pt = Offset(bounds.left + w * 0.5, bounds.top + h * 0.5);

    // This offsets the draw position to account for the widget's position being
    // multiplied against the transformation:
    List<double> loc = transformMtx.applyToVector3Array([pt.dx, pt.dy, 0.0]);
    double dx = pt.dx - loc[0], dy = pt.dy - loc[1];

    return Matrix4.identity()
      ..translate(dx, dy, 0.0) // center origin
      ..multiply(transformMtx) // rotate and scale
      ..multiply(translateMtx); // translate
  }
}
