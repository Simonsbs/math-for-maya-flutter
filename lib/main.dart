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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF9F45)),
        fontFamily: 'Roboto',
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
  String _mayaLine = 'Tap Start to play!';

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
    Operation.multiplication: 'x',
    Operation.division: '÷',
  };

  static const Map<MayaMood, String> _mayaFace = {
    MayaMood.idle: '😊',
    MayaMood.happy: '🌟',
    MayaMood.thinking: '🧠',
    MayaMood.oops: '🤔',
    MayaMood.celebrate: '🥳',
  };

  @override
  void initState() {
    super.initState();
    _equation = _generateEquation(_operation, _digits);
  }

  int _minForDigits(int digits) =>
      digits == 1 ? 0 : pow(10, digits - 1).toInt();

  int _maxForDigits(int digits) => pow(10, digits).toInt() - 1;

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
      final cappedMax = minValue > 12 ? minValue : 12;
      final a = _randomInt(minValue.clamp(0, cappedMax), cappedMax);
      final b = _randomInt(minValue.clamp(0, cappedMax), cappedMax);
      return Equation(a: a, b: b, operation: operation, result: a * b);
    }

    final divisor = _randomInt(max(minValue, 1), max(maxValue, 1));
    final quotient = _randomInt(max(minValue, 1), max(maxValue, 1));
    final dividend = divisor * quotient;
    return Equation(
      a: dividend,
      b: divisor,
      operation: operation,
      result: quotient,
    );
  }

  int _randomInt(int min, int max) {
    if (max <= min) return min;
    return min + _random.nextInt(max - min + 1);
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
      _mayaLine = 'Let\'s solve together!';
      _page = AppPage.play;
      _resetQuestion();
    });
  }

  void _goSetup() {
    setState(() {
      _page = AppPage.setup;
      _mayaMood = MayaMood.thinking;
      _mayaLine = 'Choose your challenge!';
    });
  }

  void _goHome() {
    setState(() {
      _page = AppPage.home;
      _mayaMood = MayaMood.idle;
      _mayaLine = 'Tap Start to play!';
    });
  }

  void _nextEquation() {
    setState(() {
      if (_questionNumber >= _roundLength) {
        _page = AppPage.summary;
        _mayaMood = MayaMood.celebrate;
        _mayaLine = 'Round complete! High five!';
        return;
      }

      _questionNumber += 1;
      _mayaMood = MayaMood.idle;
      _mayaLine = 'Next one! Keep going!';
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
              ? 'Start with this digit: ${resultText[0]}'
              : 'Next digit is ${resultText[idx]}';
      _mayaMood = MayaMood.thinking;
      _mayaLine = 'Use this clue!';
      _roundStats = _roundStats.copyWith(hintsUsed: _roundStats.hintsUsed + 1);
    });
  }

  void _checkAnswer() {
    if (_answer.isEmpty) {
      setState(() {
        _feedback = 'Type an answer first.';
        _mayaMood = MayaMood.thinking;
        _mayaLine = 'Tap numbers on the keypad.';
      });
      return;
    }

    final parsed = int.tryParse(_answer);
    if (parsed == null) {
      setState(() {
        _feedback = 'Use numbers only.';
        _mayaMood = MayaMood.thinking;
        _mayaLine = 'Your answer should be numbers only.';
      });
      return;
    }

    if (parsed == _equation.result) {
      setState(() {
        _feedback = 'Great job! Correct answer!';
        _mayaMood = MayaMood.happy;
        _mayaLine = 'Awesome! Tap Next Equation!';

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
      _feedback = 'Not yet. Try again or ask for a hint.';
      _mayaMood = MayaMood.oops;
      _mayaLine = 'Good try. Let\'s fix it!';
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
      _feedback = 'Solution shown: ${_equation.result}';
      _mayaMood = MayaMood.thinking;
      _mayaLine = 'Study this one and try the next!';
      _currentStreak = 0;
      _roundStats = _roundStats.copyWith(
        solutionsShown: _roundStats.solutionsShown + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7D6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _headerCard(),
              const SizedBox(height: 10),
              _mayaCard(),
              const SizedBox(height: 10),
              if (_page == AppPage.home) _homePage(),
              if (_page == AppPage.setup) _setupPage(),
              if (_page == AppPage.play) _playPage(),
              if (_page == AppPage.summary) _summaryPage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _headerCard() {
    return _card(
      child: Column(
        children: [
          const Text(
            'Math For Maya',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFA6F1D),
            ),
          ),
          const Text(
            'Native Flutter Mobile App',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F74B8),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              _scoreChip('Stars: $_totalStars'),
              _scoreChip('Streak: $_currentStreak'),
              _scoreChip('Best: $_bestStreak'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mayaCard() {
    return _card(
      child: Row(
        children: [
          Text(_mayaFace[_mayaMood]!, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Maya says: $_mayaLine',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _homePage() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFFF05385),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap to start your maths adventure.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 14),
          _actionButton('Start Game', const Color(0xFFB6F4BE), _goSetup),
        ],
      ),
    );
  }

  Widget _setupPage() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Setup',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFFF05385),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Exercise Type',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                Operation.values
                    .map(
                      (op) => _chip(
                        _operationLabel[op]!,
                        selected: _operation == op,
                        onTap: () => setState(() => _operation = op),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 10),
          const Text(
            'How many digits?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _digitChoices
                    .map(
                      (d) => _chip(
                        '$d',
                        selected: _digits == d,
                        onTap: () => setState(() => _digits = d),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 10),
          const Text(
            'How many equations?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _roundChoices
                    .map(
                      (count) => _chip(
                        '$count',
                        selected: _roundLength == count,
                        onTap: () => setState(() => _roundLength = count),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 14),
          _actionButton('Back', const Color(0xFFFFF0B5), _goHome),
          const SizedBox(height: 10),
          _actionButton('Start Round', const Color(0xFFB6F4BE), _startRound),
        ],
      ),
    );
  }

  Widget _playPage() {
    final progress = _questionNumber / _roundLength;

    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Question $_questionNumber of $_roundLength',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 14,
                  backgroundColor: const Color(0xFFD9E8FF),
                  color: const Color(0xFF72DC79),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _card(
          child: Column(
            children: [
              const Text(
                'Solve this one:',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 190,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _equationLine('${_equation.a}'),
                    _equationLine(
                      '${_operationSymbol[_equation.operation]} ${_equation.b}',
                    ),
                    const Divider(thickness: 3, color: Color(0xFF1F2A44)),
                    _equationLine(
                      _revealedSolution
                          ? '${_equation.result}'
                          : (_answer.isEmpty ? '?' : _answer),
                      color:
                          _answeredCorrectly
                              ? const Color(0xFF1B9E47)
                              : const Color(0xFFF05385),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _smallAction('Hint', _hintAction),
                  _smallAction('Check', _checkAnswer),
                  _smallAction('Show', _showSolution),
                  _smallAction(
                    'Next Equation',
                    _nextEquation,
                    color: const Color(0xFFB6F4BE),
                  ),
                ],
              ),
              if (_hint.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _hint,
                  style: const TextStyle(
                    color: Color(0xFF6F4AC7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (_feedback.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _feedback,
                  style: const TextStyle(
                    color: Color(0xFF0E6CAE),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Number Pad',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: [
                  ...[
                    '1',
                    '2',
                    '3',
                    '4',
                    '5',
                    '6',
                    '7',
                    '8',
                    '9',
                    '0',
                  ].map((d) => _keyButton(d, () => _tapDigit(d))),
                  _keyButton('Delete', _backspace, alt: true),
                  _keyButton('Clear', _clear, alt: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryPage() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Round Complete!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFFF05385),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Correct answers: ${_roundStats.correct}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            'Incorrect checks: ${_roundStats.incorrect}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            'Hints used: ${_roundStats.hintsUsed}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            'Solutions shown: ${_roundStats.solutionsShown}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _actionButton('Change Setup', const Color(0xFFFFF0B5), _goSetup),
          const SizedBox(height: 10),
          _actionButton('Play Again', const Color(0xFFB6F4BE), _startRound),
          const SizedBox(height: 10),
          _actionButton('Home', const Color(0xFFFFF0B5), _goHome),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: const Color(0xFF253252),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }

  Widget _smallAction(
    String label,
    VoidCallback onTap, {
    Color color = const Color(0xFFFFF0B5),
  }) {
    return SizedBox(
      width: 150,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: const Color(0xFF253252),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _chip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7AC8FF) : const Color(0xFFD8E9FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? const Color(0xFF05355A) : const Color(0xFF21385B),
          ),
        ),
      ),
    );
  }

  Widget _keyButton(String label, VoidCallback onTap, {bool alt = false}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            alt ? const Color(0xFFFFD4DF) : const Color(0xFFD0E9FF),
        foregroundColor: const Color(0xFF1D3154),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: alt ? 16 : 28, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _equationLine(String text, {Color color = const Color(0xFF1F2A44)}) {
    return Text(
      text,
      style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: color),
      textAlign: TextAlign.right,
    );
  }

  Widget _scoreChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6FFF0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2F9858),
        ),
      ),
    );
  }
}
