// message should have role, content, timestamp
import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable()
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

  // connect to json
  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
