import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MathForMayaApp());
}

enum Operation { addition, subtraction, multiplication, division }

enum AppPage { home, setup, play, summary }

enum MayaMood { idle, happy, thinking, oops, celebrate }

class Equation {
  const Equation({
    required this.a,
    required this.b,
    required this.operation,
    required this.result,
  });

  final int a;
  final int b;
  final Operation operation;
  final int result;
}

class RoundStats {
  const RoundStats({
    required this.correct,
    required this.incorrect,
    required this.hintsUsed,
    required this.solutionsShown,
  });

  final int correct;
  final int incorrect;
  final int hintsUsed;
  final int solutionsShown;

  RoundStats copyWith({
    int? correct,
    int? incorrect,
    int? hintsUsed,
    int? solutionsShown,
  }) {
    return RoundStats(
      correct: correct ?? this.correct,
      incorrect: incorrect ?? this.incorrect,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      solutionsShown: solutionsShown ?? this.solutionsShown,
    );
  }

  static const empty = RoundStats(
    correct: 0,
    incorrect: 0,
    hintsUsed: 0,
    solutionsShown: 0,
  );
}

class MathForMayaApp extends StatelessWidget {
  const MathForMayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math For Maya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2A7FFF)),
      ),
      home: const MathForMayaGame(),
    );
  }
}

class MathForMayaGame extends StatefulWidget {
  const MathForMayaGame({super.key});

  @override
  State<MathForMayaGame> createState() => _MathForMayaGameState();
}

class _MathForMayaGameState extends State<MathForMayaGame> {
  final Random _random = Random();

  AppPage _page = AppPage.home;
  Operation _operation = Operation.addition;
  int _digits = 1;
  int _roundLength = 10;

  late Equation _equation;
  int _questionNumber = 1;

  int _totalStars = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;

  String _answer = '';
  String _feedback = '';
  String _hint = '';
  bool _revealedSolution = false;
  bool _answeredCorrectly = false;

  RoundStats _roundStats = RoundStats.empty;

  MayaMood _mayaMood = MayaMood.idle;
  String _mayaLine = 'Let\'s begin.';

  static const List<int> _digitChoices = [1, 2, 3, 4];
  static const List<int> _roundChoices = [5, 10, 15];

  static const Map<Operation, String> _operationLabel = {
    Operation.addition: 'Addition',
    Operation.subtraction: 'Subtraction',
    Operation.multiplication: 'Multiplication',
    Operation.division: 'Division',
  };

  static const Map<Operation, String> _operationSymbol = {
    Operation.addition: '+',
    Operation.subtraction: '-',
    Operation.multiplication: '×',
    Operation.division: '÷',
  };

  static const Map<MayaMood, IconData> _moodIcon = {
    MayaMood.idle: Icons.sentiment_satisfied_alt,
    MayaMood.happy: Icons.stars_rounded,
    MayaMood.thinking: Icons.psychology_alt,
    MayaMood.oops: Icons.lightbulb,
    MayaMood.celebrate: Icons.celebration,
  };

  @override
  void initState() {
    super.initState();
    _equation = _generateEquation(_operation, _digits);
  }

  int _minForDigits(int digits) =>
      digits == 1 ? 0 : pow(10, digits - 1).toInt();

  int _maxForDigits(int digits) => pow(10, digits).toInt() - 1;

  int _randomInt(int min, int max) {
    if (max <= min) return min;
    return min + _random.nextInt(max - min + 1);
  }

  Equation _generateEquation(Operation operation, int digits) {
    final minValue = _minForDigits(digits);
    final maxValue = _maxForDigits(digits);

    if (operation == Operation.addition) {
      final a = _randomInt(minValue, maxValue);
      final b = _randomInt(minValue, maxValue);
      return Equation(a: a, b: b, operation: operation, result: a + b);
    }

    if (operation == Operation.subtraction) {
      final top = _randomInt(minValue, maxValue);
      final bottom = _randomInt(minValue, top);
      return Equation(
        a: top,
        b: bottom,
        operation: operation,
        result: top - bottom,
      );
    }

    if (operation == Operation.multiplication) {
      final minFactor = minValue.clamp(0, 12);
      final maxFactor = maxValue.clamp(0, 12);
      final a = _randomInt(minFactor, maxFactor);
      final b = _randomInt(minFactor, maxFactor);
      return Equation(a: a, b: b, operation: operation, result: a * b);
    }

    final divisor = _randomInt(max(minValue, 1), max(maxValue, 1));
    final quotient = _randomInt(max(minValue, 1), max(maxValue, 1));
    return Equation(
      a: divisor * quotient,
      b: divisor,
      operation: operation,
      result: quotient,
    );
  }

