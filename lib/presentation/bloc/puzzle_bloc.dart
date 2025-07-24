import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import '../pages/calculation_type_selection_page.dart';

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
  final List<List<String>> generatedGroups;
  final bool puzzleComplete;
  final int secondsLeft;
  final int score;
  final bool gameOver;
  final List<List<String>> remainingGroups;

  const PuzzleState({
    required this.grid,
    required this.selectedCells,
    required this.targetSum,
    required this.currentSum,
    required this.isSuccess,
    required this.foundGroups,
    required this.generatedGroups,
    required this.puzzleComplete,
    required this.secondsLeft,
    required this.score,
    required this.gameOver,
    required this.remainingGroups,
  });

  PuzzleState copyWith({
    List<List<int>>? grid,
    Set<String>? selectedCells,
    int? targetSum,
    int? currentSum,
    bool? isSuccess,
    List<List<String>>? foundGroups,
    List<List<String>>? generatedGroups,
    bool? puzzleComplete,
    int? secondsLeft,
    int? score,
    bool? gameOver,
    List<List<String>>? remainingGroups,
  }) {
    return PuzzleState(
      grid: grid ?? this.grid,
      selectedCells: selectedCells ?? this.selectedCells,
      targetSum: targetSum ?? this.targetSum,
      currentSum: currentSum ?? this.currentSum,
      isSuccess: isSuccess ?? this.isSuccess,
      foundGroups: foundGroups ?? this.foundGroups,
      generatedGroups: generatedGroups ?? this.generatedGroups,
      puzzleComplete: puzzleComplete ?? this.puzzleComplete,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      score: score ?? this.score,
      gameOver: gameOver ?? this.gameOver,
      remainingGroups: remainingGroups ?? this.remainingGroups,
    );
  }

  @override
  List<Object?> get props => [grid, selectedCells, targetSum, currentSum, isSuccess, foundGroups, generatedGroups, puzzleComplete, secondsLeft, score, gameOver, remainingGroups];
}

// BLoC
class PuzzleBloc extends Bloc<PuzzleEvent, PuzzleState> {
  static const int defaultGridSize = 7;
  static const int minValue = 1;
  static const int maxValue = 9;

  final CalculationType calculationType;
  final Level? level;

  late final Ticker _ticker;

  PuzzleBloc({required this.calculationType, this.level}) : super(_initialState(calculationType, level)) {
    on<CellToggled>(_onCellToggled);
    on<PuzzleReset>(_onPuzzleReset);
    on<TimerTicked>(_onTimerTicked);
    _ticker = Ticker((Duration elapsed) {
      final seconds = (level?.timeLimit ?? 30) - elapsed.inSeconds;
      if (seconds >= 0 && !state.gameOver && !state.puzzleComplete) {
        add(TimerTicked(seconds));
      }
    });
    _ticker.start();
  }

