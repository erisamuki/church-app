class Communication {
  final String id;
  final String subject;
  final String message;
  final String type;
  final String status;
  final DateTime sentAt;

  Communication({
    required this.id,
    required this.subject,
    required this.message,
    required this.type,
    required this.status,
    required this.sentAt,
  });

  factory Communication.fromJson(Map<String, dynamic> json) {
    return Communication(
      id: json['_id'] ?? json['id'] ?? '',
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'announcement',
      status: json['status'] ?? 'sent',
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'message': message,
      'type': type,
      'status': status,
      'sentAt': sentAt.toIso8601String(),
    };
  }
}
