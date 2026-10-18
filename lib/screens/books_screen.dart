import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
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
                                  const Text(
                                    'Biblioteca Virtual',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Explora libros y material de lectura por categorías para ampliar tus conocimientos.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.indigo[50],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (MediaQuery.of(context).size.width > 600)
                              const Icon(Icons.local_library, size: 76, color: Colors.white24),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Search and Category Filters
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Box
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar libro por título, autor o tema...',
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade200),
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
                                      backgroundColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xFF475569),
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
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
                              Icon(Icons.menu_book, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                books.isEmpty
                                    ? 'Aún no hay libros en la biblioteca.'
                                    : 'No se encontraron libros en "$_selectedCategory"${_searchQuery.isNotEmpty ? " con la búsqueda actual" : ""}.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 350,
                          mainAxisExtent: 280,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final book = filteredBooks[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.menu_book, color: Color(0xFF4F46E5), size: 22),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFC7D2FE)),
                                          ),
                                          child: Text(
                                            book.category,
                                            style: const TextStyle(
                                              color: Color(0xFF4338CA),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.title,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Por: ${book.author}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF64748B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (book.description != null && book.description!.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              book.description!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.auto_stories, size: 18),
                                        label: const Text('Leer Libro'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4F46E5),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: () {
                                          final rootUrl = baseUrl.replaceAll('/api', '');
                                          final pdfUrl = '$rootUrl${book.fileUrl}';
                                          final readerUrl = '$rootUrl/uploads/reader.html?file=$pdfUrl';
                                          launchUrl(Uri.parse(readerUrl));
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
