import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'models.dart';
import 'conversation_provider.dart';
import 'change_api_key_dialog.dart';
import 'models/message.dart';
import 'models/sender.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final http.Client _client = http.Client();
  final FocusNode _focusNode = FocusNode();
  bool _isBottom = true;

  @override
  void dispose() {
    _client.close();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  // constructUserMessage, construct a Message object from user
  // input is the text from user
  // output is a Message object
  Message constructUserMessage(String text) {
    return Message(senderId: userSender.id, content: text);
  }

  // constructAssistantMessage, construct a Message object from assistant
  // input is the text from assistant
  // output is a Message object
  Message constructAssistantMessage(String text, {bool isLoading = false}) {
    return Message(
        senderId: systemSender.id, content: text, isLoading: isLoading);
  }

  // _askTopic, ask OpenAI to give a topic for the conversation
  // inputs are the messages in the conversation
  // output is a topic for the conversation
  Future<String?> _askTopic(List<Map<String, String>> messages) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final apiKey =
        Provider.of<ConversationProvider>(context, listen: false).yourapikey;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    // add a message to tell OpenAI to give a topic
    messages.add({
      'role': 'user',
      'content': '''Give me a conversation title based on our messages.
          Only give the title text.
          The title should be short and clear.
          The title should not exceed 20 words.
          Do not start with "Conversation Title:" or "Topic:" or "The topic of this conversation is".
          Do not end with something like "would be a potential conversation title for your messages".
          Do not end with a period character.
          If you are not sure, just give the title "Unclear topic".''',
    });

    print('messages for askTopic: $messages');

    // send all current conversation to OpenAI
    final body = {
      'model': model,
      'messages': messages,
    };
    final response =
        await _client.post(url, headers: headers, body: json.encode(body));

    print('openai response: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final completions = data['choices'] as List<dynamic>;
      if (completions.isNotEmpty) {
        final completion = completions[0];
        final content = completion['message']['content'] as String;
        // delete all the prefix '\n' in content
        return content.replaceFirst(RegExp(r'^\n+'), '');
      }
    }
    return null;
  }

  // Send message to OpenAI
  Future<Message?> _sendMessage(List<Map<String, String>> messages) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final apiKey =
        Provider.of<ConversationProvider>(context, listen: false).yourapikey;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    // send all current conversation to OpenAI
    final body = {
      'model': model,
      'messages': messages,
    };
    final response =
        await _client.post(url, headers: headers, body: json.encode(body));

    print('openai response: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final completions = data['choices'] as List<dynamic>;
      if (completions.isNotEmpty) {
        final completion = completions[0];
        final content = completion['message']['content'] as String;
        // delete all the prefix '\n' in content
        final contentWithoutPrefix = content.replaceFirst(RegExp(r'^\n+'), '');

        final decodedContent = utf8.decode(contentWithoutPrefix.codeUnits);

        return constructAssistantMessage(decodedContent);
      }
    } else {
      // invalid api key
      // create a new dialog
      return constructAssistantMessage('''Invalid.
Status code: ${response.statusCode}.
Error: ${response.body}''');
    }
    return null;
  }

  // scroll to bottom
  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  void _sendMessageAndAddToChat() async {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _textController.clear();
      _focusNode.requestFocus();

      final userMessage = constructUserMessage(text);
      final assistantLoadingMessage = constructAssistantMessage(
        'Loading...',
        isLoading: true,
      );

      int assistantMessageIndex = -1;
      ConversationProvider provider =
          Provider.of<ConversationProvider>(context, listen: false);
      // add to current conversation
      provider.addMessage(userMessage);
      assistantMessageIndex =
          await provider.addMessage(assistantLoadingMessage);
      // setState to rebuild the listview
      setState(() {});

      // scroll to last message after small delay
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();

      if (context.mounted) {
        final providerInner =
            Provider.of<ConversationProvider>(context, listen: false);
        _sendMessage(providerInner.currentConversationMessages)
            .then((assistantMessage) async {
          if (assistantMessage != null) {
            setState(() {
              Provider.of<ConversationProvider>(context, listen: false)
                  .modifyMessage(assistantMessageIndex, assistantMessage);
            });
            // scroll to last message after small delay
            await Future.delayed(const Duration(milliseconds: 100));
            _scrollToBottom();

            // ask for a topic
            final topic =
                await _askTopic(providerInner.currentConversationMessages);

            if (topic != null) {
              // modify the conversation title
              providerInner.changeConversationTitle(topic);
            }
          }
        });
      }
    }
  }

  // onSubmitMessage
  void _onSubmitMessage() {
    // listen to apikey to see if changed
    Provider.of<ConversationProvider>(context, listen: false).yourapikey ==
            "YOUR_API_KEY"
        ? showChangeAPIKeyDialog(context)
        : _sendMessageAndAddToChat();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      // resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: Consumer<ConversationProvider>(
              builder: (context, conversationProvider, child) {
                return NotificationListener(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification) {
                      setState(() => _isBottom =
                          _scrollController.position.extentAfter == 0);
                    }
                    return true;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: conversationProvider.currentConversationLength,
                    itemBuilder: (BuildContext context, int index) {
                      Message message = conversationProvider
                          .currentConversation.messages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.senderId != userSender.id)
                              CircleAvatar(
                                backgroundImage:
                                    AssetImage(systemSender.avatarAssetPath),
                                radius: 16.0,
                              )
                            else
                              const SizedBox(width: 24.0),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Align(
                                alignment: message.senderId == userSender.id
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  decoration: BoxDecoration(
                                    color: message.senderId == userSender.id
                                        ? Color(0xff55bb8e)
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Builder(builder: (context) {
                                    if (message.isLoading) {
                                      return const SizedBox(
                                        height: 16.0,
                                        width: 16.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                        ),
                                      );
                                    }
                                    return SelectableText(
                                      message.content,
                                      style: TextStyle(
                                        color: message.senderId == userSender.id
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            if (message.senderId == userSender.id)
                              CircleAvatar(
                                backgroundImage:
                                    AssetImage(userSender.avatarAssetPath),
                                radius: 16.0,
                              )
                            else
                              const SizedBox(width: 24.0),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // input box
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(32.0),
            ),
            margin:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _focusNode.requestFocus(),
                    child: TextField(
                      minLines: 1,
                      maxLines: 6,
                      autofocus: true,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      controller: _textController,
                      decoration: const InputDecoration.collapsed(
                          hintText: 'Type your message...'),
                      onSubmitted: (_) => _onSubmitMessage(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _onSubmitMessage,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,

      // add floating action button, position it at the bottom right, above the send message box
      // do not show it if it's already at the bottom
      floatingActionButton: _isBottom
          ? null
          : FloatingActionButton(
              onPressed: _scrollToBottom,
              child: const Icon(Icons.arrow_downward),
            ),
    );

    // GestureDetector(
    //   onTap: () => FocusScope.of(context).unfocus(),
    //   onVerticalDragDown: (_) => FocusScope.of(context).unfocus(),
    //   child:
    // );
  }
}
