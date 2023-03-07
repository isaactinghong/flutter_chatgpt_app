import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:localstore/localstore.dart';

import 'models/conversation.dart';
import 'models/message.dart';

class ConversationProvider extends ChangeNotifier {
  final db = Localstore.instance;
  final String appDataFolder = 'ChatGPT Flutter Data';
  final String appConfigId = 'appConfig';
  final String conversationsDocId = 'conversations';

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

  // load API Key from localStore
  Future<void> loadAPIKey() async {
    final data = await db.collection(appDataFolder).doc(appConfigId).get();
    if (data != null) {
      apikey = data['apikey'];
    }
  }

  // save API Key to localStore
  Future<void> saveAPIKey(String newAPIKey) async {
    yourapikey = newAPIKey;

    await db
        .collection(appDataFolder)
        .doc(appConfigId)
        .set({'apikey': newAPIKey});
    apikey = newAPIKey;
  }

  // load conversations from localStore
  Future<void> loadConversations() async {
    final data =
        await db.collection(appDataFolder).doc(conversationsDocId).get();
    if (data != null) {
      final List<Conversation> retrievedConversations = data['conversations']
              ?.map<Conversation>((e) => Conversation.fromJson(e))
              ?.toList() ??
          [];
      conversations = retrievedConversations;
    }
  }

  // save conversations to localStore
  Future<void> saveConversations() async {
    final conversationToSave = _conversations.map((e) => e.toJson()).toList();
    print('conversationToSave: $conversationToSave');
    await db.collection(appDataFolder).doc(conversationsDocId).set({
      'conversations': conversationToSave,
    });
  }

  // add new conversation
  void addConversation(String title) {
    _conversations.add(Conversation(messages: [], title: title));
    _currentConversationIndex = _conversations.length - 1;
    notifyListeners();
  }

  // change conversation
  void changeConversation(int index) {
    _currentConversationIndex = index;
    notifyListeners();
  }

  // // add new message
  // void addMessage(Message message) {
  //   _conversations[_currentConversationIndex].messages.add(message);
  //   notifyListeners();
  // }

  // initialize provider conversation list
  ConversationProvider() {
    // load API Key
    loadAPIKey();

    // load conversations
    loadConversations();

    notifyListeners();

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
    apikey = value;
    notifyListeners();
  }

  // add to current conversation
  Future<int> addMessage(Message message) async {
    _conversations[_currentConversationIndex].messages.add(message);
    final messageIndex =
        _conversations[_currentConversationIndex].messages.length - 1;
    notifyListeners();
    await saveConversations();

    // return message index
    return messageIndex;
  }

  // modify a message in current conversation
  void modifyMessage(int index, Message message) async {
    assert(index < _conversations[_currentConversationIndex].messages.length);
    assert(index >= 0);

    _conversations[_currentConversationIndex].messages[index] = message;
    notifyListeners();
    await saveConversations();
  }

  // add a new empty conversation
  // default title is 'new conversation ${_conversations.length}'
  void addEmptyConversation(String title) async {
    if (title == '') {
      title = 'new conversation ${_conversations.length}';
    }
    _conversations.add(Conversation(messages: [], title: title));
    _currentConversationIndex = _conversations.length - 1;
    notifyListeners();
    await saveConversations();
  }

  // // add new conversation
  // void addConversation(Conversation conversation) async {
  //   _conversations.add(conversation);
  //   _currentConversationIndex = _conversations.length - 1;
  //   notifyListeners();
  //   await saveConversations();
  // }

  // remove conversation by index
  void removeConversation(int index) async {
    _conversations.removeAt(index);
    _currentConversationIndex = _conversations.length - 1;
    notifyListeners();
    await saveConversations();
  }

  // remove current conversation
  void removeCurrentConversation() async {
    _conversations.removeAt(_currentConversationIndex);
    _currentConversationIndex = _conversations.length - 1;
    if (_conversations.isEmpty) {
      addEmptyConversation('');
    }
    notifyListeners();
    await saveConversations();
  }

  //rename conversation
  void renameConversation(String title) async {
    if (title == "") {
      // no title, use default title
      title = 'new conversation ${_currentConversationIndex}';
    }
    _conversations[_currentConversationIndex].title = title;
    notifyListeners();
    await saveConversations();
  }

  // clear all conversations
  void clearConversations() async {
    _conversations.clear();
    addEmptyConversation('');
    notifyListeners();
    await saveConversations();
  }

  // clear current conversation
  void clearCurrentConversation() async {
    _conversations[_currentConversationIndex].messages.clear();
    notifyListeners();
    await saveConversations();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}

const String model = "gpt-3.5-turbo";
