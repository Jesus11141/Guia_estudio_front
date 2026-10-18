import 'package:flutter/material.dart';

class AvatarItem {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final int cost;
  final Color bgColor;
  final String title;

  const AvatarItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.cost,
    required this.bgColor,
    required this.title,
  });
}

class AvatarCatalog {
  static const List<AvatarItem> all = [
    // --- Gratuitos de Bienvenida (Costo 0) ---
    AvatarItem(
      id: 'avatar_astronaut',
      name: 'Astronauta',
      emoji: '🚀',
      category: 'Iniciales',
      cost: 0,
      bgColor: Color(0xFF6366F1),
      title: 'Explorador del Cosmos',
    ),
    AvatarItem(
      id: 'avatar_lion',
      name: 'Leoncito',
      emoji: '🦁',
      category: 'Iniciales',
      cost: 0,
      bgColor: Color(0xFFF59E0B),
      title: 'Valiente y Campeón',
    ),
    AvatarItem(
      id: 'avatar_cat',
      name: 'Gatita',
      emoji: '🐱',
      category: 'Iniciales',
      cost: 0,
      bgColor: Color(0xFFEC4899),
      title: 'Curiosa y Veloz',
    ),
    AvatarItem(
      id: 'avatar_dog',
      name: 'Perrito',
      emoji: '🐶',
      category: 'Iniciales',
      cost: 0,
      bgColor: Color(0xFF10B981),
      title: 'Amistoso y Leal',
    ),

    // --- Nivel Junior (15 a 25 Estrellas) ---
    AvatarItem(
      id: 'avatar_dino',
      name: 'Dino Rex',
      emoji: '🦖',
      category: 'Aventureros',
      cost: 15,
      bgColor: Color(0xFF059669),
      title: 'Fuerza Prehistórica',
    ),
    AvatarItem(
      id: 'avatar_fox',
      name: 'Zorrito',
      emoji: '🦊',
      category: 'Aventureros',
      cost: 15,
      bgColor: Color(0xFFEA580C),
      title: 'Astuto y Detective',
    ),
    AvatarItem(
      id: 'avatar_unicorn',
      name: 'Unicornio',
      emoji: '🦄',
      category: 'Fantasía',
      cost: 20,
      bgColor: Color(0xFFA855F7),
      title: 'Brillo y Magia',
    ),
    AvatarItem(
      id: 'avatar_dolphin',
      name: 'Delfín',
      emoji: '🐬',
      category: 'Aventureros',
      cost: 20,
      bgColor: Color(0xFF0284C7),
      title: 'Nadador Inteligente',
    ),
    AvatarItem(
      id: 'avatar_robot',
      name: 'Robot Científico',
      emoji: '🤖',
      category: 'Futuristas',
      cost: 25,
      bgColor: Color(0xFF0891B2),
      title: 'Mente Tecnológica',
    ),

    // --- Nivel Pro (30 a 50 Estrellas) ---
    AvatarItem(
      id: 'avatar_hero',
      name: 'Súper Héroe',
      emoji: '🦸',
      category: 'Héroes',
      cost: 30,
      bgColor: Color(0xFFDC2626),
      title: 'Protector del Saber',
    ),
    AvatarItem(
      id: 'avatar_panda',
      name: 'Panda Ninja',
      emoji: '🐼',
      category: 'Aventureros',
      cost: 35,
      bgColor: Color(0xFF334155),
      title: 'Paciencia y Maestría',
    ),
    AvatarItem(
      id: 'avatar_wizard',
      name: 'Mago Sabio',
      emoji: '🧙',
      category: 'Fantasía',
      cost: 40,
      bgColor: Color(0xFF7C3AED),
      title: 'Hechicero de Letras',
    ),
    AvatarItem(
      id: 'avatar_crown',
      name: 'Rey / Reina',
      emoji: '👑',
      category: 'Realeza',
      cost: 50,
      bgColor: Color(0xFFD97706),
      title: 'Monarca del Saber',
    ),

    // --- Nivel Legendario (60 a 75 Estrellas) ---
    AvatarItem(
      id: 'avatar_dragon',
      name: 'Dragón Guardián',
      emoji: '🐉',
      category: 'Legendarios',
      cost: 60,
      bgColor: Color(0xFF16A34A),
      title: 'Fuego del Conocimiento',
    ),
    AvatarItem(
      id: 'avatar_star',
      name: 'Estrella Dorada',
      emoji: '🌟',
      category: 'Legendarios',
      cost: 75,
      bgColor: Color(0xFFEAB308),
      title: 'Gran Maestro Estelar',
    ),
  ];

  static AvatarItem find(String? id) {
    if (id == null || id.isEmpty) return all.first;
    return all.firstWhere(
      (a) => a.id == id,
      orElse: () => AvatarItem(
        id: id,
        name: 'Estudiante',
        emoji: id.length <= 4 ? id : '🎓',
        category: 'Personalizado',
        cost: 0,
        bgColor: const Color(0xFF6366F1),
        title: 'Estudiante Estrella',
      ),
    );
  }
}
