import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

String get baseUrl {
  if (kReleaseMode) {
    return 'https://aprendeestudia.djhcode.com/api';
  }
  if (kIsWeb) return 'http://localhost:3000/api';
  if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
  return 'http://localhost:3000/api';
}

String? resolveImageUrl(String? rawUrl) {
  if (rawUrl == null || rawUrl.trim().isEmpty) return null;
  final trimmed = rawUrl.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    if (trimmed.contains('80.190.74.18:3001/uploads')) {
      return trimmed.replaceAll('http://80.190.74.18:3001', 'https://aprendeestudia.djhcode.com');
    }
    return trimmed;
  }
  final root = baseUrl.replaceAll('/api', '');
  if (trimmed.startsWith('/')) {
    return '$root$trimmed';
  }
  return '$root/$trimmed';
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        return User.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }
    return null;
  }

  Future<void> setUser(User? user, [String? token]) async {
    final prefs = ref.read(sharedPrefsProvider);
    if (user == null) {
      await prefs.remove('user');
      await prefs.remove('token');
    } else {
      await prefs.setString('user', jsonEncode({
        'id': user.id,
        'email': user.email,
        'role': user.role,
        'name': user.name,
        'avatar': user.avatar,
        'stars': user.stars,
        'hasGames': user.hasGames,
        'unlockedAvatars': user.unlockedAvatars,
        'institutionId': user.institutionId,
        'gradeId': user.gradeId,
        'institution': user.institution != null ? {
          'id': user.institution!.id,
          'name': user.institution!.name,
          'logoUrl': user.institution!.logoUrl,
        } : null
      }));
      if (token != null) {
        await prefs.setString('token', token);
      }
    }
    state = user;
  }
}
final authProvider = NotifierProvider<AuthNotifier, User?>(() => AuthNotifier());

final dioProvider = Provider((ref) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final prefs = ref.read(sharedPrefsProvider);
      final token = prefs.getString('token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        ref.read(authProvider.notifier).setUser(null);
      }
      return handler.next(error);
    }
  ));
  
  return dio;
});

final gradesProvider = FutureProvider<List<Grade>>((ref) async {
  ref.watch(authProvider); // Watch auth state to invalidate cache on login/logout
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/grades');
  return (response.data as List).map((e) => Grade.fromJson(e)).toList();
});

final subjectsProvider = FutureProvider.family<List<Subject>, String>((ref, gradeId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/subjects', queryParameters: {'gradeId': gradeId});
  return (response.data as List).map((e) => Subject.fromJson(e)).toList();
});

final usersProvider = FutureProvider<List<User>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/users');
  return (response.data as List).map((e) => User.fromJson(e)).toList();
});

final institutionsProvider = FutureProvider<List<Institution>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/institutions');
  return (response.data as List).map((json) => Institution.fromJson(json)).toList();
});

final lessonsProvider = FutureProvider.family<List<Lesson>, String>((ref, subjectId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/lessons', queryParameters: {'subjectId': subjectId});
  return (response.data as List).map((e) => Lesson.fromJson(e)).toList();
});

final questionsProvider = FutureProvider.family<List<Question>, String>((ref, lessonId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/lessons/$lessonId/questions');
  return (response.data as List).map((e) => Question.fromJson(e)).toList();
});

final questionsByTypeProvider = FutureProvider.family<List<Question>, String>((ref, type) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/questions/by-type/$type');
    return (response.data as List).map((e) => Question.fromJson(e)).toList();
  } catch (_) {
    return [];
  }
});

final booksProvider = FutureProvider<List<Book>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return [];

  final dio = ref.watch(dioProvider);
  final response = await dio.get('/books');

  if (response.statusCode == 200) {
    final List data = response.data;
    return data.map((json) => Book.fromJson(json)).toList();
  } else {
    throw Exception('Error al cargar libros');
  }
});


final scoresProvider = FutureProvider.family<List<Score>, String?>((ref, gradeId) async {
  final dio = ref.watch(dioProvider);
  final params = gradeId != null ? <String, dynamic>{'gradeId': gradeId} : null;
  final response = await dio.get('/scores', queryParameters: params);
  return (response.data as List).map((json) => Score.fromJson(json)).toList();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final prefs = ref.read(sharedPrefsProvider);
    final nextIsDark = state != ThemeMode.dark;
    await prefs.setBool('is_dark_mode', nextIsDark);
    state = nextIsDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setTheme(bool isDark) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool('is_dark_mode', isDark);
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() => ThemeModeNotifier());

