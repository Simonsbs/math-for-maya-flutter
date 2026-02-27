import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
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
  int _digits = 2;
  int _roundLength = 10;
  final bool _useRemainders = false;

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
  int _confettiBurstKey = 0;
  late final ConfettiController _confettiController;

  RoundStats _roundStats = RoundStats.empty;

  MayaMood _mayaMood = MayaMood.idle;
  String _mayaLine = 'Let\'s begin.';

  static const List<int> _digitChoices = [1, 2, 3, 4];
  static const List<int> _roundChoices = [5, 10, 15, -1];
  static const List<Operation> _enabledOperations = [
    Operation.addition,
    Operation.subtraction,
  ];

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
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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
  bool get _isEndlessRound => _roundLength == -1;
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
      if (!_isEndlessRound && _questionNumber >= _roundLength) {
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
            _playCorrectEffects();
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
          _playCorrectEffects();
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

  void _playCorrectEffects() {
    // Force a fresh confetti burst each time a new answer is marked correct.
    setState(() {
      _confettiBurstKey += 1;
    });
    _confettiController.stop();
    Future<void>.delayed(const Duration(milliseconds: 70), () {
      if (!mounted) return;
      _confettiController.play();
    });
    SystemSound.play(SystemSoundType.alert);
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
      body: Stack(
        children: [
          SafeArea(
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
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                key: ValueKey(_confettiBurstKey),
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 42,
                emissionFrequency: 0.03,
                gravity: 0.35,
                minBlastForce: 10,
                maxBlastForce: 28,
                colors: const [
                  Color(0xFF2A7FFF),
                  Color(0xFF00C853),
                  Color(0xFFFFC107),
                  Color(0xFFFF5252),
                  Color(0xFF9C27B0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerBar() {
    final showBack = _page != AppPage.home;
    return Row(
      children: [
        SizedBox(
          width: 48,
          child:
              showBack
                  ? IconButton(
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
                  )
                  : null,
        ),
        Expanded(
          child:
              _page == AppPage.home
                  ? _homeBrandTitle()
                  : Text(
                    _titleForPage(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _homeBrandTitle() {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
      color: const Color(0xFF1F2A44),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F0FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 18,
            color: Color(0xFF2A7FFF),
          ),
        ),
        const SizedBox(width: 8),
        Text('Math For Maya', style: titleStyle),
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
                    'Choose a Math Module',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Pick a module to start practicing.'),
                  const SizedBox(height: 14),
                  _moduleButton(
                    icon: Icons.vertical_align_center,
                    name: 'Vertical Equations',
                    subtitle: 'Solve one equation at a time',
                    onPressed: () => setState(() => _page = AppPage.setup),
                  ),
                  const SizedBox(height: 10),
                  _moduleButton(
                    icon: Icons.speed,
                    name: 'Speed Challenge',
                    subtitle: 'Coming soon',
                    onPressed: null,
                  ),
                  const SizedBox(height: 10),
                  _moduleButton(
                    icon: Icons.grid_view,
                    name: 'Times Tables',
                    subtitle: 'Coming soon',
                    onPressed: null,
                  ),
                  const SizedBox(height: 10),
                  _moduleButton(
                    icon: Icons.extension,
                    name: 'Logic Puzzles',
                    subtitle: 'Coming soon',
                    onPressed: null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _moduleButton({
    required IconData icon,
    required String name,
    required String subtitle,
    required VoidCallback? onPressed,
  }) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 74),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(subtitle, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Operation',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        _enabledOperations
                            .map(
                              (op) => _setupOptionButton(
                                label: _operationLabel[op]!,
                                leading: Icon(
                                  op == Operation.addition
                                      ? Icons.add_rounded
                                      : Icons.remove_rounded,
                                  size: 19,
                                ),
                                selected: _operation == op,
                                onTap: () => setState(() => _operation = op),
                                minWidth: 156,
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Digits',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        _digitChoices
                            .map(
                              (value) => _setupOptionButton(
                                label: '$value digits',
                                leading: _digitCountIcon(
                                  value,
                                  _digits == value
                                      ? Colors.white
                                      : const Color(0xFF27324A),
                                ),
                                selected: _digits == value,
                                onTap: () => setState(() => _digits = value),
                                minWidth: 120,
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Questions Per Round',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        _roundChoices
                            .map(
                              (value) => _setupOptionButton(
                                label:
                                    value == -1
                                        ? 'Endless'
                                        : '$value questions',
                                leading: Icon(
                                  value == -1
                                      ? Icons.all_inclusive_rounded
                                      : Icons.checklist_rounded,
                                  size: 19,
                                ),
                                selected: _roundLength == value,
                                onTap:
                                    () => setState(() => _roundLength = value),
                                minWidth: 136,
                              ),
                            )
                            .toList(),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _page = AppPage.home),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 56),
                            side: const BorderSide(
                              color: Color(0xFFADB9D6),
                              width: 1.6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          label: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _startRound,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(
                            Icons.rocket_launch_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            'Start Round',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
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

  Widget _setupOptionButton({
    required String label,
    required Widget leading,
    required bool selected,
    required VoidCallback onTap,
    required double minWidth,
  }) {
    final bg = selected ? const Color(0xFF2A7FFF) : const Color(0xFFE9EEFA);
    final fg = selected ? Colors.white : const Color(0xFF27324A);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: BoxConstraints(minWidth: minWidth, minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected ? const Color(0xFF1C5FD4) : const Color(0xFFD3DBF0),
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(color: fg, size: 19),
                child: leading,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _digitCountIcon(int count, Color color) {
    final sample = List<String>.filled(count, '8').join();
    return SizedBox(
      width: 26,
      child: Text(
        sample,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: count >= 4 ? 10 : 11,
          letterSpacing: 0.2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _playPage() {
    final progress = _isEndlessRound ? null : (_questionNumber / _roundLength);

    return Column(
      key: const ValueKey('play'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _statusPanel(),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD5E0FB)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEndlessRound
                          ? 'Question $_questionNumber - Endless'
                          : 'Question $_questionNumber of $_roundLength',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2A44),
                      ),
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: progress,
                        backgroundColor: const Color(0xFFD7E2FB),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                onPressed: _endRoundEarly,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: const Text(
                  'End',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
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
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.calculate_outlined,
                              size: 18,
                              color: Color(0xFF3D4E76),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Solve',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3D4E76),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _verticalEquationWidget(),
                            ),
                          ),
                        ),
                        if (_canUseCarryInput && !_revealedSolution)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: FilledButton.tonalIcon(
                              style: _compactActionButtonStyle(
                                isPrimary: false,
                              ),
                              onPressed: _carryTheOne,
                              icon: const Icon(
                                Icons.keyboard_double_arrow_left,
                              ),
                              label: const Text('Carry the 1'),
                            ),
                          ),
                        if (_equation.operation == Operation.subtraction &&
                            !_revealedSolution)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: FilledButton.tonalIcon(
                              style: _compactActionButtonStyle(
                                isPrimary: false,
                              ),
                              onPressed: _borrowOne,
                              icon: const Icon(Icons.redo_rounded),
                              label: const Text('Borrow 1'),
                            ),
                          ),
                        if (_isRemainderMode) ...[
                          const SizedBox(height: 2),
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
                          const SizedBox(height: 6),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonalIcon(
                                style: _compactActionButtonStyle(
                                  isPrimary: false,
                                ),
                                onPressed: _hintAction,
                                icon: const Icon(
                                  Icons.lightbulb_outline_rounded,
                                ),
                                label: const Text('Hint'),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                style: _compactActionButtonStyle(
                                  isPrimary: false,
                                ),
                                onPressed: _checkAnswer,
                                icon: const Icon(Icons.task_alt_rounded),
                                label: const Text('Check'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonalIcon(
                                style: _compactActionButtonStyle(
                                  isPrimary: false,
                                ),
                                onPressed: _showSolution,
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Show'),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FilledButton.icon(
                                style: _compactActionButtonStyle(
                                  isPrimary: true,
                                ),
                                onPressed: _nextEquation,
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: const Text('Next'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: double.infinity,
                          height: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color:
                                (_hint.isNotEmpty || _feedback.isNotEmpty)
                                    ? const Color(0xFFF0F4FF)
                                    : const Color(0xFFF7F9FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  (_hint.isNotEmpty || _feedback.isNotEmpty)
                                      ? const Color(0xFFD3DEFA)
                                      : const Color(0xFFE7ECFA),
                            ),
                          ),
                          child: Text(
                            _hint.isNotEmpty
                                ? _hint
                                : (_feedback.isNotEmpty
                                    ? _feedback
                                    : 'Enter your answer below'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3E4A67),
                            ),
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
                      childAspectRatio: 1.85,
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
                              style: const TextStyle(
                                fontSize: 29,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          style: _keypadButtonStyle(),
                          onPressed: _backspace,
                          icon: const Icon(Icons.backspace_outlined, size: 18),
                          label: const Text('Del'),
                        ),
                        FilledButton.tonalIcon(
                          style: _keypadButtonStyle(),
                          onPressed: _clear,
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          label: const Text('Clear'),
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
    final attempts = _roundStats.correct + _roundStats.incorrect;
    final accuracy =
        attempts == 0 ? 0 : ((_roundStats.correct / attempts) * 100).round();

    return Column(
      key: const ValueKey('summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _statusPanel(),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEAF0FF), Color(0xFFF7F9FF)],
              ),
              border: Border.all(color: const Color(0xFFD9E3FA)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD5E0FB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCE7FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFF3D5EA8),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Round Complete',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1F2A44),
                              ),
                            ),
                            Text(
                              'Accuracy: $accuracy%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF45557A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.2,
                    children: [
                      _summaryStatTile(
                        label: 'Correct',
                        value: '${_roundStats.correct}',
                        icon: Icons.check_circle_rounded,
                        bg: const Color(0xFFE6F7EA),
                        iconColor: const Color(0xFF1B8E3E),
                      ),
                      _summaryStatTile(
                        label: 'Incorrect',
                        value: '${_roundStats.incorrect}',
                        icon: Icons.cancel_rounded,
                        bg: const Color(0xFFFFECEC),
                        iconColor: const Color(0xFFC53A3A),
                      ),
                      _summaryStatTile(
                        label: 'Hints',
                        value: '${_roundStats.hintsUsed}',
                        icon: Icons.lightbulb_rounded,
                        bg: const Color(0xFFFFF6DF),
                        iconColor: const Color(0xFFB27A00),
                      ),
                      _summaryStatTile(
                        label: 'Solutions',
                        value: '${_roundStats.solutionsShown}',
                        icon: Icons.visibility_rounded,
                        bg: const Color(0xFFEAF0FF),
                        iconColor: const Color(0xFF3D5EA8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _page = AppPage.home),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 54),
                          side: const BorderSide(
                            color: Color(0xFFADB9D6),
                            width: 1.6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.home_rounded, size: 20),
                        label: const Text(
                          'Home',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => setState(() => _page = AppPage.setup),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.replay_rounded, size: 20),
                        label: const Text(
                          'Play Again',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
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
    final borrowMarkedValues = _prefixedMarkedValues(
      topDigits,
      borrowDisplayDigits,
    );
    final hasVisibleBorrow = borrowMarkedValues.any((d) => d.isNotEmpty);
    final carryDisplayDigits =
        _revealedSolution ? carries : _manualCarryRow(colCount);
    final hasVisibleCarry = carryDisplayDigits.any((d) => d.isNotEmpty);
    final showCarryRow =
        _equation.operation == Operation.addition && hasVisibleCarry;
    final showBorrowRow =
        _equation.operation == Operation.subtraction && hasVisibleBorrow;
    final borrowCrossedColumns = _markedColumns(borrowDisplayDigits);

    return SizedBox(
      width: (colCount + 1) * 22,
      child: Column(
        children: [
          if (showCarryRow)
            _carryEquationRow(
              carryDisplayDigits,
              color: _revealedSolution ? Colors.deepOrange : Colors.indigo,
            ),
          if (showBorrowRow)
            _equationRow(
              leading: '',
              digits: borrowMarkedValues,
              fontSize: 13,
              color: Colors.deepPurple,
              weight: FontWeight.w900,
            ),
          if (_equation.operation == Operation.subtraction && hasVisibleBorrow)
            _subtractionTopRowWithBorrow(
              topDigits,
              colCount,
              crossedColumns: borrowCrossedColumns,
            )
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

  List<String> _prefixedMarkedValues(List<String> digits, List<String> marks) {
    final row = List<String>.filled(digits.length, '');
    for (int i = 0; i < digits.length && i < marks.length; i++) {
      if (marks[i].isEmpty) continue;
      final base = digits[i].isEmpty ? '0' : digits[i];
      row[i] = '1$base';
    }
    return row;
  }

  Set<int> _markedColumns(List<String> marks) {
    final cols = <int>{};
    for (int i = 0; i < marks.length; i++) {
      if (marks[i].isNotEmpty) cols.add(i);
    }
    return cols;
  }

  Widget _subtractionTopRowWithBorrow(
    List<String> topDigits,
    int colCount, {
    required Set<int> crossedColumns,
  }) {
    final donorCounts = _borrowDonorCounts(colCount);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _digitCell('', fontSize: 30, weight: FontWeight.w800),
        for (int i = 0; i < topDigits.length; i++)
          _borrowTopDigitCell(
            topDigits[i],
            donorCounts[i] ?? 0,
            crossOut: crossedColumns.contains(i),
          ),
      ],
    );
  }

  Widget _borrowTopDigitCell(
    String digit,
    int borrowCount, {
    required bool crossOut,
  }) {
    var value = digit;
    var color = Colors.black;
    var weight = FontWeight.w800;

    if (digit.isNotEmpty && borrowCount > 0) {
      final original = int.tryParse(digit) ?? 0;
      value = '${max(0, original - borrowCount)}';
      color = Colors.deepPurple;
      weight = FontWeight.w900;
    }

    return _digitCell(
      value,
      fontSize: 30,
      color: color,
      weight: weight,
      crossOut: crossOut,
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

  Widget _carryEquationRow(List<String> digits, {required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _digitCell('', fontSize: 12, color: color, weight: FontWeight.w900),
          for (final digit in digits) _carryDigitCell(digit, color: color),
        ],
      ),
    );
  }

  Widget _carryDigitCell(String value, {required Color color}) {
    return SizedBox(
      width: 22,
      child: Transform.translate(
        offset: const Offset(-3, -2),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.0,
            color: color,
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _digitCell(
    String value, {
    required double fontSize,
    Color? color,
    required FontWeight weight,
    bool crossOut = false,
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
          decoration:
              crossOut ? TextDecoration.lineThrough : TextDecoration.none,
          decorationThickness: crossOut ? 2 : null,
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

  ButtonStyle _compactActionButtonStyle({required bool isPrimary}) {
    return FilledButton.styleFrom(
      minimumSize: const Size(0, 46),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: isPrimary ? const Color(0xFF3D5EA8) : null,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );
  }

  ButtonStyle _keypadButtonStyle() {
    return FilledButton.styleFrom(
      minimumSize: const Size(0, 50),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      backgroundColor: const Color(0xFF3E5A97),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );
  }

  Widget _summaryStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color bg,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.4,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2A44),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF45557A),
            ),
          ),
        ],
      ),
    );
  }
}
