// conversations include multiple messages
import 'message.dart';

class Conversation {
  final List<Message> messages;
  String title;

  Conversation({required this.messages, required this.title});
}
