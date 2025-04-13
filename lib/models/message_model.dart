import 'dart:convert';

class Message {
  final String content;
  final String sender;
  final DateTime dateTime;

  Message({
    required this.content,
    required this.sender,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'content': content,
      'sender': sender,
      'dateTime': dateTime.millisecondsSinceEpoch,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      content: map['content'] as String,
      sender: map['sender'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory Message.fromJson(String source) =>
      Message.fromMap(json.decode(source) as Map<String, dynamic>);
}