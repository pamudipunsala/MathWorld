import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:math';
import 'package:flutter/scheduler.dart';

// Event
abstract class PuzzleEvent extends Equatable {
  const PuzzleEvent();
  @override
  List<Object?> get props => [];
}

class CellToggled extends PuzzleEvent {
  final int row;
  final int col;
  const CellToggled(this.row, this.col);
  @override
  List<Object?> get props => [row, col];
}

class PuzzleReset extends PuzzleEvent {}

class DragSelectStart extends PuzzleEvent {
  final int row;
  final int col;
  const DragSelectStart(this.row, this.col);
  @override
  List<Object?> get props => [row, col];
}

class DragSelectUpdate extends PuzzleEvent {
  final int row;
  final int col;
  const DragSelectUpdate(this.row, this.col);
  @override
  List<Object?> get props => [row, col];
}

class DragSelectEnd extends PuzzleEvent {}

class TimerTicked extends PuzzleEvent {
  final int secondsLeft;
  const TimerTicked(this.secondsLeft);
  @override
  List<Object?> get props => [secondsLeft];
}

// State
class PuzzleState extends Equatable {
  final List<List<int>> grid;
  final Set<String> selectedCells;
  final int targetSum;
  final int currentSum;
  final bool isSuccess;
  final List<List<String>> foundGroups; // Each group is a list of cell keys
  final bool puzzleComplete;
  final int secondsLeft;
  final int score;
  final bool gameOver;

  const PuzzleState({
    required this.grid,
    required this.selectedCells,
    required this.targetSum,
    required this.currentSum,
    required this.isSuccess,
    required this.foundGroups,
    required this.puzzleComplete,
    required this.secondsLeft,
    required this.score,
    required this.gameOver,
  });

  PuzzleState copyWith({
    List<List<int>>? grid,
    Set<String>? selectedCells,
    int? targetSum,
    int? currentSum,
    bool? isSuccess,
    List<List<String>>? foundGroups,
    bool? puzzleComplete,
    int? secondsLeft,
    int? score,
    bool? gameOver,
  }) {
    return PuzzleState(
      grid: grid ?? this.grid,
      selectedCells: selectedCells ?? this.selectedCells,
      targetSum: targetSum ?? this.targetSum,
      currentSum: currentSum ?? this.currentSum,
      isSuccess: isSuccess ?? this.isSuccess,
      foundGroups: foundGroups ?? this.foundGroups,
      puzzleComplete: puzzleComplete ?? this.puzzleComplete,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      score: score ?? this.score,
      gameOver: gameOver ?? this.gameOver,
    );
  }

  @override
  List<Object?> get props => [grid, selectedCells, targetSum, currentSum, isSuccess, foundGroups, puzzleComplete, secondsLeft, score, gameOver];
}

// BLoC
class PuzzleBloc extends Bloc<PuzzleEvent, PuzzleState> {
  static const int gridSize = 5;
  static const int minValue = 1;
  static const int maxValue = 9;

  late final Ticker _ticker;

  PuzzleBloc() : super(_initialState()) {
    on<CellToggled>(_onCellToggled);
    on<PuzzleReset>(_onPuzzleReset);
    on<TimerTicked>(_onTimerTicked);
    _ticker = Ticker((Duration elapsed) {
      final seconds = 80 - elapsed.inSeconds;
      if (seconds >= 0 && !state.gameOver && !state.puzzleComplete) {
        add(TimerTicked(seconds));
      }
    });
    _ticker.start();
  }

