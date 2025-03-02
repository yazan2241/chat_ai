enum MessageType { text, audio, image, file }

class Message {
  final String id;
  final String text;
  final String? fileUrl;
  final String? fileName;
  final String time;
  final bool isFromMe;
  final DateTime timestamp;
  final MessageType type;

  Message({
    required this.id,
    required this.text,
    this.fileUrl,
    this.fileName,
    required this.time,
    required this.isFromMe,
    required this.timestamp,
    required this.type,
  });
}

class MessageGroup {
  final DateTime date;
  final List<Message> messages;
  final bool showDate;

  MessageGroup({
    required this.date,
    required this.messages,
    required this.showDate,
  });
}
