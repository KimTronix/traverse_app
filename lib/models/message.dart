// Message and Conversation models for chat functionality

class Message {
  /// Unique message ID
  final String id;

  /// Sender's name or ID
  final String sender;

  /// Message text content
  final String text;

  /// When the message was sent
  final DateTime timestamp;

  /// True if the message is sent by the current user
  final bool isMe;

  Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });
}

class Conversation {
  /// Unique conversation ID
  final String id;

  /// Name of the user or group
  final String name;

  /// Avatar image asset path
  final String avatar;

  /// List of messages in the conversation
  final List<Message> messages;

  /// True if this is a group chat
  final bool isGroup;

  /// True if this is an AI conversation
  final bool isAI;

  Conversation({
    required this.id,
    required this.name,
    required this.avatar,
    required this.messages,
    this.isGroup = false,
    this.isAI = false,
  });
}
