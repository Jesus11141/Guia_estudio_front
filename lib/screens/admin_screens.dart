import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_rewards_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers.dart';
import '../models.dart';
import 'settings_screen.dart';
import 'admin_scores_view.dart';
import 'admin_ai_view.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isSuperAdmin = user?.role == 'SUPER_ADMIN';
    final orgName = isSuperAdmin ? 'Matriz Global' : (user?.institution?.name ?? 'Unidad Educativa');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
        title: Row(
          children: [
            if (user?.institution?.logoUrl != null && !isSuperAdmin) ...[
              Image.network(user!.institution!.logoUrl!, height: 32, errorBuilder: (_,__,___) => const Icon(Icons.business, color: Colors.blue)),
              const SizedBox(width: 12),
            ],
            Text('Panel de Administración - $orgName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ]
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber[300] : const Color(0xFF64748B),
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
            tooltip: isDark ? 'Modo Claro' : 'Modo Noche (Slate Dark)',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            tooltip: 'Configuración de Cuenta',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).setUser(null);
            },
            tooltip: 'Cerrar Sesión',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 280,
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildNavItem(Icons.school_outlined, 'Gestionar Grados', 0),
                _buildNavItem(Icons.book_outlined, 'Gestionar Materias', 1),
                _buildNavItem(Icons.view_day_outlined, 'Gestionar Bloques/Trimestres', 2),
                _buildNavItem(Icons.quiz_outlined, 'Gestionar Ejercicios', 3),
                _buildNavItem(Icons.grade_outlined, 'Calificaciones', 6),
                _buildNavItem(Icons.auto_awesome_rounded, '✨ Asistente IA', 7),
                if (isSuperAdmin) _buildNavItem(Icons.business, 'Instituciones', 4),
                if (isSuperAdmin) _buildNavItem(Icons.people_outline, 'Gestión de Usuarios', 5),
              ],
            ),
          ),
          VerticalDivider(thickness: 1, width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          Expanded(
            child: _getContentView(isSuperAdmin),
          )
        ],
      ),
    );
  }

  Widget _getContentView(bool isSuperAdmin) {
    switch (_tabIndex) {
      case 0: return const AdminGradesView();
      case 1: return const AdminSubjectsView();
      case 2: return const AdminLessonsView();
      case 3: return const AdminQuestionsView();
      case 4: return isSuperAdmin ? AdminInstitutionsView() : const AdminGradesView();
      case 5: return isSuperAdmin ? AdminUsersView() : const AdminGradesView();
      case 6: return const AdminScoresScreen();
      case 7: return const AdminAiView();
      default: return const AdminGradesView();
    }
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _tabIndex == index;
    final unselectedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        color: isSelected ? const Color(0xFF4F46E5).withOpacity(isDark ? 0.25 : 0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF818CF8) : unselectedColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(
                color: isSelected ? (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5)) : unselectedColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// --- VISTA DE USUARIOS ---
class AdminUsersView extends ConsumerStatefulWidget {
  const AdminUsersView({super.key});

  @override
  ConsumerState<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends ConsumerState<AdminUsersView> {
  void _openCreateUserDialog({User? user}) {
    showDialog(context: context, builder: (_) => CreateUserDialog(userToEdit: user));
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Usuarios del Sistema', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
              ElevatedButton.icon(
                onPressed: _openCreateUserDialog,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Usuario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final u = users[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey)),
                        title: Text(u.name != null ? '${u.name} (${u.email})' : u.email, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${u.role}${u.institution != null ? ' - ${u.institution!.name}' : ''}'),
                            if (u.role == 'STUDENT') ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(u.hasGames ? Icons.sports_esports : Icons.sports_esports_outlined, size: 15, color: u.hasGames ? const Color(0xFF16A34A) : Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    u.hasGames ? 'Juegos: HABILITADOS' : 'Juegos: DESACTIVADOS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: u.hasGames ? const Color(0xFF16A34A) : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _openCreateUserDialog(user: u)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Eliminar Usuario'),
                                    content: const Text('¿Estás seguro de eliminar este usuario?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await ref.read(dioProvider).delete('/users/${u.id}');
                                    ref.invalidate(usersProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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

class CreateUserDialog extends ConsumerStatefulWidget {
  final User? userToEdit;
  const CreateUserDialog({super.key, this.userToEdit});

  @override
  ConsumerState<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<CreateUserDialog> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _role = 'STUDENT';
  String? _institutionId;
  String? _gradeId;
  bool _hasGames = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.userToEdit != null) {
      _emailCtrl.text = widget.userToEdit!.email;
      _nameCtrl.text = widget.userToEdit!.name ?? '';
      _role = widget.userToEdit!.role;
      _institutionId = widget.userToEdit!.institution?.id;
      _gradeId = widget.userToEdit!.gradeId;
      _hasGames = widget.userToEdit!.hasGames;
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final user = ref.read(authProvider);
    try {
      if (widget.userToEdit == null) {
        await ref.read(dioProvider).post('/users', data: {
          'email': _emailCtrl.text.trim(),
          'pass': _passCtrl.text,
          'role': _role,
          'name': _nameCtrl.text.trim(),
          'institutionId': user?.role == 'SUPER_ADMIN' ? _institutionId : user?.institutionId,
          'gradeId': _role == 'STUDENT' ? _gradeId : null,
          'hasGames': _role == 'STUDENT' ? _hasGames : true,
        });
      } else {
        final updatePayload = <String, dynamic>{
          'name': _nameCtrl.text.trim(),
          if (_passCtrl.text.isNotEmpty) 'pass': _passCtrl.text,
          'gradeId': _role == 'STUDENT' ? _gradeId : null,
          if (_role == 'STUDENT') 'hasGames': _hasGames,
        };
        if (user?.role == 'SUPER_ADMIN') {
          updatePayload['role'] = _role;
          updatePayload['institutionId'] = _institutionId;
        }
        await ref.read(dioProvider).put('/users/${widget.userToEdit!.id}', data: updatePayload);
      }
      ref.invalidate(usersProvider);
      if(mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.userToEdit == null ? 'Usuario creado' : 'Usuario actualizado')));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final instAsync = ref.watch(institutionsProvider);
    final gradesAsync = ref.watch(gradesProvider);

    final bool isEditing = widget.userToEdit != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Usuario' : 'Crear Usuario'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo')),
              const SizedBox(height: 16),
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Correo'), enabled: !isEditing), // Cannot edit email
              const SizedBox(height: 16),
              TextField(controller: _passCtrl, decoration: InputDecoration(labelText: isEditing ? 'Nueva contraseña (opcional)' : 'Contraseña temporal')),
              const SizedBox(height: 16),
              if (user?.role == 'SUPER_ADMIN')
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'STUDENT', child: Text('Estudiante')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Administrador Institución')),
                    DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('Súper Administrador')),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                )
              else
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'STUDENT', child: Text('Estudiante')),
                  ],
                  onChanged: isEditing ? null : (v) => setState(() => _role = v!),
                ),
              const SizedBox(height: 16),
              if (user?.role == 'SUPER_ADMIN')
                instAsync.when(
                  data: (list) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Institución (Opcional)'),
                    value: _institutionId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Ninguna')),
                      ...list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
                    ],
                    onChanged: (v) => setState(() => _institutionId = v),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e,st) => const Text('Error instituciones'),
                ),
              if (_role == 'STUDENT') ...[
                const SizedBox(height: 16),
                gradesAsync.when(
                  data: (list) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Curso / Grado'),
                    value: _gradeId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Selecciona Curso')),
                      ...list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
                    ],
                    onChanged: (v) => setState(() => _gradeId = v),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e,st) => const Text('Error grados'),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: SwitchListTile(
                        title: const Text('¿Incluir Juegos Educativos?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          _hasGames ? 'Activado: el alumno verá "Aprende Jugando"' : 'Desactivado: el alumno solo verá Mi Tablero y Biblioteca',
                          style: TextStyle(fontSize: 12, color: _hasGames ? const Color(0xFF16A34A) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                        ),
                        value: _hasGames,
                        activeColor: const Color(0xFF4F46E5),
                        onChanged: (val) => setState(() => _hasGames = val),
                      ),
                    );
                  },
                ),
              ]
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
          child: _isLoading ? const CircularProgressIndicator() : Text(isEditing ? 'Guardar' : 'Crear'),
        )
      ],
    );
  }
}

