import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AppProvider, a class that extends ChangeNotifier
/// it is used to store global variables and functions
class AppProvider extends ChangeNotifier {
  PackageInfo? packageInfo;

  /// gptModel, a string that stores the GPT model name
  String gptModel = "gpt-3.5-turbo";

  late String changelogContent = "";

  /// systemMessage, a string that stores the system message, to be sent to the chatbot as first message
  String systemMessage = "Chat with me.";

  /// textInputFocusEventEmitter, a EventEmitter that emits focus events
  /// it is used to set the focus on the input field
  StreamController<void> textInputFocusEventEmitter =
      StreamController.broadcast();

  /// setGptModel, a setter that sets the GPT model name
  // set it to shared preferences
  setGptModel(String newGPTModel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // set gpt model to shared preferences. key: gptModel
    prefs.setString("gptModel", newGPTModel);
    gptModel = newGPTModel;
    notifyListeners();
  }

  /// setSystemMessage, a setter that sets the system message
  /// set it to shared preferences
  setSystemMessage(String newSystemMessage) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // set system message to shared preferences. key: systemMessage
    prefs.setString("systemMessage", newSystemMessage);
    systemMessage = newSystemMessage;
    notifyListeners();
  }

  versionNumber() {
    return packageInfo?.version ?? 'unknown version';
  }

  // constructor
  AppProvider() {
    PackageInfo.fromPlatform().then((value) => {
          packageInfo = value,
          notifyListeners(),
        });

    // load gpt model from shared preferences
    loadGptModel();

    // load system message from shared preferences
    loadSystemMessage();
  }

  void loadGptModel() {
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey("gptModel")) {
        gptModel = prefs.getString("gptModel") ?? "gpt-3.5-turbo";
      }
      notifyListeners();
    });
  }

  void loadChangelogContent(context) {
    // load the CHANGELOG.md content from project root directory
    DefaultAssetBundle.of(context).loadString("CHANGELOG.md").then((value) => {
          changelogContent = value,
          notifyListeners(),
        });
  }

  void loadSystemMessage() {
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey("systemMessage")) {
        systemMessage = prefs.getString("systemMessage") ?? "Chat with me.";
      }
      notifyListeners();
    });
  }

  /// setFocusOnInputField, a setter that sets the focus on the input field
  void setFocusOnTextInputField() {
    textInputFocusEventEmitter.sink.add(null);
  }
}
