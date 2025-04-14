class ChatReport {
  final String id;
  final String content;
  final DateTime timestamp;
  final String type;
  final String patientId;
  final String doctorId;

  ChatReport({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.type,
    required this.patientId,
    required this.doctorId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'patientId': patientId,
      'doctorId': doctorId,
    };
  }

  factory ChatReport.fromJson(Map<String, dynamic> json) {
    return ChatReport(
      id: json['id'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'],
      patientId: json['patientId'],
      doctorId: json['doctorId'],
    );
  }
}
