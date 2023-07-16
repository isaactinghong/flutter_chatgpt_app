import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AppProvider, a class that extends ChangeNotifier
/// it is used to store global variables and functions
class AppProvider extends ChangeNotifier {
  PackageInfo? packageInfo;

  /// gptModel, a string that stores the GPT model name
  String gptModel = "gpt-3.5-turbo";

  /// setGptModel, a setter that sets the GPT model name
  // set it to shared preferences
  setGptModel(String newGPTModel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // set gpt model to shared preferences. key: gptModel
    prefs.setString("gptModel", newGPTModel);
    gptModel = newGPTModel;
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
  }

  void loadGptModel() {
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey("gptModel")) {
        gptModel = prefs.getString("gptModel") ?? "gpt-3.5-turbo";
      }
      notifyListeners();
    });
  }
}
