import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class AdminAiView extends ConsumerStatefulWidget {
  const AdminAiView({super.key});

  @override
  ConsumerState<AdminAiView> createState() => _AdminAiViewState();
}

class _AdminAiViewState extends ConsumerState<AdminAiView> {
  // Form state
  final _topicCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  int _count = 5;
  bool _isGenerating = false;
  List<Map<String, dynamic>> _generatedQuestions = [];
  String? _errorMsg;
  Map<String, dynamic>? _knowledgeStats;
  bool _isReindexing = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final res = await ref.read(dioProvider).get('/ai/knowledge-stats');
      if (mounted) setState(() => _knowledgeStats = res.data as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<void> _reindexAll() async {
    setState(() => _isReindexing = true);
    try {
      final res = await ref.read(dioProvider).post('/ai/reindex-all');
      final count = res.data['count'] ?? 0;
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Base de conocimiento sincronizada: $count lecciones indexadas.'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al sincronizar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isReindexing = false);
    }
  }

  Future<void> _generateQuiz() async {
    if (_topicCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Por favor escribe el tema del quiz.');
      return;
    }
    setState(() {
      _isGenerating = true;
      _errorMsg = null;
      _generatedQuestions = [];
    });

    try {
      final res = await ref.read(dioProvider).post('/ai/generate-quiz', data: {
        'topic': _topicCtrl.text.trim(),
        'grade': _gradeCtrl.text.trim().isNotEmpty ? _gradeCtrl.text.trim() : 'primaria',
        'subject': _subjectCtrl.text.trim().isNotEmpty ? _subjectCtrl.text.trim() : 'general',
        'count': _count,
      });
      final questions = (res.data['questions'] as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _generatedQuestions = questions);
    } catch (e) {
      if (mounted) setState(() => _errorMsg = 'Error al generar: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _saveQuestion(Map<String, dynamic> q, String? lessonId) async {
    try {
      await ref.read(dioProvider).post('/questions', data: {
        'questionText': q['questionText'],
        'optionA': q['optionA'],
        'optionB': q['optionB'],
        'optionC': q['optionC'],
        'optionD': q['optionD'],
        'correctOption': q['correctOption'],
        'explanation': q['explanation'],
        if (lessonId != null) 'lessonId': lessonId,
        'type': 'MULTIPLE_CHOICE',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pregunta guardada correctamente.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveAllQuestions() async {
    int saved = 0;
    for (final q in _generatedQuestions) {
      try {
        await ref.read(dioProvider).post('/questions', data: {
          'questionText': q['questionText'],
          'optionA': q['optionA'],
          'optionB': q['optionB'],
          'optionC': q['optionC'],
          'optionD': q['optionD'],
          'correctOption': q['correctOption'],
          'explanation': q['explanation'],
          'type': 'MULTIPLE_CHOICE',
        });
        saved++;
      } catch (_) {}
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $saved preguntas guardadas en el banco.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _gradeCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('✨', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Asistente IA con RAG 🤖', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    Text('Genera quizzes automáticamente con Gemini AI, entrenado con el contenido de tus lecciones.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                  ],
                ),
              ),
              // Knowledge base stats chip & Sync button
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_knowledgeStats != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_knowledgeStats!['totalLessons']}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
                          ),
                          const Text('Lecciones\nIndexadas', style: TextStyle(fontSize: 10, color: Color(0xFF4F46E5)), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _isReindexing ? null : _reindexAll,
                    icon: _isReindexing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(_isReindexing ? 'Sincronizando...' : 'Sincronizar RAG'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── Quiz Generator Card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🎯', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text('Generar Quiz con IA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Escribe el tema y la IA generará preguntas automáticamente usando el contenido de tus lecciones.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildField(_topicCtrl, '¿Sobre qué tema? (ej. "El ciclo del agua")', Icons.lightbulb_outline),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(_gradeCtrl, 'Grado (ej. "4to")', Icons.school_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(_subjectCtrl, 'Materia (ej. "Ciencias")', Icons.book_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Cantidad de preguntas:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const SizedBox(width: 12),
                    ...([3, 5, 8, 10].map((n) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$n'),
                        selected: _count == n,
                        selectedColor: const Color(0xFF4F46E5),
                        labelStyle: TextStyle(color: _count == n ? Colors.white : const Color(0xFF475569), fontWeight: FontWeight.bold),
                        onSelected: (_) => setState(() => _count = n),
                      ),
                    ))),
                  ],
                ),
                const SizedBox(height: 20),
                if (_errorMsg != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
                    child: Text(_errorMsg!, style: TextStyle(color: Colors.red.shade700)),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: _isGenerating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      _isGenerating ? 'Generando con IA...' : '✨ Generar Quiz con Gemini',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Generated Questions Results ──────────────────────────────────
          if (_generatedQuestions.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_generatedQuestions.length} preguntas generadas ✅',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _saveAllQuestions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('Guardar todas', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_generatedQuestions.length, (i) {
              final q = _generatedQuestions[i];
              final correct = q['correctOption'] as String? ?? 'A';
              final options = {'A': q['optionA'], 'B': q['optionB'], 'C': q['optionC'], 'D': q['optionD']};

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(q['questionText'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                        ),
                        IconButton(
                          icon: const Icon(Icons.save_rounded, color: Color(0xFF10B981)),
                          onPressed: () => _saveQuestion(q, null),
                          tooltip: 'Guardar esta pregunta',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...options.entries.map((entry) {
                      final isCorrect = entry.key == correct;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isCorrect ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(child: Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(entry.value ?? '', style: TextStyle(color: isCorrect ? const Color(0xFF166534) : const Color(0xFF475569), fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal))),
                            if (isCorrect) const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                          ],
                        ),
                      );
                    }),
                    if (q['explanation'] != null && (q['explanation'] as String).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡 ', style: TextStyle(fontSize: 14)),
                            Expanded(
                              child: Text(
                                q['explanation'],
                                style: const TextStyle(color: Color(0xFF92400E), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
