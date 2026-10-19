import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tts_helper.dart';
import '../providers.dart';
import '../audio_fx_helper.dart';
import '../widgets/confetti_celebration.dart';

class MemoryCardItem {
  final String id;
  final String word;
  final String? imageUrl;
  final String? emoji;
  final bool isTextOnly;
  bool isFlipped;
  bool isMatched;

  MemoryCardItem({
    required this.id,
    required this.word,
    this.imageUrl,
    this.emoji,
    required this.isTextOnly,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class MemoryGameScreen extends ConsumerStatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  ConsumerState<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends ConsumerState<MemoryGameScreen> {
  int _selectedThemeIndex = 0;
  List<MemoryCardItem> _cards = [];
  MemoryCardItem? _firstSelected;
  MemoryCardItem? _secondSelected;
  bool _isChecking = false;
  int _moves = 0;
  int _matchesFound = 0;
  bool _hasWon = false;

  final List<Map<String, dynamic>> _themes = [
    {
      'title': '🐶 Animalitos',
      'color': const Color(0xFF8B5CF6),
      'pairs': [
        {'word': 'Gato', 'emoji': '🐱'},
        {'word': 'Perro', 'emoji': '🐶'},
        {'word': 'León', 'emoji': '🦁'},
        {'word': 'Rana', 'emoji': '🐸'},
        {'word': 'Pato', 'emoji': '🦆'},
        {'word': 'Oso', 'emoji': '🐻'},
      ],
    },
    {
      'title': '🍎 Frutas Ricas',
      'color': const Color(0xFF10B981),
      'pairs': [
        {'word': 'Manzana', 'emoji': '🍎'},
        {'word': 'Plátano', 'emoji': '🍌'},
        {'word': 'Uva', 'emoji': '🍇'},
        {'word': 'Fresa', 'emoji': '🍓'},
        {'word': 'Naranja', 'emoji': '🍊'},
        {'word': 'Sandía', 'emoji': '🍉'},
      ],
    },
    {
      'title': '🚀 Cosas del Mundo',
      'color': const Color(0xFF0284C7),
      'pairs': [
        {'word': 'Sol', 'emoji': '☀️'},
        {'word': 'Luna', 'emoji': '🌙'},
        {'word': 'Estrella', 'emoji': '⭐'},
        {'word': 'Carro', 'emoji': '🚗'},
        {'word': 'Barco', 'emoji': '⛵'},
        {'word': 'Casa', 'emoji': '🏠'},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _startNewGame();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final customQ = await ref.read(questionsByTypeProvider('MEMORY_MATCH').future);
        if (customQ.isNotEmpty) {
          final customPairs = customQ.map((q) {
            final meta = q.metadata ?? {};
            return {
              'word': meta['targetWord']?.toString() ?? q.questionText,
              'emoji': meta['emoji']?.toString() ?? '🌟',
              'imageUrl': meta['imageUrl']?.toString() ?? '',
            };
          }).toList();
          if (mounted) {
            setState(() {
              _themes.insert(0, {
                'title': '🌟 Creados por el Profe',
                'color': const Color(0xFFE11D48),
                'pairs': customPairs,
              });
              _selectedThemeIndex = 0;
              _startNewGame();
            });
          }
        }
      } catch (_) {}
    });
  }

  void _startNewGame() {
    setState(() {
      _moves = 0;
      _matchesFound = 0;
      _hasWon = false;
      _firstSelected = null;
      _secondSelected = null;
      _isChecking = false;

      final theme = _themes[_selectedThemeIndex];
      final List<Map<String, String>> pairs = List<Map<String, String>>.from(theme['pairs']);
      
      // Select 6 pairs (12 cards total)
      final selectedPairs = pairs.take(6).toList();
      _cards = [];

      for (int i = 0; i < selectedPairs.length; i++) {
        final item = selectedPairs[i];
        final word = item['word'] ?? '';
        final emoji = item['emoji'] ?? '🌟';
        final imageUrl = item['imageUrl']?.isNotEmpty == true ? item['imageUrl'] : null;

        // Card 1: Picture Card (Emoji or Image)
        _cards.add(MemoryCardItem(
          id: 'p_$i',
          word: word,
          emoji: emoji,
          imageUrl: imageUrl,
          isTextOnly: false,
        ));

        // Card 2: Word Card (Text)
        _cards.add(MemoryCardItem(
          id: 'w_$i',
          word: word,
          isTextOnly: true,
        ));
      }

      _cards.shuffle(Random());
    });
  }

  void _onCardTap(MemoryCardItem card) {
    if (_isChecking || card.isFlipped || card.isMatched) return;

    // Read the word aloud for literacy reinforcement
    TtsHelper.speak(card.word);

    setState(() {
      card.isFlipped = true;
    });

    if (_firstSelected == null) {
      _firstSelected = card;
    } else {
      _secondSelected = card;
      _moves++;
      _checkMatch();
    }
  }

  void _checkMatch() async {
    _isChecking = true;

    if (_firstSelected!.word == _secondSelected!.word) {
      // It's a match!
      AudioFx.playCorrect();
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      setState(() {
        _firstSelected!.isMatched = true;
        _secondSelected!.isMatched = true;
        _firstSelected = null;
        _secondSelected = null;
        _matchesFound++;
        _isChecking = false;

        if (_matchesFound == 6) {
          _hasWon = true;
          AudioFx.playVictory();
          _awardStars();
        }
      });
    } else {
      // Not a match, flip them back
      AudioFx.playWrong();
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      setState(() {
        _firstSelected!.isFlipped = false;
        _secondSelected!.isFlipped = false;
        _firstSelected = null;
        _secondSelected = null;
        _isChecking = false;
      });
    }
  }

  void _awardStars() {
    Future.delayed(const Duration(milliseconds: 300), () {
      TtsHelper.speak('¡Felicidades! Encontraste todas las palabras.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = _themes[_selectedThemeIndex];
    final Color themeColor = theme['color'];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Text(
          'Memorama de Palabras',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
            tooltip: 'Reiniciar Juego',
            onPressed: _startNewGame,
          ),
        ],
      ),
      body: ConfettiCelebration(
        isActive: _hasWon,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
            children: [
              // Theme Selector & Score Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // Theme tabs
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_themes.length, (idx) {
                            final isSel = _selectedThemeIndex == idx;
                            final t = _themes[idx];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  t['title'],
                                  style: TextStyle(
                                    color: isSel ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: t['color'],
                                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                side: BorderSide(
                                  color: isSel ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setState(() {
                                      _selectedThemeIndex = idx;
                                    });
                                    _startNewGame();
                                  }
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Move counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'Intentos: $_moves',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Cards Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 4 columns on desktop/tablet, 3 on phone
                      int crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;

                      return GridView.builder(
                        itemCount: _cards.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.95,
                        ),
                        itemBuilder: (context, index) {
                          final card = _cards[index];
                          return _buildMemoryCard(card, themeColor, isDark);
                        },
                      );
                    },
                  ),
                ),
              ),

              // Bottom instruction or Victory Banner
              if (_hasWon)
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 36)),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('¡Lo lograste!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                            Text('Emparejaste todas las palabras correctamente.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _startNewGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('¡Otra vez!', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, size: 18, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Voltea 2 cartas para encontrar la pareja (Imagen y su Palabra)',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildMemoryCard(MemoryCardItem card, Color themeColor, bool isDark) {
    return GestureDetector(
      onTap: () => _onCardTap(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: card.isMatched
              ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
              : (card.isFlipped ? (isDark ? const Color(0xFF1E293B) : Colors.white) : themeColor),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: card.isMatched
                ? const Color(0xFF10B981)
                : (card.isFlipped
                    ? (isDark ? const Color(0xFF334155) : themeColor.withOpacity(0.4))
                    : Colors.transparent),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: card.isFlipped
                  ? (isDark ? Colors.black26 : Colors.black.withOpacity(0.06))
                  : themeColor.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: card.isFlipped || card.isMatched
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!card.isTextOnly) ...[
                      if (card.imageUrl != null && card.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            card.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Text(card.emoji ?? '🌟', style: const TextStyle(fontSize: 48)),
                          ),
                        )
                      else if (card.emoji != null)
                        Text(card.emoji!, style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 4),
                      Text(
                        card.word,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.menu_book, color: Color(0xFF6366F1), size: 28),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          card.word,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: card.isMatched
                                ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.white70, size: 36),
                    SizedBox(height: 4),
                    Text('?', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
        ),
      ),
    );
  }
}
