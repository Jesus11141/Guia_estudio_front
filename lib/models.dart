class Institution {
  final String id;
  final String name;
  final String? logoUrl;

  Institution({required this.id, required this.name, this.logoUrl});

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id'],
      name: json['name'],
      logoUrl: json['logoUrl'] ?? json['logo_url'],
    );
  }
}

class User {
  final String id;
  final String email;
  final String role;
  final String? avatar;
  final int stars;
  final bool hasGames;
  final List<String> unlockedAvatars;
  final String? name;
  final String? institutionId;
  final String? gradeId;
  final Institution? institution;

  User({
    required this.id, 
    required this.email, 
    required this.role,
    this.avatar,
    this.stars = 0,
    this.hasGames = true,
    this.unlockedAvatars = const [],
    this.name,
    this.institutionId,
    this.gradeId,
    this.institution,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      avatar: json['avatar'],
      stars: json['stars'] ?? 0,
      hasGames: json['hasGames'] ?? json['has_games'] ?? true,
      unlockedAvatars: (json['unlockedAvatars'] as List?)?.map((e) => e.toString()).toList() ??
                       (json['unlocked_avatars'] as List?)?.map((e) => e.toString()).toList() ??
                       const [],
      name: json['name'],
      institutionId: json['institutionId'] ?? json['institution_id'],
      gradeId: json['gradeId'] ?? json['grade_id'],
      institution: json['institution'] != null ? Institution.fromJson(json['institution']) : null,
    );
  }
}

class Grade {
  final String id;
  final String name;
  final String educationLevel;

  Grade({required this.id, required this.name, required this.educationLevel});

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      educationLevel: json['education_level'] ?? json['educationLevel'] ?? '',
    );
  }
}

class Subject {
  final String id;
  final String name;
  final String gradeId;

  Subject({required this.id, required this.name, required this.gradeId});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      gradeId: json['grade_id'] ?? json['gradeId'] ?? '',
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String content;
  final String subjectId;

  Lesson({required this.id, required this.title, required this.content, required this.subjectId});

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      subjectId: json['subject_id'] ?? json['subjectId'] ?? '',
    );
  }
}

class Question {
  final String id;
  final String lessonId;
  final String type;
  final Map<String, dynamic>? metadata;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final String? explanation;

  Question({
    required this.id,
    required this.lessonId,
    this.type = 'MULTIPLE_CHOICE',
    this.metadata,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      lessonId: json['lesson_id'] ?? json['lessonId'] ?? '',
      type: json['type'] ?? 'MULTIPLE_CHOICE',
      metadata: json['metadata'],
      questionText: json['question_text'] ?? json['questionText'] ?? '',
      optionA: json['option_a'] ?? json['optionA'] ?? '',
      optionB: json['option_b'] ?? json['optionB'] ?? '',
      optionC: json['option_c'] ?? json['optionC'] ?? '',
      optionD: json['option_d'] ?? json['optionD'] ?? '',
      correctOption: json['correct_option'] ?? json['correctOption'] ?? '',
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'type': type,
      'metadata': metadata,
      'questionText': questionText,
      'optionA': optionA,
      'optionB': optionB,
      'optionC': optionC,
      'optionD': optionD,
      'correctOption': correctOption,
      'explanation': explanation,
    };
  }
}

class Book {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String fileUrl;
  final String? institutionId;
  final String category;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    required this.fileUrl,
    this.institutionId,
    this.category = 'General',
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      description: json['description'],
      fileUrl: json['fileUrl'],
      institutionId: json['institutionId'],
      category: json['category'] ?? 'General',
    );
  }
}

class Score {
  final String id;
  final int score;
  final int totalQuestions;
  final String userName;
  final String userGrade;
  final String lessonTitle;
  final String subjectName;
  final String createdAt;

  Score({
    required this.id,
    required this.score,
    required this.totalQuestions,
    required this.userName,
    required this.userGrade,
    required this.lessonTitle,
    required this.subjectName,
    required this.createdAt,
  });

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      id: json['id'] ?? '',
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? json['total_questions'] ?? 1,
      userName: json['user']?['name'] ?? 'Desconocido',
      userGrade: json['user']?['grade']?['name'] ?? 'Sin Grado',
      lessonTitle: json['lesson']?['title'] ?? 'Sin Título',
      subjectName: json['lesson']?['subject']?['name'] ?? 'Sin Materia',
      createdAt: json['createdAt'] ?? json['created_at'] ?? '',
    );
  }
}

class Reward {
  final String id;
  final String name;
  final int cost;
  final String? imageUrl;
  final String? institutionId;

  Reward({
    required this.id,
    required this.name,
    required this.cost,
    this.imageUrl,
    this.institutionId,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      name: json['name'],
      cost: json['cost'],
      imageUrl: json['imageUrl'],
      institutionId: json['institutionId'],
    );
  }
}

class RewardClaim {
  final String id;
  final String userId;
  final String rewardId;
  final String status;
  final Reward? reward;
  final User? user;
  final DateTime? createdAt;

  RewardClaim({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.status,
    this.reward,
    this.user,
    this.createdAt,
  });

  factory RewardClaim.fromJson(Map<String, dynamic> json) {
    return RewardClaim(
      id: json['id'],
      userId: json['userId'],
      rewardId: json['rewardId'],
      status: json['status'],
      reward: json['reward'] != null ? Reward.fromJson(json['reward']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}
