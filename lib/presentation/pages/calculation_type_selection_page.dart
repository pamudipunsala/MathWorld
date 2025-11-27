import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'puzzle_page.dart';

enum CalculationType { addition, subtraction, multiplication, division }

class CalculationTypeSelectionPage extends StatelessWidget {
  const CalculationTypeSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    final isLargeScreen = screenSize.height > 800;
    
    return Scaffold(
      backgroundColor: const Color(0xFF2D3A2E), // Chalkboard green
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: isSmallScreen ? 8 : 16),
            AnimatedTitle(),
            SizedBox(height: isSmallScreen ? 16 : 24),
            Expanded(
              child: Center(
                child: AnimatedMenuButtons(),
              ),
            ),
            // Wood trim at the bottom
            Container(
              height: isSmallScreen ? 16 : 24,
              decoration: BoxDecoration(
                color: Colors.brown.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Container(
              height: isSmallScreen ? 12 : 18,
              margin: EdgeInsets.only(top: isSmallScreen ? 4 : 8),
              decoration: BoxDecoration(
                color: Colors.brown.shade700,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, CalculationType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PuzzlePage(calculationType: type),
      ),
    );
  }
}

class AnimatedTitle extends StatefulWidget {
  @override
  State<AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<AnimatedTitle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    final isLargeScreen = screenSize.height > 800;
    final fontSize = isSmallScreen ? 24.0 : (isLargeScreen ? 48.0 : 36.0);
    final topPadding = isSmallScreen ? 40.0 : (isLargeScreen ? 120.0 : 100.0);
    
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.only(
            top: isSmallScreen ? 4.0 : 0.0, 
            bottom: isSmallScreen ? 4.0 : 8.0
          ),
          child: Column(
            children: [
              SizedBox(height: topPadding),
              Text(
                'SELECT CALCULATION',
                textAlign: TextAlign.center,
                style: GoogleFonts.permanentMarker(
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        blurRadius: 0,
                        color: Colors.white.withOpacity(_glow.value),
                        offset: Offset(0, 0),
                      ),
                      Shadow(
                        blurRadius: 16,
                        color: Colors.cyanAccent.withOpacity(_glow.value * 0.7),
                        offset: Offset(0, 0),
                      ),
                      Shadow(
                        blurRadius: 32,
                        color: Colors.greenAccent.withOpacity(_glow.value * 0.5),
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChalkUnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    // Draw a wavy underline
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    for (double x = 0; x < size.width; x += 12) {
      path.lineTo(x, size.height * 0.7 + 4 * (x % 24 == 0 ? 1 : -1));
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Animated3DButton extends StatefulWidget {
  final String label;
  final Color color1;
  final Color color2;
  final VoidCallback onTap;
  const Animated3DButton({
    required this.label,
    required this.color1,
    required this.color2,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  State<Animated3DButton> createState() => _Animated3DButtonState();
}

class _Animated3DButtonState extends State<Animated3DButton> with SingleTickerProviderStateMixin {
  late AnimationController _swingController;
  late Animation<double> _swingAnimation;
  double _tapScale = 1.0;

  @override
  void initState() {
    super.initState();
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _swingAnimation = Tween<double>(begin: -0.07, end: 0.07).animate(
      CurvedAnimation(parent: _swingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _swingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _tapScale = 0.93),
      onTapUp: (_) {
        setState(() => _tapScale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _tapScale = 1.0),
              child: AnimatedScale(
          scale: _tapScale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: RotationTransition(
            turns: _swingAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
              height: MediaQuery.of(context).size.height * 0.08, // 8% of screen height
              constraints: BoxConstraints(
                maxWidth: 300,
                minWidth: 200,
                maxHeight: 80,
                minHeight: 50,
              ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [widget.color1, widget.color2],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.18),
                  blurRadius: 2,
                  offset: const Offset(-2, -2),
                  spreadRadius: -2,
                ),
              ],
              border: Border.all(color: Colors.brown.shade700, width: 3),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: GoogleFonts.permanentMarker(
                  textStyle: TextStyle(
                    color: Colors.brown.shade900,
                    fontSize: MediaQuery.of(context).size.width * 0.05, // 5% of screen width
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.18),
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedMenuButtons extends StatefulWidget {
  @override
  State<AnimatedMenuButtons> createState() => _AnimatedMenuButtonsState();
}

class _AnimatedMenuButtonsState extends State<AnimatedMenuButtons> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<Offset>> _slideAnimations;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<double>> _scaleAnimations;
  final List<_ButtonData> _buttons = [
    _ButtonData('ADDITION', Colors.amber, Colors.amber, CalculationType.addition),
    _ButtonData('SUBTRACTION', Colors.orange, Colors.orange, CalculationType.subtraction),
    _ButtonData('MULTIPLICATION', Colors.greenAccent, Colors.green, CalculationType.multiplication),
    _ButtonData('DIVISION', Colors.blueAccent, Colors.blue, CalculationType.division),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_buttons.length, (i) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    ));
    _slideAnimations = _controllers.map((c) => Tween<Offset>(
      begin: const Offset(0, 0.7), end: Offset.zero,
    ).animate(CurvedAnimation(parent: c, curve: Curves.elasticOut))).toList();
    _fadeAnimations = _controllers.map((c) => Tween<double>(
      begin: 0, end: 1,
    ).animate(CurvedAnimation(parent: c, curve: Curves.easeIn))).toList();
    _scaleAnimations = _controllers.map((c) => Tween<double>(
      begin: 0.7, end: 1.0,
    ).animate(CurvedAnimation(parent: c, curve: Curves.elasticOut))).toList();
    _runStaggered();
  }

  void _runStaggered() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_buttons.length, (i) {
        final b = _buttons[i];
        return SlideTransition(
          position: _slideAnimations[i],
          child: FadeTransition(
            opacity: _fadeAnimations[i],
            child: ScaleTransition(
              scale: _scaleAnimations[i],
              child: Animated3DButton(
                label: b.label,
                color1: b.color1,
                color2: b.color2,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LevelSelectionPage(calculationType: b.type),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ButtonData {
  final String label;
  final Color color1;
  final Color color2;
  final CalculationType type;
  _ButtonData(this.label, this.color1, this.color2, this.type);
}

class Level {
  final int gridSize;
  final int numGroups;
  final int timeLimit;
  final CalculationType type;
  final int levelNumber;
  Level({required this.gridSize, required this.numGroups, required this.timeLimit, required this.type, required this.levelNumber});
}

class LevelSelectionPage extends StatelessWidget {
  final CalculationType calculationType;
  final List<Level> levels;
  LevelSelectionPage({Key? key, required this.calculationType})
      : levels = List.generate(10, (i) {
          int gridSize = 5 + (i ~/ 2); // 5,5,6,6,7,7,8,8,9,9
          int numGroups = (gridSize * gridSize / 3).round(); // More groups for larger grids
          // AGGRESSIVE FIX: ALWAYS HAVE REASONABLE GROUPS
          if (numGroups <= 0 || numGroups > 20) {
            numGroups = (gridSize * gridSize / 4).round(); // More conservative
          }
          if (numGroups < 3) {
            numGroups = 3; // Minimum 3 groups
          }
          if (numGroups > 15) {
            numGroups = 15; // Maximum 15 groups
          }
          
          print('DEBUG LEVEL: Level ${i+1}, gridSize=$gridSize, numGroups=$numGroups, type=$calculationType');
          
          // REDUCED TIME FOR HIGHER LEVELS - MORE CHALLENGING
          int baseTime = (gridSize * numGroups * 0.3).round(); // Reduced multiplier from 0.5 to 0.3
          int timeLimit = max(20, baseTime); // Reduced minimum from 30 to 20
          
          // Additional time reduction for higher levels
          if (i >= 5) { // Levels 6-10
            timeLimit = (timeLimit * 0.7).round(); // 30% less time
          }
          if (i >= 8) { // Levels 9-10
            timeLimit = (timeLimit * 0.8).round(); // Additional 20% less time
          }
          
          // Ensure minimum time
          timeLimit = max(15, timeLimit); // Minimum 15 seconds
          
          print('DEBUG LEVEL: Level ${i+1}, gridSize=$gridSize, numGroups=$numGroups, timeLimit=${timeLimit}s, type=$calculationType');
          
          // RESPECT USER'S CHOICE - don't override calculation type
          return Level(
            gridSize: gridSize,
            numGroups: numGroups,
            timeLimit: timeLimit,
            type: calculationType, // Use user's selected type
            levelNumber: i + 1,
          );
        }),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    final isLargeScreen = screenSize.height > 800;
    final crossAxisCount = screenSize.width > 600 ? 3 : 2; // 3 columns on tablets
    
    return Scaffold(
      backgroundColor: const Color(0xFF2D3A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Select Level', 
          style: GoogleFonts.permanentMarker(
            color: Colors.white,
            fontSize: isSmallScreen ? 18 : 24,
          )
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 16 : 24, 
          horizontal: isSmallScreen ? 8 : 12
        ),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: isSmallScreen ? 1.0 : 1.2,
            crossAxisSpacing: isSmallScreen ? 8 : 16,
            mainAxisSpacing: isSmallScreen ? 8 : 16,
          ),
          itemCount: levels.length,
          itemBuilder: (context, index) {
            final level = levels[index];
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 206, 169, 57),
                foregroundColor: Colors.brown.shade900,
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.brown.shade700, width: 3),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 4 : 8, 
                  vertical: isSmallScreen ? 4 : 8
                ),
                textStyle: GoogleFonts.permanentMarker(
                  fontSize: isSmallScreen ? 16 : 22, 
                  fontWeight: FontWeight.bold
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PuzzlePage(
                      calculationType: calculationType,
                      level: level,
                    ),
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Level ${level.levelNumber}', 
                    style: GoogleFonts.permanentMarker(
                      fontSize: isSmallScreen ? 18 : 24
                    )
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Text(
                    'Grid: ${level.gridSize}x${level.gridSize}', 
                    style: GoogleFonts.permanentMarker(
                      fontSize: isSmallScreen ? 12 : 16
                    )
                  ),
                  Text(
                    'Time: ${level.timeLimit}s', 
                    style: GoogleFonts.permanentMarker(
                      fontSize: isSmallScreen ? 12 : 16
                    )
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _buildButton(BuildContext context, String label, CalculationType type, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 32),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.brown.shade900,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.brown.shade700, width: 3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        textStyle: GoogleFonts.permanentMarker(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LevelSelectionPage(calculationType: type),
          ),
        );
      },
      child: Text(label),
    ),
  );
} 