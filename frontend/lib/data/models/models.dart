// Data Models for CampusSync Flutter App

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? department;
  final String? className;
  final String? section;
  final String? rollNumber;
  final String? profileImage;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.className,
    this.section,
    this.rollNumber,
    this.profileImage,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role']?.toString().trim().toLowerCase() ?? 'student',
      department: json['department'] is Map ? json['department']['name'] : json['department']?.toString(),
      className: json['className'],
      section: json['section'],
      rollNumber: json['rollNumber'],
      profileImage: json['profileImage'],
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'role': role,
    'department': department, 'className': className,
    'section': section, 'rollNumber': rollNumber,
    'profileImage': profileImage, 'avatarUrl': avatarUrl,
  };

  String get displayAvatar => avatarUrl ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=1565C0&color=fff';
}

class ReminderModel {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String category;
  final String status;
  final bool isPinned;
  final List<String> tags;
  final Map<String, dynamic> targetAudience;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? deadlineAt;
  final UserModel? createdBy;
  final List<AttachmentModel> attachments;
  final int? readCount;
  final bool isRead;
  final String? notificationId;

  const ReminderModel({
    required this.id, required this.title, required this.description,
    required this.priority, required this.category, required this.status,
    required this.isPinned, required this.tags, required this.targetAudience,
    required this.createdAt, this.scheduledAt, this.deadlineAt, this.createdBy,
    this.attachments = const [], this.readCount, this.isRead = false,
    this.notificationId,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'normal',
      category: json['category'] ?? 'reminder',
      status: json['status'] ?? 'sent',
      isPinned: json['isPinned'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      targetAudience: Map<String, dynamic>.from(json['targetAudience'] ?? {}),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      scheduledAt: json['scheduledAt'] != null ? DateTime.tryParse(json['scheduledAt']) : null,
      deadlineAt: json['deadlineAt'] != null ? DateTime.tryParse(json['deadlineAt']) : null,
      createdBy: json['createdBy'] is Map<String, dynamic> ? UserModel.fromJson(json['createdBy']) : null,
      attachments: (json['attachments'] as List?)?.map((a) => AttachmentModel.fromJson(a)).toList() ?? [],
      readCount: json['readCount'],
      isRead: json['isRead'] ?? false,
      notificationId: json['notificationId'],
    );
  }
}

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String? subject;
  final DateTime dueDate;
  final Map<String, dynamic> targetAudience;
  final bool isCompleted;
  final bool isPending;
  final bool isOverdue;
  final List<AttachmentModel> attachments;
  final UserModel? createdBy;
  final int completedCount;
  final DateTime createdAt;

  const AssignmentModel({
    required this.id, required this.title, required this.description,
    required this.dueDate, required this.targetAudience, required this.isCompleted, 
    required this.isPending, required this.isOverdue,
    this.subject, this.attachments = const [], this.createdBy,
    this.completedCount = 0, required this.createdAt,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subject: json['subject'],
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      targetAudience: Map<String, dynamic>.from(json['targetAudience'] ?? {}),
      isCompleted: json['isCompleted'] ?? false,
      isPending: json['isPending'] ?? false,
      isOverdue: json['isOverdue'] ?? false,
      attachments: (json['attachments'] as List?)?.map((a) => AttachmentModel.fromJson(a)).toList() ?? [],
      createdBy: json['createdBy'] is Map<String, dynamic> ? UserModel.fromJson(json['createdBy']) : null,
      completedCount: (json['completedBy'] as List?)?.length ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Duration get timeUntilDue => dueDate.difference(DateTime.now());
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String priority;
  final bool readStatus;
  final DateTime deliveredAt;
  final DateTime? readAt;
  final String? reminderId;
  final String? assignmentId;

  const NotificationModel({
    required this.id, required this.title, required this.body,
    required this.type, required this.priority, required this.readStatus,
    required this.deliveredAt, this.readAt, this.reminderId, this.assignmentId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'reminder',
      priority: json['priority'] ?? 'normal',
      readStatus: json['readStatus'] ?? false,
      deliveredAt: DateTime.tryParse(json['deliveredAt'] ?? '') ?? DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
      reminderId: json['reminderId'] is Map ? json['reminderId']['_id'] : json['reminderId'],
      assignmentId: json['assignmentId'] is Map ? json['assignmentId']['_id'] : json['assignmentId'],
    );
  }
}

class AttachmentModel {
  final String originalName;
  final String url;
  final String? mimeType;
  final int? size;

  const AttachmentModel({required this.originalName, required this.url, this.mimeType, this.size});

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      originalName: json['originalName'] ?? 'file',
      url: json['url'] ?? '',
      mimeType: json['mimeType'],
      size: json['size'],
    );
  }

  bool get isPdf => mimeType?.contains('pdf') ?? originalName.endsWith('.pdf');
  bool get isImage => mimeType?.startsWith('image/') ?? ['jpg', 'jpeg', 'png', 'gif'].any((ext) => originalName.endsWith(ext));
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthResponse({required this.accessToken, required this.refreshToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: UserModel.fromJson(json['user']),
    );
  }
}
