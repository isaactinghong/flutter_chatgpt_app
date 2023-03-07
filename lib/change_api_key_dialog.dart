import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'conversation_provider.dart';

void showChangeAPIKeyDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String newAPIKey = 'YOUR_API_KEY';
      return AlertDialog(
        title: const Text('API Setting'),
        content: TextField(
          // display the current name of the conversation
          decoration: InputDecoration(
              hintText: Provider.of<ConversationProvider>(context).yourapikey),
          onChanged: (value) {
            newAPIKey = value;
          },
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xff55bb8e),
              ),
            ),
            onPressed: () {
              if (newAPIKey == '') {
                Navigator.pop(context);
                return;
              }
              Provider.of<ConversationProvider>(context, listen: false)
                  .saveAPIKey(newAPIKey);

              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}
