// Remove any unused imports at the top of the file
// Remove any unused variables or methods
// The file appears clean based on previous analysis
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../utils/logger.dart';
import '../utils/icon_standards.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/animated_welcome_bubble.dart';
import '../widgets/user_search_dialog.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/test_data.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    Logger.debug('MessagesScreen initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversations();
    });
  }

  void _loadConversations() {
    Logger.debug('_loadConversations called');
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    
    Logger.debug('AuthProvider isAuthenticated: ${authProvider.isAuthenticated}');
    Logger.debug('AuthProvider userData: ${authProvider.userData}');
    
    // Handle both real auth and demo mode
    String? userId = authProvider.userData?['id'];
    if (userId == null && authProvider.isAuthenticated) {
      // Generate demo userId for demo mode
      final userType = authProvider.userData?['value'] ?? 'traveler';
      userId = 'demo_${userType}_user';
      Logger.debug('Generated demo userId: $userId');
    }
    
    Logger.debug('Final userId: $userId');
    
    Logger.debug('Calling chatProvider.loadConversations with userId: $userId');
    if (userId != null) {
      chatProvider.loadConversations(userId);
    }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.data_object),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Initializing test users...')),
              );
              await TestData.initializeTestData();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Test users created!')),
                );
              }
            },
            tooltip: 'Initialize Test Users',
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (chatProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${chatProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadConversations,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final conversations = chatProvider.conversations;
          
          // Add this in the build method after the error handling section
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No conversations yet.\nStart chatting with the Travel Assistant!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final authProvider = context.read<AuthProvider>();
                      final chatProvider = context.read<ChatProvider>();
                      
                      // Handle both real auth and demo mode
                      String? userId = authProvider.userData?['id'];
                      if (userId == null && authProvider.isAuthenticated) {
                        final userType = authProvider.userData?['value'] ?? 'traveler';
                        userId = 'demo_${userType}_user';
                      }
                      
                      if (userId != null) {
                        Logger.info('Manual AI conversation creation triggered with userId: $userId');
                        chatProvider.testAIConversationCreation(userId);
                      } else {
                        Logger.error('Cannot create AI conversation - no userId available');
                      }
                    },
                    child: const Text('Create AI Conversation (Test)'),
                  ),
                ],
              ),
            );
          }
          
          // Check if TraverseAI conversation exists
          final traverseAIConvo = conversations.firstWhere(
            (c) => c.isAI == true,
            orElse: () => conversations.first,
          );
          
          return Column(
            children: [
              // Animated welcome bubble for TraverseAI
              if (conversations.any((c) => c.isAI == true))
                AnimatedWelcomeBubble(
                  message: "👋 Hi! I'm TraverseAI, ready to help you plan amazing adventures and navigate all of Traverse's features!",
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(conversation: traverseAIConvo),
                      ),
                    );
                  },
                  isVisible: true,
                ),
              // Conversations list
              Expanded(
                child: ListView.separated(
                  itemCount: conversations.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: AppTheme.borderLight),
                  itemBuilder: (context, index) {
              final convo = conversations[index];
              final lastMsg = convo.messages.isNotEmpty ? convo.messages.last : null;
              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(convo.avatar),
                      radius: 26,
                    ),
                    if (convo.isAI == true)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            IconStandards.getUIIcon('smart_toy'),
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  convo.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  lastMsg?.text ?? 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: lastMsg != null
                    ? Text(
                        _formatTime(lastMsg.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(conversation: convo),
                    ),
                  );
                },
              );
            },
                 ),
               ),
             ],
           );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            onPressed: () => context.go('/chat-test'),
            backgroundColor: Colors.green,
            heroTag: "chat_test",
            child: const Icon(Icons.bug_report, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () => _showUserSearchDialog(context),
            backgroundColor: AppTheme.primaryBlue,
            heroTag: "add_chat",
            child: Icon(IconStandards.getUIIcon('person_add'), color: Colors.white),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigation(),
    );
  }

  void _showUserSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UserSearchDialog(
        onUserSelected: (user) {
          _createChatWithUser(user);
        },
      ),
    );
  }

  void _createChatWithUser(Map<String, dynamic> user) {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    // Handle both real auth and demo mode
    String? userId = authProvider.userData?['id'];
    if (userId == null && authProvider.isAuthenticated) {
      final userType = authProvider.userData?['value'] ?? 'traveler';
      userId = 'demo_${userType}_user';
    }

    if (userId != null) {
      final contactName = user['full_name'] ?? user['username'] ?? 'Unknown User';
      final contactId = user['id'];

      chatProvider.createNewConversation(
        userId: userId,
        contactName: contactName,
        contactId: contactId,
        avatar: user['avatar_url'],
      );

      Logger.info('Created chat with user: $contactName');
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}



class ChatDetailScreen extends StatefulWidget {
  final Conversation conversation;
  
  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _addMessage(String text) {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final userId = authProvider.userData?['id'];
    
    if (userId != null) {
      chatProvider.sendMessage(widget.conversation.id, text, userId);
    }
  }

  // Response handling is now managed by ChatProvider

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(widget.conversation.avatar),
                  radius: 18,
                ),
                if (widget.conversation.isAI)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Icon(
                        IconStandards.getUIIcon('smart_toy'),
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (widget.conversation.isAI)
                    const Text(
                      'AI Assistant',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final conversation = chatProvider.getConversation(widget.conversation.id);
                final messages = conversation?.messages ?? widget.conversation.messages;
                
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];
                    return Align(
                  alignment: msg.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isMe
                          ? AppTheme.primaryBlue.withValues(alpha: 0.9)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isMe ? Colors.white : AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
                  },
                );
              },
            ),
          ),
          _MessageInput(
            onSend: _addMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageInput extends StatefulWidget {
  final void Function(String) onSend;
  const _MessageInput({required this.onSend});

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _hasText ? AppTheme.primaryBlue : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  IconStandards.getUIIcon('send'),
                  color: _hasText ? Colors.white : Colors.grey[600],
                ),
                onPressed: _hasText ? _sendMessage : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
