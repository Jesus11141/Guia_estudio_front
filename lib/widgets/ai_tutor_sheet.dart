import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../tts_helper.dart';
import '../models/avatar_catalog.dart';
import 'talking_robot_avatar.dart';

class AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AiChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiTutorSheet extends ConsumerStatefulWidget {
  final String? lessonTitle;
  final String? lessonContent;

  const AiTutorSheet({
    super.key,
    this.lessonTitle,
    this.lessonContent,
  });

  static Future<void> show(
    BuildContext context, {
    String? lessonTitle,
    String? lessonContent,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiTutorSheet(
        lessonTitle: lessonTitle,
        lessonContent: lessonContent,
      ),
    );
  }

  @override
  ConsumerState<AiTutorSheet> createState() => _AiTutorSheetState();
}

class _AiTutorSheetState extends ConsumerState<AiTutorSheet> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<AiChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final greeting = widget.lessonTitle != null
        ? '¡Hola! 🤖 Soy tu Profe IA. Estoy listo para ayudarte con tu lección de "${widget.lessonTitle}". ¿Qué duda tienes?'
        : '¡Hola! 🤖 Soy tu Profe IA personal. Pregúntame lo que quieras sobre tus materias, ejercicios o dudas de estudio. ¡Aprender es divertido!';
    _messages.add(AiChatMessage(text: greeting, isUser: false));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? prefillText]) async {
    final text = (prefillText ?? _inputCtrl.text).trim();
    if (text.isEmpty || _isLoading) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(AiChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/ai/tutor', data: {
        'question': text,
        if (widget.lessonContent != null && widget.lessonContent!.isNotEmpty)
          'lessonContent': widget.lessonContent,
      });

      final answer = res.data['answer'] ?? '¡Hola! No pude procesar tu respuesta en este momento. Inténtalo de nuevo.';
      if (mounted) {
        setState(() {
          _messages.add(AiChatMessage(text: answer, isUser: false));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(AiChatMessage(
            text: 'Ups, hubo un problema conectando con el Profe IA. Intenta de nuevo en unos segundos. 😊',
            isUser: false,
          ));
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final userAvatar = AvatarCatalog.find(user?.avatar);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 650,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ─── Header ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  children: [
                    // Avatar parlante dinámico en cabecera
                    ValueListenableBuilder<bool>(
                      valueListenable: TtsHelper.isSpeakingNotifier,
                      builder: (context, isSpeaking, _) {
                        return TalkingRobotAvatar(
                          size: 42,
                          isSpeaking: isSpeaking,
                          isThinking: _isLoading,
                          showSoundWaves: isSpeaking || _isLoading,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profe IA Tutor ✨',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            widget.lessonTitle != null
                                ? 'Tema: ${widget.lessonTitle}'
                                : 'Tu asistente de estudio inteligente',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () {
                        TtsHelper.stop();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              // ─── Quick Suggestion Chips ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('💡 Dame un ejemplo', () => _sendMessage('¿Puedes darme un ejemplo fácil para entenderlo?'), isDark),
                      const SizedBox(width: 8),
                      _buildChip('📝 Hazme un resumen', () => _sendMessage('¿Puedes hacerme un resumen de 3 puntos clave?'), isDark),
                      const SizedBox(width: 8),
                      _buildChip('❓ ¿Para qué sirve esto?', () => _sendMessage('¿Para qué sirve este tema en la vida diaria?'), isDark),
                      const SizedBox(width: 8),
                      _buildChip('🎯 Ponme un mini-reto', () => _sendMessage('Hazme una pregunta sorpresa para ver si entendí'), isDark),
                    ],
                  ),
                ),
              ),

              Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),

              // ─── Messages List ─────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageBubble(msg, userAvatar.emoji, isDark);
                  },
                ),
              ),

              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'El Profe IA está pensando y escribiendo...',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

              // ─── Input Bar ─────────────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        minLines: 1,
                        maxLines: 3,
                        cursorColor: const Color(0xFF6366F1),
                        style: TextStyle(
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Pregúntale al Profe IA...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Color(0xFF6366F1),
                              width: 2,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: _isLoading ? null : () => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF6366F1).withOpacity(0.4) : const Color(0xFF6366F1).withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage msg, String userEmoji, bool isDark) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF4F46E5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF312E81) : const Color(0xFFE0E7FF),
                shape: BoxShape.circle,
              ),
              child: Text(userEmoji, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar animado del Profe IA
            ValueListenableBuilder<String?>(
              valueListenable: TtsHelper.currentSpeakingTextNotifier,
              builder: (context, currentSpeakingText, _) {
                final isThisSpeaking = currentSpeakingText == msg.text;
                return TalkingRobotAvatar(
                  size: 32,
                  isSpeaking: isThisSpeaking,
                  isThinking: false,
                  showSoundWaves: isThisSpeaking,
                );
              },
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ValueListenableBuilder<String?>(
                          valueListenable: TtsHelper.currentSpeakingTextNotifier,
                          builder: (context, currentSpeakingText, _) {
                            final isThisSpeaking = currentSpeakingText == msg.text;
                            return InkWell(
                              onTap: () {
                                if (isThisSpeaking) {
                                  TtsHelper.stop();
                                } else {
                                  TtsHelper.speak(msg.text);
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isThisSpeaking
                                      ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2))
                                      : (isDark ? const Color(0xFF312E81) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isThisSpeaking
                                        ? Colors.redAccent.withOpacity(0.5)
                                        : (isDark ? const Color(0xFF6366F1).withOpacity(0.3) : Colors.transparent),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isThisSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                                      size: 16,
                                      color: isThisSpeaking
                                          ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))
                                          : (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5)),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isThisSpeaking ? 'Detener' : 'Escuchar',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isThisSpeaking
                                          ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))
                                          : (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
