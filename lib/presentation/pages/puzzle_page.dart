import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/puzzle_bloc.dart';
import 'calculation_type_selection_page.dart';
import 'package:confetti/confetti.dart';

class PuzzlePage extends StatelessWidget {
  final CalculationType calculationType;
  final Level? level;
  const PuzzlePage({Key? key, required this.calculationType, this.level}) : super(key: key);

  String getOperationSymbol() {
    switch (calculationType) {
      case CalculationType.addition:
        return '+';
      case CalculationType.subtraction:
        return '-';
      case CalculationType.multiplication:
        return '×';
      case CalculationType.division:
        return '÷';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    final isLargeScreen = screenSize.height > 800;
    final isTablet = screenSize.width > 600;
    
    return BlocProvider(
      create: (_) => PuzzleBloc(calculationType: calculationType, level: level),
      child: Scaffold(
        backgroundColor: const Color(0xFF2D3A2E), // Chalkboard green
        // Remove the AppBar
        body: SafeArea(
          bottom: false, // Don't add bottom safe area padding
          child: Column(
            children: [
              // Add bottom padding to prevent content from being cut off
              SizedBox(height: MediaQuery.of(context).padding.bottom),
              Padding(
                padding: EdgeInsets.only(
                  top: isSmallScreen ? 8 : 16, 
                  left: isSmallScreen ? 4 : 8, 
                  right: isSmallScreen ? 4 : 8, 
                  bottom: isSmallScreen ? 4 : 8
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back, 
                        color: Colors.white, 
                        size: isSmallScreen ? 24 : 30
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 8),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Math Puzzle',
                          style: GoogleFonts.permanentMarker(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 24 : (isLargeScreen ? 40 : 32),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.4),
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              BlocBuilder<PuzzleBloc, PuzzleState>(
                builder: (context, state) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12.0 : 16.0, 
                      vertical: isSmallScreen ? 2 : 4
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('⏰ ${state.secondsLeft}s',
                            style: GoogleFonts.permanentMarker(
                              textStyle: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 16 : 20,
                              ),
                            )),
                        Text('Score: ${state.score}',
                            style: GoogleFonts.permanentMarker(
                              textStyle: TextStyle(
                                color: Colors.amber,
                                fontSize: isSmallScreen ? 16 : 20,
                              ),
                            )),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 2.0 : 4.0),
                child: Text(
                  'Operation: ${getOperationSymbol()}',
                  style: GoogleFonts.permanentMarker(
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : (isLargeScreen ? 28 : 22),
                    ),
                  ),
                ),
              ),
              BlocBuilder<PuzzleBloc, PuzzleState>(
                builder: (context, state) {
                  return Text(
                    'Target: ${state.targetSum}',
                    style: GoogleFonts.permanentMarker(
                      textStyle: TextStyle(
                        color: Colors.amber,
                        fontSize: isSmallScreen ? 20 : (isLargeScreen ? 32 : 26),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isSmallScreen ? 4 : 8),
              Expanded(
                child: BlocBuilder<PuzzleBloc, PuzzleState>(
                  builder: (context, state) {
                    print('DEBUG UI: gameOver=${state.gameOver}, puzzleComplete=${state.puzzleComplete}, foundGroups=${state.foundGroups.length}/${state.requiredGroups}');
                    if (state.gameOver) {
                      return state.puzzleComplete
                          ? const WinCelebration()
                          : const LoseMessage();
                    }
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4.0 : 8.0),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: state.grid.length,
                          childAspectRatio: 1,
                        ),
                        itemCount: state.grid.length * state.grid.length,
                        itemBuilder: (context, index) {
                          final row = index ~/ state.grid.length;
                          final col = index % state.grid.length;
                          final value = state.grid[row][col];
                          final key = '$row,$col';
                          final isSelected = state.selectedCells.contains(key);
                          final isFound = state.foundGroups.any((g) => g.contains(key));
                          return Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 2.0 : 4.0),
                            child: GestureDetector(
                              onTap: () {
                                context.read<PuzzleBloc>().add(CellToggled(row, col));
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isFound
                                      ? Colors.greenAccent.shade400
                                      : isSelected
                                          ? Colors.amber.shade200
                                          : const Color(0xFFF9D857),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 6,
                                      offset: const Offset(2, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isFound
                                        ? Colors.green.shade900
                                        : isSelected
                                            ? Colors.amber.shade700
                                            : Colors.brown.shade400,
                                    width: 3,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$value',
                                    style: GoogleFonts.permanentMarker(
                                      textStyle: TextStyle(
                                        color: isFound
                                            ? Colors.white
                                            : Colors.brown.shade900,
                                        fontSize: isSmallScreen ? 18 : (isLargeScreen ? 32 : 26),
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 2,
                                            color: Colors.black.withOpacity(0.2),
                                            offset: const Offset(1, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              // BOTTOM SECTION OUTSIDE EXPANDED
              BlocBuilder<PuzzleBloc, PuzzleState>(
                builder: (context, state) {
                  return Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 0.0 : 6.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Groups found: ${state.foundGroups.length}',
                          style: GoogleFonts.permanentMarker(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 14 : 18,
                            ),
                          ),
                        ),
                        if (state.puzzleComplete && !state.gameOver)
                          Padding(
                            padding: EdgeInsets.only(top: isSmallScreen ? 4.0 : 8.0),
                            child: Text(
                              'Puzzle Complete! 🎉',
                              style: GoogleFonts.permanentMarker(
                                textStyle: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 16 : (isLargeScreen ? 28 : 22),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: isSmallScreen ? 2 : 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 24 : 32, 
                              vertical: isSmallScreen ? 8 : 12
                            ),
                            textStyle: GoogleFonts.permanentMarker(
                              fontSize: isSmallScreen ? 14 : 18
                            ),
                          ),
                          onPressed: () {
                            context.read<PuzzleBloc>().add(PuzzleReset());
                          },
                          child: const Text('Reset'),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        Container(
                          height: isSmallScreen ? 16 : 24,
                          decoration: BoxDecoration(
                            color: Colors.brown.shade800,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // Wood trim at the bottom
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

class WinCelebration extends StatefulWidget {
  const WinCelebration({Key? key}) : super(key: key);
  @override
  State<WinCelebration> createState() => _WinCelebrationState();
}

class _WinCelebrationState extends State<WinCelebration> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _textController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2))..play();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    final isLargeScreen = screenSize.height > 800;
    final fontSize = isSmallScreen ? 16.0 : (isLargeScreen ? 40.0 : 32.0);
    final emojiSize = isSmallScreen ? 32.0 : (isLargeScreen ? 64.0 : 48.0);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          emissionFrequency: 0.05,
          numberOfParticles: 30,
          maxBlastForce: 20,
          minBlastForce: 8,
          gravity: 0.2,
        ),
        ScaleTransition(
          scale: CurvedAnimation(parent: _textController, curve: Curves.elasticOut),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CONGRATULATIONS! YOU WIN!',
                textAlign: TextAlign.center,
                style: GoogleFonts.permanentMarker(
                  textStyle: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 4 : 8),
              ScaleTransition(
                scale: Tween<double>(begin: 0.7, end: 1.2)
                    .animate(CurvedAnimation(parent: _textController, curve: Curves.elasticOut)),
                child: Text('🎉', style: TextStyle(fontSize: emojiSize)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LoseMessage extends StatefulWidget {
  const LoseMessage({Key? key}) : super(key: key);

  @override
  State<LoseMessage> createState() => _LoseMessageState();
}

class _LoseMessageState extends State<LoseMessage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late AnimationController _colorAnimController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    _colorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _colorAnimController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    final isLargeScreen = screenSize.height > 800;
    final fontSize = isSmallScreen ? 20.0 : (isLargeScreen ? 40.0 : 32.0);
    final emojiSize = isSmallScreen ? 28.0 : (isLargeScreen ? 56.0 : 40.0);
    
    return Center(
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedBuilder(
          animation: _colorAnimController,
          builder: (context, child) {
            final t = _colorAnimController.value;
            final color1 = Color.lerp(Colors.red.shade700, Colors.orange.shade700, t)!;
            final color2 = Color.lerp(Colors.black, Colors.red.shade900, t)!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors: [color1, color2],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    'You Lose!\nTime Up!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.permanentMarker(
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 8),
                Text('⏰', style: TextStyle(fontSize: emojiSize)), // Emoji not masked
              ],
            );
          },
        ),
      ),
    );
  }
} 