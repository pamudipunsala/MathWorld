import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'calculation_type_selection_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _titleController;
  late AnimationController _glowController;
  late Animation<double> _iconScale;
  late Animation<double> _iconRotation;
  late Animation<double> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Icon animations
    _iconScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _iconRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeInOut,
    ));

    // Title animations
    _titleSlide = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOutBack,
    ));

    _titleOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeIn,
    ));

    // Glow animation
    _glowOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _startAnimations();
    
    // Navigate after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const CalculationTypeSelectionPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _iconController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _titleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _iconController.dispose();
    _titleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isLargeScreen = size.width > 900;
    final isTablet = size.width >= 600 && size.width <= 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2D3A2E), // Same chalkboard color as other screens
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated App Icon
              AnimatedBuilder(
                animation: _iconController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _iconScale.value,
                    child: Transform.rotate(
                      angle: _iconRotation.value * 2 * 3.14159,
                      child: Container(
                        width: isSmallScreen ? 120 : (isLargeScreen ? 200 : 160),
                        height: isSmallScreen ? 120 : (isLargeScreen ? 200 : 160),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9D857),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              'assets/images/app_icon.png', // Replace with your image name
                              width: isSmallScreen ? 80 : (isLargeScreen ? 140 : 120),
                              height: isSmallScreen ? 80 : (isLargeScreen ? 140 : 120),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to icon if image not found
                                return Icon(
                                  Icons.calculate,
                                  size: isSmallScreen ? 60 : (isLargeScreen ? 100 : 80),
                                  color: const Color(0xFF2D6A4F),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: isSmallScreen ? 30 : 40),
              
              // Animated Title
              AnimatedBuilder(
                animation: _titleController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _titleSlide.value),
                    child: Opacity(
                      opacity: _titleOpacity.value,
                      child: AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  const Color(0xFFFFD700),
                                  const Color(0xFFFFA500),
                                  const Color(0xFFFFD700),
                                ],
                                stops: [
                                  0.0,
                                  0.5,
                                  1.0,
                                ],
                                transform: GradientRotation(
                                  _glowController.value * 2 * 3.14159,
                                ),
                              ).createShader(bounds);
                            },
                            child: Text(
                              'MATH PUZZLE',
                              style: GoogleFonts.permanentMarker(
                                textStyle: TextStyle(
                                  fontSize: isSmallScreen ? 32 : (isLargeScreen ? 48 : 40),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: Colors.black.withOpacity(0.5),
                                      offset: const Offset(2, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: isSmallScreen ? 20 : 30),
              
              // Subtitle
              AnimatedBuilder(
                animation: _titleController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _titleOpacity.value,
                    child: Text(
                      'Challenge Your Mind',
                      style: GoogleFonts.permanentMarker(
                        textStyle: TextStyle(
                          fontSize: isSmallScreen ? 16 : (isLargeScreen ? 24 : 20),
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: isSmallScreen ? 40 : 60),
              
              // Loading indicator
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    width: isSmallScreen ? 40 : 50,
                    height: isSmallScreen ? 40 : 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(
                          const Color(0xFFF9D857),
                          const Color(0xFFFFD700),
                          _glowController.value,
                        )!,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 