  void _resetQuestion() {
    _equation = _generateEquation(_operation, _digits);
    _answer = '';
    _feedback = '';
    _hint = '';
    _revealedSolution = false;
    _answeredCorrectly = false;
  }

  void _startRound() {
    setState(() {
      _questionNumber = 1;
      _currentStreak = 0;
      _roundStats = RoundStats.empty;
      _mayaMood = MayaMood.idle;
      _mayaLine = 'Solve each one carefully.';
      _resetQuestion();
      _page = AppPage.play;
    });
  }

  void _nextEquation() {
    setState(() {
      if (_questionNumber >= _roundLength) {
        _page = AppPage.summary;
        _mayaMood = MayaMood.celebrate;
        _mayaLine = 'Round complete.';
        return;
      }
      _questionNumber += 1;
      _mayaMood = MayaMood.idle;
      _mayaLine = 'Next question.';
      _resetQuestion();
    });
  }

  void _tapDigit(String digit) {
    if (_revealedSolution || _answer.length >= 8) return;
    setState(() {
      _answer = '$_answer$digit';
      _feedback = '';
    });
  }

  void _backspace() {
    if (_revealedSolution) return;
    setState(() {
      if (_answer.isNotEmpty) {
        _answer = _answer.substring(0, _answer.length - 1);
      }
      _feedback = '';
    });
  }

  void _clear() {
    if (_revealedSolution) return;
    setState(() {
      _answer = '';
      _feedback = '';
    });
  }

  void _hintAction() {
    final resultText = _equation.result.toString();
    final idx =
        _answer.length < resultText.length
            ? _answer.length
            : resultText.length - 1;
    setState(() {
      _hint =
          _answer.isEmpty
              ? 'Start with: ${resultText[0]}'
              : 'Next digit: ${resultText[idx]}';
      _roundStats = _roundStats.copyWith(hintsUsed: _roundStats.hintsUsed + 1);
      _mayaMood = MayaMood.thinking;
      _mayaLine = 'Hint added.';
    });
  }

  void _checkAnswer() {
    if (_answer.isEmpty) {
      setState(() {
        _feedback = 'Enter an answer first.';
        _mayaMood = MayaMood.thinking;
        _mayaLine = 'Use the keypad.';
      });
      return;
    }

    final parsed = int.tryParse(_answer);
    if (parsed == null) {
      setState(() {
        _feedback = 'Numbers only.';
        _mayaMood = MayaMood.thinking;
        _mayaLine = 'Input should be numeric.';
      });
      return;
    }

    if (parsed == _equation.result) {
      setState(() {
        _feedback = 'Correct.';
        _mayaMood = MayaMood.happy;
        _mayaLine = 'Good work.';

        if (!_answeredCorrectly) {
          _answeredCorrectly = true;
          _totalStars += 1;
          _currentStreak += 1;
          _bestStreak = max(_bestStreak, _currentStreak);
          _roundStats = _roundStats.copyWith(correct: _roundStats.correct + 1);
        }
      });
      return;
    }

    setState(() {
      _feedback = 'Incorrect. Try again.';
      _mayaMood = MayaMood.oops;
      _mayaLine = 'Check and retry.';
      _currentStreak = 0;
      if (!_answeredCorrectly) {
        _roundStats = _roundStats.copyWith(
          incorrect: _roundStats.incorrect + 1,
        );
      }
    });
  }

