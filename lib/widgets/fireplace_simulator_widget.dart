import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

class FireplaceSimulatorWidget extends StatefulWidget {
  const FireplaceSimulatorWidget({super.key});

  @override
  State<FireplaceSimulatorWidget> createState() => _FireplaceSimulatorWidgetState();
}

class _FireplaceSimulatorWidgetState extends State<FireplaceSimulatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _flameController;
  late AnimationController _emberController;
  late AnimationController _smokeController;
  late AnimationController _sparkController;
  late AnimationController _heatWaveController;
  late AnimationController _magicController;
  
  final AudioPlayer _fireplacePlayer = AudioPlayer();
  
  double _fireIntensity = 0.8;
  bool _isFireplaceOn = true;
  bool _isSoundEnabled = true;
  String _flameColor = 'orange'; // orange, blue, purple, rainbow, dragon, phoenix
  bool _magicMode = false;
  
  final List<FlameParticle> _flames = [];
  final List<EmberParticle> _embers = [];
  final List<SmokeParticle> _smoke = [];
  final List<SparkParticle> _sparks = [];
  final List<HeatWave> _heatWaves = [];
  
  // Interactive effects
  final List<TapEffect> _tapEffects = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeParticles();
    _startFireplaceSound();
  }
  
  void _initializeAnimations() {
    _flameController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _emberController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    
    _smokeController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat();
    
    _sparkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
    
    _heatWaveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _magicController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();
  }
  
  void _initializeParticles() {
    final random = math.Random();
    
    // Initialize flames - more dynamic
    for (int i = 0; i < 25; i++) {
      _flames.add(FlameParticle(
        x: 20 + random.nextDouble() * 260,
        y: 250,
        baseHeight: 60 + random.nextDouble() * 80,
        flickerSpeed: 0.3 + random.nextDouble() * 2.0,
        intensity: 0.7 + random.nextDouble() * 0.3,
        id: i,
      ));
    }
    
    // Initialize embers - more variety
    for (int i = 0; i < 40; i++) {
      _embers.add(EmberParticle(
        x: 10 + random.nextDouble() * 280,
        y: 180 + random.nextDouble() * 120,
        size: 1 + random.nextDouble() * 6,
        speed: 0.1 + random.nextDouble() * 1.2,
        brightness: 0.5 + random.nextDouble() * 0.5,
        id: i,
      ));
    }
    
    // Initialize smoke - more realistic
    for (int i = 0; i < 15; i++) {
      _smoke.add(SmokeParticle(
        x: 80 + random.nextDouble() * 140,
        y: 100,
        opacity: 0.05 + random.nextDouble() * 0.25,
        speed: 0.2 + random.nextDouble() * 0.7,
        size: 10 + random.nextDouble() * 30,
        id: i,
      ));
    }
    
    // Initialize sparks - spectacular!
    for (int i = 0; i < 30; i++) {
      _sparks.add(SparkParticle(
        x: 50 + random.nextDouble() * 200,
        y: 200 + random.nextDouble() * 50,
        velocity: Offset(
          (random.nextDouble() - 0.5) * 4,
          -random.nextDouble() * 3 - 1,
        ),
        life: 1.0,
        size: 1 + random.nextDouble() * 3,
        id: i,
      ));
    }
    
    // Initialize heat waves
    for (int i = 0; i < 8; i++) {
      _heatWaves.add(HeatWave(
        x: 30 + i * 35.0,
        amplitude: 5 + random.nextDouble() * 15,
        frequency: 0.5 + random.nextDouble() * 1.5,
        phase: random.nextDouble() * 2 * math.pi,
        id: i,
      ));
    }
  }
  
  Future<void> _startFireplaceSound() async {
    if (_isSoundEnabled && _isFireplaceOn) {
      try {
        await _fireplacePlayer.setSource(AssetSource('audio/crackling_fire.mp3'));
        await _fireplacePlayer.setReleaseMode(ReleaseMode.loop);
        await _fireplacePlayer.setVolume(_fireIntensity * 0.6);
        await _fireplacePlayer.resume();
      } catch (e) {
        debugPrint('Error playing fireplace sound: $e');
      }
    }
  }
  
  Future<void> _stopFireplaceSound() async {
    await _fireplacePlayer.stop();
  }
  
  void _toggleFireplace() {
    setState(() {
      _isFireplaceOn = !_isFireplaceOn;
      if (_isFireplaceOn) {
        _flameController.repeat();
        _emberController.repeat();
        _smokeController.repeat();
        _sparkController.repeat();
        _heatWaveController.repeat();
        if (_magicMode) _magicController.repeat();
        _startFireplaceSound();
      } else {
        _flameController.stop();
        _emberController.stop();
        _smokeController.stop();
        _sparkController.stop();
        _heatWaveController.stop();
        _magicController.stop();
        _stopFireplaceSound();
      }
    });
  }
  
  void _updateIntensity(double intensity) {
    setState(() {
      _fireIntensity = intensity;
    });
    if (_isSoundEnabled && _isFireplaceOn) {
      _fireplacePlayer.setVolume(_fireIntensity * 0.7);
    }
  }
  
  void _toggleSound() {
    setState(() {
      _isSoundEnabled = !_isSoundEnabled;
    });
    if (_isSoundEnabled && _isFireplaceOn) {
      _startFireplaceSound();
    } else {
      _stopFireplaceSound();
    }
  }
  
  void _toggleMagicMode() {
    setState(() {
      _magicMode = !_magicMode;
      if (_magicMode && _isFireplaceOn) {
        _magicController.repeat();
      } else {
        _magicController.stop();
      }
    });
  }
  
  void _onFireplaceTap(TapDownDetails details) {
    if (!_isFireplaceOn) return;
    
    final random = math.Random();
    setState(() {
      _tapEffects.add(TapEffect(
        position: details.localPosition,
        startTime: DateTime.now().millisecondsSinceEpoch,
        id: random.nextInt(10000),
      ));
    });
    
    // Create extra sparks at tap location
    for (int i = 0; i < 15; i++) {
      _sparks.add(SparkParticle(
        x: details.localPosition.dx,
        y: details.localPosition.dy,
        velocity: Offset(
          (random.nextDouble() - 0.5) * 8,
          (random.nextDouble() - 0.5) * 8,
        ),
        life: 1.0,
        size: 2 + random.nextDouble() * 4,
        id: random.nextInt(10000),
      ));
    }
    
    // Remove old tap effects
    _tapEffects.removeWhere((effect) {
      return DateTime.now().millisecondsSinceEpoch - effect.startTime > 1000;
    });
  }
  
  @override
  void dispose() {
    _flameController.dispose();
    _emberController.dispose();
    _smokeController.dispose();
    _sparkController.dispose();
    _heatWaveController.dispose();
    _magicController.dispose();
    _fireplacePlayer.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2C1810).withOpacity(0.9),
            const Color(0xFF1A0F08).withOpacity(0.95),
            Colors.black.withOpacity(0.98),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4500).withOpacity(_isFireplaceOn ? 0.3 : 0.0),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD2691E),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.fireplace,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cozy Fireplace 🔥',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Virtual warmth for your soul',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              // Power button
              GestureDetector(
                onTap: _toggleFireplace,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isFireplaceOn ? const Color(0xFFFF4500) : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isFireplaceOn ? Icons.power_settings_new : Icons.power_off,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Fireplace simulator - now with tap interaction!
          GestureDetector(
            onTapDown: _onFireplaceTap,
            child: Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _magicMode 
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF8B4513),
                  width: _magicMode ? 4 : 3,
                ),
                boxShadow: [
                  if (_isFireplaceOn) ...[
                    BoxShadow(
                      color: _magicMode 
                          ? const Color(0xFFFFD700).withOpacity(0.6)
                          : const Color(0xFFFF4500).withOpacity(0.4),
                      blurRadius: _fireIntensity * 25,
                      spreadRadius: _fireIntensity * 5,
                    ),
                    BoxShadow(
                      color: _getFlameGlowColor().withOpacity(0.3),
                      blurRadius: _fireIntensity * 40,
                      spreadRadius: _fireIntensity * 8,
                    ),
                  ],
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Fireplace background with enhanced texture
                    _buildEnhancedFireplaceBackground(),
                    
                    // Logs with better 3D effect
                    _buildEnhancedLogs(),
                    
                    // Heat waves - visible distortion effect
                    if (_isFireplaceOn) _buildHeatWaves(),
                    
                    // Flames with 3D depth
                    if (_isFireplaceOn) _buildEnhancedFlames(),
                    
                    // Flying sparks
                    if (_isFireplaceOn) _buildSparks(),
                    
                    // Embers with glow
                    if (_isFireplaceOn) _buildEnhancedEmbers(),
                    
                    // Enhanced smoke
                    if (_isFireplaceOn) _buildEnhancedSmoke(),
                    
                    // Magic effects overlay
                    if (_isFireplaceOn && _magicMode) _buildMagicEffects(),
                    
                    // Tap effects
                    if (_isFireplaceOn) _buildTapEffects(),
                    
                    // Dynamic glow effect
                    if (_isFireplaceOn) _buildDynamicGlowEffect(),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Controls
          _buildControls(),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedFireplaceBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF5A5A5A),
            const Color(0xFF3C3C3C),
            const Color(0xFF2A2A2A),
            const Color(0xFF1A1A1A),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Enhanced brick texture with depth
          ...List.generate(10, (row) {
            return List.generate(7, (col) {
              final random = math.Random(row * 7 + col);
              return Positioned(
                left: (col * 45.0) + (row.isEven ? 22 : 0),
                top: row * 22.0,
                child: AnimatedBuilder(
                  animation: _heatWaveController,
                  builder: (context, child) {
                    final heat = _isFireplaceOn ? _fireIntensity : 0.0;
                    final shimmer = math.sin(_heatWaveController.value * 2 * math.pi + random.nextDouble()) * heat * 0.1;
                    
                    return Transform.translate(
                      offset: Offset(shimmer, 0),
                      child: Container(
                        width: 42,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(const Color(0xFF8B4513), const Color(0xFFD2691E), shimmer.abs())!.withOpacity(0.4),
                              const Color(0xFF8B4513).withOpacity(0.3),
                              const Color(0xFF654321).withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: const Color(0xFF654321).withOpacity(0.6),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            });
          }).expand((element) => element),
          
          // Atmospheric lighting
          if (_isFireplaceOn)
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomCenter,
                  radius: 1.5,
                  colors: [
                    _getFlameGlowColor().withOpacity((_fireIntensity * 0.15).clamp(0.0, 1.0)),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedLogs() {
    return Stack(
      children: [
        // Bottom log with enhanced 3D effect
        Positioned(
          bottom: 25,
          left: 25,
          child: AnimatedBuilder(
            animation: _emberController,
            builder: (context, child) {
              final glow = _isFireplaceOn ? math.sin(_emberController.value * 2 * math.pi) * 0.3 + 0.7 : 0.5;
              
              return Container(
                width: 250,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(const Color(0xFF654321), const Color(0xFFD2691E), glow * _fireIntensity)!,
                      const Color(0xFF8B4513),
                      const Color(0xFF654321),
                      Colors.black,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isFireplaceOn 
                          ? _getFlameGlowColor().withOpacity((glow * _fireIntensity * 0.4).clamp(0.0, 1.0))
                          : Colors.black.withOpacity(0.3),
                      blurRadius: _isFireplaceOn ? 8 : 4,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Wood grain texture
                    ...List.generate(8, (i) {
                      return Positioned(
                        left: i * 30.0,
                        top: 8 + (i % 3) * 4.0,
                        child: Container(
                          width: 25,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A4A4A).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Top log with charred effect
        Positioned(
          bottom: 45,
          left: 45,
          child: AnimatedBuilder(
            animation: _emberController,
            builder: (context, child) {
              final char = _isFireplaceOn ? _fireIntensity * 0.7 : 0.0;
              
              return Container(
                width: 210,
                height: 25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(const Color(0xFF654321), Colors.black, char)!,
                      Color.lerp(const Color(0xFF8B4513), const Color(0xFF2C2C2C), char)!,
                      Color.lerp(const Color(0xFFA0522D), const Color(0xFF1A1A1A), char)!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Glowing coals between logs
        if (_isFireplaceOn)
          ...List.generate(12, (i) {
            final random = math.Random(i);
            return Positioned(
              bottom: 20 + random.nextDouble() * 15,
              left: 40 + i * 18.0 + random.nextDouble() * 10,
              child: AnimatedBuilder(
                animation: _emberController,
                builder: (context, child) {
                  final pulse = math.sin(_emberController.value * 2 * math.pi + i) * 0.5 + 0.5;
                  final intensity = pulse * _fireIntensity;
                  
                  return Container(
                    width: 4 + intensity * 6,
                    height: 3 + intensity * 4,
                    decoration: BoxDecoration(
                      color: _getFlameGlowColor().withOpacity(intensity),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: _getFlameGlowColor().withOpacity((intensity * 0.8).clamp(0.0, 1.0)),
                          blurRadius: intensity * 8,
                          spreadRadius: intensity * 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
  }
  
  Widget _buildHeatWaves() {
    return AnimatedBuilder(
      animation: _heatWaveController,
      builder: (context, child) {
        return Stack(
          children: _heatWaves.map((wave) {
            final distortion = math.sin(_heatWaveController.value * 2 * math.pi * wave.frequency + wave.phase) * wave.amplitude * _fireIntensity;
            
            return Positioned(
              left: wave.x + distortion,
              bottom: 60,
              top: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity((0.02 * _fireIntensity).clamp(0.0, 1.0)),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  Widget _buildEnhancedFlames() {
    return AnimatedBuilder(
      animation: _flameController,
      builder: (context, child) {
        return Stack(
          children: _flames.map((flame) {
            final flickerOffset = math.sin(_flameController.value * 2 * math.pi * flame.flickerSpeed) * 12;
            final heightVariation = math.cos(_flameController.value * 2 * math.pi * flame.flickerSpeed * 0.8) * 25;
            final opacity = ((0.6 + math.sin(_flameController.value * 2 * math.pi * flame.flickerSpeed * 1.4) * 0.4) * _fireIntensity * flame.intensity).clamp(0.0, 1.0);
            final sway = math.sin(_flameController.value * math.pi * flame.flickerSpeed * 0.3) * 8;
            
            return Positioned(
              left: flame.x + flickerOffset + sway,
              bottom: flame.y - flame.baseHeight - heightVariation,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Main flame body
                  Container(
                    width: 12 + _fireIntensity * 15,
                    height: (flame.baseHeight + heightVariation) * _fireIntensity,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.bottomCenter,
                        radius: 1.2,
                        colors: _getEnhancedFlameColors(opacity),
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  
                  // Inner core - hotter center
                  Container(
                    width: 6 + _fireIntensity * 8,
                    height: (flame.baseHeight + heightVariation * 0.7) * _fireIntensity,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.bottomCenter,
                        colors: _getFlameCore(opacity),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  
                  // Flame tip
                  Positioned(
                    top: -5,
                    child: Container(
                      width: 3 + _fireIntensity * 4,
                      height: 15 + heightVariation * 0.3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            _getFlameGlowColor().withOpacity(opacity * 0.8),
                            _getFlameGlowColor().withOpacity(opacity * 0.4),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  Widget _buildSparks() {
    return AnimatedBuilder(
      animation: _sparkController,
      builder: (context, child) {
        final random = math.Random();
        
        // Update spark positions
        for (var spark in _sparks) {
          spark.update(_sparkController.value);
          
          // Reset spark if it died
          if (spark.life <= 0) {
            spark.reset(
              50 + random.nextDouble() * 200,
              200 + random.nextDouble() * 50,
              Offset(
                (random.nextDouble() - 0.5) * 6,
                -random.nextDouble() * 4 - 2,
              ),
            );
          }
        }
        
        return Stack(
          children: _sparks.where((spark) => spark.life > 0).map((spark) {
            final opacity = (spark.life * _fireIntensity).clamp(0.0, 1.0);
            final trail = spark.life > 0.7 ? (spark.life - 0.7) / 0.3 : 0.0;
            
            return Positioned(
              left: spark.x,
              bottom: spark.y,
              child: Stack(
                children: [
                  // Spark trail
                  if (trail > 0)
                    Container(
                      width: spark.size * 0.5,
                      height: spark.size * 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            _getFlameGlowColor().withOpacity((opacity * trail * 0.6).clamp(0.0, 1.0)),
                            _getFlameGlowColor().withOpacity((opacity * trail).clamp(0.0, 1.0)),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(spark.size),
                      ),
                    ),
                  
                  // Main spark
                  Container(
                    width: spark.size * _fireIntensity,
                    height: spark.size * _fireIntensity,
                    decoration: BoxDecoration(
                      color: _getFlameGlowColor().withOpacity(opacity),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getFlameGlowColor().withOpacity((opacity * 0.8).clamp(0.0, 1.0)),
                          blurRadius: spark.size * 2,
                          spreadRadius: spark.size * 0.5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  Widget _buildEnhancedEmbers() {
    return AnimatedBuilder(
      animation: _emberController,
      builder: (context, child) {
        return Stack(
          children: _embers.map((ember) {
            final floatOffset = math.sin(_emberController.value * 2 * math.pi * ember.speed) * 8;
            final drift = math.cos(_emberController.value * math.pi * ember.speed * 0.7) * 4;
            final pulseBrightness = ((0.4 + math.cos(_emberController.value * 2 * math.pi * ember.speed * 1.3) * 0.6) * _fireIntensity * ember.brightness).clamp(0.0, 1.0);
            
            return Positioned(
              left: ember.x + drift,
              bottom: ember.y + floatOffset,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Container(
                    width: ember.size * 3 * _fireIntensity,
                    height: ember.size * 3 * _fireIntensity,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          _getFlameGlowColor().withOpacity(pulseBrightness * 0.3),
                          Colors.transparent,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  
                  // Main ember
                  Container(
                    width: ember.size * _fireIntensity,
                    height: ember.size * _fireIntensity,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(pulseBrightness * 0.8),
                          _getFlameGlowColor().withOpacity(pulseBrightness),
                          const Color(0xFF8B0000).withOpacity(pulseBrightness * 0.6),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getFlameGlowColor().withOpacity(pulseBrightness * 0.6),
                          blurRadius: ember.size * 2,
                          spreadRadius: ember.size * 0.3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  Widget _buildEnhancedSmoke() {
    return AnimatedBuilder(
      animation: _smokeController,
      builder: (context, child) {
        return Stack(
          children: _smoke.map((smoke) {
            final drift = _smokeController.value * 120;
            final swirl = math.sin(_smokeController.value * 4 * math.pi) * 20;
            final opacity = (smoke.opacity * (1 - _smokeController.value * 0.8) * _fireIntensity).clamp(0.0, 1.0);
            final expansion = 1 + _smokeController.value * 2;
            
            return Positioned(
              left: smoke.x + drift * smoke.speed + swirl,
              bottom: smoke.y + drift * 1.5,
              child: Container(
                width: smoke.size * expansion,
                height: smoke.size * expansion,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.grey.withOpacity((opacity * 0.8).clamp(0.0, 1.0)),
                      Colors.grey.withOpacity((opacity * 0.4).clamp(0.0, 1.0)),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  Widget _buildMagicEffects() {
    return AnimatedBuilder(
      animation: _magicController,
      builder: (context, child) {
        return Stack(
          children: [
            // Magical sparkles
            ...List.generate(20, (i) {
              final angle = (_magicController.value * 2 * math.pi) + (i * 0.314);
              final radius = 100 + math.sin(_magicController.value * 4 * math.pi + i) * 30;
              final x = 150 + math.cos(angle) * radius;
              final y = 175 + math.sin(angle) * radius * 0.5;
              
              return Positioned(
                left: x,
                bottom: y,
                child: Container(
                  width: 4 + math.sin(_magicController.value * 6 * math.pi + i) * 3,
                  height: 4 + math.sin(_magicController.value * 6 * math.pi + i) * 3,
                  decoration: BoxDecoration(
                    color: HSVColor.fromAHSV(
                      0.8,
                      (_magicController.value * 360 + i * 18) % 360,
                      1.0,
                      1.0,
                    ).toColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: HSVColor.fromAHSV(
                          0.5,
                          (_magicController.value * 360 + i * 18) % 360,
                          1.0,
                          1.0,
                        ).toColor(),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            }),
            
            // Rainbow overlay on flames
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    HSVColor.fromAHSV(0.3, (_magicController.value * 360) % 360, 1.0, 1.0).toColor(),
                    HSVColor.fromAHSV(0.2, (_magicController.value * 360 + 60) % 360, 1.0, 1.0).toColor(),
                    HSVColor.fromAHSV(0.1, (_magicController.value * 360 + 120) % 360, 1.0, 1.0).toColor(),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildTapEffects() {
    return Stack(
      children: _tapEffects.map((effect) {
        final age = (DateTime.now().millisecondsSinceEpoch - effect.startTime) / 1000.0;
        final progress = (age / 1.0).clamp(0.0, 1.0);
        final opacity = (1.0 - progress) * 0.8;
        final size = progress * 100;
        
        return Positioned(
          left: effect.position.dx - size / 2,
          top: effect.position.dy - size / 2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(
                color: _getFlameGlowColor().withOpacity(opacity),
                width: 3,
              ),
              shape: BoxShape.circle,
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildDynamicGlowEffect() {
    return AnimatedBuilder(
      animation: _flameController,
      builder: (context, child) {
        final primaryGlow = ((0.4 + math.sin(_flameController.value * 2 * math.pi) * 0.6) * _fireIntensity).clamp(0.0, 1.0);
        final secondaryGlow = ((0.3 + math.cos(_flameController.value * 3 * math.pi) * 0.4) * _fireIntensity).clamp(0.0, 1.0);
        
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.bottomCenter,
              radius: 1.8,
              colors: [
                _getFlameGlowColor().withOpacity((primaryGlow * 0.4).clamp(0.0, 1.0)),
                _getFlameGlowColor().withOpacity((secondaryGlow * 0.3).clamp(0.0, 1.0)),
                _getFlameGlowColor().withOpacity((primaryGlow * 0.2).clamp(0.0, 1.0)),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildControls() {
    return Column(
      children: [
        // Intensity control
        Row(
          children: [
            const Icon(Icons.whatshot, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            const Text(
              'Intensity',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFFF4500),
                  inactiveTrackColor: Colors.grey,
                  thumbColor: const Color(0xFFD2691E),
                  overlayColor: const Color(0xFFFF4500).withOpacity(0.3),
                ),
                child: Slider(
                  value: _fireIntensity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  onChanged: _updateIntensity,
                ),
              ),
            ),
            Text(
              '${(_fireIntensity * 100).round()}%',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Control buttons
        Row(
          children: [
            // Sound toggle
            Expanded(
              child: GestureDetector(
                onTap: _toggleSound,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _isSoundEnabled ? const Color(0xFFD2691E) : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      if (_isSoundEnabled)
                        BoxShadow(
                          color: const Color(0xFFD2691E).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sound',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Magic mode toggle
            Expanded(
              child: GestureDetector(
                onTap: _toggleMagicMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: _magicMode 
                        ? LinearGradient(
                            colors: [
                              const Color(0xFFFFD700),
                              const Color(0xFFFF69B4),
                              const Color(0xFF9370DB),
                            ],
                          )
                        : null,
                    color: _magicMode ? null : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      if (_magicMode)
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.6),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _magicMode ? '✨' : '🪄',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Magic',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Enhanced flame color picker
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const Text(
                'Flame Style:',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ...['orange', 'blue', 'purple', 'rainbow', 'dragon', 'phoenix'].map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => _flameColor = color),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: _getColorGradient(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _flameColor == color ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            if (_flameColor == color)
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: _getFlameIcon(color),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  List<Color> _getEnhancedFlameColors(double opacity) {
    switch (_flameColor) {
      case 'blue':
        return [
          const Color(0xFF0066FF).withOpacity(opacity),
          const Color(0xFF00AAFF).withOpacity(opacity * 0.9),
          const Color(0xFF87CEEB).withOpacity(opacity * 0.7),
          const Color(0xFFE0F6FF).withOpacity(opacity * 0.4),
          Colors.transparent,
        ];
      case 'purple':
        return [
          const Color(0xFF8A2BE2).withOpacity(opacity),
          const Color(0xFFDA70D6).withOpacity(opacity * 0.9),
          const Color(0xFFE6E6FA).withOpacity(opacity * 0.6),
          const Color(0xFFF8F8FF).withOpacity(opacity * 0.3),
          Colors.transparent,
        ];
      case 'rainbow':
        final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
        return [
          HSVColor.fromAHSV(opacity, (time * 50) % 360, 1.0, 1.0).toColor(),
          HSVColor.fromAHSV(opacity * 0.9, (time * 50 + 60) % 360, 1.0, 1.0).toColor(),
          HSVColor.fromAHSV(opacity * 0.7, (time * 50 + 120) % 360, 1.0, 1.0).toColor(),
          HSVColor.fromAHSV(opacity * 0.4, (time * 50 + 180) % 360, 1.0, 1.0).toColor(),
          Colors.transparent,
        ];
      case 'dragon':
        return [
          const Color(0xFF8B0000).withOpacity(opacity),
          const Color(0xFFDC143C).withOpacity(opacity * 0.9),
          const Color(0xFFFF4500).withOpacity(opacity * 0.7),
          const Color(0xFFFFD700).withOpacity(opacity * 0.5),
          const Color(0xFFFFF8DC).withOpacity(opacity * 0.2),
          Colors.transparent,
        ];
      case 'phoenix':
        return [
          const Color(0xFFFFD700).withOpacity(opacity),
          const Color(0xFFFF8C00).withOpacity(opacity * 0.9),
          const Color(0xFFFF4500).withOpacity(opacity * 0.8),
          const Color(0xFFDC143C).withOpacity(opacity * 0.6),
          const Color(0xFF8B0000).withOpacity(opacity * 0.3),
          Colors.transparent,
        ];
      default: // orange
        return [
          const Color(0xFFFF4500).withOpacity(opacity),
          const Color(0xFFFF6347).withOpacity(opacity * 0.9),
          const Color(0xFFFFD700).withOpacity(opacity * 0.7),
          const Color(0xFFFFA500).withOpacity(opacity * 0.5),
          const Color(0xFFFFF8DC).withOpacity(opacity * 0.2),
          Colors.transparent,
        ];
    }
  }
  
  List<Color> _getFlameCore(double opacity) {
    switch (_flameColor) {
      case 'blue':
        return [
          Colors.white.withOpacity(opacity * 0.9),
          const Color(0xFF87CEEB).withOpacity(opacity * 0.7),
          Colors.transparent,
        ];
      case 'purple':
        return [
          Colors.white.withOpacity(opacity * 0.9),
          const Color(0xFFE6E6FA).withOpacity(opacity * 0.7),
          Colors.transparent,
        ];
      case 'rainbow':
        return [
          Colors.white.withOpacity(opacity * 0.9),
          Colors.white.withOpacity(opacity * 0.5),
          Colors.transparent,
        ];
      case 'dragon':
        return [
          const Color(0xFFFFD700).withOpacity(opacity * 0.9),
          const Color(0xFFFF4500).withOpacity(opacity * 0.7),
          Colors.transparent,
        ];
      case 'phoenix':
        return [
          Colors.white.withOpacity(opacity * 0.9),
          const Color(0xFFFFD700).withOpacity(opacity * 0.8),
          Colors.transparent,
        ];
      default:
        return [
          Colors.white.withOpacity(opacity * 0.9),
          const Color(0xFFFFD700).withOpacity(opacity * 0.7),
          Colors.transparent,
        ];
    }
  }
  
  Color _getFlameGlowColor() {
    switch (_flameColor) {
      case 'blue':
        return const Color(0xFF0066FF);
      case 'purple':
        return const Color(0xFF8A2BE2);
      case 'rainbow':
        final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
        return HSVColor.fromAHSV(1.0, (time * 100) % 360, 1.0, 1.0).toColor();
      case 'dragon':
        return const Color(0xFF8B0000);
      case 'phoenix':
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFFFF4500);
    }
  }
  
  LinearGradient _getColorGradient(String colorName) {
    switch (colorName) {
      case 'blue':
        return const LinearGradient(colors: [Color(0xFF0066FF), Color(0xFF87CEEB)]);
      case 'purple':
        return const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFFE6E6FA)]);
      case 'rainbow':
        return const LinearGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.blue]);
      case 'dragon':
        return const LinearGradient(colors: [Color(0xFF8B0000), Color(0xFFFFD700)]);
      case 'phoenix':
        return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFDC143C)]);
      default:
        return const LinearGradient(colors: [Color(0xFFFF4500), Color(0xFFFFD700)]);
    }
  }
  
  Widget? _getFlameIcon(String colorName) {
    switch (colorName) {
      case 'dragon':
        return const Center(child: Text('🐉', style: TextStyle(fontSize: 12)));
      case 'phoenix':
        return const Center(child: Text('🔥', style: TextStyle(fontSize: 12)));
      case 'rainbow':
        return const Center(child: Text('🌈', style: TextStyle(fontSize: 10)));
      default:
        return null;
    }
  }
  
  List<Color> _getFlameColors(double opacity) {
    return _getEnhancedFlameColors(opacity);
  }
  
  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'blue':
        return const Color(0xFF0066FF);
      case 'purple':
        return const Color(0xFF8A2BE2);
      default:
        return const Color(0xFFFF4500);
    }
  }
}

// Enhanced particle classes for spectacular effects
class FlameParticle {
  final double x;
  final double y;
  final double baseHeight;
  final double flickerSpeed;
  final double intensity;
  final int id;
  
  FlameParticle({
    required this.x,
    required this.y,
    required this.baseHeight,
    required this.flickerSpeed,
    required this.intensity,
    required this.id,
  });
}

class EmberParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double brightness;
  final int id;
  
  EmberParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.brightness,
    required this.id,
  });
}

class SmokeParticle {
  final double x;
  final double y;
  final double opacity;
  final double speed;
  final double size;
  final int id;
  
  SmokeParticle({
    required this.x,
    required this.y,
    required this.opacity,
    required this.speed,
    required this.size,
    required this.id,
  });
}

class SparkParticle {
  double x;
  double y;
  Offset velocity;
  double life;
  final double size;
  final int id;
  
  SparkParticle({
    required this.x,
    required this.y,
    required this.velocity,
    required this.life,
    required this.size,
    required this.id,
  });
  
  void update(double deltaTime) {
    x += velocity.dx * deltaTime * 60;
    y += velocity.dy * deltaTime * 60;
    velocity = Offset(velocity.dx * 0.98, velocity.dy + 0.5); // gravity
    life -= deltaTime * 2;
  }
  
  void reset(double newX, double newY, Offset newVelocity) {
    x = newX;
    y = newY;
    velocity = newVelocity;
    life = 1.0;
  }
}

class HeatWave {
  final double x;
  final double amplitude;
  final double frequency;
  final double phase;
  final int id;
  
  HeatWave({
    required this.x,
    required this.amplitude,
    required this.frequency,
    required this.phase,
    required this.id,
  });
}

class TapEffect {
  final Offset position;
  final int startTime;
  final int id;
  
  TapEffect({
    required this.position,
    required this.startTime,
    required this.id,
  });
}
