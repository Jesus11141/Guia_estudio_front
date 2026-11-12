import 'package:flutter/material.dart';

class InteractiveStudyMaterial extends StatefulWidget {
  final String lessonTitle;
  final String content;
  final VoidCallback onStartPractice;

  const InteractiveStudyMaterial({
    super.key,
    required this.lessonTitle,
    required this.content,
    required this.onStartPractice,
  });

  @override
  State<InteractiveStudyMaterial> createState() => _InteractiveStudyMaterialState();
}

class _StudySection {
  final String title;
  final String rawBody;
  final IconData icon;

  _StudySection({
    required this.title,
    required this.rawBody,
    required this.icon,
  });
}

class _InteractiveStudyMaterialState extends State<InteractiveStudyMaterial> {
  int _currentSectionIndex = 0;
  late List<_StudySection> _sections;

  @override
  void initState() {
    super.initState();
    _parseSections();
  }

  @override
  void didUpdateWidget(covariant InteractiveStudyMaterial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _parseSections();
      _currentSectionIndex = 0;
    }
  }

  void _parseSections() {
    final raw = widget.content.trim();
    if (raw.isEmpty) {
      _sections = [];
      return;
    }

    final List<_StudySection> parsed = [];
    final lines = raw.split('\n');

    String currentTitle = '1. Introducción y Conceptos';
    final List<String> currentBuffer = [];
    final List<IconData> iconPool = [
      Icons.auto_stories_rounded,
      Icons.lightbulb_rounded,
      Icons.edit_note_rounded,
      Icons.rule_folder_rounded,
      Icons.fact_check_rounded,
      Icons.star_rounded,
    ];
    int iconIdx = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // Detect header section (#### o ### si no es el título principal de unidad)
      if (trimmed.startsWith('#### ') ||
          (trimmed.startsWith('### ') && !trimmed.toLowerCase().contains('unit '))) {
        // Si ya teníamos texto acumulado, guardar sección previa
        if (currentBuffer.isNotEmpty) {
          final body = currentBuffer.join('\n').trim();
          if (body.isNotEmpty) {
            parsed.add(_StudySection(
              title: currentTitle,
              rawBody: body,
              icon: iconPool[iconIdx % iconPool.length],
            ));
            iconIdx++;
          }
          currentBuffer.clear();
        }

        // Nuevo título de sección limpio
        currentTitle = trimmed
            .replaceFirst(RegExp(r'^#{3,4}\s*'), '')
            .replaceAll(RegExp(r'\*+'), '')
            .trim();
      } else if (trimmed == '---') {
        // Separador horizontal, no agregarlo al texto crudo
        continue;
      } else {
        // Omitir título principal repetido de tipo "### Unit X: ..."
        if (trimmed.startsWith('### Unit ') || trimmed.startsWith('## Unit ')) {
          continue;
        }
        currentBuffer.add(line);
      }
    }

    // Agregar la última sección acumulada
    if (currentBuffer.isNotEmpty) {
      final body = currentBuffer.join('\n').trim();
      if (body.isNotEmpty) {
        parsed.add(_StudySection(
          title: currentTitle,
          rawBody: body,
          icon: iconPool[iconIdx % iconPool.length],
        ));
      }
    }

    // Si no se encontró ninguna sección con ####, crear una única sección
    if (parsed.isEmpty) {
      parsed.add(_StudySection(
        title: 'Guía de Estudio',
        rawBody: raw,
        icon: Icons.menu_book_rounded,
      ));
    }

    _sections = parsed;
  }

  @override
  Widget build(BuildContext context) {
    if (_sections.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final currentSection = _sections[_currentSectionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── 1. BARRA SUPERIOR: PESTAÑAS DE SECCIONES (TABS) ─────────────
        if (_sections.length > 1) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(_sections.length, (idx) {
                  final sec = _sections[idx];
                  final isSelected = idx == _currentSectionIndex;

                  // Cortar título si es muy largo para la pestaña
                  String tabLabel = sec.title;
                  if (tabLabel.length > 28) {
                    tabLabel = '${tabLabel.substring(0, 26)}...';
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _currentSectionIndex = idx),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 8 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4F46E5).withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              sec.icon,
                              size: isMobile ? 15 : 17,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tabLabel,
                              style: TextStyle(
                                fontSize: isMobile ? 12.5 : 13.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ─── 2. TARJETA PRINCIPAL DEL CONTENIDO VISUAL ────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 18 : 24),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera de la Sección Activa
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 18 : 24,
                  vertical: isMobile ? 14 : 18,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A).withOpacity(0.6) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isMobile ? 17 : 23),
                    topRight: Radius.circular(isMobile ? 17 : 23),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(currentSection.icon, color: const Color(0xFF6366F1), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_sections.length > 1)
                            Text(
                              'PARTE ${_currentSectionIndex + 1} DE ${_sections.length}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          Text(
                            currentSection.title,
                            style: TextStyle(
                              fontSize: isMobile ? 15 : 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Cuerpo con Renderizado Visual Limpio (Sin Markdown crudo)
              Padding(
                padding: EdgeInsets.all(isMobile ? 18.0 : 26.0),
                child: _SectionContentRenderer(
                  rawContent: currentSection.rawBody,
                  isDark: isDark,
                  isMobile: isMobile,
                ),
              ),

              // Pie de la tarjeta: Botones de navegación (Anterior / Siguiente / Ir a Práctica)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A).withOpacity(0.3) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(isMobile ? 17 : 23),
                    bottomRight: Radius.circular(isMobile ? 17 : 23),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón Anterior
                    if (_currentSectionIndex > 0)
                      TextButton.icon(
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(isMobile ? 'Anterior' : 'Sección Anterior'),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        onPressed: () {
                          setState(() => _currentSectionIndex--);
                        },
                      )
                    else
                      const SizedBox.shrink(),

                    // Botón Siguiente o Ir a Práctica
                    if (_currentSectionIndex < _sections.length - 1)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: Text(isMobile ? 'Siguiente' : 'Siguiente Sección'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 22,
                            vertical: isMobile ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          setState(() => _currentSectionIndex++);
                        },
                      )
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                        label: const Text('¡Comenzar Práctica!'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 18 : 24,
                            vertical: isMobile ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          shadowColor: const Color(0xFF10B981).withOpacity(0.4),
                        ),
                        onPressed: widget.onStartPractice,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── RENDERIZADOR VISUAL DE BLOQUES DE CONTENIDO ────────────────────────────
class _SectionContentRenderer extends StatelessWidget {
  final String rawContent;
  final bool isDark;
  final bool isMobile;

  const _SectionContentRenderer({
    required this.rawContent,
    required this.isDark,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(rawContent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) => _buildBlockWidget(block, context)).toList(),
    );
  }

  List<_ContentBlock> _parseBlocks(String text) {
    final lines = text.split('\n');
    final List<_ContentBlock> blocks = [];
    final List<String> textAccumulator = [];

    void flushText() {
      if (textAccumulator.isNotEmpty) {
        final body = textAccumulator.join('\n').trim();
        if (body.isNotEmpty) {
          blocks.add(_ContentBlock(type: _BlockType.paragraph, lines: [body]));
        }
        textAccumulator.clear();
      }
    }

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // 1. Detectar Tabla Markdown (| col1 | col2 |)
      if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
        flushText();
        final List<String> tableLines = [];
        while (i < lines.length && lines[i].trim().startsWith('|') && lines[i].trim().endsWith('|')) {
          tableLines.add(lines[i].trim());
          i++;
        }
        blocks.add(_ContentBlock(type: _BlockType.table, lines: tableLines));
        continue;
      }

      // 2. Detectar Callout / Caja de Nota Importante (*Nota:*, > , ¡Importante!)
      if (trimmed.toLowerCase().startsWith('*nota:*') ||
          trimmed.toLowerCase().startsWith('nota:') ||
          trimmed.toLowerCase().contains('¡muy importante!') ||
          trimmed.toLowerCase().contains('¡importante!')) {
        flushText();
        blocks.add(_ContentBlock(type: _BlockType.callout, lines: [trimmed]));
        i++;
        continue;
      }

      // 3. Detectar Viñeta con Ejemplo Destacado (e.g. "- *a cat* (un gato)")
      if (trimmed.startsWith('- *') || trimmed.startsWith('* *') || (trimmed.startsWith('- ') && trimmed.contains('(') && trimmed.contains(')'))) {
        flushText();
        blocks.add(_ContentBlock(type: _BlockType.examplePill, lines: [trimmed]));
        i++;
        continue;
      }

      // 4. Detectar Título de regla numerada (e.g. "1. **Cuando la letra H es MUDA:**")
      if (RegExp(r'^\d+\.\s+\*\*').hasMatch(trimmed)) {
        flushText();
        blocks.add(_ContentBlock(type: _BlockType.ruleHeader, lines: [trimmed]));
        i++;
        continue;
      }

      // 5. Detectar viñeta normal
      if (trimmed.startsWith('* ') || trimmed.startsWith('- ')) {
        flushText();
        blocks.add(_ContentBlock(type: _BlockType.bullet, lines: [trimmed]));
        i++;
        continue;
      }

      // Texto de párrafo acumulado
      if (trimmed.isNotEmpty) {
        textAccumulator.add(line);
      } else {
        flushText();
      }
      i++;
    }

    flushText();
    return blocks;
  }

  Widget _buildBlockWidget(_ContentBlock block, BuildContext context) {
    switch (block.type) {
      case _BlockType.table:
        return _buildTableWidget(block.lines);

      case _BlockType.callout:
        return _buildCalloutWidget(block.lines.first);

      case _BlockType.examplePill:
        return _buildExamplePillWidget(block.lines.first);

      case _BlockType.ruleHeader:
        return _buildRuleHeaderWidget(block.lines.first);

      case _BlockType.bullet:
        return _buildBulletWidget(block.lines.first);

      case _BlockType.paragraph:
        return _buildParagraphWidget(block.lines.first);
    }
  }

  // ─── TABLA ESTILIZADA ──────────────────────────────────────────────────────
  Widget _buildTableWidget(List<String> tableLines) {
    if (tableLines.isEmpty) return const SizedBox.shrink();

    // Extraer cabecera y filas (omitir separador |:---|:---|)
    final rows = tableLines.where((l) => !RegExp(r'^[\|\s\-\:\+]+$').hasMatch(l)).toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    final headerCols = rows.first
        .split('|')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    final dataRows = rows.skip(1).map((r) {
      return r
          .split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFF4F46E5),
            ),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              return isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white;
            }),
            columnSpacing: isMobile ? 18 : 28,
            horizontalMargin: 16,
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            columns: headerCols
                .map((col) => DataColumn(
                      label: Text(
                        col.replaceAll(RegExp(r'\*+'), ''),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ))
                .toList(),
            rows: dataRows.map((cols) {
              return DataRow(
                cells: cols.map((cellText) {
                  return DataCell(
                    _RichFormattedText(
                      text: cellText,
                      isDark: isDark,
                      fontSize: 13,
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ─── CAJA DE NOTA O ALERTA DESTACADA ───────────────────────────────────────
  Widget _buildCalloutWidget(String line) {
    final cleanText = line.replaceFirst(RegExp(r'^\*?[Nn]ota:?\*?\s*'), '');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF451A03).withOpacity(0.5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFFD97706).withOpacity(0.6) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DATO CLAVE / NOTA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 3),
                _RichFormattedText(
                  text: cleanText,
                  isDark: isDark,
                  fontSize: 13.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TARJETA/CHIP DE EJEMPLO DESTACADO ─────────────────────────────────────
  Widget _buildExamplePillWidget(String line) {
    final clean = line.replaceFirst(RegExp(r'^[\*\-\s]+'), '');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 10),
          Flexible(
            child: _RichFormattedText(
              text: clean,
              isDark: isDark,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─── CABECERA DE REGLA O NUMERAL ───────────────────────────────────────────
  Widget _buildRuleHeaderWidget(String line) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _RichFormattedText(
              text: line,
              isDark: isDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── VIÑETA REGULAR ────────────────────────────────────────────────────────
  Widget _buildBulletWidget(String line) {
    final clean = line.replaceFirst(RegExp(r'^[\*\-\s]+'), '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: _RichFormattedText(
              text: clean,
              isDark: isDark,
              fontSize: 14.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── PÁRRAFO REGULAR ───────────────────────────────────────────────────────
  Widget _buildParagraphWidget(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _RichFormattedText(
        text: text,
        isDark: isDark,
        fontSize: 14.5,
        height: 1.6,
      ),
    );
  }
}

// ─── FORMATEADOR INLINE DE TEXTO (Negrita, Cursiva, Resaltados) ─────────────
class _RichFormattedText extends StatelessWidget {
  final String text;
  final bool isDark;
  final double fontSize;
  final double height;
  final FontWeight fontWeight;

  const _RichFormattedText({
    required this.text,
    required this.isDark,
    this.fontSize = 14,
    this.height = 1.5,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    final spans = _parseSpans(text);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          height: height,
          fontWeight: fontWeight,
          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
        ),
        children: spans,
      ),
    );
  }

  List<InlineSpan> _parseSpans(String raw) {
    final List<InlineSpan> spans = [];
    final pattern = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)');
    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(raw)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: raw.substring(lastMatchEnd, match.start)));
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        // Negrita
        final clean = matchedText.substring(2, matchedText.length - 2);
        spans.add(TextSpan(
          text: clean,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*')) {
        // Cursiva / Destacado en color
        final clean = matchedText.substring(1, matchedText.length - 1);
        spans.add(TextSpan(
          text: clean,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
          ),
        ));
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`')) {
        // Código / Término
        final clean = matchedText.substring(1, matchedText.length - 1);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              clean,
              style: TextStyle(
                fontSize: fontSize * 0.9,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.amber[300] : const Color(0xFF1E293B),
              ),
            ),
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < raw.length) {
      spans.add(TextSpan(text: raw.substring(lastMatchEnd)));
    }

    return spans;
  }
}

enum _BlockType {
  paragraph,
  bullet,
  examplePill,
  ruleHeader,
  callout,
  table,
}

class _ContentBlock {
  final _BlockType type;
  final List<String> lines;

  _ContentBlock({required this.type, required this.lines});
}
