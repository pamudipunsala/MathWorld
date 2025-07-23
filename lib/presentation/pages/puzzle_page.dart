import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/puzzle_bloc.dart';

class PuzzlePage extends StatelessWidget {
  const PuzzlePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PuzzleBloc(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Math Puzzle'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              BlocBuilder<PuzzleBloc, PuzzleState>(
                builder: (context, state) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('Time: ${state.secondsLeft}s', style: Theme.of(context).textTheme.titleLarge),
                      Text('Score: ${state.score}', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  );
                },
              ),
              BlocBuilder<PuzzleBloc, PuzzleState>(
                builder: (context, state) {
                  return Text(
                    'Sum: ${state.targetSum}',
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<PuzzleBloc, PuzzleState>(
                  builder: (context, state) {
                    if (state.gameOver) {
                      return Center(
                        child: Text(
                          state.puzzleComplete
                              ? 'Congratulations! You win! 🎉'
                              : 'Time Up! ⏰',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      );
                    }
                    return GridView.builder(
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
                        return GestureDetector(
                          onTap: () {
                            context.read<PuzzleBloc>().add(CellToggled(row, col));
                          },
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isFound
                                  ? Colors.green.withOpacity(0.7)
                                  : isSelected
                                      ? Theme.of(context).colorScheme.secondary.withOpacity(0.7)
                                      : Theme.of(context).cardColor,
                              border: Border.all(
                                color: isFound
                                    ? Colors.green
                                    : isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '$value',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ),
                        );
                      },
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
                          'Groups found: ${state.foundGroups.length}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (state.puzzleComplete && !state.gameOver)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Puzzle Complete! 🎉',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            context.read<PuzzleBloc>().add(PuzzleReset());
                          },
                          child: const Text('Reset'),
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