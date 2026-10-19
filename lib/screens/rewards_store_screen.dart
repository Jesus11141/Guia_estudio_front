import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models.dart';
import '../models/avatar_catalog.dart';
import '../audio_fx_helper.dart';
import '../widgets/confetti_celebration.dart';

class RewardsStoreScreen extends ConsumerStatefulWidget {
  const RewardsStoreScreen({super.key});

  @override
  ConsumerState<RewardsStoreScreen> createState() => _RewardsStoreScreenState();
}

class _RewardsStoreScreenState extends ConsumerState<RewardsStoreScreen> {
  bool _showConfetti = false;
  bool _isLoading = false;

  void _triggerConfetti() {
    setState(() => _showConfetti = true);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showConfetti = false);
    });
  }

  Future<void> _handleAvatarAction(AvatarItem avatar, bool isUnlocked) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    if (isUnlocked) {
      // Equip avatar
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Text(avatar.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('¿Usar a ${avatar.name}?', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Text('¿Quieres que "${avatar.title}" sea tu nuevo avatar de perfil?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: avatar.bgColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('¡Sí, equipar!'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => _isLoading = true);
      try {
        final res = await ref.read(dioProvider).post('/users/me/buy-avatar', data: {
          'avatarId': avatar.id,
          'cost': 0,
        });
        ref.read(authProvider.notifier).setUser(User.fromJson(res.data));
        AudioFx.playStar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              content: Row(
                children: [
                  Text(avatar.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text('¡Avatar equipado con éxito! Te ves genial.', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          AudioFx.playWrong();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al cambiar de avatar')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Buy & equip avatar
      if (user.stars < avatar.cost) {
        AudioFx.playWrong();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            content: Text('Necesitas ${avatar.cost} estrellas. ¡Te faltan ${avatar.cost - user.stars} 🌟!'),
          ),
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Text(avatar.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('¡Desbloquear ${avatar.name}!', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(avatar.title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Text('🌟', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Costo: ${avatar.cost} estrellas.\nTe quedarán ${user.stars - avatar.cost} 🌟.',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('¡Desbloquear ahora!'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => _isLoading = true);
      try {
        final res = await ref.read(dioProvider).post('/users/me/buy-avatar', data: {
          'avatarId': avatar.id,
          'cost': avatar.cost,
        });
        ref.read(authProvider.notifier).setUser(User.fromJson(res.data));
        AudioFx.playVictory();
        _triggerConfetti();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              content: Row(
                children: [
                  Text(avatar.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('🎉 ¡Felicidades! Desbloqueaste a ${avatar.name}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          AudioFx.playWrong();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al desbloquear avatar')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _buyReward(Reward r) async {
    final user = ref.read(authProvider);
    if (user == null || user.stars < r.cost) {
      AudioFx.playWrong();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tienes suficientes estrellas.')));
      return;
    }

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar canje'),
        content: Text('¿Seguro que quieres canjear ${r.cost} estrellas por "${r.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(c);
              try {
                await ref.read(dioProvider).post('/rewards/${r.id}/redeem');
                AudioFx.playVictory();
                _triggerConfetti();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('¡Canje exitoso! Pídele tu premio a tu profesor.')),
                  );
                }
                ref.invalidate(authProvider);
                setState(() {});
              } catch (e) {
                if (mounted) {
                  AudioFx.playWrong();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al canjear premio')));
                }
              }
            },
            child: const Text('Canjear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final equippedItem = AvatarCatalog.find(user?.avatar);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
          elevation: 0,
          title: Text(
            'Tienda de Premios 🎁',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
          centerTitle: false,
          actions: [
            if (user != null)
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF78350F), const Color(0xFF92400E)]
                        : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.amber.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌟', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      '${user.stars}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          bottom: TabBar(
            labelColor: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
            unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            indicatorColor: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: const [
              Tab(icon: Icon(Icons.face_retouching_natural_rounded), text: 'Avatares Mágicos 🎭'),
              Tab(icon: Icon(Icons.card_giftcard_rounded), text: 'Premios Escolares 🎁'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildAvatarsTab(user, equippedItem, isDark),
                _buildPhysicalRewardsTab(isDark),
              ],
            ),
            if (_showConfetti)
              const IgnorePointer(
                child: ConfettiCelebration(isActive: true, child: SizedBox.expand()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarsTab(User? user, AvatarItem equippedItem, bool isDark) {
    final unlockedList = user?.unlockedAvatars ?? [];
    final totalAvatars = AvatarCatalog.all.length;
    final unlockedCount = AvatarCatalog.all.where((a) => a.cost == 0 || unlockedList.contains(a.id)).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner of equipped avatar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [equippedItem.bgColor.withOpacity(0.85), equippedItem.bgColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: equippedItem.bgColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(equippedItem.emoji, style: const TextStyle(fontSize: 34)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu Avatar Actual',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        equippedItem.name,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        equippedItem.title,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Colección: $unlockedCount / $totalAvatars',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '🌟 Desbloquea y Colecciona Avatares',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¡Usa tus estrellas ganadas en los juegos y cuestionarios para conseguir nuevos personajes!',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Avatars Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                      ? 3
                      : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: AvatarCatalog.all.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemBuilder: (context, index) {
                  final avatar = AvatarCatalog.all[index];
                  final isEquipped = (user?.avatar == avatar.id) ||
                      (user?.avatar == null && avatar.id == 'avatar_astronaut');
                  final isUnlocked = avatar.cost == 0 || unlockedList.contains(avatar.id);
                  final canAfford = (user?.stars ?? 0) >= avatar.cost;

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isEquipped
                            ? const Color(0xFF10B981)
                            : (isDark
                                ? const Color(0xFF334155)
                                : (isUnlocked ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1))),
                        width: isEquipped ? 2.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isEquipped
                              ? Colors.green.withOpacity(0.15)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Avatar Header with Badge
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: avatar.bgColor.withOpacity(0.12),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    avatar.emoji,
                                    style: const TextStyle(fontSize: 54),
                                  ),
                                ),
                                if (isEquipped)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        '✓ EN USO',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  )
                                else if (!isUnlocked)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF334155),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.lock_rounded, color: Colors.white, size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${avatar.cost} 🌟',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'TUYO',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Avatar Info & Button
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Text(
                                avatar.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                avatar.title,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: isEquipped
                                    ? OutlinedButton(
                                        onPressed: null,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF10B981),
                                          side: const BorderSide(color: Color(0xFF10B981)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: const Text('Equipado', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                                      )
                                    : isUnlocked
                                        ? ElevatedButton(
                                            onPressed: _isLoading ? null : () => _handleAvatarAction(avatar, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF4F46E5),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            child: const Text('Equipar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          )
                                        : ElevatedButton(
                                            onPressed: (_isLoading || !canAfford)
                                                ? () {
                                                    AudioFx.playWrong();
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('¡Te faltan ${avatar.cost - (user?.stars ?? 0)} estrellas para desbloquear a ${avatar.name}!'),
                                                      ),
                                                    );
                                                  }
                                                : () => _handleAvatarAction(avatar, false),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: canAfford ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                                              foregroundColor: canAfford ? Colors.white : const Color(0xFF94A3B8),
                                              elevation: canAfford ? 1 : 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            child: Text(
                                              canAfford ? 'Obtener (${avatar.cost} ⭐)' : 'Bloqueado',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                            ),
                                          ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPhysicalRewardsTab(bool isDark) {
    return FutureBuilder(
      future: ref.read(dioProvider).get('/rewards'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Center(child: Text('Error al cargar la tienda.'));
        final list = (snapshot.data!.data as List).map((e) => Reward.fromJson(e)).toList();

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard, size: 64, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 12),
                Text(
                  'Aún no hay premios escolares.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '¡Pídele a tu profesor que agregue premios a la tienda!',
                  style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 250,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final r = list[index];
            return Card(
              elevation: 4,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Builder(
                    builder: (context) {
                      final resolvedImg = resolveImageUrl(r.imageUrl);
                      if (resolvedImg != null && resolvedImg.isNotEmpty) {
                        return Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(
                              resolvedImg,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (c, child, progress) {
                                if (progress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (c, err, stack) => Container(
                                color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                                child: const Center(
                                  child: Icon(Icons.card_giftcard_rounded, size: 54, color: Color(0xFFF59E0B)),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: const Center(
                            child: Text('🎁', style: TextStyle(fontSize: 48)),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          r.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text('${r.cost} 🌟', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 18)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _buyReward(r),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Canjear', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
