import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import 'quiz_screen.dart';
import 'rewards_store_screen.dart';
import 'memory_game_screen.dart';

class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  // Built-in starter levels for La Sílaba Perdida
  List<Question> _getMissingSyllableQuestions() {
    return [
      Question(
        id: 'ms_1',
        lessonId: 'free_play',
        type: 'MISSING_SYLLABLE',
        questionText: '¡Encuentra la sílaba que falta!',
        optionA: 'ma',
        optionB: 'lo',
        optionC: 'ra',
        optionD: 'so',
        correctOption: 'B',
        explanation: 'Pe - LO - ta forma Pelota.',
        metadata: {
          'targetWord': 'Pelota',
          'syllables': ['Pe', 'lo', 'ta'],
          'missingIndex': 1,
          'options': ['ma', 'lo', 'ra', 'so'],
          'imageUrl': 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=400&q=80',
        },
      ),
      Question(
        id: 'ms_2',
        lessonId: 'free_play',
        type: 'MISSING_SYLLABLE',
        questionText: '¿Con qué sílaba empieza este animalito?',
        optionA: 'Ga',
        optionB: 'Pa',
        optionC: 'Ma',
        optionD: 'Ra',
        correctOption: 'A',
        explanation: 'GA - to forma Gato.',
        metadata: {
          'targetWord': 'Gato',
          'syllables': ['Ga', 'to'],
          'missingIndex': 0,
          'options': ['Ga', 'Pa', 'Ma', 'Ra'],
          'imageUrl': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400&q=80',
        },
      ),
      Question(
        id: 'ms_3',
        lessonId: 'free_play',
        type: 'MISSING_SYLLABLE',
        questionText: '¡Completa el nombre de esta fruta!',
        optionA: 'ta',
        optionB: 'da',
        optionC: 'na',
        optionD: 'la',
        correctOption: 'C',
        explanation: 'Man - za - NA forma Manzana.',
        metadata: {
          'targetWord': 'Manzana',
          'syllables': ['Man', 'za', 'na'],
          'missingIndex': 2,
          'options': ['ta', 'da', 'na', 'la'],
          'imageUrl': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400&q=80',
        },
      ),
      Question(
        id: 'ms_4',
        lessonId: 'free_play',
        type: 'MISSING_SYLLABLE',
        questionText: '¿Qué sílaba falta en medio de este vegetal?',
        optionA: 'ba',
        optionB: 'ma',
        optionC: 'sa',
        optionD: 'la',
        correctOption: 'B',
        explanation: 'To - MA - te forma Tomate.',
        metadata: {
          'targetWord': 'Tomate',
          'syllables': ['To', 'ma', 'te'],
          'missingIndex': 1,
          'options': ['ba', 'ma', 'sa', 'la'],
          'imageUrl': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=400&q=80',
        },
      ),
      Question(
        id: 'ms_5',
        lessonId: 'free_play',
        type: 'MISSING_SYLLABLE',
        questionText: '¡Brilla en la noche! ¿Qué sílaba falta?',
        optionA: 'ple',
        optionB: 'gre',
        optionC: 'bre',
        optionD: 'tre',
        correctOption: 'D',
        explanation: 'Es - TRE - lla forma Estrella.',
        metadata: {
          'targetWord': 'Estrella',
          'syllables': ['Es', 'tre', 'lla'],
          'missingIndex': 1,
          'options': ['ple', 'gre', 'bre', 'tre'],
          'imageUrl': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400&q=80',
        },
      ),
    ];
  }
  // Built-in starter levels for Tren de Sílabas
  List<Question> _getSyllableTrainQuestions() {
    return [
      Question(
        id: 'st_1',
        lessonId: 'free_play',
        type: 'SYLLABLE_TRAIN',
        questionText: '¡Arma la palabra observando la imagen!',
        optionA: '-',
        optionB: '-',
        optionC: '-',
        optionD: '-',
        correctOption: 'A',
        explanation: 'Las sílabas de GATO son: GA y TO.',
        metadata: {
          'targetWord': 'Gato',
          'syllables': ['Ga', 'to'],
          'distractors': ['ma', 'so'],
          'imageUrl': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400&q=80',
        },
      ),
      Question(
        id: 'st_2',
        lessonId: 'free_play',
        type: 'SYLLABLE_TRAIN',
        questionText: '¡Arma el nombre del animalito!',
        optionA: '-',
        optionB: '-',
        optionC: '-',
        optionD: '-',
        correctOption: 'A',
        explanation: 'Las sílabas de PERRO son: PE y RRO.',
        metadata: {
          'targetWord': 'Perro',
          'syllables': ['Pe', 'rro'],
          'distractors': ['la', 'mi'],
          'imageUrl': 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=400&q=80',
        },
      ),
      Question(
        id: 'st_3',
        lessonId: 'free_play',
        type: 'SYLLABLE_TRAIN',
        questionText: '¡Arma esta rica fruta!',
        optionA: '-',
        optionB: '-',
        optionC: '-',
        optionD: '-',
        correctOption: 'A',
        explanation: 'Las sílabas de MANZANA son: MAN, ZA y NA.',
        metadata: {
          'targetWord': 'Manzana',
          'syllables': ['Man', 'za', 'na'],
          'distractors': ['pe', 'lo'],
          'imageUrl': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400&q=80',
        },
      ),
      Question(
        id: 'st_4',
        lessonId: 'free_play',
        type: 'SYLLABLE_TRAIN',
        questionText: '¡Arma la palabra para jugar!',
        optionA: '-',
        optionB: '-',
        optionC: '-',
        optionD: '-',
        correctOption: 'A',
        explanation: 'Las sílabas de PELOTA son: PE, LO y TA.',
        metadata: {
          'targetWord': 'Pelota',
          'syllables': ['Pe', 'lo', 'ta'],
          'distractors': ['ca', 'me'],
          'imageUrl': 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=400&q=80',
        },
      ),
      Question(
        id: 'st_5',
        lessonId: 'free_play',
        type: 'SYLLABLE_TRAIN',
        questionText: '¡Arma la criatura mítica!',
        optionA: '-',
        optionB: '-',
        optionC: '-',
        optionD: '-',
        correctOption: 'A',
        explanation: 'Las sílabas de DRAGÓN son: DRA y GÓN.',
        metadata: {
          'targetWord': 'Dragón',
          'syllables': ['Dra', 'gón'],
          'distractors': ['tro', 'ban'],
          'imageUrl': 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=400&q=80',
        },
      ),
    ];
  }

  // Built-in starter levels for Arma la Oración
  List<Question> _getSentenceBuilderQuestions() {
    return [
      Question(
        id: 'sb_1',
        lessonId: 'free_play',
        type: 'SENTENCE_BUILDER',
        questionText: '¡Ordena las palabras para formar la oración!',
        optionA: '-',
        optionB: '-',
        optionC: '-',
        optionD: '-',
        correctOption: 'A',
        explanation: 'La oración correcta es: El perro come croquetas.',
        metadata: {
          'targetSentence': 'El perro come croquetas',
          'words': ['El', 'perro', 'come', 'croquetas'],
          'distractors': ['gato', 'duerme'],
          'imageUrl': 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=400&q=80',
        },
      ),
      Question(
        id: 'sb_2',
        lessonId: 'free_play',
        type: 'SENTENCE_BUILDER',
        questionText: '¡Ordena las palabras sobre el gatito!',
        optionA: '-',
        optionB: '-',
        optionC: '-',
        optionD: '-',
        correctOption: 'A',
        explanation: 'La oración correcta es: El gato duerme mucho.',
        metadata: {
          'targetSentence': 'El gato duerme mucho',
          'words': ['El', 'gato', 'duerme', 'mucho'],
          'distractors': ['corre', 'salta'],
          'imageUrl': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400&q=80',
        },
      ),
      Question(
        id: 'sb_3',
        lessonId: 'free_play',
        type: 'SENTENCE_BUILDER',
        questionText: '¡Ordena las palabras de la fruta!',
        optionA: '-',
        optionB: '-',
        optionC: '-',
        optionD: '-',
        correctOption: 'A',
        explanation: 'La oración correcta es: La manzana es roja.',
        metadata: {
          'targetSentence': 'La manzana es roja',
          'words': ['La', 'manzana', 'es', 'roja'],
          'distractors': ['azul', 'verde'],
          'imageUrl': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400&q=80',
        },
      ),
      Question(
        id: 'sb_4',
        lessonId: 'free_play',
        type: 'SENTENCE_BUILDER',
        questionText: '¡Ordena las palabras para leer esta frase!',
        optionA: '-',
        optionB: '-',
        optionC: '-',
        optionD: '-',
        correctOption: 'A',
        explanation: 'La oración correcta es: Mi mamá me ama.',
        metadata: {
          'targetSentence': 'Mi mamá me ama',
          'words': ['Mi', 'mamá', 'me', 'ama'],
          'distractors': ['papá', 'come'],
        },
      ),
      Question(
        id: 'sb_5',
        lessonId: 'free_play',
        type: 'SENTENCE_BUILDER',
        questionText: '¡Ordena las palabras sobre el cielo!',
        optionA: '-',
        optionB: '-',
        optionC: '-',
        optionD: '-',
        correctOption: 'A',
        explanation: 'La oración correcta es: El sol brilla hoy.',
        metadata: {
          'targetSentence': 'El sol brilla hoy',
          'words': ['El', 'sol', 'brilla', 'hoy'],
          'distractors': ['luna', 'noche'],
        },
      ),
    ];
  }

  // Built-in starter levels for Rana Saltarina
  List<Question> _getFrogQuestions() {
    return [
      Question(
        id: 'fr_1',
        lessonId: 'free_play',
        type: 'FROG_SEQUENCE',
        questionText: '¿Qué número sigue en la serie de 2 en 2?',
        optionA: '8',
        optionB: '7',
        optionC: '10',
        optionD: '6',
        correctOption: 'A',
        explanation: '2 + 2 = 4, 4 + 2 = 6, 6 + 2 = 8.',
        metadata: {
          'startNumber': 2,
          'step': 2,
          'jumps': 3,
        },
      ),
      Question(
        id: 'fr_2',
        lessonId: 'free_play',
        type: 'FROG_SEQUENCE',
        questionText: '¡Ayuda a la ranita a saltar de 5 en 5!',
        optionA: '25',
        optionB: '20',
        optionC: '15',
        optionD: '30',
        correctOption: 'A',
        explanation: '5, 10, 15, 20... ¡el siguiente es 25!',
        metadata: {
          'startNumber': 5,
          'step': 5,
          'jumps': 4,
        },
      ),
      Question(
        id: 'fr_3',
        lessonId: 'free_play',
        type: 'FROG_SEQUENCE',
        questionText: '¡Salta de 3 en 3 hacia adelante!',
        optionA: '12',
        optionB: '11',
        optionC: '10',
        optionD: '15',
        correctOption: 'A',
        explanation: '3 + 3 = 6, 6 + 3 = 9, 9 + 3 = 12.',
        metadata: {
          'startNumber': 3,
          'step': 3,
          'jumps': 3,
        },
      ),
      Question(
        id: 'fr_4',
        lessonId: 'free_play',
        type: 'FROG_SEQUENCE',
        questionText: '¡Saltando de 10 en 10!',
        optionA: '40',
        optionB: '35',
        optionC: '50',
        optionD: '45',
        correctOption: 'A',
        explanation: '10, 20, 30... ¡el siguiente es 40!',
        metadata: {
          'startNumber': 10,
          'step': 10,
          'jumps': 3,
        },
      ),
    ];
  }

  void _launchGame(BuildContext context, WidgetRef ref, String title, String type, List<Question> fallbackQuestions) async {
    List<Question> questions = fallbackQuestions;
    try {
      final customQuestions = await ref.read(questionsByTypeProvider(type).future);
      if (customQuestions.isNotEmpty) {
        questions = [...customQuestions, ...fallbackQuestions];
      }
    } catch (_) {}
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            customTitle: title,
            customQuestions: questions,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA855F7).withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sports_esports, color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('ZONA DE JUEGOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '¡Aprende Jugando!',
                            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Practica tus habilidades jugando, supera retos y junta estrellas para tus premios favoritos.',
                            style: TextStyle(fontSize: 16, color: Colors.purple.shade50, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Stars badge & store link
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsStoreScreen()));
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text('Tus Estrellas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🌟 ', style: TextStyle(fontSize: 22)),
                                Text(
                                  '${user?.stars ?? 0}',
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text('Ir a Tiendita ➔', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

                            if (user?.role == 'ADMIN' || user?.role == 'SUPER_ADMIN') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.add_photo_alternate, color: Color(0xFF2563EB), size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💡 ¿Quieres agregar más palabras o tus propias imágenes a estos juegos?',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Ve al menú lateral a "Juegos Educativos" para crear nuevos Trenes de Sílabas, Memorama, Sílabas Perdidas o Retos con tus fotos desde tu PC. ¡Aparecerán automáticamente aquí para tus alumnos!',
                              style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ==========================================
              // SECCIÓN 1: APRENDE A LEER
              // ==========================================
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.auto_stories, color: Colors.purple, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aprende a Leer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      Text('Juegos de palabras, sílabas y comprensión lectora', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      // Card: Memorama de Palabras
                      _buildGameCard(
                        context: context,
                        width: constraints.maxWidth > 700 ? (constraints.maxWidth - 40) / 2 : constraints.maxWidth,
                        title: 'Memorama de Palabras',
                        tag: 'ASOCIACIÓN Y MEMORIA',
                        description: 'Encuentra las parejas de imágenes y palabras escritas. ¡Con voz, temas y festejo!',
                        icon: Icons.grid_view_rounded,
                        gradientColors: [const Color(0xFFE11D48), const Color(0xFFF43F5E)],
                        badgeColor: Colors.pink.shade100,
                        badgeTextColor: Colors.pink.shade900,
                        buttonText: '¡Jugar Ahora! ▶',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MemoryGameScreen()),
                          );
                        },
                      ),

                      // Card: La Sílaba Perdida
                      _buildGameCard(
                        context: context,
                        width: constraints.maxWidth > 700 ? (constraints.maxWidth - 40) / 2 : constraints.maxWidth,
                        title: 'La Sílaba Perdida',
                        tag: 'COMPLETAR PALABRAS',
                        description: 'Observa la imagen y la palabra incompleta: ¿qué sílaba falta para que esté completa?',
                        icon: Icons.extension_rounded,
                        gradientColors: [const Color(0xFFD97706), const Color(0xFFF59E0B)],
                        badgeColor: Colors.amber.shade100,
                        badgeTextColor: Colors.amber.shade900,
                        buttonText: '¡Jugar Ahora! ▶',
                        onTap: () => _launchGame(context, ref, 'La Sílaba Perdida', 'MISSING_SYLLABLE', _getMissingSyllableQuestions()),
                      ),
                      // Card: Tren de Sílabas
                      _buildGameCard(
                        context: context,
                        width: constraints.maxWidth > 700 ? (constraints.maxWidth - 40) / 2 : constraints.maxWidth,
                        title: 'El Tren de Sílabas',
                        tag: 'PALABRAS Y SÍLABAS',
                        description: 'Descubre qué palabra se oculta arrastrando las sílabas a los vagones en orden.',
                        icon: Icons.train,
                        gradientColors: [const Color(0xFF7C3AED), const Color(0xFF9333EA)],
                        badgeColor: Colors.purple.shade100,
                        badgeTextColor: Colors.purple.shade900,
                        buttonText: '¡Jugar Ahora! ▶',
                        onTap: () => _launchGame(context, ref, 'Tren de Sílabas', 'SYLLABLE_TRAIN', _getSyllableTrainQuestions()),
                      ),

                      // Card: Arma la Oración
                      _buildGameCard(
                        context: context,
                        width: constraints.maxWidth > 700 ? (constraints.maxWidth - 40) / 2 : constraints.maxWidth,
                        title: 'Arma la Oración',
                        tag: 'LECTURA FLUIDA',
                        description: 'Conecta las palabras en orden para construir la frase y escucharla en voz alta.',
                        icon: Icons.draw,
                        gradientColors: [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
                        badgeColor: Colors.teal.shade100,
                        badgeTextColor: Colors.teal.shade900,
                        buttonText: '¡Jugar Ahora! ▶',
                        onTap: () => _launchGame(context, ref, 'Arma la Oración', 'SENTENCE_BUILDER', _getSentenceBuilderQuestions()),
                      ),

                      // Card: El Abecedario Mágico (Coming soon)
                      _buildComingSoonCard(
                        width: constraints.maxWidth > 700 ? (constraints.maxWidth - 40) / 2 : constraints.maxWidth,
                        title: 'El Abecedario Mágico',
                        tag: 'FONÉTICA',
                        description: 'Aprende los sonidos de las letras y cómo se juntan para formar sílabas mágicas.',
                        icon: Icons.sort_by_alpha,
                        accentColor: Colors.amber,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 48),

              // ==========================================
              // SECCIÓN 2: APRENDE LOS NÚMEROS
              // ==========================================
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.calculate, color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aprende los Números', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      Text('Juegos de conteo, secuencias y lógica matemática', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      // Card: Rana Saltarina
                      _buildGameCard(
                        context: context,
                        width: constraints.maxWidth > 700 ? (constraints.maxWidth - 40) / 2 : constraints.maxWidth,
                        title: 'La Rana Saltarina',
                        tag: 'SECUENCIAS Y PATRONES',
                        description: 'Ayuda a la ranita a saltar de hoja en hoja calculando la serie de números correcta.',
                        icon: Icons.videogame_asset,
                        gradientColors: [const Color(0xFF059669), const Color(0xFF10B981)],
                        badgeColor: Colors.green.shade100,
                        badgeTextColor: Colors.green.shade900,
                        buttonText: '¡Jugar Ahora! ▶',
                        onTap: () => _launchGame(context, ref, 'Rana Saltarina', 'FROG_SEQUENCE', _getFrogQuestions()),
                      ),

                      // Card: Cuenta y Suma (Coming soon)
                      _buildComingSoonCard(
                        width: constraints.maxWidth > 700 ? (constraints.maxWidth - 40) / 2 : constraints.maxWidth,
                        title: 'Cuenta y Suma',
                        tag: 'CONTEO VISUAL',
                        description: 'Cuenta frutas, animalitos y juguetes para resolver divertidos retos de suma.',
                        icon: Icons.plus_one,
                        accentColor: Colors.pink,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required double width,
    required String title,
    required String tag,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required Color badgeColor,
    required Color badgeTextColor,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(color: badgeTextColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: gradientColors.first,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonCard({
    required double width,
    required String title,
    required String tag,
    required String description,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_clock, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        'MUY PRONTO',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.grey.shade400, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Próximamente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
