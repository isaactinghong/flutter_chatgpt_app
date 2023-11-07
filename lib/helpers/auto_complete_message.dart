// autoCompleteMessage, ask OpenAI to give a topic for the conversation
// inputs are the messages in the conversation
// output is a topic for the conversation
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_chat/app_provider.dart';
import 'package:flutter_chat/main.dart';
import 'package:provider/provider.dart';

import '../conversation_provider.dart';

Future<String?> autoCompleteMessage({
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
      'content': '''
you are auto-complete assistant for the user. please help me extend or finish off my last sentence
Try to suggest in my perspective.
just give me the suggestion beginning right from the cursor position of my input.
include the initial space character for the sentence if there should be one.
only give me at maximum 5 words.
''',
    }
  ];

  // add all messages into bodyMessages
  bodyMessages.addAll(messages);

  log.d('messages for autoCompleteMessage: $bodyMessages');

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
    log.e('autoCompleteMessage error: $e');

    // return the error message
    return 'Error: $e';
  }
  return null;
}
