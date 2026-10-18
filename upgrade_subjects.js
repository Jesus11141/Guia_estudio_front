const fs = require('fs');
const code = fs.readFileSync('lib/screens/student_screens.dart', 'utf-8');

const startStr = 'class SubjectsScreen extends ConsumerWidget {';
const endStr = 'class LessonsScreen extends ConsumerWidget {';

const startIdx = code.indexOf(startStr);
const endIdx = code.indexOf(endStr);

if (startIdx !== -1 && endIdx !== -1) {
  const replacement = `class SubjectsScreen extends ConsumerWidget {
  final Grade grade;
  const SubjectsScreen({super.key, required this.grade});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider(grade.id));
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Materias - \${grade.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)], // Blue gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grade.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 8),
                              Text('Selecciona la materia que deseas estudiar hoy.', style: TextStyle(fontSize: 18, color: Colors.blue[50])),
                            ],
                          ),
                        ),
                        if (MediaQuery.of(context).size.width > 600)
                          const Icon(Icons.category, size: 80, color: Colors.white24),
                      ],
                    ),
                  ),
                ),
              ),
              subjectsAsync.when(
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No hay materias disponibles para este grado.', style: TextStyle(fontSize: 16)),
                      )),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 450,
                        mainAxisExtent: 120,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final subject = subjects[index];
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
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => LessonsScreen(subject: subject)));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56, height: 56,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F9FF),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Center(child: Icon(Icons.auto_stories, color: Color(0xFF0EA5E9), size: 28)),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Text(subject.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      ),
                                      const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 32),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: subjects.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (e, st) => SliverToBoxAdapter(child: Center(child: Text('Error: \\$e'))),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ),
      ),
    );
  }
}

`;
  const result = code.substring(0, startIdx) + replacement + code.substring(endIdx);
  fs.writeFileSync('lib/screens/student_screens.dart', result);
  console.log("Successfully upgraded SubjectsScreen");
}
