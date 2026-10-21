import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../providers.dart';

class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> {
  String _selectedCategory = 'Todas';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: booksAsync.when(
            data: (books) {
              // Extract unique categories
              final categories = [
                'Todas',
                ...books
                    .map((b) => b.category.trim())
                    .where((c) => c.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort()
              ];

              // Filter books based on category and search query
              final filteredBooks = books.where((book) {
                final matchesCategory = _selectedCategory == 'Todas' ||
                    book.category.trim().toLowerCase() == _selectedCategory.toLowerCase();
                final matchesSearch = _searchQuery.isEmpty ||
                    book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    book.author.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (book.description != null &&
                        book.description!.toLowerCase().contains(_searchQuery.toLowerCase()));
                return matchesCategory && matchesSearch;
              }).toList();

              final isMobile = MediaQuery.of(context).size.width < 600;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 12 : 24,
                        isMobile ? 14 : 32,
                        isMobile ? 12 : 24,
                        isMobile ? 14 : 20,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 18 : 32),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.3),
                              blurRadius: 20,
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
                                  Text(
                                    'Biblioteca Virtual',
                                    style: TextStyle(
                                      fontSize: isMobile ? 22 : 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Explora libros y material de lectura por categorías para ampliar tus conocimientos.',
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 16,
                                      color: Colors.indigo[50],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isMobile)
                              const Icon(Icons.local_library, size: 76, color: Colors.white24),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Search and Category Filters
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Box
                          TextField(
                            controller: _searchController,
                            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              hintText: 'Buscar libro por título, autor o tema...',
                              hintStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              prefixIcon: Icon(Icons.search, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                              ),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          ),
                          const SizedBox(height: 16),

                          // Category Chips Bar
                          if (categories.length > 1)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: categories.map((cat) {
                                  final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();
                                  final count = cat == 'Todas'
                                      ? books.length
                                      : books.where((b) => b.category.trim().toLowerCase() == cat.toLowerCase()).length;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                                    child: ChoiceChip(
                                      label: Text('$cat ($count)'),
                                      selected: isSelected,
                                      selectedColor: const Color(0xFF4F46E5),
                                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected
                                              ? const Color(0xFF4F46E5)
                                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        ),
                                      ),
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _selectedCategory = cat);
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Books Grid or Empty State
                  if (filteredBooks.isEmpty)
                    SliverToBoxAdapter(
                       child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Column(
                            children: [
                              Icon(Icons.menu_book, size: 64, color: isDark ? const Color(0xFF475569) : Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                books.isEmpty
                                    ? 'Aún no hay libros en la biblioteca.'
                                    : 'No se encontraron libros en "$_selectedCategory"${_searchQuery.isNotEmpty ? " con la búsqueda actual" : ""}.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
                      sliver: SliverGrid(
                        gridDelegate: isMobile
                            ? const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 315,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 12,
                              )
                            : const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 310,
                                mainAxisExtent: 490,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                              ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final book = filteredBooks[index];
                            return BookCard3D(
                              book: book,
                              index: index,
                              onRead: () async {
                                final prefs = ref.read(sharedPrefsProvider);
                                final key = 'book_progress_${book.id}';
                                final current = prefs.getInt(key) ?? 0;
                                final next = current == 0 ? 35 : (current < 75 ? 75 : 100);
                                await prefs.setInt(key, next);
                                setState(() {});

                                final rootUrl = baseUrl.replaceAll('/api', '');
                                final pdfUrl = '$rootUrl${book.fileUrl}';
                                final readerUrl = '$rootUrl/uploads/reader.html?file=$pdfUrl';
                                launchUrl(Uri.parse(readerUrl));
                              },
                            );
                          },
                          childCount: filteredBooks.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }
}

// ─── 3D BOOK PALETTE & THEMES ───────────────────────────────────────────────
class BookPalette {
  final List<Color> gradient;
  final Color accentColor;
  final IconData icon;

  const BookPalette({
    required this.gradient,
    required this.accentColor,
    required this.icon,
  });

  static BookPalette getForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('mate') || cat.contains('álgebra') || cat.contains('cálculo') || cat.contains('física')) {
      return const BookPalette(
        gradient: [Color(0xFF0F766E), Color(0xFF064E3B)],
        accentColor: Color(0xFF2DD4BF),
        icon: Icons.calculate_rounded,
      );
    } else if (cat.contains('lengua') || cat.contains('literatura') || cat.contains('lectura') || cat.contains('cuento') || cat.contains('novela')) {
      return const BookPalette(
        gradient: [Color(0xFF4338CA), Color(0xFF6B21A8)],
        accentColor: Color(0xFFA78BFA),
        icon: Icons.auto_stories_rounded,
      );
    } else if (cat.contains('cien') || cat.contains('bio') || cat.contains('quím') || cat.contains('natura')) {
      return const BookPalette(
        gradient: [Color(0xFF047857), Color(0xFF14532D)],
        accentColor: Color(0xFF4ADE80),
        icon: Icons.science_rounded,
      );
    } else if (cat.contains('hist') || cat.contains('socia') || cat.contains('cívica') || cat.contains('geograf')) {
      return const BookPalette(
        gradient: [Color(0xFF991B1B), Color(0xFF701A75)],
        accentColor: Color(0xFFF87171),
        icon: Icons.account_balance_rounded,
      );
    } else if (cat.contains('inglés') || cat.contains('idioma') || cat.contains('english')) {
      return const BookPalette(
        gradient: [Color(0xFF1D4ED8), Color(0xFF1E1B4B)],
        accentColor: Color(0xFF60A5FA),
        icon: Icons.translate_rounded,
      );
    } else if (cat.contains('arte') || cat.contains('músic') || cat.contains('dibujo')) {
      return const BookPalette(
        gradient: [Color(0xFFC026D3), Color(0xFF4C0519)],
        accentColor: Color(0xFFF472B6),
        icon: Icons.palette_rounded,
      );
    }
    // Dynamic fallback gradients
    final defaultGradients = [
      [const Color(0xFF312E81), const Color(0xFF1E1B4B)],
      [const Color(0xFF0369A1), const Color(0xFF0C4A6E)],
      [const Color(0xFF4C1D95), const Color(0xFF2E1065)],
      [const Color(0xFF831843), const Color(0xFF500724)],
    ];
    final idx = category.hashCode.abs() % defaultGradients.length;
    return BookPalette(
      gradient: defaultGradients[idx],
      accentColor: const Color(0xFFFBBF24),
      icon: Icons.menu_book_rounded,
    );
  }
}

// ─── TARJETA 3D ESTILO APP STORE / NETFLIX ──────────────────────────────────
class BookCard3D extends ConsumerStatefulWidget {
  final Book book;
  final int index;
  final VoidCallback onRead;

  const BookCard3D({
    super.key,
    required this.book,
    required this.index,
    required this.onRead,
  });

  @override
  ConsumerState<BookCard3D> createState() => _BookCard3DState();
}

class _BookCard3DState extends ConsumerState<BookCard3D> {
  bool _isHovered = false;

  Widget _buildBadge(int index, int progress, bool isMobile) {
    if (progress >= 100) {
      return _badgeContainer(
        gradient: const [Color(0xFF10B981), Color(0xFF059669)],
        icon: Icons.check_circle_rounded,
        text: 'LEÍDO',
        isMobile: isMobile,
      );
    } else if (progress > 0) {
      return _badgeContainer(
        gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        icon: Icons.auto_stories,
        text: 'EN CURSO',
        isMobile: isMobile,
      );
    } else if (index % 3 == 0) {
      return _badgeContainer(
        gradient: const [Color(0xFF10B981), Color(0xFF047857)],
        icon: Icons.auto_awesome,
        text: 'NUEVO',
        isMobile: isMobile,
      );
    } else if (index % 3 == 1) {
      return _badgeContainer(
        gradient: const [Color(0xFFF97316), Color(0xFFDC2626)],
        icon: Icons.local_fire_department_rounded,
        text: isMobile ? 'TOP' : 'MÁS LEÍDO',
        isMobile: isMobile,
      );
    } else {
      return _badgeContainer(
        gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        icon: Icons.star_rounded,
        text: isMobile ? 'TOP' : 'DESTACADO',
        isMobile: isMobile,
      );
    }
  }

  Widget _badgeContainer({
    required List<Color> gradient,
    required IconData icon,
    required String text,
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 9,
        vertical: isMobile ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.35),
            blurRadius: isMobile ? 4 : 8,
            offset: Offset(0, isMobile ? 2 : 3),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: isMobile ? 9 : 12),
          SizedBox(width: isMobile ? 2.5 : 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 8 : 10,
              fontWeight: FontWeight.w900,
              letterSpacing: isMobile ? 0.3 : 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DBookCover(BookPalette palette, bool isMobile) {
    final bookWidth = isMobile ? 82.0 : 130.0;
    final bookHeight = isMobile ? 116.0 : 180.0;

    return AnimatedScale(
      scale: _isHovered ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: bookWidth,
        height: bookHeight,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            bottomLeft: Radius.circular(4),
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.35 : 0.20),
              blurRadius: _isHovered ? 20 : 12,
              offset: Offset(_isHovered ? 6 : 4, _isHovered ? 12 : 7),
            ),
            BoxShadow(
              color: palette.gradient.first.withOpacity(_isHovered ? 0.25 : 0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1. Right page stack edge (Páginas de papel del libro)
            Positioned(
              right: 0,
              top: 2,
              bottom: 2,
              width: isMobile ? 3.5 : 5,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5EE),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  border: Border(
                    left: BorderSide(color: Colors.black.withOpacity(0.12)),
                    right: BorderSide(color: Colors.black.withOpacity(0.08)),
                  ),
                ),
              ),
            ),

            // 2. Superficie Principal de la Carátula
            Positioned.fill(
              right: isMobile ? 3 : 4,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 10 : 16,
                  isMobile ? 8 : 12,
                  isMobile ? 6 : 10,
                  isMobile ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: palette.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Etiqueta superior de categoría
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 4 : 6,
                        vertical: isMobile ? 1 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Text(
                        widget.book.category.toUpperCase(),
                        style: TextStyle(
                          color: palette.accentColor,
                          fontSize: isMobile ? 7.0 : 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: isMobile ? 0.6 : 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Emblema Central
                    Container(
                      width: isMobile ? 30 : 46,
                      height: isMobile ? 30 : 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            palette.accentColor.withOpacity(0.35),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        border: Border.all(
                          color: palette.accentColor.withOpacity(0.6),
                          width: isMobile ? 1.0 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: palette.accentColor.withOpacity(0.2),
                            blurRadius: isMobile ? 4 : 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          palette.icon,
                          color: Colors.white,
                          size: isMobile ? 16 : 24,
                        ),
                      ),
                    ),

                    // Título y Autor sobre la Portada
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.book.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 8.5 : 11,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isMobile ? 2 : 3),
                        Text(
                          widget.book.author,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: isMobile ? 7.0 : 9,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3. Lomo 3D del Libro (Spine)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: isMobile ? 9 : 14,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.45),
                      Colors.black.withOpacity(0.12),
                      Colors.white.withOpacity(0.22),
                      Colors.black.withOpacity(0.35),
                    ],
                    stops: const [0.0, 0.45, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // 4. Reflejo brillante diagonal (Glossy plastic wrap)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.35, 0.55, 1.0],
                      colors: [
                        Colors.white.withOpacity(0.18),
                        Colors.white.withOpacity(0.04),
                        Colors.transparent,
                        Colors.black.withOpacity(0.12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int progress, bool isDark, bool isMobile) {
    final pct = (progress / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              progress > 0 ? 'Progreso' : 'Estado',
              style: TextStyle(
                fontSize: isMobile ? 9.5 : 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            Text(
              progress == 100
                  ? (isMobile ? '¡Leído! 🎉' : '¡Completado! 🎉')
                  : (progress > 0 ? '$progress%' : (isMobile ? 'Sin iniciar' : 'Por comenzar')),
              style: TextStyle(
                fontSize: isMobile ? 9.5 : 11,
                fontWeight: FontWeight.bold,
                color: progress == 100
                    ? const Color(0xFF10B981)
                    : (progress > 0 ? const Color(0xFF818CF8) : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 3 : 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: isMobile ? 4 : 6,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: progress == 100
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFF6366F1), const Color(0xFFA855F7)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPrefsProvider);
    final progress = prefs.getInt('book_progress_${widget.book.id}') ?? 0;
    final palette = BookPalette.getForCategory(widget.book.category);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 22),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF818CF8)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : const Color(0xFF4F46E5)).withOpacity(_isHovered ? 0.25 : (isDark ? 0.15 : 0.04)),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 8 : 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 1. ZONA SUPERIOR: ESCENARIO 3D DEL LIBRO Y BADGE ───────────
            Container(
              height: isMobile ? 138 : 220,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMobile ? 15 : 21),
                  topRight: Radius.circular(isMobile ? 15 : 21),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B).withOpacity(0.6)]
                      : [const Color(0xFFF1F5F9), Colors.white.withOpacity(0.5)],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sombra del pedestal / estante
                  Positioned(
                    bottom: isMobile ? 8 : 12,
                    child: Container(
                      width: isMobile ? 70 : 110,
                      height: isMobile ? 8 : 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.20),
                            blurRadius: isMobile ? 8 : 14,
                            spreadRadius: isMobile ? 1 : 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // El Libro en 3D
                  Positioned(
                    bottom: isMobile ? 10 : 16,
                    child: _build3DBookCover(palette, isMobile),
                  ),

                  // Badge de Estado Flotante en la esquina
                  Positioned(
                    top: isMobile ? 8 : 12,
                    right: isMobile ? 8 : 12,
                    child: _buildBadge(widget.index, progress, isMobile),
                  ),
                ],
              ),
            ),

            // ─── 2. ZONA INFERIOR: METADATOS Y ACCIONES ────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 10 : 16,
                  isMobile ? 8 : 12,
                  isMobile ? 10 : 16,
                  isMobile ? 10 : 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chip de categoría
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 6 : 8,
                            vertical: isMobile ? 2 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE)),
                          ),
                          child: Text(
                            widget.book.category,
                            style: TextStyle(
                              color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                              fontSize: isMobile ? 9.5 : 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: isMobile ? 4 : 8),

                        // Título del libro
                        Text(
                          widget.book.title,
                          style: TextStyle(
                            fontSize: isMobile ? 12.0 : 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isMobile ? 2 : 4),

                        // Autor
                        Text(
                          'Por: ${widget.book.author}',
                          style: TextStyle(
                            fontSize: isMobile ? 10.0 : 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Barra de progreso y botón de acción
                    Column(
                      children: [
                        _buildProgressBar(progress, isDark, isMobile),
                        SizedBox(height: isMobile ? 6 : 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.auto_stories, size: isMobile ? 13 : 16),
                            label: Text(
                              progress > 0
                                  ? (progress == 100 ? (isMobile ? 'Releer' : 'Releer Libro') : (isMobile ? 'Continuar' : 'Continuar Lectura'))
                                  : (isMobile ? 'Leer' : 'Leer Libro'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 11 : 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: isMobile ? 7 : 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                              ),
                            ),
                            onPressed: widget.onRead,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
