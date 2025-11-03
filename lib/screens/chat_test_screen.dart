import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/real_time_messaging_widget.dart';
import '../utils/theme.dart';
import '../utils/logger.dart';

class ChatTestScreen extends StatefulWidget {
  const ChatTestScreen({super.key});

  @override
  State<ChatTestScreen> createState() => _ChatTestScreenState();
}

class _ChatTestScreenState extends State<ChatTestScreen> {
  String _selectedUser = 'user1';
  final String _conversationId = 'test_conversation_${DateTime.now().millisecondsSinceEpoch}';
  bool _conversationCreated = false;

  final Map<String, Map<String, String>> _testUsers = {
    'user1': {
      'id': 'test_user_1',
      'name': 'Alice Johnson',
      'email': 'alice@test.com',
    },
    'user2': {
      'id': 'test_user_2',
      'name': 'Bob Smith',
      'email': 'bob@test.com',
    },
  };

  @override
  void initState() {
    super.initState();
    _createTestConversation();
  }

  Future<void> _createTestConversation() async {
    final chatProvider = context.read<ChatProvider>();

    try {
      // Create conversation between the two test users
      await chatProvider.createNewConversation(
        userId: _testUsers['user1']!['id']!,
        contactName: _testUsers['user2']!['name']!,
        contactId: _testUsers['user2']!['id']!,
      );

      setState(() {
        _conversationCreated = true;
      });

      Logger.info('Test conversation created with ID: $_conversationId');
    } catch (e) {
      Logger.error('Failed to create test conversation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2-User Chat Test'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          DropdownButton<String>(
            value: _selectedUser,
            dropdownColor: Colors.white,
            underline: Container(),
            icon: const Icon(Icons.person, color: Colors.white),
            items: _testUsers.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value['name']!,
                  style: const TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedUser = newValue;
                });
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // User indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _selectedUser == 'user1' ? Colors.blue.shade50 : Colors.green.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _selectedUser == 'user1' ? Colors.blue : Colors.green,
                  child: Text(
                    _testUsers[_selectedUser]!['name']![0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chatting as: ${_testUsers[_selectedUser]!['name']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      _testUsers[_selectedUser]!['email']!,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Switch user button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedUser = _selectedUser == 'user1' ? 'user2' : 'user1';
                });
              },
              icon: const Icon(Icons.swap_horiz),
              label: Text(
                'Switch to ${_testUsers[_selectedUser == 'user1' ? 'user2' : 'user1']!['name']}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const Divider(height: 1),

          // Chat interface
          Expanded(
            child: _conversationCreated
              ? RealTimeMessagingWidget(
                  userId: _testUsers[_selectedUser]!['id']!,
                  conversationId: _conversationId,
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Setting up test conversation...'),
                    ],
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Chat Test Instructions'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Send a message as the current user'),
                  SizedBox(height: 8),
                  Text('2. Tap "Switch User" button to change users'),
                  SizedBox(height: 8),
                  Text('3. Send a reply as the other user'),
                  SizedBox(height: 8),
                  Text('4. Messages should persist and show in real-time'),
                  SizedBox(height: 8),
                  Text('5. Each user sees their own messages on the right'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it!'),
                ),
              ],
            ),
          );
        },
        backgroundColor: AppTheme.primaryBlue,
        label: const Text('Instructions'),
        icon: const Icon(Icons.help_outline),
      ),
    );
  }
}