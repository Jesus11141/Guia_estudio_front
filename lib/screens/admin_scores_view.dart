import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models.dart';
import 'package:intl/intl.dart';

class AdminScoresScreen extends ConsumerStatefulWidget {
  const AdminScoresScreen({super.key});

  @override
  ConsumerState<AdminScoresScreen> createState() => _AdminScoresScreenState();
}

class _AdminScoresScreenState extends ConsumerState<AdminScoresScreen> {
  String? _selectedGradeId;

  @override
  Widget build(BuildContext context) {
    final gradesAsync = ref.watch(gradesProvider);
    final scoresAsync = ref.watch(scoresProvider(_selectedGradeId));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calificaciones de los Estudiantes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: gradesAsync.when(
              data: (grades) => DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Filtrar por Grado (Opcional)',
                  prefixIcon: Icon(Icons.filter_list),
                ),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                value: _selectedGradeId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos los grados')),
                  ...grades.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                ],
                onChanged: (val) => setState(() => _selectedGradeId = val),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => Text('Error al cargar grados: $e'),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: scoresAsync.when(
              data: (scores) {
                if (scores.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay calificaciones registradas aún.',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: scores.length,
                  itemBuilder: (context, index) {
                    final score = scores[index];
                    final percentage = (score.score / score.totalQuestions) * 100;
                    
                    Color scoreColor = const Color(0xFF10B981); // Green
                    if (percentage < 50) scoreColor = const Color(0xFFEF4444); // Red
                    else if (percentage < 75) scoreColor = const Color(0xFFF59E0B); // Orange

                    DateTime parsedDate;
                    try {
                      parsedDate = DateTime.parse(score.createdAt).toLocal();
                    } catch (e) {
                      parsedDate = DateTime.now();
                    }
                    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(parsedDate);

                    return Card(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(
                                color: scoreColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text('${score.score}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: scoreColor)),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    score.userName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${score.userGrade} • ${score.subjectName}',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(score.lessonTitle, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
                                  ),
                                  child: Text(
                                    '$percentage%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(dateStr, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          )
        ],
      ),
    );
  }
}
