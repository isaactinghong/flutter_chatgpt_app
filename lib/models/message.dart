// message should have role, content, timestamp
class Message {
  final String content;
  final DateTime timestamp;
  // sender id
  final String senderId;
  final bool isLoading;

  Message({
    required this.senderId,
    DateTime? timestamp,
    this.content = '',
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
