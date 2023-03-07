// Sender should have name and avatar
class Sender {
  final String name;
  final String avatarAssetPath;
  // id
  final String id;

  Sender({required this.name, required this.avatarAssetPath, String? id})
      : id = id ?? name;
}

final Sender systemSender = Sender(
    name: 'System', avatarAssetPath: 'resources/avatars/ChatGPT_logo.png');
final Sender userSender =
    Sender(name: 'User', avatarAssetPath: 'resources/avatars/person.png');
