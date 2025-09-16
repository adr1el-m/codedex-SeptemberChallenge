import 'package:flutter/material.dart';

class ParallaxLayer {
  final Widget? widget;
  final LinearGradient? gradient;
  final bool vignette;
  final double opacity;

  ParallaxLayer({this.widget, this.gradient, this.vignette = false, this.opacity = 1.0});

  ParallaxLayer.widget(this.widget, {this.opacity = 1.0})
      : gradient = null,
        vignette = false;

  ParallaxLayer.gradient(this.gradient, {this.vignette = false, this.opacity = 1.0}) : widget = null;
}

class ParallaxBackground extends StatefulWidget {
  final ScrollController scrollController;
  final List<ParallaxLayer> layers;
  final double maxTiltDegrees;
  final double responsiveness;

  const ParallaxBackground({
    super.key,
    required this.scrollController,
    required this.layers,
    this.maxTiltDegrees = 10.0,
    this.responsiveness = 1.0,
  });

  @override
  _ParallaxBackgroundState createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground> {
  double _tilt = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        final scrollOffset = widget.scrollController.offset;
        _tilt = (scrollOffset / 200).clamp(-widget.maxTiltDegrees, widget.maxTiltDegrees);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(_tilt * (3.14159 / 180)),
      alignment: FractionalOffset.center,
      child: Stack(
        children: widget.layers.map((layer) {
          return Positioned.fill(
            child: Opacity(
              opacity: layer.opacity,
              child: layer.widget ??
                  Container(
                    decoration: BoxDecoration(
                      gradient: layer.gradient,
                    ),
                    child: layer.vignette
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                radius: 1.5,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                              ),
                            ),
                          )
                        : null,
                  ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
