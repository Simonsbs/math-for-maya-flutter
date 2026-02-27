import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MathForMayaApp());
}

enum Operation { addition, subtraction, multiplication, division }

enum AppPage { home, setup, play, summary }

enum MayaMood { idle, happy, thinking, oops, celebrate }

enum AnswerField { quotient, remainder }

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
  bool _useRemainders = false;

  late Equation _equation;
  int _questionNumber = 1;

  int _totalStars = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;

  String _answer = '';
  String _quotientAnswer = '';
  String _remainderAnswer = '';
  AnswerField _activeField = AnswerField.quotient;
  String _feedback = '';
  String _hint = '';
  bool _revealedSolution = false;
  bool _answeredCorrectly = false;
  String _carryMarks = '';
  String _borrowMarks = '';

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
    _equation = _generateEquation(_operation, _digits, _useRemainders);
  }

  int _minForDigits(int digits) =>
      digits == 1 ? 0 : pow(10, digits - 1).toInt();

  int _maxForDigits(int digits) => pow(10, digits).toInt() - 1;

  int _randomInt(int min, int max) {
    if (max <= min) return min;
    return min + _random.nextInt(max - min + 1);
  }

  bool get _isRemainderMode =>
      _equation.operation == Operation.division && _useRemainders;
  bool get _canUseCarryInput =>
      _equation.operation == Operation.addition && !_isRemainderMode;
  int get _currentColumnCount {
    final top = _equation.a.toString().length;
    final bottom = _equation.b.toString().length;
    final answerLen =
        (_revealedSolution
                ? _equation.result.toString()
                : (_answer.isEmpty ? '?' : _answer))
            .length;
    return max(max(top, bottom), answerLen);
  }

  Equation _generateEquation(
    Operation operation,
    int digits,
    bool useRemainders,
  ) {
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
    if (useRemainders) {
      final remainder = _randomInt(1, max(divisor - 1, 1));
      return Equation(
        a: divisor * quotient + remainder,
        b: divisor,
        operation: operation,
        result: quotient,
      );
    }
    return Equation(
      a: divisor * quotient,
      b: divisor,
      operation: operation,
      result: quotient,
    );
  }

  void _resetQuestion() {
    _equation = _generateEquation(_operation, _digits, _useRemainders);
    _answer = '';
    _quotientAnswer = '';
    _remainderAnswer = '';
    _activeField = AnswerField.quotient;
    _feedback = '';
    _hint = '';
    _revealedSolution = false;
    _answeredCorrectly = false;
    _carryMarks = '';
    _borrowMarks = '';
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
    if (_revealedSolution) return;
    setState(() {
      if (_isRemainderMode) {
        if (_activeField == AnswerField.quotient &&
            _quotientAnswer.length < 8) {
          _quotientAnswer = '$digit$_quotientAnswer';
        } else if (_activeField == AnswerField.remainder &&
            _remainderAnswer.length < 8) {
          _remainderAnswer = '$digit$_remainderAnswer';
        }
      } else {
        if (_answer.length >= 8) return;
        _answer = '$digit$_answer';
      }
      _feedback = '';
    });
  }

  void _backspace() {
    if (_revealedSolution) return;
    setState(() {
      if (_isRemainderMode) {
        if (_activeField == AnswerField.quotient &&
            _quotientAnswer.isNotEmpty) {
          _quotientAnswer = _quotientAnswer.substring(1);
        } else if (_activeField == AnswerField.remainder &&
            _remainderAnswer.isNotEmpty) {
          _remainderAnswer = _remainderAnswer.substring(1);
        }
      } else if (_answer.isNotEmpty) {
        _answer = _answer.substring(1);
      }
      _feedback = '';
    });
  }

  void _clear() {
    if (_revealedSolution) return;
    setState(() {
      if (_isRemainderMode) {
        if (_activeField == AnswerField.quotient) {
          _quotientAnswer = '';
        } else {
          _remainderAnswer = '';
        }
      } else {
        _answer = '';
      }
      _feedback = '';
    });
  }

  void _hintAction() {
    if (_isRemainderMode) {
      final quotientText = (_equation.a ~/ _equation.b).toString();
      final remainderText = (_equation.a % _equation.b).toString();
      setState(() {
        if (_quotientAnswer.length < quotientText.length) {
          final idx = max(0, quotientText.length - 1 - _quotientAnswer.length);
          _hint =
              _quotientAnswer.isEmpty
                  ? 'Quotient ones digit: ${quotientText[quotientText.length - 1]}'
                  : 'Next quotient digit: ${quotientText[idx]}';
          _activeField = AnswerField.quotient;
        } else {
          final idx = max(
            0,
            remainderText.length - 1 - _remainderAnswer.length,
          );
          _hint =
              _remainderAnswer.isEmpty
                  ? 'Remainder ones digit: ${remainderText[remainderText.length - 1]}'
                  : 'Next remainder digit: ${remainderText[idx]}';
          _activeField = AnswerField.remainder;
        }
        _roundStats = _roundStats.copyWith(
          hintsUsed: _roundStats.hintsUsed + 1,
        );
        _mayaMood = MayaMood.thinking;
        _mayaLine = 'Hint added.';
      });
      return;
    }
    final resultText = _equation.result.toString();
    final idx = max(0, resultText.length - 1 - _answer.length);
    setState(() {
      _hint =
          _answer.isEmpty
              ? 'Start with ones digit: ${resultText[resultText.length - 1]}'
              : 'Next digit: ${resultText[idx]}';
      _roundStats = _roundStats.copyWith(hintsUsed: _roundStats.hintsUsed + 1);
      _mayaMood = MayaMood.thinking;
      _mayaLine = 'Hint added.';
    });
  }

  void _checkAnswer() {
    if (_isRemainderMode) {
      if (_quotientAnswer.isEmpty || _remainderAnswer.isEmpty) {
        setState(() {
          _feedback = 'Enter quotient and remainder.';
          _mayaMood = MayaMood.thinking;
          _mayaLine = 'Fill both fields.';
        });
        return;
      }
      final parsedQuotient = int.tryParse(_quotientAnswer);
      final parsedRemainder = int.tryParse(_remainderAnswer);
      if (parsedQuotient == null || parsedRemainder == null) {
        setState(() {
          _feedback = 'Numbers only.';
          _mayaMood = MayaMood.thinking;
          _mayaLine = 'Input should be numeric.';
        });
        return;
      }
      final expectedQuotient = _equation.a ~/ _equation.b;
      final expectedRemainder = _equation.a % _equation.b;
      if (parsedQuotient == expectedQuotient &&
          parsedRemainder == expectedRemainder) {
        setState(() {
          _feedback = 'Correct.';
          _mayaMood = MayaMood.happy;
          _mayaLine = 'Good work.';
          if (!_answeredCorrectly) {
            _answeredCorrectly = true;
            _totalStars += 1;
            _currentStreak += 1;
            _bestStreak = max(_bestStreak, _currentStreak);
            _roundStats = _roundStats.copyWith(
              correct: _roundStats.correct + 1,
            );
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
      return;
    }
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
      if (_isRemainderMode) {
        final q = _equation.a ~/ _equation.b;
        final r = _equation.a % _equation.b;
        _feedback = 'Solution: Q $q, R $r';
      } else {
        _feedback = 'Solution: ${_equation.result}';
      }
      _roundStats = _roundStats.copyWith(
        solutionsShown: _roundStats.solutionsShown + 1,
      );
      _mayaMood = MayaMood.thinking;
      _mayaLine = 'Review and continue.';
      _currentStreak = 0;
    });
  }

  void _carryTheOne() {
    if (!_canUseCarryInput || _revealedSolution) return;
    setState(() {
      if (_currentColumnCount < 2) {
        _mayaMood = MayaMood.thinking;
        _mayaLine = 'No next column for carry yet.';
        _feedback = '';
        return;
      }
      if (_carryMarks.length < 8) {
        _carryMarks = '$_carryMarks${1}';
      }
      _feedback = '';
      _mayaMood = MayaMood.thinking;
      _mayaLine = 'Carry 1 added.';
    });
  }

  void _borrowOne() {
    if (_equation.operation != Operation.subtraction || _revealedSolution) {
      return;
    }
    setState(() {
      if (_currentColumnCount < 2) {
        _mayaMood = MayaMood.thinking;
        _mayaLine = 'No next column to borrow from yet.';
        _feedback = '';
        return;
      }
      if (_borrowMarks.length < 8) {
        _borrowMarks = '$_borrowMarks${1}';
      }
      _feedback = '';
      _mayaMood = MayaMood.thinking;
      _mayaLine = 'Borrow 1 added.';
    });
  }

  void _endRoundEarly() {
    setState(() {
      _mayaMood = MayaMood.thinking;
      _mayaLine = 'Round ended.';
      _page = AppPage.summary;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (_page != AppPage.play) _headerBar(),
              if (_page != AppPage.play) const SizedBox(height: 10),
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerBar() {
    return Row(
      children: [
        if (_page != AppPage.home)
          IconButton(
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
        Expanded(
          child: Text(
            _titleForPage(),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 48),
      ],
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(_moodIcon[_mayaMood], size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _mayaLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$_totalStars★  $_currentStreak🔥  $_bestStreak🏆',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homePage() {
    return Column(
      key: const ValueKey('home'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _statusPanel(),
        const SizedBox(height: 10),
        Expanded(
          child: Card(
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
                  const Text('One equation at a time with touch controls.'),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => setState(() => _page = AppPage.setup),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _setupPage() {
    return Column(
      key: const ValueKey('setup'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _statusPanel(),
        const SizedBox(height: 10),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Operation',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        Operation.values
                            .map(
                              (op) => ChoiceChip(
                                label: Text(_operationLabel[op]!),
                                selected: _operation == op,
                                onSelected: (_) {
                                  setState(() {
                                    _operation = op;
                                    if (_operation != Operation.division) {
                                      _useRemainders = false;
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                  ),
                  if (_operation == Operation.division) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Division Answer Mode',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Exact Only'),
                          selected: !_useRemainders,
                          onSelected:
                              (_) => setState(() => _useRemainders = false),
                        ),
                        ChoiceChip(
                          label: const Text('Use Remainders'),
                          selected: _useRemainders,
                          onSelected:
                              (_) => setState(() => _useRemainders = true),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
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
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _page = AppPage.home),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
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
        ),
      ],
    );
  }

  Widget _playPage() {
    final progress = _questionNumber / _roundLength;

    return Column(
      key: const ValueKey('play'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _statusPanel(),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Question $_questionNumber of $_roundLength'),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: progress),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _endRoundEarly,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('End Game'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            children: [
              Expanded(
                flex: 6,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        const Text('Solve'),
                        const SizedBox(height: 4),
                        _verticalEquationWidget(),
                        if (_canUseCarryInput && !_revealedSolution)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: FilledButton.tonal(
                              style: _compactActionButtonStyle(),
                              onPressed: _carryTheOne,
                              child: const Text('Carry the 1'),
                            ),
                          ),
                        if (_equation.operation == Operation.subtraction &&
                            !_revealedSolution)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: FilledButton.tonal(
                              style: _compactActionButtonStyle(),
                              onPressed: _borrowOne,
                              child: const Text('Borrow 1'),
                            ),
                          ),
                        if (_isRemainderMode) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: Text(
                                    'Q ${_quotientAnswer.isEmpty ? "?" : _quotientAnswer}',
                                  ),
                                  selected:
                                      _activeField == AnswerField.quotient,
                                  onSelected:
                                      (_) => setState(
                                        () =>
                                            _activeField = AnswerField.quotient,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ChoiceChip(
                                  label: Text(
                                    'R ${_remainderAnswer.isEmpty ? "?" : _remainderAnswer}',
                                  ),
                                  selected:
                                      _activeField == AnswerField.remainder,
                                  onSelected:
                                      (_) => setState(
                                        () =>
                                            _activeField =
                                                AnswerField.remainder,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonal(
                                style: _compactActionButtonStyle(),
                                onPressed: _hintAction,
                                child: const Text('Hint'),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FilledButton.tonal(
                                style: _compactActionButtonStyle(),
                                onPressed: _checkAnswer,
                                child: const Text('Check'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonal(
                                style: _compactActionButtonStyle(),
                                onPressed: _showSolution,
                                child: const Text('Show'),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FilledButton(
                                style: _compactActionButtonStyle(),
                                onPressed: _nextEquation,
                                child: const Text('Next'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 16,
                          child: Text(
                            _hint.isNotEmpty
                                ? _hint
                                : (_feedback.isNotEmpty ? _feedback : ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 5,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: GridView.count(
                      crossAxisCount: 3,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.9,
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
                        ].map(
                          (digit) => FilledButton(
                            style: _keypadButtonStyle(),
                            onPressed: () => _tapDigit(digit),
                            child: Text(
                              digit,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                        FilledButton.tonal(
                          style: _keypadButtonStyle(),
                          onPressed: _backspace,
                          child: const Text('Del'),
                        ),
                        FilledButton.tonal(
                          style: _keypadButtonStyle(),
                          onPressed: _clear,
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryPage() {
    return Column(
      key: const ValueKey('summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _statusPanel(),
        const SizedBox(height: 10),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Round Complete',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text('Correct answers: ${_roundStats.correct}'),
                  Text('Incorrect checks: ${_roundStats.incorrect}'),
                  Text('Hints used: ${_roundStats.hintsUsed}'),
                  Text('Solutions shown: ${_roundStats.solutionsShown}'),
                  const Spacer(),
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
        ),
      ],
    );
  }

  Widget _eqLine(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 30,
        height: 1.15,
        fontWeight: FontWeight.w800,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _verticalEquationWidget() {
    if (_isRemainderMode) {
      return SizedBox(
        width: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _eqLine('${_equation.a}'),
            _eqLine('${_operationSymbol[_equation.operation]} ${_equation.b}'),
            const Divider(thickness: 2),
            _remainderAnswerDisplay(),
          ],
        ),
      );
    }

    final top = _equation.a.toString();
    final bottom = _equation.b.toString();
    final liveAnswer =
        _revealedSolution
            ? _equation.result.toString()
            : (_answer.isEmpty ? '?' : _answer);
    final colCount = max(
      max(top.length, bottom.length),
      max(_equation.result.toString().length, liveAnswer.length),
    );

    final carries =
        _equation.operation == Operation.addition
            ? _additionCarryRow(_equation.a, _equation.b, colCount)
            : List<String>.filled(colCount, '');
    final topDigits = _alignDigits(top, colCount);
    final borrowDisplayDigits = _manualBorrowRow(colCount);
    final hasVisibleBorrow = borrowDisplayDigits.any((d) => d.isNotEmpty);
    final carryDisplayDigits =
        _revealedSolution ? carries : _manualCarryRow(colCount);
    final hasVisibleCarry = carryDisplayDigits.any((d) => d.isNotEmpty);
    final showCarryRow =
        _equation.operation == Operation.addition && hasVisibleCarry;
    final showBorrowRow =
        _equation.operation == Operation.subtraction && hasVisibleBorrow;

    return SizedBox(
      width: (colCount + 1) * 22,
      child: Column(
        children: [
          if (showCarryRow)
            _equationRow(
              leading: '',
              digits: carryDisplayDigits,
              fontSize: 14,
              color: _revealedSolution ? Colors.deepOrange : Colors.indigo,
              weight: FontWeight.w900,
            ),
          if (showBorrowRow)
            _equationRow(
              leading: '',
              digits: borrowDisplayDigits,
              fontSize: 14,
              color: Colors.deepPurple,
              weight: FontWeight.w900,
            ),
          if (_equation.operation == Operation.subtraction && hasVisibleBorrow)
            _subtractionTopRowWithBorrow(topDigits, colCount)
          else
            _equationRow(leading: '', digits: topDigits),
          _equationRow(
            leading: _operationSymbol[_equation.operation]!,
            digits: _alignDigits(bottom, colCount),
          ),
          const Divider(thickness: 2, height: 10),
          _equationRow(leading: '', digits: _alignDigits(liveAnswer, colCount)),
        ],
      ),
    );
  }

  List<String> _alignDigits(String value, int colCount) {
    final digits = value.split('');
    if (digits.length >= colCount) return digits;
    return List<String>.filled(colCount - digits.length, '') + digits;
  }

  List<String> _additionCarryRow(int a, int b, int colCount) {
    final row = List<String>.filled(colCount, '');
    int left = a;
    int right = b;
    int carry = 0;
    int colFromRight = 0;
    while (left > 0 || right > 0) {
      final sum = (left % 10) + (right % 10) + carry;
      carry = sum ~/ 10;
      if (carry > 0) {
        final targetColFromRight = colFromRight + 1;
        final index = colCount - 1 - targetColFromRight;
        if (index >= 0 && index < row.length) {
          row[index] = '$carry';
        }
      }
      left ~/= 10;
      right ~/= 10;
      colFromRight += 1;
    }
    return row;
  }

  List<String> _manualCarryRow(int colCount) {
    final row = List<String>.filled(colCount, '');
    for (int i = 0; i < _carryMarks.length; i++) {
      final index = colCount - 2 - i;
      if (index < 0 || index >= row.length) break;
      row[index] = _carryMarks[i];
    }
    return row;
  }

  List<String> _manualBorrowRow(int colCount) {
    final row = List<String>.filled(colCount, '');
    for (int i = 0; i < _borrowMarks.length; i++) {
      final index = colCount - 1 - i;
      if (index < 0 || index >= row.length) break;
      row[index] = _borrowMarks[i];
    }
    return row;
  }

  Map<int, int> _borrowDonorCounts(int colCount) {
    final counts = <int, int>{};
    for (int i = 0; i < _borrowMarks.length; i++) {
      final donorIndex = colCount - 2 - i;
      if (donorIndex < 0 || donorIndex >= colCount) break;
      counts[donorIndex] = (counts[donorIndex] ?? 0) + 1;
    }
    return counts;
  }

  Widget _subtractionTopRowWithBorrow(List<String> topDigits, int colCount) {
    final donorCounts = _borrowDonorCounts(colCount);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _digitCell('', fontSize: 30, weight: FontWeight.w800),
        for (int i = 0; i < topDigits.length; i++)
          _borrowTopDigitCell(topDigits[i], donorCounts[i] ?? 0),
      ],
    );
  }

  Widget _borrowTopDigitCell(String digit, int borrowCount) {
    if (digit.isEmpty || borrowCount <= 0) {
      return _digitCell(digit, fontSize: 30, weight: FontWeight.w800);
    }

    final original = int.tryParse(digit) ?? 0;
    final updated = max(0, original - borrowCount);
    return SizedBox(
      width: 22,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Text(
            '$original',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              height: 1.05,
              color: Colors.black54,
              decoration: TextDecoration.lineThrough,
              decorationThickness: 2,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Positioned(
            top: -4,
            right: 0,
            child: Text(
              '$updated',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.deepPurple,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _equationRow({
    required String leading,
    required List<String> digits,
    double fontSize = 30,
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _digitCell(leading, fontSize: fontSize, color: color, weight: weight),
        for (final digit in digits)
          _digitCell(digit, fontSize: fontSize, color: color, weight: weight),
      ],
    );
  }

  Widget _digitCell(
    String value, {
    required double fontSize,
    Color? color,
    required FontWeight weight,
  }) {
    return SizedBox(
      width: 22,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.05,
          color: color,
          fontWeight: weight,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _remainderAnswerDisplay() {
    final q =
        _revealedSolution
            ? (_equation.a ~/ _equation.b).toString()
            : (_quotientAnswer.isEmpty ? '?' : _quotientAnswer);
    final r =
        _revealedSolution
            ? (_equation.a % _equation.b).toString()
            : (_remainderAnswer.isEmpty ? '?' : _remainderAnswer);
    return Text(
      'Q:$q  R:$r',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  ButtonStyle _compactActionButtonStyle() {
    return FilledButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );
  }

  ButtonStyle _keypadButtonStyle() {
    return FilledButton.styleFrom(
      minimumSize: const Size(0, 50),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );
  }
}
