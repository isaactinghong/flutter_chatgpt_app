import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../conversation_provider.dart';

class ConversationText {
  String title;
  String text;

  ConversationText({required this.title, required this.text});
}

/// constructConversationText
ConversationText constructConversationText(BuildContext context) {
// allow user to export conversation to clipboard
  final conversationProvider =
      Provider.of<ConversationProvider>(context, listen: false);

  // get current conversation
  final currentConversation = conversationProvider.currentConversation;

  // get current conversation title
  final currentConversationTitle = currentConversation.title;

  // get current conversation messages
  final currentConversationMessages = currentConversation.messages;

  // construct the conversation string
  String conversationString = 'Title: $currentConversationTitle\n\n';

  for (var message in currentConversationMessages) {
    var senderName = message.senderId;
    if (message.senderId == 'System') {
      senderName = 'ChatGPT';
    } else {
      senderName = 'You';
    }

    // add a  "-----" style divider
    conversationString = '$conversationString\n-----------------\n';

    conversationString =
        '$conversationString$senderName: \n${message.content}\n\n';
  }

  return ConversationText(
    title: currentConversationTitle,
    text: conversationString,
  );
}