  static PuzzleState _initialState(CalculationType calculationType, Level? level) {
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    final gridSize = level?.gridSize ?? defaultGridSize;
    final avgGroupLength = 4;
    final maxGroups = ((gridSize * gridSize) / avgGroupLength).floor() - 1;
    final numGroups = min(level?.numGroups ?? 4, maxGroups);
    final timeLimit = level?.timeLimit ?? 30;
    final opType = level?.type ?? calculationType;
    final levelNumber = level?.levelNumber ?? 1;
    final grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
    int targetValue;
    final usedCells = <String>{};
    List<List<int>> groupValues = [];
    List<List<String>> generatedGroups = [];
    int groupsPlaced = 0;
    int maxAttempts = numGroups * 200;
    int attempts = 0;
    while (groupsPlaced < numGroups && attempts < maxAttempts) {
      attempts++;
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
      // Check if all cells are available and not used by previous groups
      bool canPlace = true;
      List<String> groupCells = [];
      for (int i = 0; i < len; i++) {
        int rr = r0 + dr * i;
        int cc = c0 + dc * i;
        String cellKey = '$rr,$cc';
        if (rr < 0 || rr >= gridSize || cc < 0 || cc >= gridSize || usedCells.contains(cellKey)) {
          canPlace = false;
          break;
        }
        groupCells.add(cellKey);
      }
      if (!canPlace) continue;
      // Generate numbers and target for the group
      List<int> nums;
      int groupTarget;
      switch (opType) {
        case CalculationType.addition:
          if (levelNumber <= 3) {
            groupTarget = 10 + random.nextInt(16); // 10–25
          } else if (levelNumber <= 6) {
            groupTarget = 20 + random.nextInt(21); // 20–40
          } else {
            groupTarget = 30 + random.nextInt(31); // 30–60
          }
          nums = _randomPartition(groupTarget, len, random);
          break;
        case CalculationType.subtraction:
          int restSum = 5 + random.nextInt(15 + levelNumber * 2);
          nums = _randomPartition(restSum, len - 1, random);
          int first = restSum + (3 + random.nextInt(10 + levelNumber * 2));
          nums = [first, ...nums];
          groupTarget = first - restSum;
          break;
        case CalculationType.multiplication:
          groupTarget = 2 + levelNumber + random.nextInt(6 + levelNumber);
          nums = _randomProductPartition(groupTarget, len, random);
          break;
        case CalculationType.division:
          int restProduct = 2 + random.nextInt(5 + levelNumber);
          nums = _randomProductPartition(restProduct, len - 1, random);
          int first = restProduct * (2 + random.nextInt(5 + levelNumber));
          nums = [first, ...nums];
          groupTarget = first ~/ restProduct;
          break;
      }
      for (int i = 0; i < len; i++) {
        int rr = r0 + dr * i;
        int cc = c0 + dc * i;
        grid[rr][cc] = nums[i];
        usedCells.add(groupCells[i]);
      }
      groupValues.add(nums);
      generatedGroups.add(groupCells);
      groupsPlaced++;
    }
    targetValue = groupValues.isNotEmpty ? _getGroupTarget(groupValues[0], opType) : 0;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] == 0) {
          int val;
          do {
            val = minValue + random.nextInt(maxValue - minValue + 1);
            grid[r][c] = val;
          } while (_cellCreatesNewGroup(grid, r, c, targetValue));
        }
      }
    }
    return PuzzleState(
      grid: grid,
      selectedCells: <String>{},
      targetSum: targetValue,
      currentSum: 0,
      isSuccess: false,
      foundGroups: [],
      generatedGroups: generatedGroups,
      puzzleComplete: false,
      secondsLeft: timeLimit,
      score: 0,
      gameOver: false,
      remainingGroups: List.from(generatedGroups),
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

  static List<int> _randomProductPartition(int product, int n, Random random) {
    if (n == 1) return [product];
    List<int> parts = [];
    int remaining = product;
    for (int i = 0; i < n - 1; i++) {
      int factor = 1 + random.nextInt(remaining > 10 ? 9 : remaining - 1);
      parts.add(factor);
      remaining = remaining ~/ factor;
      if (remaining <= 1) remaining = 2;
    }
    parts.add(remaining);
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

  static int _getGroupTarget(List<int> nums, CalculationType type) {
    switch (type) {
      case CalculationType.addition:
        return nums.reduce((a, b) => a + b);
      case CalculationType.subtraction:
        if (nums.length == 2) {
          return (nums[0] - nums[1]).abs();
        } else if (nums.length > 2) {
          final maxVal = nums.reduce((a, b) => a > b ? a : b);
          int sumOthers = 0;
          for (final v in nums) {
            if (v != maxVal) sumOthers += v;
          }
          return maxVal - sumOthers;
        }
        return 0;
      case CalculationType.multiplication:
        return nums.reduce((a, b) => a * b);
      case CalculationType.division:
        if (nums.length < 2) return 0;
        int divisor = 1;
        for (int i = 1; i < nums.length; i++) {
          final int value = nums[i];
          divisor *= value;
        }
        return divisor == 0 ? 0 : nums[0] ~/ divisor;
    }
  }

  void _onCellToggled(CellToggled event, Emitter<PuzzleState> emit) {
    final key = '${event.row},${event.col}';
    final selected = Set<String>.from(state.selectedCells);
    if (selected.contains(key)) {
      selected.remove(key);
    } else {
      selected.add(key);
    }
    int? calcResult;
    switch (calculationType) {
      case CalculationType.addition:
        calcResult = selected.fold(0, (acc, cell) {
          final parts = cell.split(',');
          final r = int.parse(parts[0]);
          final c = int.parse(parts[1]);
          return acc! + state.grid[r][c];
        });
        break;
      case CalculationType.subtraction:
        if (selected.length == 2) {
          final values = selected.map((cell) {
            final parts = cell.split(',');
            final r = int.parse(parts[0]);
            final c = int.parse(parts[1]);
            return state.grid[r][c];
          }).toList();
          calcResult = (values[0] - values[1]).abs();
        } else if (selected.length > 2) {
          final values = selected.map((cell) {
            final parts = cell.split(',');
            final r = int.parse(parts[0]);
            final c = int.parse(parts[1]);
            return state.grid[r][c];
          }).toList();
          final maxVal = values.reduce((a, b) => a > b ? a : b);
          int sumOthers = 0;
          for (final v in values) {
            if (v != maxVal) sumOthers += v;
          }
          calcResult = maxVal - sumOthers;
        }
        break;
      case CalculationType.multiplication:
        if (selected.isNotEmpty) {
          calcResult = selected.fold(1, (acc, cell) {
            final parts = cell.split(',');
            final r = int.parse(parts[0]);
            final c = int.parse(parts[1]);
            return acc! * state.grid[r][c];
          });
        }
        break;
      case CalculationType.division:
        if (selected.isNotEmpty) {
          final values = selected.map((cell) {
            final parts = cell.split(',');
            final r = int.parse(parts[0]);
            final c = int.parse(parts[1]);
            return state.grid[r][c];
          }).toList();
          final divisor = values.skip(1).fold(1, (a, b) => a * b);
          if (divisor != 0) {
            calcResult = values[0] ~/ divisor;
          }
        }
        break;
    }
    bool isNewGroup = selected.isNotEmpty &&
      calcResult == state.targetSum &&
      !state.foundGroups.any((g) => Set.from(g).containsAll(selected) && g.length == selected.length);
    final foundGroups = List<List<String>>.from(state.foundGroups);
    int score = state.score;
    bool puzzleComplete = state.puzzleComplete;
    bool gameOver = state.gameOver;
    if (isNewGroup) {
      foundGroups.add(selected.toList());
      score += 10;

      // Remove the matched group from remainingGroups
      final remaining = List<List<String>>.from(state.remainingGroups);
      remaining.removeWhere((gen) => Set.from(gen).containsAll(selected) && gen.length == selected.length);

      puzzleComplete = remaining.isEmpty;
      if (puzzleComplete) {
        gameOver = true;
        _ticker.stop();
      }
      emit(state.copyWith(
        selectedCells: {},
        currentSum: 0,
        isSuccess: false,
        foundGroups: foundGroups,
        remainingGroups: remaining,
        puzzleComplete: puzzleComplete,
        score: score,
        gameOver: gameOver,
      ));
    } else {
      emit(state.copyWith(
        selectedCells: selected,
        currentSum: calcResult ?? 0,
        isSuccess: calcResult == state.targetSum,
      ));
    }
  }

  void _onPuzzleReset(PuzzleReset event, Emitter<PuzzleState> emit) {
    _ticker.stop();
    emit(_initialState(calculationType, level));
    _ticker.start();
  }

  void _onTimerTicked(TimerTicked event, Emitter<PuzzleState> emit) {
    if (event.secondsLeft <= 0) {
      emit(state.copyWith(secondsLeft: 0, gameOver: true));
      _ticker.stop();
    } else {
      emit(state.copyWith(secondsLeft: event.secondsLeft));
    }
  }

  static List<List<String>> _findAllGroups(List<List<int>> grid, int target, CalculationType type) {
    final groups = <List<String>>[];
    final n = grid.length;
    // Horizontal
    for (int r = 0; r < n; r++) {
      for (int c1 = 0; c1 < n; c1++) {
        final cells = <String>[];
        for (int c2 = c1; c2 < n; c2++) {
          cells.add('$r,$c2');
          final values = cells.map((cell) {
            final parts = cell.split(',');
            final rr = int.parse(parts[0]);
            final cc = int.parse(parts[1]);
            return grid[rr][cc];
          }).toList();
          if (_getGroupTarget(values, type) == target && cells.length > 1) {
            groups.add(List.from(cells));
          }
        }
      }
    }
    // Vertical
    for (int c = 0; c < n; c++) {
      for (int r1 = 0; r1 < n; r1++) {
        final cells = <String>[];
        for (int r2 = r1; r2 < n; r2++) {
          cells.add('$r2,$c');
          final values = cells.map((cell) {
            final parts = cell.split(',');
            final rr = int.parse(parts[0]);
            final cc = int.parse(parts[1]);
            return grid[rr][cc];
          }).toList();
          if (_getGroupTarget(values, type) == target && cells.length > 1) {
            groups.add(List.from(cells));
          }
        }
      }
    }
    // Diagonal (top-left to bottom-right)
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final cells = <String>[];
        int rr = r, cc = c;
        while (rr < n && cc < n) {
          cells.add('$rr,$cc');
          final values = cells.map((cell) {
            final parts = cell.split(',');
            final rrr = int.parse(parts[0]);
            final ccc = int.parse(parts[1]);
            return grid[rrr][ccc];
          }).toList();
          if (_getGroupTarget(values, type) == target && cells.length > 1) {
            groups.add(List.from(cells));
          }
          rr++;
          cc++;
        }
      }
    }
    // Diagonal (top-right to bottom-left)
    for (int r = 0; r < n; r++) {
      for (int c = n - 1; c >= 0; c--) {
        final cells = <String>[];
        int rr = r, cc = c;
        while (rr < n && cc >= 0) {
          cells.add('$rr,$cc');
          final values = cells.map((cell) {
            final parts = cell.split(',');
            final rrr = int.parse(parts[0]);
            final ccc = int.parse(parts[1]);
            return grid[rrr][ccc];
          }).toList();
          if (_getGroupTarget(values, type) == target && cells.length > 1) {
            groups.add(List.from(cells));
          }
          rr++;
          cc--;
        }
      }
    }
    return groups;
  }
} 