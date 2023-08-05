import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat/main.dart';
import 'construct_conversation_text.dart';

void saveConversationAsTxt(
  BuildContext context,
) {
  // constructConversationText
  ConversationText conversationText = constructConversationText(context);

  // save to file
  saveToFile(conversationText, context);
}

void saveToFile(
  ConversationText conversationText,
  BuildContext context,
) async {
  // get current conversation title
  final currentConversationTitle = conversationText.title;

  // get current conversation messages
  final currentConversationMessages = conversationText.text;

  // currentConversationMessages to bytes
  Uint8List bytes =
      Uint8List.fromList(utf8.encode(currentConversationMessages));
  String filename = currentConversationTitle.replaceAll(' ', '_');

  // log all parameters: filename, bytes, extension, mimeType
  log.d('filename: $filename');
  log.d('bytes: $bytes');

  // prompt user to save file as, use file_saver
  // https://pub.dev/packages/file_saver
  final resultPath = await FileSaver.instance.saveFile(
    name: filename,
    bytes: bytes,
    ext: "txt",
    mimeType: MimeType.text,
  );

  // scaffoldMessenger to show snackbar
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved to $resultPath'),
      ),
    );
  }
}
