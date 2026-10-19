import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../models.dart';
import '../providers.dart';

class AdminGamesView extends ConsumerStatefulWidget {
  const AdminGamesView({super.key});

  @override
  ConsumerState<AdminGamesView> createState() => _AdminGamesViewState();
}

class _AdminGamesViewState extends ConsumerState<AdminGamesView> {
  String _selectedGameType = 'SYLLABLE_TRAIN';

  // Controllers for El Tren de Sílabas
  final _trainWordCtrl = TextEditingController();
  final _trainSyllablesCtrl = TextEditingController();
  final _trainDistractorsCtrl = TextEditingController();
  final _trainImageCtrl = TextEditingController();
  final _trainPromptCtrl = TextEditingController(text: '¡Arma la palabra observando la imagen!');

  // Controllers for La Sílaba Perdida
  final _missingWordCtrl = TextEditingController();
  final _missingSyllablesCtrl = TextEditingController();
  final _missingSyllableTargetCtrl = TextEditingController();
  final _missingOptionsCtrl = TextEditingController();
  final _missingImageCtrl = TextEditingController();

  // Controllers for Memorama
  final _memoryWordCtrl = TextEditingController();
  final _memoryEmojiOrImageCtrl = TextEditingController();
  final _memoryHintCtrl = TextEditingController();

  // Controllers for Arma la Oración
  final _sentenceTargetCtrl = TextEditingController();
  final _sentenceDistractorsCtrl = TextEditingController();
  final _sentenceImageCtrl = TextEditingController();

  // Controllers for Rana Saltarina
  final _frogStartCtrl = TextEditingController(text: '2');
  final _frogStepCtrl = TextEditingController(text: '2');
  final _frogJumpsCtrl = TextEditingController(text: '3');
  final _frogPromptCtrl = TextEditingController(text: '¡Ayuda a la ranita a saltar de 2 en 2!');

  String? _selectedLessonId;
  bool _isLoading = false;
  String? _editingId;

  Future<void> _pickAndUploadImage(TextEditingController controller) async {
    try {
      final token = ref.read(sharedPrefsProvider).getString('token');

      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subiendo imagen...'), duration: Duration(seconds: 1)),
          );
        }

