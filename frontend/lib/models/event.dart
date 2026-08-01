/// Maps to PostgreSQL schema: events (church events table)
class ChurchEvent {
  final String id;
  final String title;
  final String? description;
  final String
      eventType; // service, fellowship, outreach, conference, wedding, funeral, baptism, other
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final int? expectedAttendees;
  final int? actualAttendees;
  final String? ministry; // which department is organizing
  final String? organizerId; // user id of organizer
  final String status; // upcoming, ongoing, completed, cancelled, postponed
  final bool isRecurring;
  final String? recurrenceRule; // e.g., "weekly", "monthly"
  final String? coverImageUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ChurchEvent({
    required this.id,
    required this.title,
    this.description,
    required this.eventType,
    required this.location,
    required this.startDate,
    this.endDate,
    this.expectedAttendees,
    this.actualAttendees,
    this.ministry,
    this.organizerId,
    this.status = 'upcoming',
    this.isRecurring = false,
    this.recurrenceRule,
    this.coverImageUrl,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Display-friendly type label
  String get typeLabel {
    return eventType.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  /// Display-friendly status label
  String get statusLabel {
    return status[0].toUpperCase() + status.substring(1);
  }

  /// Formatted date range
  String get dateRange {
    final start = _formatDate(startDate);
    if (endDate == null) return start;
    final end = _formatDate(endDate!);
    if (_sameDay(startDate, endDate!)) {
      return '$start Â· ${_formatTime(startDate)} - ${_formatTime(endDate!)}';
    }
    return '$start - $end';
  }

  /// Just the day name
  String get dayName {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[startDate.weekday - 1];
  }

  /// Short date for cards: "28 Jul"
  String get shortDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${startDate.day} ${months[startDate.month - 1]}';
  }

  /// Is this event in the future?
  bool get isUpcoming => startDate.isAfter(DateTime.now());

  /// Is this event happening now?
  bool get isOngoing {
    final now = DateTime.now();
    if (endDate != null) {
      return startDate.isBefore(now) && endDate!.isAfter(now);
    }
    return _sameDay(startDate, now);
  }

  /// Attendance percentage
  double? get attendanceRate {
    if (expectedAttendees == null || actualAttendees == null) return null;
    if (expectedAttendees == 0) return 0;
    return (actualAttendees! / expectedAttendees!) * 100;
  }

  /// Days until event
  int get daysUntil {
    final now = DateTime.now();
    final eventDay = DateTime(startDate.year, startDate.month, startDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return eventDay.difference(today).inDays;
  }

  /// "In 3 days" / "Today" / "Tomorrow" / "Past"
  String get timeUntilLabel {
    if (daysUntil < 0) return 'Past';
    if (daysUntil == 0) return 'Today';
    if (daysUntil == 1) return 'Tomorrow';
    return 'In $daysUntil days';
  }

  factory ChurchEvent.fromJson(Map<String, dynamic> json) {
    return ChurchEvent(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'],
      eventType: json['event_type'] ?? json['type'] ?? 'other',
      location: json['location'] ?? '',
      startDate: _parseDate(json['start_datetime'] ?? json['start_date'] ?? json['date']),
      endDate: _parseDateNullable(json['end_datetime'] ?? json['end_date']),
      expectedAttendees: json['expected_attendees'],
      actualAttendees: json['actual_attendees'],
      ministry: json['ministry'] ?? json['department'],
      organizerId: json['organizer_id']?.toString(),
      status: json['status'] ?? 'upcoming',
      isRecurring: json['is_recurring'] ?? false,
      recurrenceRule: json['recurrence_rule'],
      coverImageUrl: json['cover_image_url'],
      notes: json['notes'],
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDateNullable(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_type': eventType,
      'location': location,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'expected_attendees': expectedAttendees,
      'actual_attendees': actualAttendees,
      'ministry': ministry,
      'organizer_id': organizerId,
      'status': status,
      'is_recurring': isRecurring,
      'recurrence_rule': recurrenceRule,
      'cover_image_url': coverImageUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    final json = toJson();
    json.remove('id');
    json.remove('created_at');
    json.remove('updated_at');
    json.remove('actual_attendees');
    return json;
  }

  ChurchEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? eventType,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    int? expectedAttendees,
    int? actualAttendees,
    String? ministry,
    String? organizerId,
    String? status,
    bool? isRecurring,
    String? recurrenceRule,
    String? coverImageUrl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChurchEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      expectedAttendees: expectedAttendees ?? this.expectedAttendees,
      actualAttendees: actualAttendees ?? this.actualAttendees,
      ministry: ministry ?? this.ministry,
      organizerId: organizerId ?? this.organizerId,
      status: status ?? this.status,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'ChurchEvent(id: $id, title: $title, date: $shortDate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChurchEvent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Private helpers
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.parse(value.toString());
  }

  static DateTime? _parseDateNullable(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value.toString());
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
