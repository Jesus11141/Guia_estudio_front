import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets/frog_game.dart';
import '../tts_helper.dart';
import '../audio_fx_helper.dart';
import '../widgets/confetti_celebration.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final Lesson? lesson;
  final List<Question>? customQuestions;
  final String? customTitle;

  const QuizScreen({
    super.key,
    this.lesson,
    this.customQuestions,
    this.customTitle,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentIndex = 0;
  String? _selectedOption;
  bool _hasAnswered = false;
  int _score = 0;

  Future<void> _submitScore(int totalQuestions) async {
    try {
      final dio = ref.read(dioProvider);
      if (widget.lesson != null) {
        await dio.post('/scores', data: {
          'lessonId': widget.lesson!.id,
          'score': _score,
          'totalQuestions': totalQuestions,
        });
      }
    } catch (e) {
      debugPrint('Error saving score: $e');
    }
  }

  String _getOptionText(Question q, String opt) {
    if (opt == 'A') return q.optionA;
    if (opt == 'B') return q.optionB;
    if (opt == 'C') return q.optionC;
    if (opt == 'D') return q.optionD;
    return '';
  }

  Future<void> _showAiExplanation(Question question) async {
    final correctText = _getOptionText(question, question.correctOption);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return FutureBuilder<String>(
          future: _fetchAiExplanation(question, correctText),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                content: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: Color(0xFF4F46E5)),
                      SizedBox(height: 20),
                      Text(
                        'Profe IA está pensando una explicación...',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final explanationText = snapshot.data ?? question.explanation ?? 'Recuerda repasar el tema para la próxima vez.';

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('💡', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Explicación del Profe IA',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Respuesta correcta: $correctText',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46), fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      explanationText,
                      style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => TtsHelper.speak(explanationText),
                  icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF4F46E5), size: 18),
                  label: const Text('Escuchar', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('¡Entendido!'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> _fetchAiExplanation(Question question, String correctText) async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/ai/explain-answer', data: {
        'questionText': question.questionText,
        'correctText': correctText,
        'explanation': question.explanation ?? '',
      });
      return res.data['answer'] ?? question.explanation ?? '';
    } catch (e) {
      return question.explanation ?? 'La respuesta correcta es: $correctText. ¡Sigue practicando!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.customTitle ?? (widget.lesson != null ? 'Práctica: ${widget.lesson!.title}' : 'Práctica Libre');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.customQuestions != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
          centerTitle: true,
        ),
        body: _buildQuestionsBody(context, widget.customQuestions!),
      );
    }

    final questionsAsync = ref.watch(questionsProvider(widget.lesson!.id));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), // Slate 50 / Slate 900
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: questionsAsync.when(
        data: (questions) => _buildQuestionsBody(context, questions),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildQuestionsBody(BuildContext context, List<Question> questions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (questions.isEmpty) {
      return Center(
        child: Text(
          'Aún no hay ejercicios para esta lección.',
          style: TextStyle(
            fontSize: 18,
            color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
          ),
        ),
      );
    }

    if (_currentIndex >= questions.length) {
      // Pantalla de resultados con confeti festivo
      return ConfettiCelebration(
        isActive: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 4),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 8))
                  ],
                ),
                child: const Icon(Icons.emoji_events_rounded, size: 84, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(height: 32),
              Text(
                '¡Excelente Trabajo! 🎉',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Puntuación: $_score / ${questions.length}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(widget.customTitle != null ? '¡Terminar Juego! 🌟' : 'Volver al Temario', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      );
    }

    final question = questions[_currentIndex];
    final isCorrect = _selectedOption == question.correctOption;
    final String? bgImageUrl = question.metadata?['imageUrl'];

    return Stack(
      children: [
        if (bgImageUrl != null && bgImageUrl.toString().isNotEmpty)
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.08 : 0.15,
              child: Image.network(
                bgImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
          ),
        Column(
          children: [
            // Progress indicator fixed at top
            Container(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: (_currentIndex) / questions.length,
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        minHeight: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900), // Better width for games
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF312E81).withOpacity(0.4) : const Color(0xFFE0E7FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Pregunta ${_currentIndex + 1} de ${questions.length}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                              if (_hasAnswered && question.explanation != null && question.explanation!.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.lightbulb, color: Color(0xFFF59E0B), size: 32),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Row(
                                          children: [
                                            Icon(Icons.lightbulb, color: Color(0xFFF59E0B)),
                                            SizedBox(width: 8),
                                            Text('Guía de Estudio', style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        content: Text(question.explanation!, style: const TextStyle(fontSize: 16, height: 1.5)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.bold)),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          LayoutBuilder(
                            builder: (context, constraints) {
                              bool isWide = constraints.maxWidth > 700;
                              
                              Widget questionContent = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (question.type == 'FROG_SEQUENCE')
                                    FrogGameWidget(
                                      question: question,
                                      hasAnswered: _hasAnswered,
                                      isCorrect: _hasAnswered && _selectedOption == question.correctOption,
                                    )
                                  else if (question.type == 'MISSING_SYLLABLE')
                                    MissingSyllableWidget(
                                      question: question,
                                      hasAnswered: _hasAnswered,
                                      onOptionSelected: (String? val) {
                                        if (!_hasAnswered) {
                                          setState(() {
                                            _selectedOption = val;
                                          });
                                        }
                                      },
                                    )
                                  else if (question.type == 'SENTENCE_BUILDER')
                                    SentenceBuilderWidget(
                                      question: question,
                                      hasAnswered: _hasAnswered,
                                      onWordsPlaced: (String? val) {
                                        if (!_hasAnswered) {
                                          setState(() {
                                            _selectedOption = val;
                                          });
                                        }
                                      },
                                    )
                                  else if (question.type == 'SYLLABLE_TRAIN')
                                    SyllableTrainWidget(
                                      question: question,
                                      hasAnswered: _hasAnswered,
                                      onSyllablesPlaced: (String? val) {
                                        if (!_hasAnswered) {
                                          setState(() {
                                            _selectedOption = val;
                                          });
                                        }
                                      },
                                    )
                                  else
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            question.questionText,
                                            style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.volume_up, color: Color(0xFF4F46E5), size: 32),
                                          onPressed: () => TtsHelper.speak(question.questionText),
                                        ),
                                      ],
                                    ),
                                ],
                              );
                              
                              Widget optionsContent = Column(
                                children: ['A', 'B', 'C', 'D'].map((opt) {
                                  String text = '';
                                  if (opt == 'A') text = question.optionA;
                                  if (opt == 'B') text = question.optionB;
                                  if (opt == 'C') text = question.optionC;
                                  if (opt == 'D') text = question.optionD;
                                  if (text.isEmpty) return const SizedBox.shrink();
                                  
                                  bool isThisSelected = _selectedOption == opt;
                                  bool isThisCorrect = opt == question.correctOption;
                                  
                                  Color bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
                                  Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
                                  Color textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155);
                                  
                                  if (_hasAnswered) {
                                    if (isThisCorrect) {
                                      bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
                                      borderColor = const Color(0xFF10B981);
                                      textColor = isDark ? const Color(0xFF86EFAC) : const Color(0xFF065F46);
                                    } else if (isThisSelected && !isCorrect) {
                                      bgColor = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);
                                      borderColor = const Color(0xFFEF4444);
                                      textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
                                    }
                                  } else if (isThisSelected) {
                                    bgColor = isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF);
                                    borderColor = const Color(0xFF4F46E5);
                                    textColor = isDark ? Colors.white : const Color(0xFF312E81);
                                  }
                                  
                                  return GestureDetector(
                                    onTap: _hasAnswered ? null : () {
                                      setState(() {
                                        _selectedOption = opt;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        border: Border.all(color: borderColor, width: isThisSelected || (_hasAnswered && isThisCorrect) ? 3 : 2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36, height: 36,
                                            decoration: BoxDecoration(
                                              color: _hasAnswered && isThisCorrect 
                                                  ? const Color(0xFF10B981) 
                                                  : _hasAnswered && isThisSelected && !isCorrect
                                                      ? const Color(0xFFEF4444)
                                                      : (isThisSelected
                                                          ? const Color(0xFF4F46E5)
                                                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9))),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: Text(opt, style: TextStyle(
                                                fontWeight: FontWeight.w900, 
                                                color: isThisSelected || (_hasAnswered && isThisCorrect)
                                                    ? Colors.white
                                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                              )),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    text,
                                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.volume_up, color: textColor.withOpacity(0.5), size: 24),
                                                  onPressed: () => TtsHelper.speak(text),
                                                ),
                                              ]
                                            ),
                                          ),
                                          if (_hasAnswered && isThisCorrect)
                                            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
                                          if (_hasAnswered && isThisSelected && !isCorrect)
                                            const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 28),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                              
                              if (question.type == 'SYLLABLE_TRAIN' || question.type == 'SENTENCE_BUILDER' || question.type == 'MISSING_SYLLABLE') {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    questionContent,
                                  ],
                                );
                              }
                              
                              if (isWide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 11, child: questionContent), // Frog game gets slightly more width
                                    const SizedBox(width: 48),
                                    Expanded(flex: 9, child: optionsContent),
                                  ],
                                );
                              } else {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    questionContent,
                                    const SizedBox(height: 40),
                                    optionsContent,
                                  ],
                                );
                              }
                            }
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Bottom Action Bar
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 20, offset: const Offset(0, -4))]
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: _hasAnswered && !isCorrect
                        ? Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showAiExplanation(question),
                                  icon: Icon(Icons.auto_awesome_rounded, color: isDark ? const Color(0xFFDDD6FE) : const Color(0xFF7C3AED), size: 20),
                                  label: Text(
                                    '¿Por qué? Explicación IA 💡',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFFDDD6FE) : const Color(0xFF7C3AED),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6), width: 2),
                                    backgroundColor: isDark ? const Color(0xFF312E81).withOpacity(0.4) : const Color(0xFFFAF5FF),
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 5,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_currentIndex + 1 >= questions.length) {
                                      _submitScore(questions.length);
                                      AudioFx.playVictory();
                                    }
                                    setState(() {
                                      _currentIndex++;
                                      _selectedOption = null;
                                      _hasAnswered = false;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    elevation: 4,
                                  ),
                                  child: const Text(
                                    'CONTINUAR',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: _selectedOption == null ? null : () {
                              if (!_hasAnswered) {
                                // Check answer and play sound
                                if (isCorrect) {
                                  AudioFx.playCorrect();
                                } else {
                                  AudioFx.playWrong();
                                }
                                setState(() {
                                  _hasAnswered = true;
                                  if (isCorrect) _score++;
                                });
                              } else {
                                // Next question
                                if (_currentIndex + 1 >= questions.length) {
                                  _submitScore(questions.length);
                                  AudioFx.playVictory();
                                }
                                setState(() {
                                  _currentIndex++;
                                  _selectedOption = null;
                                  _hasAnswered = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasAnswered 
                                 ? (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444)) 
                                 : const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFE2E8F0),
                              disabledForegroundColor: const Color(0xFF94A3B8),
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              minimumSize: const Size(double.infinity, 60),
                              elevation: _selectedOption == null ? 0 : 4,
                            ),
                            child: Text(
                              _hasAnswered ? 'CONTINUAR' : 'COMPROBAR RESPUESTA',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                            ),
                          ),
                  ),
                ),
              )
            ],
              ),
            ],
          );
  }
}

