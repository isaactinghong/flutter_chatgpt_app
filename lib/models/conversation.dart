// conversations include multiple messages
import 'package:json_annotation/json_annotation.dart';

import 'message.dart';

part 'conversation.g.dart';

@JsonSerializable()
class Conversation {
  final List<Message> messages;
  String title;

  Conversation({required this.messages, required this.title});

  // connect to json
  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationToJson(this);
}