        final uri = Uri.parse('$baseUrl/upload/image');
        var request = http.MultipartRequest('POST', uri);
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        final pickedFile = result.first;
        final bytes = await pickedFile.readAsBytes();

        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: pickedFile.name,
        ));

        var response = await request.send();
        if (response.statusCode == 200 || response.statusCode == 201) {
          final respStr = await response.stream.bytesToString();
          final data = jsonDecode(respStr);
          final serverOrigin = baseUrl.replaceAll('/api', '');
          final fullUrl = serverOrigin + data['url'];

          setState(() {
            controller.text = fullUrl;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Imagen subida con éxito!'), backgroundColor: Colors.green),
            );
          }
        } else {
          throw 'Error al subir imagen (código ${response.statusCode})';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearForm() {
    setState(() {
      _editingId = null;
      _trainWordCtrl.clear();
      _trainSyllablesCtrl.clear();
      _trainDistractorsCtrl.clear();
      _trainImageCtrl.clear();
      _trainPromptCtrl.text = '¡Arma la palabra observando la imagen!';

      _missingWordCtrl.clear();
      _missingSyllablesCtrl.clear();
      _missingSyllableTargetCtrl.clear();
      _missingOptionsCtrl.clear();
      _missingImageCtrl.clear();

      _memoryWordCtrl.clear();
      _memoryEmojiOrImageCtrl.clear();
      _memoryHintCtrl.clear();

      _sentenceTargetCtrl.clear();
      _sentenceDistractorsCtrl.clear();
      _sentenceImageCtrl.clear();

      _frogStartCtrl.text = '2';
      _frogStepCtrl.text = '2';
      _frogJumpsCtrl.text = '3';
      _frogPromptCtrl.text = '¡Ayuda a la ranita a saltar en la serie!';
    });
  }

  void _loadForEdit(Question q) {
    setState(() {
      _editingId = q.id;
      _selectedGameType = q.type;
      final meta = q.metadata ?? {};

      if (q.type == 'SYLLABLE_TRAIN') {
        _trainWordCtrl.text = meta['targetWord']?.toString() ?? '';
        final syllables = (meta['syllables'] as List?)?.map((e) => e.toString()).toList() ?? [];
        _trainSyllablesCtrl.text = syllables.join(', ');
        final distractors = (meta['distractors'] as List?)?.map((e) => e.toString()).toList() ?? [];
        _trainDistractorsCtrl.text = distractors.join(', ');
        _trainImageCtrl.text = meta['imageUrl']?.toString() ?? '';
        _trainPromptCtrl.text = q.questionText;
      } else if (q.type == 'MISSING_SYLLABLE') {
        _missingWordCtrl.text = meta['targetWord']?.toString() ?? '';
        final syllables = (meta['syllables'] as List?)?.map((e) => e.toString()).toList() ?? [];
        _missingSyllablesCtrl.text = syllables.join(', ');
        final missingIdx = meta['missingIndex'] is int ? meta['missingIndex'] as int : -1;
        if (missingIdx >= 0 && missingIdx < syllables.length) {
          _missingSyllableTargetCtrl.text = syllables[missingIdx];
        }
        final options = (meta['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
        _missingOptionsCtrl.text = options.join(', ');
        _missingImageCtrl.text = meta['imageUrl']?.toString() ?? '';
      } else if (q.type == 'MEMORY_MATCH') {
        _memoryWordCtrl.text = q.questionText;
        _memoryEmojiOrImageCtrl.text = meta['imageUrl']?.toString() ?? meta['emoji']?.toString() ?? '';
        _memoryHintCtrl.text = q.explanation ?? '';
      } else if (q.type == 'SENTENCE_BUILDER') {
        _sentenceTargetCtrl.text = meta['targetSentence']?.toString() ?? q.questionText;
        final distractors = (meta['distractors'] as List?)?.map((e) => e.toString()).toList() ?? [];
        _sentenceDistractorsCtrl.text = distractors.join(', ');
        _sentenceImageCtrl.text = meta['imageUrl']?.toString() ?? '';
      } else if (q.type == 'FROG_SEQUENCE') {
        _frogStartCtrl.text = (meta['startNumber'] ?? 2).toString();
        _frogStepCtrl.text = (meta['step'] ?? 2).toString();
        _frogJumpsCtrl.text = (meta['jumps'] ?? 3).toString();
        _frogPromptCtrl.text = q.questionText;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      Map<String, dynamic> payload = {
        'type': _selectedGameType,
        'lessonId': _selectedLessonId,
      };

      if (_selectedGameType == 'SYLLABLE_TRAIN') {
        final targetWord = _trainWordCtrl.text.trim();
        if (targetWord.isEmpty) {
          throw 'Ingresa la palabra a armar';
        }
        List<String> syllables = _trainSyllablesCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (syllables.isEmpty) {
          syllables = [targetWord];
        }
        List<String> distractors = _trainDistractorsCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        payload['questionText'] = _trainPromptCtrl.text.trim().isNotEmpty
            ? _trainPromptCtrl.text.trim()
            : '¡Arma la palabra observando la imagen!';
        payload['optionA'] = targetWord;
        payload['optionB'] = '-';
        payload['optionC'] = '-';
        payload['optionD'] = '-';
        payload['correctOption'] = 'A';
        payload['explanation'] = 'Las sílabas de $targetWord son: ${syllables.join(' - ')}.';
        payload['metadata'] = {
          'targetWord': targetWord,
          'syllables': syllables,
          'distractors': distractors,
          'imageUrl': _trainImageCtrl.text.trim().isNotEmpty ? _trainImageCtrl.text.trim() : null,
        };
      } else if (_selectedGameType == 'MISSING_SYLLABLE') {
        final targetWord = _missingWordCtrl.text.trim();
        if (targetWord.isEmpty) throw 'Ingresa la palabra completa';

        List<String> syllables = _missingSyllablesCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (syllables.isEmpty) throw 'Ingresa las sílabas separadas por coma';

        final missingSyllable = _missingSyllableTargetCtrl.text.trim();
        int missingIdx = syllables.indexWhere((s) => s.toLowerCase() == missingSyllable.toLowerCase());
        if (missingIdx == -1) missingIdx = 0;

        List<String> options = _missingOptionsCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (!options.contains(missingSyllable) && missingSyllable.isNotEmpty) {
          options.insert(0, missingSyllable);
        }
        while (options.length < 4) {
          options.add('sílaba');
        }

        payload['questionText'] = '¿Qué sílaba le falta a esta palabra?';
        payload['optionA'] = options[0];
        payload['optionB'] = options.length > 1 ? options[1] : '-';
        payload['optionC'] = options.length > 2 ? options[2] : '-';
        payload['optionD'] = options.length > 3 ? options[3] : '-';
        payload['correctOption'] = String.fromCharCode(65 + options.indexOf(missingSyllable).clamp(0, 3));
        payload['explanation'] = '$targetWord se forma con ${syllables.join(' - ')}.';
        payload['metadata'] = {
          'targetWord': targetWord,
          'syllables': syllables,
          'missingIndex': missingIdx,
          'options': options.take(4).toList(),
          'imageUrl': _missingImageCtrl.text.trim().isNotEmpty ? _missingImageCtrl.text.trim() : null,
        };
      } else if (_selectedGameType == 'MEMORY_MATCH') {
        final word = _memoryWordCtrl.text.trim();
        if (word.isEmpty) throw 'Ingresa la palabra para la carta de Memorama';

        final emojiOrImg = _memoryEmojiOrImageCtrl.text.trim();
        final isUrl = emojiOrImg.startsWith('http://') || emojiOrImg.startsWith('https://') || emojiOrImg.startsWith('/uploads/');

        payload['questionText'] = word;
        payload['optionA'] = word;
        payload['optionB'] = emojiOrImg;
        payload['optionC'] = '-';
        payload['optionD'] = '-';
        payload['correctOption'] = 'A';
        payload['explanation'] = _memoryHintCtrl.text.trim().isNotEmpty ? _memoryHintCtrl.text.trim() : 'Pareja de memorama: $word';
        payload['metadata'] = {
          'targetWord': word,
          'emoji': !isUrl && emojiOrImg.isNotEmpty ? emojiOrImg : null,
          'imageUrl': isUrl ? emojiOrImg : null,
        };
      } else if (_selectedGameType == 'SENTENCE_BUILDER') {
        final sentence = _sentenceTargetCtrl.text.trim();
        if (sentence.isEmpty) throw 'Ingresa la oración completa';

        final words = sentence.split(' ').where((w) => w.isNotEmpty).toList();
        List<String> distractors = _sentenceDistractorsCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        payload['questionText'] = '¡Ordena las palabras para formar la oración!';
        payload['optionA'] = sentence;
        payload['optionB'] = '-';
        payload['optionC'] = '-';
        payload['optionD'] = '-';
        payload['correctOption'] = 'A';
        payload['explanation'] = 'La oración correcta es: $sentence';
        payload['metadata'] = {
          'targetSentence': sentence,
          'words': words,
          'distractors': distractors,
          'imageUrl': _sentenceImageCtrl.text.trim().isNotEmpty ? _sentenceImageCtrl.text.trim() : null,
        };
      } else if (_selectedGameType == 'FROG_SEQUENCE') {
        final start = int.tryParse(_frogStartCtrl.text) ?? 2;
        final step = int.tryParse(_frogStepCtrl.text) ?? 2;
        final jumps = int.tryParse(_frogJumpsCtrl.text) ?? 3;
        final correctVal = start + (step * jumps);

        payload['questionText'] = _frogPromptCtrl.text.trim().isNotEmpty
            ? _frogPromptCtrl.text.trim()
            : '¿Qué número sigue en la serie de $step en $step?';
        payload['optionA'] = correctVal.toString();
        payload['optionB'] = (correctVal - step + 1).toString();
        payload['optionC'] = (correctVal + step).toString();
        payload['optionD'] = (correctVal - 1).toString();
        payload['correctOption'] = 'A';
        payload['explanation'] = 'Iniciando en $start y sumando $step cada salto: ¡El valor correcto es $correctVal!';
        payload['metadata'] = {
          'startNumber': start,
          'step': step,
          'jumps': jumps,
        };
      }

      if (_editingId == null) {
        await dio.post('/questions', data: payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Reto guardado con éxito para el juego!')),
          );
        }
      } else {
        await dio.patch('/questions/$_editingId', data: payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Reto actualizado con éxito!')),
          );
        }
      }

      _clearForm();
      ref.invalidate(questionsByTypeProvider(_selectedGameType));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteQuestion(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Reto del Juego'),
        content: const Text('¿Estás seguro de que deseas eliminar este reto? Los alumnos ya no lo verán.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(dioProvider).delete('/questions/$id');
        ref.invalidate(questionsByTypeProvider(_selectedGameType));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reto eliminado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildGameSelectorCard({
    required BuildContext context,
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedGameType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGameType = type;
          _clearForm();
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.12)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
              : [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hintText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = controller.text.trim();
    final hasImage = text.isNotEmpty && (text.startsWith('http://') || text.startsWith('https://') || text.startsWith('/uploads/'));
    final previewUrl = text.startsWith('/uploads/') ? baseUrl.replaceAll('/api', '') + text : text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hintText ?? 'Pega un enlace o sube un archivo desde tu PC',
                  prefixIcon: const Icon(Icons.image_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _pickAndUploadImage(controller),
                icon: const Icon(Icons.cloud_upload_rounded, size: 20),
                label: const Text('Subir Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        if (hasImage) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    previewUrl,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 54,
                      height: 54,
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ Imagen cargada correctamente',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF059669)),
                      ),
                      Text(
                        'Esta imagen se mostrará a los alumnos al jugar.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                  tooltip: 'Quitar imagen',
                  onPressed: () {
                    setState(() {
                      controller.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsByTypeProvider(_selectedGameType));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.sports_esports_rounded, color: Color(0xFF6366F1), size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestión de Juegos Educativos',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Agrega nuevas palabras, imágenes y retos para el salón recreativo "Aprende Jugando"',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Selector de Juego
                Text(
                  '1. Selecciona el juego que deseas enriquecer:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildGameSelectorCard(
                      context: context,
                      type: 'SYLLABLE_TRAIN',
                      title: 'El Tren de Sílabas',
                      subtitle: 'Armar palabras en vagones',
                      icon: Icons.train_rounded,
                      color: const Color(0xFF8B5CF6),
                    ),
                    _buildGameSelectorCard(
                      context: context,
                      type: 'MISSING_SYLLABLE',
                      title: 'La Sílaba Perdida',
                      subtitle: 'Completar la sílaba faltante',
                      icon: Icons.extension_rounded,
                      color: const Color(0xFFEC4899),
                    ),
                    _buildGameSelectorCard(
                      context: context,
                      type: 'MEMORY_MATCH',
                      title: 'Memorama de Palabras',
                      subtitle: 'Parejas de cartas y memoria',
                      icon: Icons.style_rounded,
                      color: const Color(0xFF10B981),
                    ),
                    _buildGameSelectorCard(
                      context: context,
                      type: 'SENTENCE_BUILDER',
                      title: 'Arma la Oración',
                      subtitle: 'Ordenar frases completas',
                      icon: Icons.edit_note_rounded,
                      color: const Color(0xFF0EA5E9),
                    ),
                    _buildGameSelectorCard(
                      context: context,
                      type: 'FROG_SEQUENCE',
                      title: 'La Rana Saltarina',
                      subtitle: 'Series numéricas y saltos',
                      icon: Icons.eco_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Formulario de Creación / Edición
                Card(
                  elevation: 2,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _editingId == null ? '✨ Crear Nuevo Reto para este Juego' : '✏️ Editando Reto Seleccionado',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                              ),
                            ),
                            if (_editingId != null)
                              TextButton.icon(
                                onPressed: _clearForm,
                                icon: const Icon(Icons.cancel, size: 18),
                                label: const Text('Cancelar Edición'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Formulario Específico según el tipo
                        if (_selectedGameType == 'SYLLABLE_TRAIN') ...[
                          TextField(
                            controller: _trainWordCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Palabra a armar (ej: Pelota, Gato, Manzana)',
                              prefixIcon: Icon(Icons.spellcheck),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _trainSyllablesCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Sílabas en orden separadas por coma (ej: Pe, lo, ta)',
                              prefixIcon: Icon(Icons.view_column_rounded),
                              helperText: 'El niño deberá ordenar estas sílabas en los vagones.',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _trainDistractorsCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Sílabas distractoras opcionales (ej: ma, so)',
                              prefixIcon: Icon(Icons.shuffle),
                              helperText: 'Sílabas adicionales para elevar la dificultad.',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildImageField(
                            context: context,
                            controller: _trainImageCtrl,
                            label: 'Imagen de apoyo para el tren (opcional)',
                          ),
                        ] else if (_selectedGameType == 'MISSING_SYLLABLE') ...[
                          TextField(
                            controller: _missingWordCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Palabra completa (ej: Tomate)',
                              prefixIcon: Icon(Icons.abc),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _missingSyllablesCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Todas las sílabas separadas por coma (ej: To, ma, te)',
                              prefixIcon: Icon(Icons.view_array_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: _missingSyllableTargetCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Sílaba que falta (ej: ma)',
                                    prefixIcon: Icon(Icons.help_outline),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _missingOptionsCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Opciones separadas por coma (ej: ba, ma, sa, la)',
                                    prefixIcon: Icon(Icons.list_alt),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildImageField(
                            context: context,
                            controller: _missingImageCtrl,
                            label: 'Imagen ilustrativa (opcional)',
                          ),
                        ] else if (_selectedGameType == 'MEMORY_MATCH') ...[
                          TextField(
                            controller: _memoryWordCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Palabra o Concepto de la tarjeta (ej: León, Manzana, Guitarra)',
                              prefixIcon: Icon(Icons.text_fields),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildImageField(
                            context: context,
                            controller: _memoryEmojiOrImageCtrl,
                            label: 'Emoji (ej: 🦁) o Imagen de la carta',
                            hintText: 'Escribe un emoji como 🍎 o sube una imagen con el botón',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _memoryHintCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Pista o frase pronunciada por voz (opcional)',
                              prefixIcon: Icon(Icons.record_voice_over_outlined),
                            ),
                          ),
                        ] else if (_selectedGameType == 'SENTENCE_BUILDER') ...[
                          TextField(
                            controller: _sentenceTargetCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Oración completa y correcta (ej: El sol brilla en la mañana)',
                              prefixIcon: Icon(Icons.short_text_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _sentenceDistractorsCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Palabras distractoras opcionales (ej: luna, noche, salta)',
                              prefixIcon: Icon(Icons.shuffle),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildImageField(
                            context: context,
                            controller: _sentenceImageCtrl,
                            label: 'Imagen contextual para la oración (opcional)',
                          ),
                        ] else if (_selectedGameType == 'FROG_SEQUENCE') ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _frogStartCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Número Inicial (ej: 2)',
                                    prefixIcon: Icon(Icons.looks_one_rounded),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _frogStepCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Salto / Paso (ej: 2)',
                                    prefixIcon: Icon(Icons.trending_up),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _frogJumpsCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Cantidad de Saltos (ej: 3)',
                                    prefixIcon: Icon(Icons.repeat),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _frogPromptCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Pregunta o Instrucción animada',
                              prefixIcon: Icon(Icons.help_outline),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _save,
                            icon: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Icon(_editingId == null ? Icons.add_circle_outline : Icons.check_circle_outline),
                            label: Text(
                              _editingId == null ? 'Guardar y Publicar en el Juego' : 'Actualizar Reto',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Lista de Retos Existentes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Retos Existentes en este Juego',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      ),
                    ),
                    questionsAsync.maybeWhen(
                      data: (list) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${list.length} retos creados',
                          style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                questionsAsync.when(
                  data: (questions) {
                    if (questions.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(40),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.sports_esports_outlined, size: 56, color: isDark ? const Color(0xFF475569) : Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Aún no has agregado retos personalizados a este juego.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '¡Usa el formulario de arriba para añadir tus propias palabras o imágenes!',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        final meta = q.metadata ?? {};
                        final imgUrl = meta['imageUrl']?.toString();

                        String mainTitle = q.questionText;
                        String subTitle = q.explanation ?? '';
                        if (q.type == 'SYLLABLE_TRAIN' && meta['targetWord'] != null) {
                          mainTitle = 'Palabra: ${meta['targetWord']}';
                          final syl = (meta['syllables'] as List?)?.join(' - ') ?? '';
                          subTitle = 'Sílabas: $syl';
                        } else if (q.type == 'MISSING_SYLLABLE' && meta['targetWord'] != null) {
                          mainTitle = 'Palabra: ${meta['targetWord']}';
                          final syl = (meta['syllables'] as List?)?.join(' - ') ?? '';
                          subTitle = 'Estructura: $syl';
                        } else if (q.type == 'MEMORY_MATCH') {
                          final emoji = meta['emoji']?.toString() ?? '🎴';
                          mainTitle = '$emoji  ${q.questionText}';
                        } else if (q.type == 'SENTENCE_BUILDER' && meta['targetSentence'] != null) {
                          mainTitle = meta['targetSentence'].toString();
                        } else if (q.type == 'FROG_SEQUENCE') {
                          mainTitle = 'Serie: inicia en ${meta['startNumber']}, paso +${meta['step']}';
                        }

                        return Card(
                          elevation: 1,
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: imgUrl != null && imgUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      imgUrl.startsWith('/uploads/')
                                          ? baseUrl.replaceAll('/api', '') + imgUrl
                                          : imgUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const CircleAvatar(child: Icon(Icons.image)),
                                    ),
                                  )
                                : CircleAvatar(
                                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                    child: const Icon(Icons.star, color: Color(0xFF6366F1)),
                                  ),
                            title: Text(
                              mainTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                              ),
                            ),
                            subtitle: Text(
                              subTitle,
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.indigo),
                                  tooltip: 'Editar',
                                  onPressed: () => _loadForEdit(q),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Eliminar',
                                  onPressed: () => _deleteQuestion(q.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                  error: (err, _) => Center(child: Text('Error al cargar retos: $err')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