class SyllableTrainWidget extends StatefulWidget {
  final Question question;
  final bool hasAnswered;
  final ValueChanged<String?> onSyllablesPlaced;

  const SyllableTrainWidget({super.key, required this.question, required this.hasAnswered, required this.onSyllablesPlaced});

  @override
  State<SyllableTrainWidget> createState() => _SyllableTrainWidgetState();
}

class _SyllableTrainWidgetState extends State<SyllableTrainWidget> {
  late List<String> targetSyllables;
  late List<String> availableSyllables;
  late List<String?> placedSyllables;
  
  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void didUpdateWidget(covariant SyllableTrainWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _initGame();
    }
  }

  void _initGame() {
    final meta = widget.question.metadata ?? {};
    targetSyllables = List<String>.from(meta['syllables'] ?? []);
    final distractors = List<String>.from(meta['distractors'] ?? []);
    
    availableSyllables = [...targetSyllables, ...distractors];
    availableSyllables.shuffle();
    
    placedSyllables = List.filled(targetSyllables.length, null);
  }

  void _checkComplete() {
    bool isFull = !placedSyllables.contains(null);
    if (!isFull) {
      widget.onSyllablesPlaced(null);
    } else {
      bool won = true;
      for (int i = 0; i < targetSyllables.length; i++) {
        if (placedSyllables[i] != targetSyllables[i]) {
          won = false;
          break;
        }
      }
      widget.onSyllablesPlaced(won ? widget.question.correctOption : 'WRONG_OPTION');
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.question.metadata ?? {};
    final String targetWord = meta['targetWord'] ?? '';
    final String? imageUrl = meta['imageUrl'];
    final bool isWon = widget.hasAnswered;

    return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.question.questionText,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.3),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Color(0xFF4F46E5), size: 32),
                  onPressed: () => TtsHelper.speak(widget.question.questionText),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Train wagos
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(imageUrl, height: 90, fit: BoxFit.cover, errorBuilder: (c,e,s) => const SizedBox.shrink()),
                    ),
                  ),
                ...List.generate(targetSyllables.length, (index) {
                  return DragTarget<String>(
                    builder: (context, candidateData, rejectedData) {
                      final placed = placedSyllables[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: placed == null ? Colors.grey.shade200 : (isWon ? (placed == targetSyllables[index] ? Colors.green.shade100 : Colors.red.shade100) : Colors.purple.shade50),
                          border: Border.all(color: placed == null ? Colors.grey.shade400 : (isWon ? (placed == targetSyllables[index] ? Colors.green : Colors.red) : Colors.purple), width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                      child: placed != null 
                        ? GestureDetector(
                            onTap: isWon ? null : () {
                              setState(() {
                                availableSyllables.add(placed);
                                placedSyllables[index] = null;
                              });
                            },
                            child: Text(placed, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          )
                        : (candidateData.isNotEmpty ? const Icon(Icons.download, color: Colors.grey) : null),
                    ),
                  );
                },
                onWillAccept: (data) => placedSyllables[index] == null && !isWon,
                onAccept: (data) {
                  setState(() {
                    placedSyllables[index] = data;
                    availableSyllables.remove(data);
                  });
                  _checkComplete();
                },
              );
            }),
          ],
        ),
        
        const SizedBox(height: 48),
        
        // Available blocks
        if (!isWon)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: availableSyllables.map((syllable) {
              return GestureDetector(
                onTap: () {
                  final firstEmptyIndex = placedSyllables.indexOf(null);
                  if (firstEmptyIndex != -1) {
                    setState(() {
                      placedSyllables[firstEmptyIndex] = syllable;
                      availableSyllables.remove(syllable);
                    });
                    _checkComplete();
                  }
                },
                child: Draggable<String>(
                  data: syllable,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(color: Colors.purple.shade400, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(syllable, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
                    ),
                  ),
                  childWhenDragging: Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.purple, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.2), offset: const Offset(0,4), blurRadius: 4)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(syllable, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple)),
                        GestureDetector(
                          onTap: () => TtsHelper.speak(syllable),
                          child: const Icon(Icons.volume_up, size: 16, color: Colors.purple),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
        if (isWon)
          Column(
            children: [
              const SizedBox(height: 20),
              Icon(
                (!placedSyllables.contains(null) && placedSyllables.join('') == targetSyllables.join('')) ? Icons.star : Icons.close, 
                color: (!placedSyllables.contains(null) && placedSyllables.join('') == targetSyllables.join('')) ? Colors.orange : Colors.red, 
                size: 64
              ),
              const SizedBox(height: 8),
              Text(
                !placedSyllables.contains(null) && placedSyllables.join('') == targetSyllables.join('') 
                  ? '¡Correcto! Es $targetWord' 
                  : '¡Incorrecto! La palabra era $targetWord', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: (!placedSyllables.contains(null) && placedSyllables.join('') == targetSyllables.join('')) ? Colors.green : Colors.red
                )
              ),
            ],
          )
      ],
    );
  }
}
// ==========================================================
// WIDGET: ARMA LA ORACIÓN (SENTENCE BUILDER)
// ==========================================================

