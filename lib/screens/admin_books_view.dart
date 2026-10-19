import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../providers.dart';

class AdminBooksView extends ConsumerStatefulWidget {
  const AdminBooksView({super.key});

  @override
  ConsumerState<AdminBooksView> createState() => _AdminBooksViewState();
}

class _AdminBooksViewState extends ConsumerState<AdminBooksView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  String? _selectedCategory;
  bool _isCreatingNewCategory = false;
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _pickFile() async {
    try {
      List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub'],
      );
      if (result.isNotEmpty) {
        setState(() {
          _selectedFile = result.first;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _saveBook(List<String> existingCategories) async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona un archivo PDF o EPUB')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    final dio = ref.read(dioProvider);

    try {
      final bytes = await _selectedFile!.readAsBytes();

      String categoryToSave;
      if (existingCategories.isEmpty || _isCreatingNewCategory) {
        categoryToSave = _categoryController.text.trim();
      } else {
        categoryToSave = _selectedCategory ?? (existingCategories.isNotEmpty ? existingCategories.first : 'General');
      }
      if (categoryToSave.isEmpty) categoryToSave = 'General';

      FormData formData = FormData.fromMap({
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': categoryToSave,
        'file': MultipartFile.fromBytes(bytes, filename: _selectedFile!.name),
      });

      var response = await dio.post('/books', data: formData);
      if (response.statusCode == 201 || response.statusCode == 200) {
        ref.invalidate(booksProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Libro subido con éxito!')),
          );
        }
        setState(() {
          _titleController.clear();
          _authorController.clear();
          _descriptionController.clear();
          _categoryController.clear();
          _selectedCategory = null;
          _isCreatingNewCategory = false;
          _selectedFile = null;
          _formKey.currentState?.reset();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir libro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmDeleteBook(Book book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Libro'),
        content: Text('¿Estás seguro de que deseas eliminar "${book.title}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteBook(book.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _deleteBook(String id) async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.delete('/books/$id');
      if (response.statusCode == 200) {
        ref.invalidate(booksProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Libro eliminado')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar libro')),
        );
      }
    }
  }

  void _editBook(Book book, List<String> existingCategories) {
    final editFormKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: book.title);
    final authorCtrl = TextEditingController(text: book.author);
    final descCtrl = TextEditingController(text: book.description ?? '');
    final newCatCtrl = TextEditingController();

    String currentCategory = book.category.trim().isNotEmpty ? book.category.trim() : 'General';
    bool editIsCreatingNew = !existingCategories.contains(currentCategory);
    if (editIsCreatingNew) {
      newCatCtrl.text = currentCategory;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.edit, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 8),
                  const Text('Editar Libro'),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: editFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(labelText: 'Título del Libro'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: authorCtrl,
                          decoration: const InputDecoration(labelText: 'Autor'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descCtrl,
                          decoration: const InputDecoration(labelText: 'Descripción (Opcional)'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        const Text('Categoría:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
                        const SizedBox(height: 8),
                        if (editIsCreatingNew || existingCategories.isEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: newCatCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre de la categoría',
                                    hintText: 'Ej: Cuentos, Ciencias...',
                                    prefixIcon: Icon(Icons.category_outlined),
                                  ),
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                                ),
                              ),
                              if (existingCategories.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setDialogState(() {
                                        editIsCreatingNew = false;
                                        currentCategory = existingCategories.first;
                                      });
                                    },
                                    child: const Text('Lista'),
                                  ),
                                ),
                              ],
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: existingCategories.contains(currentCategory) ? currentCategory : existingCategories.first,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.category_outlined),
                                  ),
                                  items: [
                                    ...existingCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                                    const DropdownMenuItem(
                                      value: '__NEW__',
                                      child: Row(
                                        children: [
                                          Icon(Icons.add, color: Color(0xFF4F46E5), size: 18),
                                          SizedBox(width: 8),
                                          Text('+ Nueva categoría...', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val == '__NEW__') {
                                      setDialogState(() {
                                        editIsCreatingNew = true;
                                        newCatCtrl.clear();
                                      });
                                    } else if (val != null) {
                                      setDialogState(() {
                                        currentCategory = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (!editFormKey.currentState!.validate()) return;
                    final category = editIsCreatingNew || existingCategories.isEmpty
                        ? newCatCtrl.text.trim()
                        : currentCategory;

                    final dio = ref.read(dioProvider);
                    try {
                      final res = await dio.patch('/books/${book.id}', data: {
                        'title': titleCtrl.text.trim(),
                        'author': authorCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'category': category.isNotEmpty ? category : 'General',
                      });
                      if (res.statusCode == 200) {
                        ref.invalidate(booksProvider);
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Libro actualizado con éxito')),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al actualizar libro: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);

    return booksAsync.when(
      data: (books) {
        // Collect existing unique categories from books
        final existingCategories = books
            .map((b) => b.category.trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestión de Biblioteca',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text(
                'Sube libros en PDF o EPUB y organízalos por categorías para que los estudiantes los encuentren fácilmente.',
                style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),

              // Upload Form Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cloud_upload, color: Color(0xFF4F46E5)),
                          SizedBox(width: 8),
                          Text('Subir Nuevo Libro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título del Libro',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _authorController,
                        decoration: const InputDecoration(
                          labelText: 'Autor',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Category Selector / Input Field
                      if (existingCategories.isEmpty || _isCreatingNewCategory)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _categoryController,
                                decoration: InputDecoration(
                                  labelText: existingCategories.isEmpty ? 'Categoría' : 'Nueva Categoría',
                                  hintText: 'Ej: Cuentos, Ciencias, Historia, Lectura...',
                                  prefixIcon: const Icon(Icons.category_outlined),
                                  helperText: existingCategories.isEmpty
                                      ? 'Como aún no tienes categorías, escribe el nombre de la categoría para este libro.'
                                      : 'Escribe el nombre de la nueva categoría.',
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                              ),
                            ),
                            if (existingCategories.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.list),
                                  label: const Text('Elegir existente'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF4F46E5),
                                    side: const BorderSide(color: Color(0xFF4F46E5)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isCreatingNewCategory = false;
                                      _categoryController.clear();
                                      if (_selectedCategory == null && existingCategories.isNotEmpty) {
                                        _selectedCategory = existingCategories.first;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: (_selectedCategory != null && existingCategories.contains(_selectedCategory))
                                    ? _selectedCategory
                                    : existingCategories.first,
                                decoration: const InputDecoration(
                                  labelText: 'Categoría',
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                items: [
                                  ...existingCategories.map((cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat),
                                      )),
                                  const DropdownMenuItem(
                                    value: '__NEW__',
                                    child: Row(
                                      children: [
                                        Icon(Icons.add_circle, color: Color(0xFF4F46E5), size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          '+ Añadir nueva categoría...',
                                          style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val == '__NEW__') {
                                    setState(() {
                                      _isCreatingNewCategory = true;
                                      _categoryController.clear();
                                    });
                                  } else {
                                    setState(() {
                                      _selectedCategory = val;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Nueva Categoría'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                                  foregroundColor: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isCreatingNewCategory = true;
                                    _categoryController.clear();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (Opcional)',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Seleccionar PDF o EPUB'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              foregroundColor: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            onPressed: _pickFile,
                          ),
                          const SizedBox(width: 16),
                          if (_selectedFile != null)
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _selectedFile!.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isLoading ? null : () => _saveBook(existingCategories),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Subir Libro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Libros Disponibles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                  Text('${books.length} libros en total', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 16),
              if (books.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(
                      'No hay libros subidos aún. ¡Usa el formulario de arriba para subir el primero!',
                      style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 16),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(Icons.menu_book, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5)),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                book.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE)),
                              ),
                              child: Text(
                                book.category,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Por: ${book.author}${book.description != null && book.description!.isNotEmpty ? " • ${book.description}" : ""}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Leer libro (Lector con Zoom)',
                              icon: const Icon(Icons.open_in_new, color: Colors.blue),
                              onPressed: () {
                                final rootUrl = baseUrl.replaceAll('/api', '');
                                final pdfUrl = '$rootUrl${book.fileUrl}';
                                final readerUrl = '$rootUrl/uploads/reader.html?file=$pdfUrl';
                                launchUrl(Uri.parse(readerUrl));
                              },
                            ),
                            IconButton(
                              tooltip: 'Editar información',
                              icon: const Icon(Icons.edit, color: Colors.amber),
                              onPressed: () => _editBook(book, existingCategories),
                            ),
                            IconButton(
                              tooltip: 'Eliminar libro',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteBook(book),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(48.0),
        child: CircularProgressIndicator(),
      )),
      error: (e, st) => Center(child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text('Error al cargar libros: $e'),
      )),
    );
  }
}