// --- VISTA GRADOS ---
class AdminGradesView extends ConsumerStatefulWidget {
  const AdminGradesView({super.key});
  @override
  ConsumerState<AdminGradesView> createState() => _AdminGradesViewState();
}

class _AdminGradesViewState extends ConsumerState<AdminGradesView> {
  final _nameCtrl = TextEditingController();
  final _levelCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _levelCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(dioProvider).post('/grades', data: {'name': _nameCtrl.text, 'educationLevel': _levelCtrl.text});
      ref.invalidate(gradesProvider);
      _nameCtrl.clear(); _levelCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grado creado')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gestionar Grados', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crear Nuevo Grado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                const SizedBox(height: 16),
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del Grado')),
                const SizedBox(height: 16),
                TextField(controller: _levelCtrl, decoration: const InputDecoration(labelText: 'Nivel Educativo')),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Guardar Grado'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Grados Existentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final gradesAsync = ref.watch(gradesProvider);
                return gradesAsync.when(
                  data: (grades) => ListView.builder(
                    itemCount: grades.length,
                    itemBuilder: (context, index) {
                      final grade = grades[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(grade.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(grade.educationLevel),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Eliminar Grado'),
                                  content: Text('¿Seguro que deseas eliminar "${grade.name}"? Se borrarán todas sus materias y lecciones.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await ref.read(dioProvider).delete('/grades/${grade.id}');
                                  ref.invalidate(gradesProvider);
                                  if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grado eliminado')));
                                } catch (e) {
                                  if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error: $e'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- VISTA MATERIAS ---
class AdminSubjectsView extends ConsumerStatefulWidget {
  const AdminSubjectsView({super.key});
  @override
  ConsumerState<AdminSubjectsView> createState() => _AdminSubjectsViewState();
}

class _AdminSubjectsViewState extends ConsumerState<AdminSubjectsView> {
  final _nameCtrl = TextEditingController();
  String? _selectedGradeId;
  bool _isLoading = false;

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _selectedGradeId == null) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(dioProvider).post('/subjects', data: {'name': _nameCtrl.text, 'gradeId': _selectedGradeId});
      ref.invalidate(subjectsProvider);
      _nameCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Materia creada')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradesAsync = ref.watch(gradesProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gestionar Materias', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crear Nueva Materia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                const SizedBox(height: 16),
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre de la Materia')),
                const SizedBox(height: 16),
                gradesAsync.when(
                  data: (grades) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Selecciona el Grado'),
                    value: _selectedGradeId,
                    items: grades.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                    onChanged: (val) => setState(() => _selectedGradeId = val),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, st) => Text('Error al cargar grados: $e'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Guardar Materia'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Materias Existentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Expanded(
            child: gradesAsync.when(
              data: (grades) {
                if (_selectedGradeId == null) {
                  return const Text('Selecciona un grado arriba para ver sus materias.');
                }
                return Consumer(
                  builder: (context, ref, child) {
                    final subjectsAsync = ref.watch(subjectsProvider(_selectedGradeId!));
                    return subjectsAsync.when(
                      data: (subjects) => ListView.builder(
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Eliminar Materia'),
                                      content: Text('¿Seguro que deseas eliminar "${subject.name}"?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await ref.read(dioProvider).delete('/subjects/${subject.id}');
                                      ref.invalidate(subjectsProvider);
                                      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Materia eliminada')));
                                    } catch (e) {
                                      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Text('Error: $e'),
                    );
                  }
                );
              },
              loading: () => const SizedBox(),
              error: (e, st) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }
}

// --- VISTA LECCIONES ---
class AdminLessonsView extends ConsumerStatefulWidget {
  const AdminLessonsView({super.key});
  @override
  ConsumerState<AdminLessonsView> createState() => _AdminLessonsViewState();
}

class _AdminLessonsViewState extends ConsumerState<AdminLessonsView> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  
  String? _selectedGradeId;
  String? _selectedSubjectId;
  bool _isLoading = false;
  String? _editingId;

  Future<void> _save() async {
    if (_selectedSubjectId == null || _titleCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final data = {
        'title': _titleCtrl.text,
        'content': _contentCtrl.text,
        'subjectId': _selectedSubjectId,
      };

      if (_editingId == null) {
        await ref.read(dioProvider).post('/lessons', data: data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bloque/Trimestre creado')));
      } else {
        await ref.read(dioProvider).patch('/lessons/$_editingId', data: data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bloque/Trimestre actualizado')));
        _editingId = null;
      }

      ref.invalidate(lessonsProvider);
      _titleCtrl.clear();
      _contentCtrl.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _editLesson(dynamic lesson) {
    setState(() {
      _titleCtrl.text = lesson.title;
      _contentCtrl.text = lesson.content ?? '';
      _selectedSubjectId = lesson.subjectId;
      _editingId = lesson.id;
    });
  }

  void _cancelEdit() {
    setState(() {
      _titleCtrl.clear();
      _contentCtrl.clear();
      _editingId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradesAsync = ref.watch(gradesProvider);
    final subjectsAsync = _selectedGradeId != null ? ref.watch(subjectsProvider(_selectedGradeId!)) : const AsyncValue.data(<Subject>[]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gestionar Bloques/Trimestres', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_editingId == null ? 'Nuevo Bloque/Trimestre' : 'Editar Bloque/Trimestre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                    if (_editingId != null)
                      TextButton.icon(
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Cancelar Edición'),
                        onPressed: _cancelEdit,
                      )
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: gradesAsync.when(
                        data: (grades) => DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: '1. Selecciona el Grado (Opcional para edición)'),
                          value: _selectedGradeId,
                          items: grades.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedGradeId = val;
                              _selectedSubjectId = null;
                            });
                          },
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, st) => Text('Error al cargar grados: $e'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: subjectsAsync.when(
                        data: (subjects) {
                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: '2. Selecciona la Materia'),
                            value: _selectedSubjectId,
                            items: [
                              if (_selectedSubjectId != null && !subjects.any((s) => s.id == _selectedSubjectId))
                                DropdownMenuItem(value: _selectedSubjectId, child: const Text('Materia Actual (Mantener)')),
                              ...subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                            ],
                            onChanged: (val) => setState(() => _selectedSubjectId = val),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (e, st) => Text('Error al cargar materias: $e'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Título del Bloque (ej. Trimestre 1)')),
                const SizedBox(height: 16),
                TextField(controller: _contentCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Descripción / Contenido')),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: _editingId == null ? const Color(0xFF4F46E5) : Colors.orange, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                  child: Text(_editingId == null ? 'Guardar Bloque' : 'Actualizar Bloque'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Bloques Existentes (Por Materia)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          if (_selectedSubjectId == null)
            const Text('Selecciona un grado y una materia arriba para ver sus bloques.', style: TextStyle(color: Colors.grey))
          else
            ref.watch(lessonsProvider(_selectedSubjectId!)).when(
              data: (lessons) {
                if (lessons.isEmpty) return const Text('No hay bloques para esta materia.');
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(lesson.content ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _editLesson(lesson),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Eliminar Bloque'),
                                    content: Text('¿Seguro que deseas eliminar "${lesson.title}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await ref.read(dioProvider).delete('/lessons/${lesson.id}');
                                    ref.invalidate(lessonsProvider(_selectedSubjectId!));
                                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bloque eliminado')));
                                  } catch (e) {
                                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => Text('Error: $e'),
            ),
        ],
      ),
    );
  }
}


// --- VISTA GESTIÓN DE PREGUNTAS / EJERCICIOS ---
class AdminQuestionsView extends ConsumerStatefulWidget {
  const AdminQuestionsView({super.key});
  @override
  ConsumerState<AdminQuestionsView> createState() => _AdminQuestionsViewState();
}

class _AdminQuestionsViewState extends ConsumerState<AdminQuestionsView> {
  final _questionCtrl = TextEditingController();
  final _optACtrl = TextEditingController();
  final _optBCtrl = TextEditingController();
  final _optCCtrl = TextEditingController();
  final _optDCtrl = TextEditingController();
  final _explCtrl = TextEditingController();
  
  String _selectedType = 'MULTIPLE_CHOICE';
  final _frogStartCtrl = TextEditingController();
  final _frogStepCtrl = TextEditingController();
  final _frogJumpsCtrl = TextEditingController();

  final _trainTargetCtrl = TextEditingController();
  final _trainSyllablesCtrl = TextEditingController();
  final _trainDistractorsCtrl = TextEditingController();
  final _trainImageCtrl = TextEditingController();
  final _sentenceTargetCtrl = TextEditingController();
  final _sentenceDistractorsCtrl = TextEditingController();
  final _sentenceImageCtrl = TextEditingController();
  
  String? _selectedGradeId;
  String? _selectedSubjectId;
  String? _selectedLessonId;
  String _correctOption = 'A';
  bool _isLoading = false;
  String? _editingId;

  Future<void> _save() async {
    if (_selectedLessonId == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una lección primero')));
      return;
    }
    
    if (_selectedType == 'SENTENCE_BUILDER' && _questionCtrl.text.trim().isEmpty) {
      _questionCtrl.text = '¡Ordena las palabras para formar la oración!';
    }
    if (_selectedType == 'SENTENCE_BUILDER' && _sentenceTargetCtrl.text.trim().isEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe la oración completa')));
      return;
    }
    if (_selectedType == 'SYLLABLE_TRAIN' && _questionCtrl.text.trim().isEmpty) {
      _questionCtrl.text = '¡Arma la palabra!'; // Default instruction if empty
    }
    
    if (_questionCtrl.text.trim().isEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La pregunta o instrucción es obligatoria')));
      return;
    }
    
    if (_selectedType == 'MULTIPLE_CHOICE' && _optACtrl.text.trim().isEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La Opción A es obligatoria')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic>? metadata;
      if (_selectedType == 'FROG_SEQUENCE') {
        metadata = {
          'startNumber': int.tryParse(_frogStartCtrl.text) ?? 0,
          'step': int.tryParse(_frogStepCtrl.text) ?? 1,
          'jumps': int.tryParse(_frogJumpsCtrl.text) ?? 3,
        };
      } else if (_selectedType == 'SYLLABLE_TRAIN') {
        metadata = {
          'targetWord': _trainTargetCtrl.text.trim(),
          'syllables': _trainSyllablesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          'distractors': _trainDistractorsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          'imageUrl': _trainImageCtrl.text.trim().isEmpty ? null : _trainImageCtrl.text.trim(),
        };
      } else if (_selectedType == 'SENTENCE_BUILDER') {
        final words = _sentenceTargetCtrl.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        metadata = {
          'targetSentence': _sentenceTargetCtrl.text.trim(),
          'words': words,
          'distractors': _sentenceDistractorsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          'imageUrl': _sentenceImageCtrl.text.trim().isEmpty ? null : _sentenceImageCtrl.text.trim(),
        };
      }
      
      final data = {
        'lessonId': _selectedLessonId,
        'type': _selectedType,
        'metadata': metadata,
        'questionText': _questionCtrl.text,
        'optionA': (_selectedType == 'SYLLABLE_TRAIN' || _selectedType == 'SENTENCE_BUILDER') ? '-' : _optACtrl.text,
        'optionB': (_selectedType == 'SYLLABLE_TRAIN' || _selectedType == 'SENTENCE_BUILDER') ? '-' : _optBCtrl.text,
        'optionC': (_selectedType == 'SYLLABLE_TRAIN' || _selectedType == 'SENTENCE_BUILDER') ? '-' : _optCCtrl.text,
        'optionD': (_selectedType == 'SYLLABLE_TRAIN' || _selectedType == 'SENTENCE_BUILDER') ? '-' : _optDCtrl.text,
        'correctOption': _correctOption,
        'explanation': _explCtrl.text,
      };
      
      if (_editingId == null) {
        await ref.read(dioProvider).post('/questions', data: data);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ejercicio creado')));
      } else {
        await ref.read(dioProvider).patch('/questions/$_editingId', data: data);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ejercicio actualizado')));
        _editingId = null;
      }
      
      _questionCtrl.clear();
      _optACtrl.clear();
      _optBCtrl.clear();
      _optCCtrl.clear();
      _optDCtrl.clear();
      _explCtrl.clear();
      _frogStartCtrl.clear();
      _frogStepCtrl.clear();
      _frogJumpsCtrl.clear();
      _trainTargetCtrl.clear();
      _trainSyllablesCtrl.clear();
      _trainDistractorsCtrl.clear();
      _trainImageCtrl.clear();
      _sentenceTargetCtrl.clear();
      _sentenceDistractorsCtrl.clear();
      _sentenceImageCtrl.clear();
      _selectedType = 'MULTIPLE_CHOICE';
      ref.invalidate(questionsProvider);
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

    Future<void> _uploadImage() async {
    final baseUrl = 'https://aprendeestudia.djhcode.com/api';
    final token = ref.read(sharedPrefsProvider).getString('token');
    
    var result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.isNotEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subiendo imagen...')));
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/image'));
      request.headers['Authorization'] = 'Bearer $token';
      
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        await result.first.readAsBytes(),
        filename: result.first.name,
      ));
      
      try {
        var response = await request.send();
        if (response.statusCode == 201 || response.statusCode == 200) {
          final respStr = await response.stream.bytesToString();
          final data = jsonDecode(respStr);
          setState(() {
            _trainImageCtrl.text = baseUrl.replaceAll('/api', '') + data['url'];
          });
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imagen subida con éxito')));
        } else {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir imagen')));
        }
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _uploadImageForSentence() async {
    final baseUrl = 'https://aprendeestudia.djhcode.com/api';
    final token = ref.read(sharedPrefsProvider).getString('token');
    
    var result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.isNotEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subiendo imagen...')));
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/image'));
      request.headers['Authorization'] = 'Bearer $token';
      
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        await result.first.readAsBytes(),
        filename: result.first.name,
      ));
      
      try {
        var response = await request.send();
        if (response.statusCode == 201 || response.statusCode == 200) {
          final respStr = await response.stream.bytesToString();
          final data = jsonDecode(respStr);
          setState(() {
            _sentenceImageCtrl.text = baseUrl.replaceAll('/api', '') + data['url'];
          });
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imagen subida con éxito')));
        } else {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir imagen')));
        }
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

void _editQuestion(dynamic q) {
    setState(() {
      _selectedType = q.type ?? 'MULTIPLE_CHOICE';
      if (_selectedType == 'FROG_SEQUENCE' && q.metadata != null) {
        _frogStartCtrl.text = q.metadata['startNumber']?.toString() ?? '';
        _frogStepCtrl.text = q.metadata['step']?.toString() ?? '';
        _frogJumpsCtrl.text = q.metadata['jumps']?.toString() ?? '';
      } else if (_selectedType == 'SYLLABLE_TRAIN' && q.metadata != null) {
        _trainTargetCtrl.text = q.metadata['targetWord']?.toString() ?? '';
        _trainSyllablesCtrl.text = (q.metadata['syllables'] as List?)?.join(', ') ?? '';
        _trainDistractorsCtrl.text = (q.metadata['distractors'] as List?)?.join(', ') ?? '';
        _trainImageCtrl.text = q.metadata['imageUrl']?.toString() ?? '';
      }
      _questionCtrl.text = q.questionText;
      _optACtrl.text = q.optionA;
      _optBCtrl.text = q.optionB;
      _optCCtrl.text = q.optionC;
      _optDCtrl.text = q.optionD;
      _explCtrl.text = q.explanation ?? '';
      _correctOption = q.correctOption;
      _selectedLessonId = q.lessonId;
      _editingId = q.id;
    });
  }

  void _cancelEdit() {
    setState(() {
      _questionCtrl.clear();
      _optACtrl.clear();
      _optBCtrl.clear();
      _optCCtrl.clear();
      _optDCtrl.clear();
      _explCtrl.clear();
      _frogStartCtrl.clear();
      _frogStepCtrl.clear();
      _frogJumpsCtrl.clear();
      _trainTargetCtrl.clear();
      _trainSyllablesCtrl.clear();
      _trainDistractorsCtrl.clear();
      _trainImageCtrl.clear();
      _editingId = null;
      _selectedType = 'MULTIPLE_CHOICE';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradesAsync = ref.watch(gradesProvider);
    
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_editingId == null ? 'Crear Nuevo Ejercicio' : 'Editar Ejercicio', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
              if (_editingId != null)
                TextButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar Edición'),
                  onPressed: _cancelEdit,
                )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                gradesAsync.when(
                  data: (grades) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: '1. Selecciona Grado (Opcional en Edición)'),
                    value: _selectedGradeId,
                    items: grades.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedGradeId = val;
                        _selectedSubjectId = null;
                        _selectedLessonId = null;
                      });
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, st) => Text('Error: $e'),
                ),
                const SizedBox(height: 16),
                
                if (_selectedGradeId != null || _editingId != null)
                  Consumer(builder: (context, ref, child) {
                    final subjectsAsync = ref.watch(subjectsProvider(_selectedGradeId ?? ''));
                    return subjectsAsync.when(
                      data: (subs) => DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: '2. Selecciona Materia (Opcional en Edición)'),
                        value: _selectedSubjectId,
                        items: subs.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSubjectId = val;
                            _selectedLessonId = null;
                          });
                        },
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e,st) => const Text('Error'),
                    );
                  }),
                const SizedBox(height: 16),
                
                if (_selectedSubjectId != null || _editingId != null)
                  Consumer(builder: (context, ref, child) {
                    final lessonsAsync = ref.watch(lessonsProvider(_selectedSubjectId ?? ''));
                    return lessonsAsync.when(
                      data: (less) => DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: '3. Selecciona Lección (Trimestre)'),
                        value: _selectedLessonId,
                        items: [
                          if (_selectedLessonId != null && !less.any((l) => l.id == _selectedLessonId))
                            DropdownMenuItem(value: _selectedLessonId, child: const Text('Lección Actual (Mantener)')),
                          ...less.map((l) => DropdownMenuItem(value: l.id, child: Text(l.title)))
                        ],
                        onChanged: (val) => setState(() => _selectedLessonId = val),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e,st) => const Text('Error'),
                    );
                  }),
                const SizedBox(height: 32),
                
                if (_selectedLessonId != null) ...[
                  Text('¿Qué tipo de ejercicio deseas agregar a esta lección?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 210,
                        child: InkWell(
                          onTap: () {
                            _editingId = null;
                            _showQuestionDialog('MULTIPLE_CHOICE');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? const Color(0xFF4338CA) : Colors.indigo.shade100, width: 2),
                              boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10)],
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.text_fields, size: 40, color: Colors.indigo),
                                const SizedBox(height: 10),
                                Text('Pregunta Clásica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                                const SizedBox(height: 4),
                                Text('Opción múltiple (A, B, C, D)', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontSize: 11), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 210,
                        child: InkWell(
                          onTap: () {
                            _editingId = null;
                            _showQuestionDialog('FROG_SEQUENCE');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? const Color(0xFF15803D) : Colors.green.shade100, width: 2),
                              boxShadow: [BoxShadow(color: Colors.green.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10)],
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.videogame_asset, size: 40, color: Colors.green),
                                const SizedBox(height: 10),
                                Text('Rana Saltarina', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                                const SizedBox(height: 4),
                                Text('Series y conteo animado', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontSize: 11), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 210,
                        child: InkWell(
                          onTap: () {
                            _editingId = null;
                            _showQuestionDialog('SYLLABLE_TRAIN');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? const Color(0xFF7E22CE) : Colors.purple.shade100, width: 2),
                              boxShadow: [BoxShadow(color: Colors.purple.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10)],
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.train, size: 40, color: Colors.purple),
                                const SizedBox(height: 10),
                                Text('Tren de Sílabas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                                const SizedBox(height: 4),
                                Text('Armar palabras por sílabas', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontSize: 11), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 210,
                        child: InkWell(
                          onTap: () {
                            _editingId = null;
                            _showQuestionDialog('SENTENCE_BUILDER');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? const Color(0xFF0F766E) : Colors.teal.shade100, width: 2),
                              boxShadow: [BoxShadow(color: Colors.teal.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10)],
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.draw, size: 40, color: Colors.teal),
                                const SizedBox(height: 10),
                                Text('Arma la Oración', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                                const SizedBox(height: 4),
                                Text('Ordenar frases en orden', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontSize: 11), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 48),
                Text('Ejercicios Existentes (de la lección seleccionada)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                const SizedBox(height: 16),
                if (_selectedLessonId != null)
                  Consumer(
                    builder: (context, ref, child) {
                      final questionsAsync = ref.watch(questionsProvider(_selectedLessonId!));
                      return questionsAsync.when(
                        data: (questions) {
                          if (questions.isEmpty) return const Text('No hay ejercicios creados.');
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: questions.length,
                            itemBuilder: (context, index) {
                              final q = questions[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: q.type == 'FROG_SEQUENCE' ? Colors.green.shade100 : (q.type == 'SYLLABLE_TRAIN' ? Colors.purple.shade100 : (q.type == 'SENTENCE_BUILDER' ? Colors.teal.shade100 : Colors.indigo.shade100)),
                                    child: Icon(q.type == 'FROG_SEQUENCE' ? Icons.videogame_asset : (q.type == 'SYLLABLE_TRAIN' ? Icons.train : (q.type == 'SENTENCE_BUILDER' ? Icons.auto_stories : Icons.text_fields)), color: q.type == 'FROG_SEQUENCE' ? Colors.green : (q.type == 'SYLLABLE_TRAIN' ? Colors.purple : (q.type == 'SENTENCE_BUILDER' ? Colors.teal : Colors.indigo))),
                                  ),
                                  title: Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Respuesta: ${q.correctOption}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.orange),
                                        onPressed: () {
                                          _editQuestion(q);
                                          _showQuestionDialog(q.type);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Eliminar Ejercicio'),
                                              content: const Text('¿Seguro que deseas eliminar este ejercicio?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            try {
                                              await ref.read(dioProvider).delete('/questions/${q.id}');
                                              ref.invalidate(questionsProvider(_selectedLessonId!));
                                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eliminado')));
                                            } catch (e) {
                                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (e, st) => Text('Error: $e'),
                      );
                    },
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuestionDialog(String type) {
    _selectedType = type;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(_editingId == null 
              ? (_selectedType == 'FROG_SEQUENCE' ? 'Nuevo Juego de Rana' 
                : (_selectedType == 'SYLLABLE_TRAIN' ? 'Nuevo Tren de Sílabas' : (_selectedType == 'SENTENCE_BUILDER' ? 'Nueva Oración para Armar' : 'Nueva Pregunta Clásica'))) 
              : 'Editar Ejercicio'),
            content: SizedBox(
              width: 800,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedType == 'FROG_SEQUENCE') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Configuración de la Rana', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: TextField(controller: _frogStartCtrl, decoration: const InputDecoration(labelText: 'Número Inicial (ej. 2)'))),
                                const SizedBox(width: 16),
                                Expanded(child: TextField(controller: _frogStepCtrl, decoration: const InputDecoration(labelText: 'Salto/Patrón (ej. 3)'))),
                                const SizedBox(width: 16),
                                Expanded(child: TextField(controller: _frogJumpsCtrl, decoration: const InputDecoration(labelText: 'Cant. de Saltos (ej. 4)'))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else if (_selectedType == 'SYLLABLE_TRAIN') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.shade200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Configuración del Tren de Sílabas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                            const SizedBox(height: 12),
                            TextField(controller: _trainTargetCtrl, decoration: const InputDecoration(labelText: 'Palabra Completa (ej. Dragón)')),
                            const SizedBox(height: 12),
                            TextField(controller: _trainSyllablesCtrl, decoration: const InputDecoration(labelText: 'Sílabas Correctas (separadas por coma, ej. Dra, gón)')),
                            const SizedBox(height: 12),
                            TextField(controller: _trainDistractorsCtrl, decoration: const InputDecoration(labelText: 'Sílabas Distractoras (opcional, separadas por coma)')),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: TextField(controller: _trainImageCtrl, decoration: const InputDecoration(labelText: 'URL de Imagen (opcional)'))),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _uploadImage,
                                  icon: const Icon(Icons.upload),
                                  label: const Text('Subir'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else if (_selectedType == 'SENTENCE_BUILDER') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.teal.shade200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Configuración de "Arma la Oración"', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                            const SizedBox(height: 12),
                            TextField(controller: _sentenceTargetCtrl, decoration: const InputDecoration(labelText: 'Oración Completa (ej. El perro come croquetas)')),
                            const SizedBox(height: 12),
                            TextField(controller: _sentenceDistractorsCtrl, decoration: const InputDecoration(labelText: 'Palabras Distractoras (opcional, separadas por coma, ej. gato, salta)')),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: TextField(controller: _sentenceImageCtrl, decoration: const InputDecoration(labelText: 'URL de Imagen ilustrativa (opcional)'))),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _uploadImageForSentence,
                                  icon: const Icon(Icons.upload),
                                  label: const Text('Subir'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    TextField(controller: _questionCtrl, decoration: InputDecoration(labelText: _selectedType == 'SYLLABLE_TRAIN' ? 'Instrucción (ej. ¡Arma la palabra!)' : (_selectedType == 'SENTENCE_BUILDER' ? 'Instrucción (ej. ¡Ordena las palabras!)' : 'Pregunta / Instrucción')), maxLines: 2),
                    const SizedBox(height: 16),
                    
                    if (_selectedType != 'SYLLABLE_TRAIN' && _selectedType != 'SENTENCE_BUILDER') ...[
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _optACtrl, decoration: const InputDecoration(labelText: 'Opción A'))),
                          const SizedBox(width: 16),
                          Expanded(child: TextField(controller: _optBCtrl, decoration: const InputDecoration(labelText: 'Opción B'))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _optCCtrl, decoration: const InputDecoration(labelText: 'Opción C'))),
                          const SizedBox(width: 16),
                          Expanded(child: TextField(controller: _optDCtrl, decoration: const InputDecoration(labelText: 'Opción D'))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Respuesta Correcta'),
                        value: _correctOption,
                        items: ['A', 'B', 'C', 'D'].map((o) => DropdownMenuItem(value: o, child: Text('Opción $o'))).toList(),
                        onChanged: (v) => setModalState(() => _correctOption = v!),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(controller: _explCtrl, decoration: const InputDecoration(labelText: 'Explicación / Guía de Estudio (Opcional)'), maxLines: 2),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _cancelEdit();
                  Navigator.pop(ctx);
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                onPressed: _isLoading ? null : () async {
                  setModalState(() => _isLoading = true);
                  await _save();
                  setModalState(() => _isLoading = false);
                  if (mounted) Navigator.pop(ctx);
                },
                child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Guardar'),
              ),
            ],
          );
        });
      },
    );
  }
}


// --- VISTA GESTIÓN DE INSTITUCIONES (SÓLO SUPER ADMIN) ---

class AdminInstitutionsView extends ConsumerStatefulWidget {
  const AdminInstitutionsView({super.key});
  @override
  ConsumerState<AdminInstitutionsView> createState() => _AdminInstitutionsViewState();
}

class _AdminInstitutionsViewState extends ConsumerState<AdminInstitutionsView> {
  final _nameCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(dioProvider).post('/institutions', data: {
        'name': _nameCtrl.text,
        'logoUrl': _logoCtrl.text.isNotEmpty ? _logoCtrl.text : null,
      });
      ref.invalidate(institutionsProvider);
      _nameCtrl.clear();
      _logoCtrl.clear();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Institución creada')));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final instAsync = ref.watch(institutionsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gestionar Instituciones', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nueva Institución Educativa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                const SizedBox(height: 16),
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre de la Institución')),
                const SizedBox(height: 16),
                TextField(controller: _logoCtrl, decoration: const InputDecoration(labelText: 'URL del Logo (Opcional)')),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Crear Institución'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Instituciones Existentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          instAsync.when(
            data: (institutions) => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: institutions.length,
              itemBuilder: (context, index) {
                final inst = institutions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: inst.logoUrl != null 
                        ? Image.network(inst.logoUrl!, width: 40, height: 40, errorBuilder: (_,__,___) => const Icon(Icons.school))
                        : const Icon(Icons.business),
                    title: Text(inst.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('ID: ${inst.id}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar Institución'),
                            content: Text('¿Seguro que deseas eliminar "${inst.name}"? Se borrarán sus usuarios y datos asociados.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await ref.read(dioProvider).delete('/institutions/${inst.id}');
                            ref.invalidate(institutionsProvider);
                            if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Institución eliminada')));
                          } catch (e) {
                            if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar')));
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, st) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}