class SentenceBuilderWidget extends StatefulWidget {
  final Question question;
  final bool hasAnswered;
  final Function(String?) onWordsPlaced;

  const SentenceBuilderWidget({
    super.key,
    required this.question,
    required this.hasAnswered,
    required this.onWordsPlaced,
  });

  @override
  State<SentenceBuilderWidget> createState() => _SentenceBuilderWidgetState();
}

class _SentenceBuilderWidgetState extends State<SentenceBuilderWidget> {
  late List<String> targetWords;
  late List<String> availableWords;
  late List<String?> placedWords;
  late String targetSentence;
  bool _spokenOnAnswer = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void didUpdateWidget(covariant SentenceBuilderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _initGame();
    }
    if (widget.hasAnswered && !_spokenOnAnswer) {
      _spokenOnAnswer = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        TtsHelper.speak(targetSentence);
      });
    }
  }

  void _initGame() {
    _spokenOnAnswer = false;
    final meta = widget.question.metadata ?? {};
    targetSentence = (meta['targetSentence'] ?? widget.question.questionText).toString().trim();
    
    if (meta['words'] != null && (meta['words'] as List).isNotEmpty) {
      targetWords = (meta['words'] as List).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else {
      targetWords = targetSentence.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    }
    
    List<String> distractors = [];
    if (meta['distractors'] != null && (meta['distractors'] as List).isNotEmpty) {
      distractors = (meta['distractors'] as List).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }

    availableWords = [...targetWords, ...distractors]..shuffle();
    placedWords = List.filled(targetWords.length, null);
  }

  void _checkComplete() {
    bool isFull = !placedWords.contains(null);
    if (!isFull) {
      widget.onWordsPlaced(null);
    } else {
      bool won = true;
      for (int i = 0; i < targetWords.length; i++) {
        if (placedWords[i] != targetWords[i]) {
          won = false;
          break;
        }
      }
      widget.onWordsPlaced(won ? widget.question.correctOption : 'WRONG_OPTION');
    }
  }

  void _placeWord(String word) {
    if (widget.hasAnswered) return;
    final firstEmpty = placedWords.indexOf(null);
    if (firstEmpty != -1) {
      setState(() {
        placedWords[firstEmpty] = word;
        availableWords.remove(word);
      });
      _checkComplete();
    }
  }

  void _unplaceWord(int index) {
    if (widget.hasAnswered) return;
    final word = placedWords[index];
    if (word != null) {
      setState(() {
        availableWords.add(word);
        placedWords[index] = null;
      });
      _checkComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.question.metadata ?? {};
    final String? imageUrl = meta['imageUrl'];
    final bool isWon = widget.hasAnswered;
    final bool isAllCorrect = !placedWords.contains(null) && placedWords.join(' ') == targetWords.join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Instruction header with audio
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.question.questionText.isNotEmpty ? widget.question.questionText : '¡Ordena las palabras para formar la oración!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.3),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up, color: Color(0xFF0D9488), size: 32),
              onPressed: () => TtsHelper.speak(widget.question.questionText.isNotEmpty ? widget.question.questionText : 'Ordena las palabras para formar la oración'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Optional Illustration Image
        if (imageUrl != null && imageUrl.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imageUrl,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
          ),

        // Sentence placement zone (The Line of Words)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: isWon 
              ? (isAllCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2))
              : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isWon 
                ? (isAllCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
                : const Color(0xFFCCFBF1),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: List.generate(targetWords.length, (index) {
                  final placed = placedWords[index];
                  return DragTarget<String>(
                    builder: (context, candidateData, rejectedData) {
                      Color boxColor = Colors.teal.shade50;
                      Color borderColor = Colors.teal.shade200;
                      Color textColor = Colors.teal.shade900;

                      if (placed == null) {
                        boxColor = Colors.grey.shade100;
                        borderColor = Colors.grey.shade300;
                      } else if (isWon) {
                        if (placed == targetWords[index]) {
                          boxColor = const Color(0xFFDCFCE7);
                          borderColor = const Color(0xFF22C55E);
                          textColor = const Color(0xFF15803D);
                        } else {
                          boxColor = const Color(0xFFFEE2E2);
                          borderColor = const Color(0xFFEF4444);
                          textColor = const Color(0xFFB91C1C);
                        }
                      }

                      return InkWell(
                        onTap: () => _unplaceWord(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: const BoxConstraints(minWidth: 70, minHeight: 52),
                          decoration: BoxDecoration(
                            color: boxColor,
                            border: Border.all(
                              color: borderColor,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: placed != null ? [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))
                            ] : null,
                          ),
                          child: Center(
                            child: placed != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      placed,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    if (!isWon) ...[
                                      const SizedBox(width: 6),
                                      Icon(Icons.close, size: 16, color: textColor.withOpacity(0.6)),
                                    ],
                                  ],
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                          ),
                        ),
                      );
                    },
                    onWillAccept: (data) => placedWords[index] == null && !isWon,
                    onAccept: (data) {
                      setState(() {
                        placedWords[index] = data;
                        availableWords.remove(data);
                      });
                      _checkComplete();
                    },
                  );
                }),
              ),
              if (!isWon && placedWords.every((p) => p == null)) ...[
                const SizedBox(height: 12),
                Text(
                  'Toca o arrastra las palabras en orden',
                  style: TextStyle(fontSize: 14, color: Colors.teal.shade700, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Available words bank
        if (!isWon) ...[
          const Text(
            'Palabras disponibles:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: availableWords.map((word) {
              return Draggable<String>(
                data: word,
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Text(
                      word,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(word, style: const TextStyle(fontSize: 20, color: Colors.transparent)),
                  ),
                ),
                child: InkWell(
                  onTap: () => _placeWord(word),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF0D9488), width: 2),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D9488).withOpacity(0.15),
                          offset: const Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          word,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => TtsHelper.speak(word),
                          child: const Icon(Icons.volume_up, size: 20, color: Color(0xFF0D9488)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        // Feedback / Result when answered
        if (isWon) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isAllCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isAllCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAllCorrect ? Icons.check_circle : Icons.info,
                      color: isAllCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      size: 32,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        isAllCorrect ? '¡Excelente lectura! 🎉' : '¡Casi lo logras!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isAllCorrect ? const Color(0xFF15803D) : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'La oración es:',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  '"$targetSentence"',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => TtsHelper.speak(targetSentence),
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Escuchar oración completa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAllCorrect ? const Color(0xFF16A34A) : const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ==========================================================
// WIDGET: LA SÍLABA PERDIDA (MISSING SYLLABLE)
// ==========================================================

class MissingSyllableWidget extends StatefulWidget {
  final Question question;
  final bool hasAnswered;
  final Function(String?) onOptionSelected;

  const MissingSyllableWidget({
    super.key,
    required this.question,
    required this.hasAnswered,
    required this.onOptionSelected,
  });

  @override
  State<MissingSyllableWidget> createState() => _MissingSyllableWidgetState();
}

class _MissingSyllableWidgetState extends State<MissingSyllableWidget> {
  late String targetWord;
  late List<String> syllables;
  late int missingIndex;
  late List<String> options;
  String? _selectedSyllable;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void didUpdateWidget(covariant MissingSyllableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _initGame();
    }
  }

  void _initGame() {
    final meta = widget.question.metadata ?? {};
    targetWord = meta['targetWord']?.toString() ?? 'Palabra';
    syllables = (meta['syllables'] as List?)?.map((e) => e.toString()).toList() ?? ['Pa', 'la', 'bra'];
    missingIndex = (meta['missingIndex'] as num?)?.toInt() ?? 1;
    if (missingIndex >= syllables.length) missingIndex = 0;

    if (meta['options'] != null && (meta['options'] as List).isNotEmpty) {
      options = (meta['options'] as List).map((e) => e.toString()).toList();
    } else {
      options = [
        widget.question.optionA,
        widget.question.optionB,
        widget.question.optionC,
        widget.question.optionD,
      ].where((o) => o.isNotEmpty && o != '-').toList();
    }
    _selectedSyllable = null;
  }

  void _selectOption(int index, String syllable) {
    if (widget.hasAnswered) return;
    setState(() {
      _selectedSyllable = syllable;
    });
    final letter = String.fromCharCode(65 + index);
    widget.onOptionSelected(letter);
    TtsHelper.speak(syllable);
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.question.metadata ?? {};
    final String? imageUrl = meta['imageUrl'];
    final bool isWon = widget.hasAnswered;
    final String correctSyllable = (missingIndex < syllables.length) ? syllables[missingIndex] : '';
    final bool isCorrect = isWon && _selectedSyllable?.toLowerCase() == correctSyllable.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.question.questionText.isNotEmpty ? widget.question.questionText : '¡Encuentra la sílaba que falta!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.3),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up, color: Color(0xFFEA580C), size: 32),
              onPressed: () => TtsHelper.speak(widget.question.questionText.isNotEmpty ? widget.question.questionText : 'Encuentra la sílaba que falta para completar la palabra'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (imageUrl != null && imageUrl.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imageUrl,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
          ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFED7AA), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: List.generate(syllables.length, (index) {
              final isMissing = index == missingIndex;
              final text = isMissing ? (_selectedSyllable ?? '?') : syllables[index];

              Color boxColor = isMissing ? const Color(0xFFFFF7ED) : const Color(0xFFEEF2FF);
              Color borderColor = isMissing ? const Color(0xFFF97316) : const Color(0xFFC7D2FE);
              Color textColor = isMissing ? const Color(0xFFC2410C) : const Color(0xFF4338CA);

              if (isWon && isMissing) {
                if (isCorrect) {
                  boxColor = const Color(0xFFDCFCE7);
                  borderColor = const Color(0xFF22C55E);
                  textColor = const Color(0xFF15803D);
                } else {
                  boxColor = const Color(0xFFFEE2E2);
                  borderColor = const Color(0xFFEF4444);
                  textColor = const Color(0xFFB91C1C);
                }
              }

              return Container(
                constraints: const BoxConstraints(minWidth: 75, minHeight: 65),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: isMissing ? 3 : 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 36),

        if (!isWon) ...[
          const Text(
            'Toca la sílaba correcta:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(options.length, (index) {
              final opt = options[index];
              final isSelected = _selectedSyllable == opt;

              return InkWell(
                onTap: () => _selectOption(index, opt),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: const BoxConstraints(minWidth: 85, minHeight: 65),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEA580C) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFFED7AA),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withOpacity(isSelected ? 0.3 : 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        opt,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : const Color(0xFF9A3412),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => TtsHelper.speak(opt),
                        child: Icon(
                          Icons.volume_up,
                          size: 18,
                          color: isSelected ? Colors.white70 : const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],

        if (isWon) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.info,
                      color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      size: 32,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isCorrect ? '¡Excelente! Es "$targetWord"' : '¡Casi! La palabra era "$targetWord"',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isCorrect ? const Color(0xFF15803D) : const Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => TtsHelper.speak(targetWord),
                  icon: const Icon(Icons.volume_up),
                  label: Text('Escuchar "$targetWord"', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
