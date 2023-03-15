import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// AppProvider, a class that extends ChangeNotifier
/// it is used to store global variables and functions
class AppProvider extends ChangeNotifier {
  PackageInfo? packageInfo;

  versionNumber() {
    return packageInfo?.version ?? 'unknown version';
  }

  // constructor
  AppProvider() {
    PackageInfo.fromPlatform().then((value) => {
          packageInfo = value,
          notifyListeners(),
        });
  }
}
