import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

import 'models/conversation.dart';
import 'models/message.dart';

class ConversationProvider extends ChangeNotifier {
  final LocalStorage storage = LocalStorage('chatgpt');

  List<Conversation> _conversations = [];
  int _currentConversationIndex = 0;
  String apikey = "YOUR_API_KEY";

  List<Conversation> get conversations => _conversations;
  int get currentConversationIndex => _currentConversationIndex;
  String get currentConversationTitle =>
      _conversations[_currentConversationIndex].title;
  int get currentConversationLength =>
      _conversations[_currentConversationIndex].messages.length;
  Conversation get currentConversation =>
      _conversations[_currentConversationIndex];
  // get current conversation's messages format
  //'messages': [
  //   {'role': 'user', 'content': text},
  // ],
  List<Map<String, String>> get currentConversationMessages {
    List<Map<String, String>> messages = [
      {
        'role': "system",
        'content':
            "You are ChatGPT, a large language model trained by OpenAI. Answer as concisely as possible."
      }
    ];
    for (Message message
        in _conversations[_currentConversationIndex].messages) {
      messages.add({
        'role': message.senderId == 'User' ? 'user' : 'system',
        'content': message.content
      });
    }
    return messages;
  }

  // initialize provider conversation list
  ConversationProvider() {
    // load api key when storage is ready
    storage.ready.then((value) {
      apikey = storage.getItem('apiKey') ?? apikey;
      notifyListeners();
    });

    _conversations.add(Conversation(messages: [], title: 'new conversation'));
  }

  // change conversations
  set conversations(List<Conversation> value) {
    _conversations = value;
    notifyListeners();
  }

  // change current conversation
  set currentConversationIndex(int value) {
    _currentConversationIndex = value;
    notifyListeners();
  }

  String get yourapikey => apikey;
  // change api key
  set yourapikey(String value) {
    storage.setItem('apiKey', value);
    apikey = value;
    notifyListeners();
  }

  // add to current conversation
  void addMessage(Message message) {
    _conversations[_currentConversationIndex].messages.add(message);
    notifyListeners();
  }

  // add a new empty conversation
  // default title is 'new conversation ${_conversations.length}'
  void addEmptyConversation(String title) {
    if (title == '') {
      title = 'new conversation ${_conversations.length}';
    }
    _conversations.add(Conversation(messages: [], title: title));
    _currentConversationIndex = _conversations.length - 1;
    notifyListeners();
  }

  // add new conversation
  void addConversation(Conversation conversation) {
    _conversations.add(conversation);
    _currentConversationIndex = _conversations.length - 1;
    notifyListeners();
  }

  // remove conversation by index
  void removeConversation(int index) {
    _conversations.removeAt(index);
    _currentConversationIndex = _conversations.length - 1;
    notifyListeners();
  }

  // remove current conversation
  void removeCurrentConversation() {
    _conversations.removeAt(_currentConversationIndex);
    _currentConversationIndex = _conversations.length - 1;
    if (_conversations.isEmpty) {
      addEmptyConversation('');
    }
    notifyListeners();
  }

  //rename conversation
  void renameConversation(String title) {
    if (title == "") {
      // no title, use default title
      title = 'new conversation ${_currentConversationIndex}';
    }
    _conversations[_currentConversationIndex].title = title;
    notifyListeners();
  }

  // clear all conversations
  void clearConversations() {
    _conversations.clear();
    addEmptyConversation('');
    notifyListeners();
  }

  // clear current conversation
  void clearCurrentConversation() {
    _conversations[_currentConversationIndex].messages.clear();
    notifyListeners();
  }
}

const String model = "gpt-3.5-turbo";
