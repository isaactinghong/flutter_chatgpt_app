import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'construct_conversation_text.dart';

void copyConversationToClipboard(
  BuildContext context,
) {
  // constructConversationText
  ConversationText conversationText = constructConversationText(context);

  // copy to clipboard
  Clipboard.setData(ClipboardData(text: conversationText.text));

  // show snackbar
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied this conversation to clipboard'),
      ),
    );
  }
}
