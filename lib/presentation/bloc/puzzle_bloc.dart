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
  final int requiredGroups;

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
    required this.requiredGroups,
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
    int? requiredGroups,
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
      requiredGroups: requiredGroups ?? this.requiredGroups,
    );
  }

  @override
  List<Object?> get props => [grid, selectedCells, targetSum, currentSum, isSuccess, foundGroups, generatedGroups, puzzleComplete, secondsLeft, score, gameOver, remainingGroups, requiredGroups];
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
    final numGroups = level?.numGroups ?? 4;
    final timeLimit = level?.timeLimit ?? 30;
    final opType = level?.type ?? calculationType;
    
    print('DEBUG: Creating puzzle with gridSize=$gridSize, numGroups=$numGroups, opType=$opType');
    
    // FORCE SIMPLE TARGETS - NO LEVEL OVERRIDE
    int targetValue = 0;
    
    // Always use simple targets regardless of level
    if (opType == CalculationType.addition) {
      targetValue = 6 + random.nextInt(4); // 6-9
    } else if (opType == CalculationType.subtraction) {
      targetValue = 1 + random.nextInt(2); // 1-2 ONLY
    } else if (opType == CalculationType.multiplication) {
      targetValue = 4 + random.nextInt(4); // 4-7
    } else { // division
      targetValue = 2 + random.nextInt(2); // 2-3
    }
    
    print('DEBUG: FORCED target $targetValue for operation $opType (ignoring level complexity)');
    
    // Create a grid with GUARANTEED working groups
    List<List<int>> grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
    
    // Place EXACTLY the required number of working groups
    List<List<String>> workingGroups = [];
    int groupsToPlace = numGroups;
    
    // Place horizontal groups first
    for (int i = 0; i < groupsToPlace && i < gridSize; i++) {
      int row = i;
      int col = 0;
      
      // Create 3 numbers that definitely work
      List<int> numbers = _createGuaranteedWorkingNumbers(targetValue, opType, random);
      
      // Place them horizontally
      grid[row][col] = numbers[0];
      grid[row][col + 1] = numbers[1];
      grid[row][col + 2] = numbers[2];
      
      workingGroups.add(['$row,$col', '$row,${col+1}', '$row,${col+2}']);
      print('DEBUG: Placed horizontal group ${i+1} with numbers $numbers for target $targetValue');
    }
    
    // Fill remaining cells with random numbers (avoiding zeros for mult/div)
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] == 0) {
          if (opType == CalculationType.multiplication || opType == CalculationType.division) {
            grid[r][c] = 2 + random.nextInt(8); // 2-9
          } else {
            grid[r][c] = 1 + random.nextInt(9); // 1-9
          }
        }
      }
    }
    
    // Verify our groups actually work
    List<List<String>> verifiedGroups = [];
    for (List<String> group in workingGroups) {
      List<int> numbers = [];
      for (String cell in group) {
        List<int> coords = cell.split(',').map((e) => int.parse(e)).toList();
        numbers.add(grid[coords[0]][coords[1]]);
      }
      
      int result = _getGroupTarget(numbers, opType);
      if (result == targetValue) {
        verifiedGroups.add(group);
        print('DEBUG: Verified group $numbers = $result (target: $targetValue)');
      } else {
        print('DEBUG: WARNING - Group $numbers = $result (expected: $targetValue)');
      }
    }
    
    // If verification failed, create a simple guaranteed group
    if (verifiedGroups.isEmpty) {
      print('DEBUG: Creating emergency guaranteed group');
      if (opType == CalculationType.subtraction) {
        grid[0][0] = targetValue + 3;
        grid[0][1] = 2;
        grid[0][2] = 1;
        verifiedGroups.add(['0,0', '0,1', '0,2']);
      } else if (opType == CalculationType.addition) {
        grid[0][0] = 1;
        grid[0][1] = 1;
        grid[0][2] = targetValue - 2;
        verifiedGroups.add(['0,0', '0,1', '0,2']);
      } else if (opType == CalculationType.multiplication) {
        grid[0][0] = 2;
        grid[0][1] = 2;
        grid[0][2] = targetValue ~/ 4;
        verifiedGroups.add(['0,0', '0,1', '0,2']);
      } else { // division
        grid[0][0] = targetValue * 2;
        grid[0][1] = 2;
        grid[0][2] = 1;
        verifiedGroups.add(['0,0', '0,1', '0,2']);
      }
    }
    
    // CALCULATE REASONABLE REQUIRED GROUPS
    int requiredGroups = numGroups; // Start with requested number
    
    // If numGroups is 0 or too small, calculate a reasonable number
    if (requiredGroups <= 0) {
      requiredGroups = (gridSize * gridSize / 6).round(); // More reasonable calculation
      if (requiredGroups < 3) {
        requiredGroups = 3; // Minimum 3 groups
      }
    }
    
    print('DEBUG: numGroups=$numGroups, calculated requiredGroups=$requiredGroups');
    
    print('DEBUG: FINAL RESULT - Target: $targetValue, Working groups: ${verifiedGroups.length}, Required: $requiredGroups');
    print('DEBUG: Verified groups: $verifiedGroups');
    print('DEBUG: Grid preview: ${grid.take(3).map((row) => row.take(3).toList()).toList()}');
    
    return PuzzleState(
      grid: grid,
      selectedCells: <String>{},
      targetSum: targetValue,
      currentSum: 0,
      isSuccess: false,
      foundGroups: [],
      generatedGroups: [],
      remainingGroups: [],
      requiredGroups: requiredGroups,
      puzzleComplete: false,
      secondsLeft: timeLimit,
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
          return nums[0] - nums[1]; // Simple: first - second
        } else if (nums.length > 2) {
          // For 3+ numbers: first - (sum of rest)
          int first = nums[0];
          int sumRest = 0;
          for (int i = 1; i < nums.length; i++) {
            sumRest += nums[i];
          }
          return first - sumRest;
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

  // Helper method to create 3 numbers that work with the target
  static List<int> _createWorkingNumbers(int target, CalculationType opType) {
    switch (opType) {
      case CalculationType.addition:
        // Create 3 numbers that sum to target
        int num1 = 1 + Random().nextInt(target - 2);
        int num2 = 1 + Random().nextInt(target - num1 - 1);
        int num3 = target - num1 - num2;
        return [num1, num2, num3];
      case CalculationType.subtraction:
        // Create 3 numbers where max - sum(others) = target
        int num1 = 1 + Random().nextInt(3);
        int num2 = 1 + Random().nextInt(3);
        int maxNum = num1 + num2 + target;
        return [maxNum, num1, num2];
      case CalculationType.multiplication:
        // Create 3 factors that multiply to target
        int num1 = 2 + Random().nextInt(2); // 2-3
        int num2 = 2 + Random().nextInt(2); // 2-3
        int num3 = target ~/ (num1 * num2);
        if (num3 * num1 * num2 == target && num3 >= 2 && num3 <= 6) {
          return [num1, num2, num3];
        } else {
          // Fallback to simple factors
          return [2, 2, target ~/ 4];
        }
      case CalculationType.division:
        // Create dividend, divisor, and 1
        int divisor = 2 + Random().nextInt(2); // 2-3
        int dividend = divisor * target;
        return [dividend, divisor, 1];
    }
  }

  // GUARANTEED working numbers method
  static List<int> _createGuaranteedWorkingNumbers(int target, CalculationType opType, Random random) {
    switch (opType) {
      case CalculationType.addition:
        // Simple guaranteed addition: [1, 1, target-2]
        return [1, 1, target - 2];
      case CalculationType.subtraction:
        // Simple guaranteed subtraction: [target+3, 2, 1] gives (target+3) - (2+1) = target
        return [target + 3, 2, 1];
      case CalculationType.multiplication:
        // Simple guaranteed multiplication: [2, 2, target/4] gives 2*2*(target/4) = target
        return [2, 2, target ~/ 4];
      case CalculationType.division:
        // Simple guaranteed division: [target*2, 2, 1] gives (target*2) / (2*1) = target
        return [target * 2, 2, 1];
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
      puzzleComplete = foundGroups.length >= state.requiredGroups;
      print('DEBUG: Found group ${foundGroups.length}/${state.requiredGroups}, puzzleComplete: $puzzleComplete');
      if (puzzleComplete) {
        gameOver = true;
        _ticker.stop();
        print('DEBUG: PUZZLE COMPLETE! Setting gameOver to true');
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
      // Only set gameOver if the puzzle is not complete
      if (!state.puzzleComplete) {
        emit(state.copyWith(secondsLeft: 0, gameOver: true));
        _ticker.stop();
      } else {
        // If puzzle is complete, just stop the timer but don't set gameOver
        emit(state.copyWith(secondsLeft: 0));
        _ticker.stop();
      }
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
          if (_getGroupTarget(values, type) == target && cells.length >= 3) {
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
          if (_getGroupTarget(values, type) == target && cells.length >= 3) {
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
          if (_getGroupTarget(values, type) == target && cells.length >= 3) {
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
          if (_getGroupTarget(values, type) == target && cells.length >= 3) {
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