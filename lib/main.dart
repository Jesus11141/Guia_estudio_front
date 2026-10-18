import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'providers.dart';
import 'screens/login_screen.dart';
import 'screens/student_screens.dart';
import 'screens/admin_screens.dart';
import 'screens/settings_screen.dart';
import 'screens/books_screen.dart';
import 'screens/admin_books_view.dart';
import 'screens/games_hub_screen.dart';
import 'screens/rewards_store_screen.dart';
import 'screens/admin_rewards_screen.dart';
import 'screens/admin_games_view.dart';
import 'models/avatar_catalog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    
    return MaterialApp(
      title: 'Aprende Estudia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Modern Indigo
          background: const Color(0xFFF8FAFC), // Slate 50
        ),
        textTheme: GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shadowColor: const Color(0xFF94A3B8).withOpacity(0.15),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide.none,
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9), // Slate 100
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          floatingLabelStyle: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 24,
          backgroundColor: Colors.white,
        ),
      ),
      home: user == null ? const LoginScreen() : const MainNavigator(),
    );
  }
}

class MainNavigator extends ConsumerStatefulWidget {
  const MainNavigator({super.key});

  @override
  ConsumerState<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends ConsumerState<MainNavigator> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentRoute = 'STUDENT';
  bool _isSidebarCollapsed = false;

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  Widget _buildNavItem(IconData icon, String title, String routeId, {bool isDrawer = false}) {
    final isSelected = _currentRoute == routeId;
    final collapsed = !isDrawer && _isSidebarCollapsed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          if (isDrawer) {
            Navigator.of(context).pop(); // Close drawer on mobile
          }
          setState(() => _currentRoute = routeId);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: collapsed
              ? Tooltip(
                  message: title,
                  child: Center(
                    child: Icon(icon, color: isSelected ? Colors.white : Colors.indigo[200], size: 22),
                  ),
                )
              : Row(
                  children: [
                    Icon(icon, color: isSelected ? Colors.white : Colors.indigo[200], size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.indigo[100],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSidebarContent({
    required bool isDrawer,
    required dynamic user,
    required bool isAdmin,
    required bool isSuperAdmin,
  }) {
    final collapsed = !isDrawer && _isSidebarCollapsed;

    return Container(
      width: isDrawer ? 280 : (_isSidebarCollapsed ? 70 : 260),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        top: isDrawer,
        bottom: isDrawer,
        child: Column(
          children: [
            // ─── Header: Logo / Menu Toggle ──────────────────────────
            Container(
              height: 68,
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 16),
              alignment: Alignment.center,
              child: collapsed
                  ? IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: _toggleSidebar,
                      tooltip: 'Abrir menú',
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: user?.institution?.logoUrl != null
                              ? Image.network(
                                  user!.institution!.logoUrl!,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.school, color: Colors.white, size: 20),
                                )
                              : const Icon(Icons.school, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            user?.institution?.name ?? 'Guía de Estudio',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isDrawer ? Icons.close : Icons.chevron_left,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            if (isDrawer) {
                              Navigator.of(context).pop();
                            } else {
                              _toggleSidebar();
                            }
                          },
                          tooltip: isDrawer ? 'Cerrar menú' : 'Colapsar menú',
                        ),
                      ],
                    ),
            ),

            const Divider(height: 1, color: Colors.white12),
            const SizedBox(height: 12),

            // ─── Navigation Items ────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 16),
                children: [
                  if (!collapsed) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'APRENDIZAJE',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                    ),
                  ],
                  _buildNavItem(Icons.auto_awesome_mosaic_rounded, 'Mi Tablero', 'STUDENT', isDrawer: isDrawer),
                  _buildNavItem(Icons.local_library_outlined, 'Biblioteca Virtual', 'STUDENT_BOOKS', isDrawer: isDrawer),
                  if (isAdmin || (user?.hasGames ?? true))
                    _buildNavItem(Icons.sports_esports_rounded, 'Aprende Jugando', 'GAMES_HUB', isDrawer: isDrawer),
                  if (isAdmin || (user?.hasGames ?? true))
                    _buildNavItem(Icons.stars_rounded, 'Tienda de Premios', 'REWARDS_STORE', isDrawer: isDrawer),

                  if (isAdmin) ...[
                    const SizedBox(height: 24),
                    if (!collapsed)
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'ADMINISTRACIÓN',
                          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                      ),
                    _buildNavItem(Icons.school_outlined, 'Grados', 'ADMIN_GRADES', isDrawer: isDrawer),
                    _buildNavItem(Icons.book_outlined, 'Materias', 'ADMIN_SUBJECTS', isDrawer: isDrawer),
                    _buildNavItem(Icons.view_day_outlined, 'Bloques Curriculares', 'ADMIN_LESSONS', isDrawer: isDrawer),
                    _buildNavItem(Icons.quiz_outlined, 'Preguntas (Quiz)', 'ADMIN_QUESTIONS', isDrawer: isDrawer),
                    _buildNavItem(Icons.sports_esports_outlined, 'Juegos Educativos', 'ADMIN_GAMES', isDrawer: isDrawer),
                    _buildNavItem(Icons.library_books, 'Biblioteca', 'ADMIN_BOOKS', isDrawer: isDrawer),
                    _buildNavItem(Icons.card_giftcard_rounded, 'Premios y Tienda', 'ADMIN_REWARDS', isDrawer: isDrawer),
                    _buildNavItem(Icons.people_outline, 'Usuarios', 'ADMIN_USERS', isDrawer: isDrawer),
                    if (isSuperAdmin) _buildNavItem(Icons.business, 'Instituciones', 'ADMIN_INSTITUTIONS', isDrawer: isDrawer),
                  ],
                ],
              ),
            ),

            // ─── Footer: User Avatar & Session ───────────────────────
            Container(
              padding: EdgeInsets.all(collapsed ? 8 : 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: Builder(
                builder: (context) {
                  final equippedAvatar = AvatarCatalog.find(user?.avatar);
                  if (collapsed) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: '${user?.name ?? user?.email ?? 'Usuario'}\n${equippedAvatar.name} • ${user?.stars ?? 0} ⭐',
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: equippedAvatar.bgColor.withOpacity(0.35),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                            ),
                            child: Center(
                              child: Text(equippedAvatar.emoji, style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white54, size: 18),
                          onPressed: () => ref.read(authProvider.notifier).setUser(null),
                          tooltip: 'Cerrar sesión',
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: equippedAvatar.bgColor.withOpacity(0.35),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                        ),
                        child: Center(
                          child: Text(equippedAvatar.emoji, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user?.name ?? user?.email ?? 'Usuario',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (user?.role == 'STUDENT')
                              Text(
                                '${equippedAvatar.name} • ${user?.stars ?? 0} ⭐',
                                style: TextStyle(color: Colors.amber[200], fontSize: 11, fontWeight: FontWeight.w600),
                              )
                            else
                              Text(user?.role ?? '', style: TextStyle(color: Colors.indigo[200], fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white54, size: 18),
                        onPressed: () {
                          if (isDrawer) Navigator.of(context).pop();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        },
                        tooltip: 'Configuración',
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white54, size: 18),
                        onPressed: () => ref.read(authProvider.notifier).setUser(null),
                        tooltip: 'Cerrar sesión',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isSuperAdmin = user?.role == 'SUPER_ADMIN';
    final isAdmin = user?.role == 'ADMIN' || isSuperAdmin;
    final isMobile = MediaQuery.of(context).size.width < 900;

    Widget body;
    switch (_currentRoute) {
      case 'STUDENT': 
        body = const GradesScreen(); 
        break;
      case 'GAMES_HUB':
        body = const GamesHubScreen();
        break;
      case 'REWARDS_STORE':
        body = const RewardsStoreScreen();
        break;
      case 'ADMIN_REWARDS':
        body = isAdmin ? const AdminRewardsScreen() : const GradesScreen();
        break;
      case 'STUDENT_BOOKS':
        body = const BooksScreen();
        break;
      case 'ADMIN_GRADES': 
        body = Scaffold(appBar: AppBar(title: const Text('Gestionar Grados')), body: const AdminGradesView()); 
        break;
      case 'ADMIN_SUBJECTS': 
        body = Scaffold(appBar: AppBar(title: const Text('Gestionar Materias')), body: const AdminSubjectsView()); 
        break;
      case 'ADMIN_LESSONS': 
        body = Scaffold(appBar: AppBar(title: const Text('Bloques Curriculares')), body: const AdminLessonsView()); 
        break;
      case 'ADMIN_QUESTIONS': 
        body = Scaffold(appBar: AppBar(title: const Text('Preguntas y Ejercicios')), body: const AdminQuestionsView()); 
        break;
      case 'ADMIN_GAMES':
        body = isAdmin ? Scaffold(appBar: AppBar(title: const Text('Gestión de Juegos Educativos')), body: const AdminGamesView()) : const GradesScreen();
        break;
      case 'ADMIN_INSTITUTIONS': 
        body = isSuperAdmin ? Scaffold(appBar: AppBar(title: const Text('Instituciones Educativas')), body: AdminInstitutionsView()) : const AdminGradesView(); 
        break;
      case 'ADMIN_USERS': 
        body = isAdmin ? Scaffold(appBar: AppBar(title: const Text('Gestión de Usuarios')), body: AdminUsersView()) : const AdminGradesView(); 
        break;
      case 'ADMIN_BOOKS':
        body = isAdmin ? Scaffold(appBar: AppBar(title: const Text('Gestión de Biblioteca')), body: const AdminBooksView()) : const GradesScreen();
        break;
      default: 
        body = const GradesScreen();
    }

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          elevation: 16,
          child: _buildSidebarContent(
            isDrawer: true,
            user: user,
            isAdmin: isAdmin,
            isSuperAdmin: isSuperAdmin,
          ),
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1B4B),
          foregroundColor: Colors.white,
          elevation: 2,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'Abrir menú',
            ),
          ),
          title: Row(
            children: [
              if (user?.institution?.logoUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    user!.institution!.logoUrl!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.school, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  user?.institution?.name ?? 'Guía de Estudio',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            if (user?.role == 'STUDENT')
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${user?.stars ?? 0}',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ],
                ),
              ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 22),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              tooltip: 'Configuración',
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: body,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isSidebarCollapsed ? 70 : 260,
            child: _buildSidebarContent(
              isDrawer: false,
              user: user,
              isAdmin: isAdmin,
              isSuperAdmin: isSuperAdmin,
            ),
          ),
          // Main Content
          Expanded(
            child: ClipRRect(
              child: body,
            ),
          ),
        ],
      ),
    );
  }
  }
}
