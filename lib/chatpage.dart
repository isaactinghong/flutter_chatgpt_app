import 'dart:async';
import 'dart:io';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'conversation_provider.dart';
import 'change_api_key_dialog.dart';
import 'helpers/ask_topic.dart';
// import 'helpers/auto_complete_message.dart';
import 'helpers/copy_conversation_to_clipboard.dart';
import 'helpers/save_conversation_as_txt.dart';
import 'main.dart';
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
  bool _isBottom = true;

  /// textInputFocusEventEmitter, a EventEmitter from AppProvider
  late StreamController<void> textInputFocusEventEmitter;

  /// SuggestionsBoxController for TypeAheadFormField
  late SuggestionsBoxController suggestionsBoxController =
      SuggestionsBoxController();

  late final _focusNode = FocusNode(
    onKey: (FocusNode node, RawKeyEvent evt) {
      // if the key pressed is Escape, unfocus the textfield and hide the suggestions box
      if (evt.logicalKey.keyLabel == 'Escape') {
        if (evt is RawKeyDownEvent) {
          node.unfocus();
          suggestionsBoxController.close();
        }
        return KeyEventResult.handled;
      }
      // else if the key is up, move the selection up
      else if (evt.logicalKey.keyLabel == 'ArrowUp') {
        if (evt is RawKeyDownEvent) {
          suggestionsBoxController.open();
        }
        return KeyEventResult.handled;
      }

      // if the key pressed is others, show the suggestions box
      // suggestionsBoxController.open();

      if (!evt.isShiftPressed && evt.logicalKey.keyLabel == 'Enter') {
        if (evt is RawKeyDownEvent) {
          _onSubmitMessage();
        }
        return KeyEventResult.handled;
        // else, if shift is pressed and enter is pressed
        // add newline to text
      } else if (evt.isShiftPressed && evt.logicalKey.keyLabel == 'Enter') {
        if (evt is RawKeyDownEvent) {
          // add newline to cursor position of the text
          final text = _textController.text;
          final selection = _textController.selection;
          final newText = text.replaceRange(
            selection.start,
            selection.end,
            '\n',
          );
          final newSelection = TextSelection.collapsed(
            offset: selection.start + 1,
          );
          _textController.value = TextEditingValue(
            text: newText,
            selection: newSelection,
          );

          // calculate number of lines before selection
          final textBeforeSelection = text.substring(0, selection.start);
          final numberOfLinesBeforeSelection =
              textBeforeSelection.split('\n').length;

          // log
          log.d('numberOfLinesBeforeSelection: $numberOfLinesBeforeSelection');

          // get selection position in double
          final selectionPosition = numberOfLinesBeforeSelection * 19;
          double selectionPositionDouble = selectionPosition.toDouble();

          // scroll to the selection position
          _textInputScrollController.animateTo(selectionPositionDouble,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut);
        }
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }
    },
  );

  final ScrollController _textInputScrollController = ScrollController();

  @override
  void dispose() {
    _client.close();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // register focusNode into AppProvider
    textInputFocusEventEmitter =
        Provider.of<AppProvider>(context, listen: false)
            .textInputFocusEventEmitter;

    // listen to textInputFocusEventEmitter
    textInputFocusEventEmitter.stream.listen((event) {
      _focusNode.requestFocus();
    });
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

  // Send message to OpenAI
  Stream<Message> _sendMessage(List<Map<String, String>> messages) {
    final openAiUri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final apiKey =
        Provider.of<ConversationProvider>(context, listen: false).yourapikey;

    // prepare messages into List<OpenAIChatCompletionChoiceMessageModel> openAIMessages
    List<OpenAIChatCompletionChoiceMessageModel> openAIMessages = [];

    // add system message to instruct OpenAI to generate what kind of response
    openAIMessages.add(OpenAIChatCompletionChoiceMessageModel(
      content: Provider.of<AppProvider>(context, listen: false).systemMessage,
      role: OpenAIChatMessageRole.system,
    ));

    for (var message in messages) {
      // convert message['role'] into OpenAIChatMessageRole.user or OpenAIChatMessageRole.assistant
      openAIMessages.add(OpenAIChatCompletionChoiceMessageModel(
        content: message['content']!,
        role: message['role'] == 'user'
            ? OpenAIChatMessageRole.user
            : OpenAIChatMessageRole.assistant,
      ));
    }

    Stream<OpenAIStreamChatCompletionModel> completionStream =
        OpenAI.instance.chat.createStream(
      model: Provider.of<AppProvider>(context, listen: false).gptModel,
      messages: openAIMessages,
      // maxTokens: 100,
      temperature: 0.5,
      topP: 1,
    );

    // construct a BehaviorSubject to store the temporary message string
    // the message is to be updated by the response from OpenAI
    String tempMessage = "";

    // listen to the response from OpenAI
    //
    return completionStream.map((event) {
      log.d('openai response: $event');

      OpenAIStreamChatCompletionModel openAIStreamChatCompletionModel = event;

      // get the completion from the response
      final completions = openAIStreamChatCompletionModel.choices;

      if (completions.isNotEmpty) {
        final completion = completions[0];

        final content = completion.delta.content;

        // log the content
        log.d('streamed content: $content');

        if (content != null) {
          // delete all the prefix '\n' in content
          // final contentWithoutPrefix =
          //     content.replaceFirst(RegExp(r'^\n+'), '');

          // final decodedContent = utf8.decode(contentWithoutPrefix.codeUnits);

          // constructAssistantMessage(decodedContent);
          // update the tempMessageStream by appending the decodedContent
          // tempMessage = tempMessage + decodedContent;
          tempMessage = tempMessage + content;
        }
      }
      return constructAssistantMessage(
        tempMessage,
        isLoading: true,
      );
    });

    // log.d('openai response: ${response.body}');
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       final completions = data['choices'] as List<dynamic>;
//       if (completions.isNotEmpty) {
//         final completion = completions[0];
//         final content = completion['message']['content'] as String;
//         // delete all the prefix '\n' in content
//         final contentWithoutPrefix = content.replaceFirst(RegExp(r'^\n+'), '');

//         final decodedContent = utf8.decode(contentWithoutPrefix.codeUnits);

//         return constructAssistantMessage(decodedContent);
//       }
//     } else {
//       // invalid api key
//       // create a new dialog
//       return constructAssistantMessage('''Invalid.
// Status code: ${response.statusCode}.
// Error: ${response.body}''');
//     }
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
    try {
      final text = _textController.text.trim();
      if (text.isNotEmpty) {
        _textController.clear();
        _focusNode.requestFocus();

        final userMessage = constructUserMessage(text);
        final assistantLoadingMessage = constructAssistantMessage(
          '',
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

          _sendMessage(providerInner.currentConversationMessages).listen(
              (assistantMessage) async {
            // log onListen
            log.d('_sendMessage onListen');

            // log the assistantMessage
            log.d('assistantMessage.content: ${assistantMessage.content}');
            // log.d('assistantMessageIndex: $assistantMessageIndex');
            // log.d('assistantMessage.isLoading: ${assistantMessage.isLoading}');
            // log.d('assistantMessage.senderId: ${assistantMessage.senderId}');
            // log.d('assistantMessage.timestamp: ${assistantMessage.timestamp}');

            setState(() {
              Provider.of<ConversationProvider>(context, listen: false)
                  .modifyMessage(assistantMessageIndex, assistantMessage);
            });
            // scroll to last message after small delay
            await Future.delayed(const Duration(milliseconds: 100));
            _scrollToBottom();
          }, onDone: () {
            // log onDone
            log.d('_sendMessage onDone');

            // modify the message to remove the loading spinner
            final assistantMessage = constructAssistantMessage(
              providerInner
                  .currentConversation.messages[assistantMessageIndex].content,
              isLoading: false,
            );

            setState(() {
              Provider.of<ConversationProvider>(context, listen: false)
                  .modifyMessage(assistantMessageIndex, assistantMessage);
            });

            // ask for a topic
            askTopic(
              messages: providerInner.currentConversationMessages,
              context: context,
              client: _client,
            ).then((topic) {
              if (topic != null) {
                // modify the conversation title
                providerInner.changeConversationTitle(topic);
              }
            });
          }, onError: (e) {
            // log onError
            log.d('_sendMessage onError: $e');

            // add the error message to the conversation
            final errorMessage = constructAssistantMessage(
              'Error: $e',
            );

            setState(() {
              Provider.of<ConversationProvider>(context, listen: false)
                  .modifyMessage(assistantMessageIndex, errorMessage);
            });
          });
        }
      }
    } catch (e) {
      log.e('_sendMessageAndAddToChat error: $e', e);

      // add the error message to the conversation
      final errorMessage = constructAssistantMessage(
        'Error: $e',
      );

      // add to current conversation
      Provider.of<ConversationProvider>(context, listen: false)
          .addMessage(errorMessage);
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
      body: GestureDetector(
        onSecondaryTapUp: (details) {
          showContextMenuForConversation(details);
        },
        child: Column(
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
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: AssetImage(
                                          systemSender.avatarAssetPath),
                                      radius: 16.0,
                                    ),
                                    // show loading spinner if message is loading
                                    if (message.isLoading)
                                      const Positioned.fill(
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: SizedBox(
                                            height: 16.0,
                                            width: 16.0,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
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
                                          ? const Color(0xff55bb8e)
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
                                      // not needed anymore because we stream the message from openai
                                      // if (message.isLoading) {
                                      //   return const SizedBox(
                                      //     height: 16.0,
                                      //     width: 16.0,
                                      //     child: CircularProgressIndicator(
                                      //       strokeWidth: 2.0,
                                      //     ),
                                      //   );
                                      // }
                                      return SelectableText(
                                        message.content,
                                        style: TextStyle(
                                          color:
                                              message.senderId == userSender.id
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
                        scrollController: _textInputScrollController,
                        autofocus: true,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.multiline,
                        // textInputAction: TextInputAction.newline,
                        textInputAction: Platform.isWindows
                            ? TextInputAction.done
                            : TextInputAction.newline,
                        controller: _textController,
                        decoration: const InputDecoration.collapsed(
                            hintText: 'Type your message...'),
                        // onSubmitted: (_) => _onSubmitMessage(),
                      ),
                      // child: TypeAheadFormField(
                      //   suggestionsBoxController: suggestionsBoxController,
                      //   noItemsFoundBuilder: (context) {
                      //     // show nothing
                      //     return const SizedBox.shrink();
                      //   },
                      //   textFieldConfiguration: TextFieldConfiguration(
                      //     controller: _textController,
                      //     decoration: const InputDecoration(
                      //       hintText: 'Type your message...',
                      //       border: InputBorder.none,
                      //     ),
                      //     minLines: 1,
                      //     maxLines: 6,
                      //     textInputAction: Platform.isWindows
                      //         ? TextInputAction.done
                      //         : TextInputAction.newline,
                      //     autofocus: true,
                      //     focusNode: _focusNode,
                      //   ),
                      //   hideOnLoading: true,
                      //   debounceDuration: const Duration(milliseconds: 1000),
                      //   direction: AxisDirection.up,
                      //   suggestionsCallback: (pattern) async {
                      //     return await getSuggestions(pattern);
                      //   },
                      //   itemBuilder: (context, suggestion) {
                      //     return ListTile(
                      //       title: Text(suggestion),
                      //     );
                      //   },
                      //   transitionBuilder:
                      //       (context, suggestionsBox, controller) {
                      //     return suggestionsBox;
                      //   },
                      //   onSuggestionSelected: (suggestion) {
                      //     // remove starting "..." from suggestion
                      //     suggestion = suggestion.substring(3);

                      //     _textController.text =
                      //         _textController.text + suggestion;
                      //   },
                      //   onSaved: (value) {
                      //     // this._selectedCity = value
                      //   },
                      // ),
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

  void showContextMenuForConversation(
    TapUpDetails tapUpDetails,
  ) {
    // log entry
    log.d('showContextMenuForConversation');

    // show a context menu
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        tapUpDetails.globalPosition.dx,
        tapUpDetails.globalPosition.dy,
        tapUpDetails.globalPosition.dx,
        tapUpDetails.globalPosition.dy,
      ),
      items: [
        // copy to clipboard
        const PopupMenuItem(
          value: 'copy_to_clipboard',
          // shorter
          height: 22.0,
          child: Text(
            'Copy conversation to clipboard',
            // smaller font
            style: TextStyle(
              fontSize: 12.0,
            ),
          ),
        ),
        // save as txt
        const PopupMenuItem(
          value: 'save_as_txt',
          // shorter
          height: 22.0,
          child: Text(
            'Save conversation as .txt',
            // smaller font
            style: TextStyle(
              fontSize: 12.0,
            ),
          ),
        ),
      ],
      elevation: 8.0,
      // smaller size
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ).then((value) {
      if (value == 'copy_to_clipboard') {
        // copy the conversation to clipboard
        copyConversationToClipboard(context);
      } else if (value == 'save_as_txt') {
        // save the conversation as txt
        saveConversationAsTxt(context);
      }
    });
  }

  // Future<Iterable<String>> getSuggestions(String input) async {
  //   var currentMessages =
  //       Provider.of<ConversationProvider>(context, listen: false)
  //           .currentConversationMessages;

  //   // check if the input is empty with trim
  //   if (input.trim().isEmpty) {
  //     return const Iterable.empty();
  //   }

  //   // add the input to the currentMessages
  //   currentMessages.add(
  //     {
  //       'content': input,
  //       'role': 'user',
  //     },
  //   );

  //   // log about to call autoCompleteMessage
  //   log.d('about to call autoCompleteMessage');

  //   var autoCompleteResult = await autoCompleteMessage(
  //     messages: currentMessages,
  //     context: context,
  //     client: _client,
  //   );

  //   // log autoCompleteResult
  //   log.d('autoCompleteResult: $autoCompleteResult');

  //   if (autoCompleteResult == null) {
  //     return const Iterable.empty();
  //   }

  //   // return a list of suggestions based on the input
  //   return Iterable.generate(
  //     1,
  //     (index) => "...$autoCompleteResult",
  //   );
  // }
}