  void _showSolution() {
    if (_revealedSolution) return;
    setState(() {
      _revealedSolution = true;
      _feedback = 'Solution: ${_equation.result}';
      _roundStats = _roundStats.copyWith(
        solutionsShown: _roundStats.solutionsShown + 1,
      );
      _mayaMood = MayaMood.thinking;
      _mayaLine = 'Review and continue.';
      _currentStreak = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForPage()),
        leading:
            _page == AppPage.home
                ? null
                : IconButton(
                  onPressed:
                      _page == AppPage.play
                          ? null
                          : () {
                            setState(() {
                              if (_page == AppPage.setup ||
                                  _page == AppPage.summary) {
                                _page = AppPage.home;
                              }
                            });
                          },
                  icon: const Icon(Icons.arrow_back),
                ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (_page) {
            AppPage.home => _homePage(),
            AppPage.setup => _setupPage(),
            AppPage.play => _playPage(),
            AppPage.summary => _summaryPage(),
          },
        ),
      ),
    );
  }

  String _titleForPage() {
    return switch (_page) {
      AppPage.home => 'Math For Maya',
      AppPage.setup => 'Setup',
      AppPage.play => 'Play',
      AppPage.summary => 'Round Summary',
    };
  }

  Widget _statusPanel() {
    return Card(
      child: ListTile(
        leading: Icon(_moodIcon[_mayaMood], size: 30),
        title: Text(_mayaLine),
        subtitle: Text(
          'Stars: $_totalStars   Streak: $_currentStreak   Best: $_bestStreak',
        ),
      ),
    );
  }

  Widget _homePage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statusPanel(),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Vertical Maths Equations',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose settings, solve one equation at a time, and complete the round.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => setState(() => _page = AppPage.setup),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupPage() {
    return ListView(
      key: const ValueKey('setup'),
      padding: const EdgeInsets.all(16),
      children: [
        _statusPanel(),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Operation',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SegmentedButton<Operation>(
                  multiSelectionEnabled: false,
                  selected: {_operation},
                  segments:
                      Operation.values
                          .map(
                            (op) => ButtonSegment<Operation>(
                              value: op,
                              label: Text(_operationLabel[op]!),
                            ),
                          )
                          .toList(),
                  onSelectionChanged: (selection) {
                    setState(() => _operation = selection.first);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Digits',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      _digitChoices
                          .map(
                            (value) => ChoiceChip(
                              label: Text('$value'),
                              selected: _digits == value,
                              onSelected:
                                  (_) => setState(() => _digits = value),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Questions Per Round',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      _roundChoices
                          .map(
                            (value) => ChoiceChip(
                              label: Text('$value'),
                              selected: _roundLength == value,
                              onSelected:
                                  (_) => setState(() => _roundLength = value),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _page = AppPage.home),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _startRound,
                        child: const Text('Start Round'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _playPage() {
    final progress = _questionNumber / _roundLength;

    return ListView(
      key: const ValueKey('play'),
      padding: const EdgeInsets.all(16),
      children: [
        _statusPanel(),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Question $_questionNumber of $_roundLength'),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Solve'),
                const SizedBox(height: 12),
                SizedBox(
                  width: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _eqLine('${_equation.a}'),
                      _eqLine(
                        '${_operationSymbol[_equation.operation]} ${_equation.b}',
                      ),
                      const Divider(thickness: 2),
                      _eqLine(
                        _revealedSolution
                            ? '${_equation.result}'
                            : (_answer.isEmpty ? '?' : _answer),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: _hintAction,
                      child: const Text('Hint'),
                    ),
                    FilledButton.tonal(
                      onPressed: _checkAnswer,
                      child: const Text('Check'),
                    ),
                    FilledButton.tonal(
                      onPressed: _showSolution,
                      child: const Text('Show Solution'),
                    ),
                    FilledButton(
                      onPressed: _nextEquation,
                      child: const Text('Next Equation'),
                    ),
                  ],
                ),
                if (_hint.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_hint),
                ],
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(_feedback),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: [
                ...['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'].map(
                  (digit) => FilledButton(
                    onPressed: () => _tapDigit(digit),
                    child: Text(digit, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _backspace,
                  child: const Text('Delete'),
                ),
                FilledButton.tonal(
                  onPressed: _clear,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryPage() {
    return ListView(
      key: const ValueKey('summary'),
      padding: const EdgeInsets.all(16),
      children: [
        _statusPanel(),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Round Complete',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text('Correct answers: ${_roundStats.correct}'),
                Text('Incorrect checks: ${_roundStats.incorrect}'),
                Text('Hints used: ${_roundStats.hintsUsed}'),
                Text('Solutions shown: ${_roundStats.solutionsShown}'),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => setState(() => _page = AppPage.setup),
                  child: const Text('Change Setup'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: _startRound,
                  child: const Text('Play Again'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => setState(() => _page = AppPage.home),
                  child: const Text('Home'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _eqLine(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 36,
        height: 1.15,
        fontWeight: FontWeight.w800,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
