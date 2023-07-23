import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_provider.dart';
import 'conversation_provider.dart';
import 'change_api_key_dialog.dart';
import 'models/conversation.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () {
                    Provider.of<ConversationProvider>(context, listen: false)
                        .addEmptyConversation('');
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // border: Border.all(color: Color(Colors.grey[300]?.value ?? 0)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      // left align
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.add, color: Colors.grey[800], size: 20.0),
                        const SizedBox(width: 15.0),
                        const Text(
                          'New Chat',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontFamily: 'din-regular',
                            // fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Consumer<ConversationProvider>(
                  builder: (context, conversationProvider, child) {
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: conversationProvider.conversations.length,
                      itemBuilder: (BuildContext context, int index) {
                        Conversation conversation =
                            conversationProvider.conversations[index];
                        return Dismissible(
                          key: UniqueKey(),
                          onDismissed: (direction) {
                            conversationProvider.removeConversation(index);
                          },
                          child: GestureDetector(
                            onTap: () {
                              conversationProvider.currentConversationIndex =
                                  index;
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10.0),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: conversationProvider
                                            .currentConversationIndex ==
                                        index
                                    ? const Color(0xff55bb8e)
                                    : Colors.white,
                                // border: Border.all(color: Color(Colors.grey[200]?.value ?? 0)),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  // coversation icon
                                  Icon(
                                    Icons.person,
                                    color: conversationProvider
                                                .currentConversationIndex ==
                                            index
                                        ? Colors.white
                                        : Colors.grey[700],
                                    size: 20.0,
                                  ),
                                  const SizedBox(width: 15.0),
                                  Flexible(
                                    child: Text(
                                      conversation.title,
                                      style: TextStyle(
                                        // fontWeight: FontWeight.bold,
                                        color: conversationProvider
                                                    .currentConversationIndex ==
                                                index
                                            ? Colors.white
                                            : Colors.grey[700],
                                        fontFamily: 'din-regular',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // add a input field to change the system message
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Message: ',
                        style: TextStyle(
                          fontFamily: 'din-regular',
                          color: Colors.grey[700],
                          fontSize: 18.0,
                        ),
                      ),
                      TextField(
                        // autofocus: true,
                        maxLines: 2,
                        controller: TextEditingController(
                          text: Provider.of<AppProvider>(context, listen: true)
                              .systemMessage,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (value) {
                          Provider.of<AppProvider>(context, listen: false)
                              .setSystemMessage(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Chat with me.',
                          hintStyle: TextStyle(
                            fontFamily: 'din-regular',
                            color: Colors.grey[700],
                            fontSize: 18.0,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // const SizedBox(height: 20.0),

              // add gpt model input field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Text(
                        'GPT Model: ',
                        style: TextStyle(
                          fontFamily: 'din-regular',
                          color: Colors.grey[700],
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        controller: TextEditingController(
                          text: Provider.of<AppProvider>(context, listen: true)
                              .gptModel,
                        ),
                        onSubmitted: (value) {
                          Provider.of<AppProvider>(context, listen: false)
                              .setGptModel(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'gpt-4',
                          hintStyle: TextStyle(
                            fontFamily: 'din-regular',
                            color: Colors.grey[700],
                            fontSize: 18.0,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // add version number above the api setting button
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: GestureDetector(
                  child: Text(
                    // get version number from AppProvider
                    'Version ${Provider.of<AppProvider>(context).versionNumber()}',
                    style: TextStyle(
                      fontFamily: 'din-regular',
                      color: Colors.grey[700],
                      fontSize: 18.0,
                    ),
                  ),
                  // onTap, prompt a modal to display the CHANGELOG.md content
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'ChatGPT Flutter',
                      applicationVersion:
                          'Version ${Provider.of<AppProvider>(context, listen: false).versionNumber()}',
                      children: [
                        // releases page url: https://github.com/isaactinghong/flutter_chatgpt_app/releases/
                        // show the url link the the github releases page
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Latest Releases:',
                                style: TextStyle(
                                  fontFamily: 'din-regular',
                                  color: Colors.grey[700],
                                  fontSize: 18.0,
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              GestureDetector(
                                onTap: () async {
                                  // open the url in browser using url_launcher package
                                  final Uri url = Uri.parse(
                                      'https://github.com/isaactinghong/flutter_chatgpt_app/releases/');
                                  if (!await launchUrl(url)) {
                                    throw Exception('Could not launch $url');
                                  }
                                },
                                child: Text(
                                  'https://github.com/isaactinghong/flutter_chatgpt_app/releases/',
                                  style: TextStyle(
                                    fontFamily: 'din-regular',
                                    color: Colors.grey[700],
                                    fontSize: 18.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.8,
                          // width is required to display the markdown content
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Markdown(
                            // display the CHANGELOG.md content from project root directory
                            data:
                                Provider.of<AppProvider>(context, listen: false)
                                    .changelogContent,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // add a setting button at the end of the drawer
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: GestureDetector(
                  onTap: () {
                    showChangeAPIKeyDialog(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.settings, color: Colors.grey[700], size: 20.0),
                      const SizedBox(width: 15.0),
                      Text(
                        'API Setting',
                        style: TextStyle(
                          fontFamily: 'din-regular',
                          color: Colors.grey[700],
                          fontSize: 18.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
