import 'package:flutter/material.dart';
import 'package:flutter_chat/app_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'chatpage.dart';
import 'menu_drawer.dart';
import 'conversation_provider.dart';
import 'popmenu.dart';

var log = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  // create theme
  final ThemeData theme = ThemeData(
    primarySwatch: Colors.grey,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // title with version number from AppProvider
      title:
          'Flutter Chat v${Provider.of<AppProvider>(context, listen: false).versionNumber()}',
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            Provider.of<ConversationProvider>(context, listen: true)
                .currentConversationTitle,
            style: const TextStyle(
              fontSize: 20.0, // change font size
              color: Colors.black, // change font color
              fontFamily: 'din-regular', // change font family
            ),
          ),
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          backgroundColor: Colors.grey[100],
          elevation: 0, // remove box shadow
          toolbarHeight: 50,
          actions: const [
            CustomPopupMenu(),
          ],
        ),
        drawer: const MenuDrawer(),
        body: const Center(
          child: ChatPage(),
        ),
      ),
    );
  }
}
