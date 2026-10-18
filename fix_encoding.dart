import 'dart:io';

void main() {
  final file = File('lib/screens/quiz_screen.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll('AÃƒÆ’Ã‚Âºn no hay', 'Aún no hay');
  content = content.replaceAll('lecciÃƒÆ’Ã‚Â³n', 'lección');
  content = content.replaceAll('Ã‚Â¡Excelente Trabajo!', '¡Excelente Trabajo!');
  content = content.replaceAll('PuntuaciÃƒÆ’Ã‚Â³n', 'Puntuación');
  content = content.replaceAll('GuÃƒÆ’Ã‚Âa', 'Guía');
  content = content.replaceAll('Ã‚Â¡Correcto!', '¡Correcto!');

  file.writeAsStringSync(content);
  print('Fixed encoding issues');
}
