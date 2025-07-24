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
    return BlocProvider(
      create: (_) => PuzzleBloc(calculationType: calculationType, level: level),
      child: Scaffold(
        backgroundColor: const Color(0xFF2D3A2E), // Chalkboard green
        // Remove the AppBar
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 8, right: 8, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Math Puzzle',
                          style: GoogleFonts.permanentMarker(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('⏰ ${state.secondsLeft}s',
                            style: GoogleFonts.permanentMarker(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            )),
                        Text('Score: ${state.score}',
                            style: GoogleFonts.permanentMarker(
                              textStyle: const TextStyle(
                                color: Colors.amber,
                                fontSize: 20,
                              ),
                            )),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Operation: ${getOperationSymbol()}',
                  style: GoogleFonts.permanentMarker(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
              BlocBuilder<PuzzleBloc, PuzzleState>(
                builder: (context, state) {
                  return Text(
                    'Target: ${state.targetSum}',
                    style: GoogleFonts.permanentMarker(
                      textStyle: const TextStyle(
                        color: Colors.amber,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<PuzzleBloc, PuzzleState>(
                  builder: (context, state) {
                    if (state.gameOver) {
                      return state.puzzleComplete
                          ? const WinCelebration()
                          : const LoseMessage();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                            padding: const EdgeInsets.all(4.0),
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
                                        fontSize: 26,
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
              BlocBuilder<PuzzleBloc, PuzzleState>(
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Groups found: ${state.foundGroups.length}/${state.generatedGroups.length}',
                          style: GoogleFonts.permanentMarker(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (state.puzzleComplete && !state.gameOver)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Puzzle Complete! 🎉',
                              style: GoogleFonts.permanentMarker(
                                textStyle: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            textStyle: GoogleFonts.permanentMarker(fontSize: 18),
                          ),
                          onPressed: () {
                            context.read<PuzzleBloc>().add(PuzzleReset());
                          },
                          child: const Text('Reset'),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.brown.shade800,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // Wood trim at the bottom
                        Container(
                          height: 18,
                          margin: const EdgeInsets.only(top: 8),
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
                    fontSize: 32,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ScaleTransition(
                scale: Tween<double>(begin: 0.7, end: 1.2)
                    .animate(CurvedAnimation(parent: _textController, curve: Curves.elasticOut)),
                child: const Text('🎉', style: TextStyle(fontSize: 48)),
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
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('⏰', style: TextStyle(fontSize: 40)), // Emoji not masked
              ],
            );
          },
        ),
      ),
    );
  }
} 