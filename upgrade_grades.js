const fs = require('fs');

const code = fs.readFileSync('lib/screens/student_screens.dart', 'utf-8');

const startStr = 'class GradesScreen extends ConsumerWidget {';
const endStr = '  void _showProfileDialog(BuildContext context, WidgetRef ref, User? user) {';

const startIdx = code.indexOf(startStr);
const endIdx = code.indexOf(endStr);

if (startIdx !== -1 && endIdx !== -1) {
  const replacement = `class GradesScreen extends ConsumerWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(gradesProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Lighter slate background for more contrast
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200), // Max width for large screens
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('¡Hola, \${user?.name ?? user?.email ?? 'Estudiante'}!', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 8),
                              Text('Bienvenido a tu plataforma de aprendizaje. ¿Qué quieres estudiar hoy?', style: TextStyle(fontSize: 18, color: Colors.indigo[50])),
                            ],
                          ),
                        ),
                        if (MediaQuery.of(context).size.width > 600)
                          const Icon(Icons.menu_book, size: 80, color: Colors.white24),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tus Grados / Cursos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              gradesAsync.when(
                data: (grades) {
                  if (grades.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No estás inscrito en ningún grado aún.', style: TextStyle(fontSize: 16)),
                      )),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 450,
                        mainAxisExtent: 140,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final grade = grades[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                hoverColor: const Color(0xFFF8FAFC),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectsScreen(grade: grade)));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 64, height: 64,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                                          ]
                                        ),
                                        child: const Center(child: Icon(Icons.school, color: Colors.white, size: 32)),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(grade.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                                              child: Text(grade.educationLevel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 32),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: grades.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (e, st) => SliverToBoxAdapter(child: Center(child: Text('Error: \\$e'))),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 60)), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

`;
  
  // Notice we also remove `_showProfileDialog` since it goes from startStr to endStr but wait, we need to cut `_showProfileDialog` out entirely.
  // We can just find the end of the class. 
  
  // Find the end of `_showProfileDialog`
  const endDialogStr = '  }'; // This is fragile. Let's just find `class SubjectsScreen` and stop before it.
  const endClassIdx = code.indexOf('class SubjectsScreen');
  
  const result = code.substring(0, startIdx) + replacement + '\n' + code.substring(endClassIdx);
  fs.writeFileSync('lib/screens/student_screens.dart', result);
  console.log("Successfully upgraded GradesScreen and removed _showProfileDialog and removed appbar");
} else {
  console.log("Could not find boundaries.");
}
