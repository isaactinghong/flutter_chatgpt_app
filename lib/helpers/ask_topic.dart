// _askTopic, ask OpenAI to give a topic for the conversation
// inputs are the messages in the conversation
// output is a topic for the conversation
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_chat/app_provider.dart';
import 'package:flutter_chat/main.dart';
import 'package:provider/provider.dart';

import '../conversation_provider.dart';

Future<String?> askTopic({
  required List<Map<String, String>> messages,
  required BuildContext context,
  required http.Client client,
}) async {
  final url = Uri.parse('https://api.openai.com/v1/chat/completions');
  final apiKey =
      Provider.of<ConversationProvider>(context, listen: false).yourapikey;
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };

  // add a message to tell OpenAI to give a topic
  var bodyMessages = [
    {
      'role': 'system',
      'content': '''Give me a conversation title based on our messages.
          Only give the title text.
          The title should be short and clear.
          The title should not exceed 20 words.
          Do not start with "Conversation Title:" or "Topic:" or "The topic of this conversation is".
          Do not end with something like "would be a potential conversation title for your messages".
          Do not end with a period character.
          Do not use quotation mark to quote the entire title.
          If you are not sure, just give the title: Unclear topic.''',
    }
  ];
  // add all messages into bodyMessages
  bodyMessages.addAll(messages);

  log.d('messages for askTopic: $bodyMessages');

  // send all current conversation to OpenAI
  final body = {
    // use AppProvider.gptModel as model name
    'model': Provider.of<AppProvider>(context, listen: false).gptModel,
    'messages': bodyMessages,
  };

  try {
    final response =
        await client.post(url, headers: headers, body: json.encode(body));

    log.d('openai response: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final completions = data['choices'] as List<dynamic>;
      if (completions.isNotEmpty) {
        final completion = completions[0];
        final content = completion['message']['content'] as String;

        final decodedContent = utf8.decode(content.codeUnits);

        // delete all the prefix '\n' in content
        return decodedContent.replaceFirst(RegExp(r'^\n+'), '');
      }
    }
  } catch (e) {
    log.e('_askTopic error: $e');

    // return the error message
    return 'Error: $e';
  }
  return null;
}
