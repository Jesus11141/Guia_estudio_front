import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../providers.dart';
import '../models.dart';

class AdminRewardsScreen extends ConsumerStatefulWidget {
  const AdminRewardsScreen({super.key});

  @override
  ConsumerState<AdminRewardsScreen> createState() => _AdminRewardsScreenState();
}

class _AdminRewardsScreenState extends ConsumerState<AdminRewardsScreen> {
  final _nameCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  
  Reward? _editingReward;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  void _startEdit(Reward reward) {
    setState(() {
      _editingReward = reward;
      _nameCtrl.text = reward.name;
      _costCtrl.text = reward.cost.toString();
      _imageCtrl.text = reward.imageUrl ?? '';
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingReward = null;
      _nameCtrl.clear();
      _costCtrl.clear();
      _imageCtrl.clear();
    });
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final token = ref.read(sharedPrefsProvider).getString('token');
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.isNotEmpty) {
        setState(() => _isUploadingImage = true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 12),
                  Text('Subiendo foto del premio...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
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

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final serverOrigin = baseUrl.replaceAll('/api', '');
          final fullUrl = '$serverOrigin${data['url']}';

          setState(() {
            _imageCtrl.text = fullUrl;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Foto subida con éxito! 🎉'),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          throw 'Error al subir imagen (código ${response.statusCode})';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveReward() async {
    final name = _nameCtrl.text.trim();
    final cost = int.tryParse(_costCtrl.text.trim());

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el nombre del premio')),
      );
      return;
    }
    if (cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un costo en estrellas válido (> 0)')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final imageUrl = _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim();

    try {
      if (_editingReward == null) {
        // Create
        await ref.read(dioProvider).post('/rewards', data: {
          'name': name,
          'cost': cost,
          'imageUrl': imageUrl,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 ¡Premio creado con éxito!'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Edit / Update
        await ref.read(dioProvider).patch('/rewards/${_editingReward!.id}', data: {
          'name': name,
          'cost': cost,
          'imageUrl': imageUrl,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✏️ ¡Premio "$name" actualizado con éxito!'),
              backgroundColor: const Color(0xFF4F46E5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      _cancelEdit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete(Reward r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar Premio?'),
        content: Text('¿Seguro que deseas eliminar el premio "${r.name}"? Los estudiantes ya no podrán canjearlo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(dioProvider).delete('/rewards/${r.id}');
      if (_editingReward?.id == r.id) {
        _cancelEdit();
      } else {
        setState(() {});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premio eliminado'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  Future<void> _markDelivered(String id) async {
    try {
      await ref.read(dioProvider).patch('/rewards/claims/$id', data: {'status': 'DELIVERED'});
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Premio marcado como entregado! 🎉'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildImageThumbnail(String? rawUrl, {double size = 56}) {
    final resolved = resolveImageUrl(rawUrl);
    if (resolved == null || resolved.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text('🎁', style: TextStyle(fontSize: 26)),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          resolved,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
          errorBuilder: (context, error, stack) {
            return Container(
              color: const Color(0xFFFEF2F2),
              child: const Center(
                child: Icon(Icons.broken_image_rounded, size: 24, color: Color(0xFFEF4444)),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Row(
            children: [
              Text('🎁 ', style: TextStyle(fontSize: 22)),
              Text('Administrar Premios y Canjes', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            ],
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF4F46E5),
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: Color(0xFF4F46E5),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Premios de la Tienda'),
              Tab(icon: Icon(Icons.shopping_bag_rounded), text: 'Canjes de Estudiantes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Premios
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 360,
                          child: _buildFormCard(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildRewardsList(),
                        ),
                      ],
                    );
                  } else {
                    return ListView(
                      children: [
                        _buildFormCard(),
                        const SizedBox(height: 16),
                        _buildRewardsList(),
                      ],
                    );
                  }
                },
              ),
            ),

            // Tab 2: Canjes
            _buildClaimsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    final isEditing = _editingReward != null;
    final previewUrl = resolveImageUrl(_imageCtrl.text.trim());

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                  color: isEditing ? const Color(0xFFF59E0B) : const Color(0xFF4F46E5),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEditing ? 'Editar Premio' : 'Crear Nuevo Premio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isEditing ? const Color(0xFFB45309) : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Cancelar edición',
                    onPressed: _cancelEdit,
                  ),
              ],
            ),
            if (isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Modificando: "${_editingReward!.name}"',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                ),
              ),
            const Divider(height: 20),

            // Nombre
            const Text('Nombre del Premio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'Ej. Huevo Kinder, Set de Plastilinas...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
                prefixIcon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 14),

            // Costo
            const Text('Costo en Estrellas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextField(
              controller: _costCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ej. 25',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
                prefixIcon: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                suffixText: '🌟',
              ),
            ),
            const SizedBox(height: 14),

            // Foto / Imagen del premio
            const Text('Foto del Premio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
            const SizedBox(height: 6),

            // Preview Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  if (previewUrl != null && previewUrl.isNotEmpty)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            previewUrl,
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (c, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                height: 130,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (c, err, stack) => Container(
                              height: 130,
                              color: const Color(0xFFFEE2E2),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_rounded, color: Colors.redAccent, size: 36),
                                    SizedBox(height: 4),
                                    Text('No se pudo cargar la imagen', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: InkWell(
                            onTap: () {
                              setState(() => _imageCtrl.clear());
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        children: [
                          Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 6),
                          Text('Sin foto seleccionada', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Text('Se mostrará un icono de regalo 🎁', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Botón Subir Foto
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: _isUploadingImage
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: Text(_isUploadingImage ? 'Subiendo imagen...' : 'Subir Foto desde mi dispositivo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                        side: const BorderSide(color: Color(0xFF4F46E5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Campo de URL manual (opcional)
            TextField(
              controller: _imageCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'O pega la URL de la imagen directamente:',
                hintText: 'https://... o /uploads/...',
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
                prefixIcon: const Icon(Icons.link_rounded, size: 18, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 20),

            // Botón Guardar / Actualizar
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(isEditing ? Icons.check_circle_rounded : Icons.save_rounded),
                label: Text(
                  _isSaving
                      ? 'Guardando...'
                      : (isEditing ? 'Actualizar Premio' : 'Guardar Premio'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEditing ? const Color(0xFFF59E0B) : const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveReward,
              ),
            ),
            if (isEditing) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _cancelEdit,
                  child: const Text('Cancelar Edición', style: TextStyle(color: Color(0xFF64748B))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsList() {
    return FutureBuilder(
      future: ref.read(dioProvider).get('/rewards'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar premios: ${snapshot.error}'));
        }
        final list = (snapshot.data!.data as List).map((e) => Reward.fromJson(e)).toList();

        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('No hay premios registrados todavía.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  const Text('Usa el formulario para crear el primer premio de la tienda.', style: TextStyle(color: Color(0xFF94A3B8))),
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Premios en Catálogo (${list.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
                      tooltip: 'Actualizar lista',
                      onPressed: () => setState(() {}),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final r = list[index];
                    final isCurrentlyEditing = _editingReward?.id == r.id;

                    return Container(
                      decoration: BoxDecoration(
                        color: isCurrentlyEditing ? const Color(0xFFFEF3C7).withOpacity(0.4) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: _buildImageThumbnail(r.imageUrl, size: 52),
                        title: Text(
                          r.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isCurrentlyEditing ? const Color(0xFF92400E) : const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🌟', style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${r.cost} estrellas',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF92400E)),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrentlyEditing) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Editando',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Color(0xFF4F46E5)),
                              tooltip: 'Editar premio',
                              onPressed: () => _startEdit(r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              tooltip: 'Eliminar premio',
                              onPressed: () => _confirmDelete(r),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClaimsTab() {
    return FutureBuilder(
      future: ref.read(dioProvider).get('/rewards/claims'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar canjes: ${snapshot.error}'));
        }
        final list = (snapshot.data!.data as List).map((e) => RewardClaim.fromJson(e)).toList();

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('Aún no hay canjes solicitados por estudiantes.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              ],
            ),
          );
        }

        final pendingCount = list.where((c) => c.status == 'PENDING').length;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Total de canjes: ${list.length} | Pendientes por entregar: $pendingCount',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
                      tooltip: 'Actualizar',
                      onPressed: () => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = list[index];
                      final isPending = c.status == 'PENDING';

                      return ListTile(
                        leading: _buildImageThumbnail(c.reward?.imageUrl, size: 48),
                        title: Text(
                          '${c.user?.name ?? c.user?.email ?? "Estudiante"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text('Premio: ${c.reward?.name ?? "Premio desconocido"} (${c.reward?.cost ?? 0} ⭐)'),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPending ? '⏳ Pendiente de entregar' : '✅ Entregado',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isPending ? const Color(0xFF92400E) : const Color(0xFF065F46),
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: isPending
                            ? ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('Marcar Entregado'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _markDelivered(c.id),
                              )
                            : const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
