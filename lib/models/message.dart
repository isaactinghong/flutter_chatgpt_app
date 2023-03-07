// message should have role, content, timestamp
class Message {
  final String content;
  final DateTime timestamp;
  // sender id
  final String senderId;

  Message({required this.content, required this.senderId, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}