  static PuzzleState _initialState() {
    final random = Random();
    const int numGroups = 4; // Number of valid groups to generate
    final grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
    final targetSum = 15;
    final usedCells = <String>{};
    // Helper to check if a cell is available
    bool isAvailable(int r, int c) => r >= 0 && r < gridSize && c >= 0 && c < gridSize && !usedCells.contains('$r,$c');
    // Place groups
    for (int g = 0; g < numGroups; g++) {
      bool placed = false;
      for (int attempt = 0; attempt < 100 && !placed; attempt++) {
        // Randomly choose direction: 0=horizontal, 1=vertical, 2=diag TL-BR, 3=diag TR-BL
        final dir = random.nextInt(4);
        final len = 3 + random.nextInt(gridSize - 2); // group length 3 to gridSize
        int dr = 0, dc = 0;
        switch (dir) {
          case 0: dr = 0; dc = 1; break; // horizontal
          case 1: dr = 1; dc = 0; break; // vertical
          case 2: dr = 1; dc = 1; break; // diag TL-BR
          case 3: dr = 1; dc = -1; break; // diag TR-BL
        }
        int r0, c0;
        if (dir == 3) {
          r0 = random.nextInt(gridSize - len + 1);
          c0 = random.nextInt(gridSize - len + 1) + len - 1;
        } else {
          r0 = random.nextInt(gridSize - (dr * (len - 1)));
          c0 = random.nextInt(gridSize - (dc * (len - 1)));
        }
        // Check if all cells are available
        bool canPlace = true;
        for (int i = 0; i < len; i++) {
          int rr = r0 + dr * i;
          int cc = c0 + dc * i;
          if (!isAvailable(rr, cc)) {
            canPlace = false;
            break;
          }
        }
        if (!canPlace) continue;
        // Generate random numbers that sum to targetSum
        final nums = _randomPartition(targetSum, len, random);
        for (int i = 0; i < len; i++) {
          int rr = r0 + dr * i;
          int cc = c0 + dc * i;
          grid[rr][cc] = nums[i];
          usedCells.add('$rr,$cc');
        }
        placed = true;
      }
    }
    // Fill the rest of the grid with random numbers (1-9) that do not create new valid groups
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] == 0) {
          int val;
          do {
            val = minValue + random.nextInt(maxValue - minValue + 1);
            grid[r][c] = val;
          } while (_cellCreatesNewGroup(grid, r, c, targetSum));
        }
      }
    }
    return PuzzleState(
      grid: grid,
      selectedCells: <String>{},
      targetSum: targetSum,
      currentSum: 0,
      isSuccess: false,
      foundGroups: [],
      puzzleComplete: false,
      secondsLeft: 80,
      score: 0,
      gameOver: false,
    );
  }

  // Helper: generate a random partition of sum into n positive integers
  static List<int> _randomPartition(int sum, int n, Random random) {
    if (n == 1) return [sum];
    final cuts = <int>[0, sum];
    for (int i = 0; i < n - 1; i++) {
      cuts.add(1 + random.nextInt(sum - 1));
    }
    cuts.sort();
    final parts = <int>[];
    for (int i = 1; i < cuts.length; i++) {
      parts.add(cuts[i] - cuts[i - 1]);
    }
    return parts;
  }

  // Helper: check if placing a value at (r,c) creates a new valid group
  static bool _cellCreatesNewGroup(List<List<int>> grid, int r, int c, int targetSum) {
    final n = grid.length;
    // Check all 4 directions for new valid groups of length >= 2
    for (final dir in [const [0, 1], const [1, 0], const [1, 1], const [1, -1]]) {
      for (int len = 2; len <= n; len++) {
        int sum = 0;
        bool inBounds = true;
        for (int i = 0; i < len; i++) {
          int rr = r - dir[0] * i;
          int cc = c - dir[1] * i;
          if (rr < 0 || rr >= n || cc < 0 || cc >= n) {
            inBounds = false;
            break;
          }
          sum += grid[rr][cc];
        }
        if (inBounds && sum == targetSum) return true;
      }
    }
    return false;
  }

  void _onCellToggled(CellToggled event, Emitter<PuzzleState> emit) {
    final key = '${event.row},${event.col}';
    final selected = Set<String>.from(state.selectedCells);
    if (selected.contains(key)) {
      selected.remove(key);
    } else {
      selected.add(key);
    }
    int sum = 0;
    for (final cell in selected) {
      final parts = cell.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      sum += state.grid[r][c];
    }
    bool isNewGroup = selected.isNotEmpty &&
      sum == state.targetSum &&
      !state.foundGroups.any((g) => Set.from(g).containsAll(selected) && g.length == selected.length);
    final foundGroups = List<List<String>>.from(state.foundGroups);
    int score = state.score;
    bool puzzleComplete = state.puzzleComplete;
    bool gameOver = state.gameOver;
    if (isNewGroup) {
      foundGroups.add(selected.toList());
      score += 10;
      // Check if all possible groups are found
      final allGroups = _findAllGroups(state.grid, state.targetSum);
      puzzleComplete = foundGroups.length == allGroups.length;
      if (puzzleComplete) {
        gameOver = true;
        _ticker.stop();
      }
      emit(state.copyWith(
        selectedCells: {},
        currentSum: 0,
        isSuccess: false,
        foundGroups: foundGroups,
        puzzleComplete: puzzleComplete,
        score: score,
        gameOver: gameOver,
      ));
    } else {
      emit(state.copyWith(
        selectedCells: selected,
        currentSum: sum,
        isSuccess: sum == state.targetSum,
      ));
    }
  }

  void _onPuzzleReset(PuzzleReset event, Emitter<PuzzleState> emit) {
    emit(_initialState());
  }

  void _onTimerTicked(TimerTicked event, Emitter<PuzzleState> emit) {
    if (event.secondsLeft <= 0) {
      emit(state.copyWith(secondsLeft: 0, gameOver: true));
      _ticker.stop();
    } else {
      emit(state.copyWith(secondsLeft: event.secondsLeft));
    }
  }

  static List<List<String>> _findAllGroups(List<List<int>> grid, int targetSum) {
    // Brute force: find all horizontal, vertical, and diagonal groups
    final groups = <List<String>>[];
    final n = grid.length;
    // Horizontal
    for (int r = 0; r < n; r++) {
      for (int c1 = 0; c1 < n; c1++) {
        int sum = 0;
        final cells = <String>[];
        for (int c2 = c1; c2 < n; c2++) {
          sum += grid[r][c2];
          cells.add('$r,$c2');
          if (sum == targetSum && cells.length > 1) {
            groups.add(List.from(cells));
          }
          if (sum >= targetSum) break;
        }
      }
    }
    // Vertical
    for (int c = 0; c < n; c++) {
      for (int r1 = 0; r1 < n; r1++) {
        int sum = 0;
        final cells = <String>[];
        for (int r2 = r1; r2 < n; r2++) {
          sum += grid[r2][c];
          cells.add('$r2,$c');
          if (sum == targetSum && cells.length > 1) {
            groups.add(List.from(cells));
          }
          if (sum >= targetSum) break;
        }
      }
    }
    // Diagonal (top-left to bottom-right)
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        int sum = 0;
        final cells = <String>[];
        int rr = r, cc = c;
        while (rr < n && cc < n) {
          sum += grid[rr][cc];
          cells.add('$rr,$cc');
          if (sum == targetSum && cells.length > 1) {
            groups.add(List.from(cells));
          }
          if (sum >= targetSum) break;
          rr++;
          cc++;
        }
      }
    }
    // Diagonal (top-right to bottom-left)
    for (int r = 0; r < n; r++) {
      for (int c = n - 1; c >= 0; c--) {
        int sum = 0;
        final cells = <String>[];
        int rr = r, cc = c;
        while (rr < n && cc >= 0) {
          sum += grid[rr][cc];
          cells.add('$rr,$cc');
          if (sum == targetSum && cells.length > 1) {
            groups.add(List.from(cells));
          }
          if (sum >= targetSum) break;
          rr++;
          cc--;
        }
      }
    }
    return groups;
  }
} 