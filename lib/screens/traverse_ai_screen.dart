import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/openai_service.dart';
import '../services/ai_chat_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class TraverseAiScreen extends StatefulWidget {
  const TraverseAiScreen({super.key});

  @override
  State<TraverseAiScreen> createState() => _TraverseAiScreenState();
}

class _TraverseAiScreenState extends State<TraverseAiScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _isVerified = false;
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    // Verification removed - all users can access AI
    setState(() {
      _isVerified = true;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Verification check removed - all users can access AI

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();

    try {
      final response = await OpenAIService.instance.generateTravelResponse(
        text,
        conversationHistory: _messages.map((m) => m['text']!).toList()
      );

      setState(() {
        _messages.add({'role': 'assistant', 'text': response});
        _isLoading = false;
      });

      // Auto-save to session - verification removed
      await _autoSaveMessages();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  Future<void> _autoSaveMessages() async {
    try {
      // Create session if none exists
      if (_currentSessionId == null) {
        _currentSessionId = await AiChatService.createChatSession();
      }

      if (_currentSessionId != null && _messages.length >= 2) {
        // Save the last user message and AI response
        final userMessage = _messages[_messages.length - 2];
        final aiMessage = _messages[_messages.length - 1];

        await AiChatService.saveMessage(
          sessionId: _currentSessionId!,
          role: userMessage['role']!,
          content: userMessage['text']!,
        );

        await AiChatService.saveMessage(
          sessionId: _currentSessionId!,
          role: aiMessage['role']!,
          content: aiMessage['text']!,
        );
      }
    } catch (e) {
      // Silently handle save errors - don't interrupt chat flow
      print('Auto-save failed: $e');
    }
  }

  Future<void> _saveConversation() async {
    if (_messages.isEmpty) return;

    // Verification check removed - all users can save chats

    try {
      final sessionId = await AiChatService.saveConversation(
        messages: _messages,
        sessionName: 'Chat ${DateTime.now().toString().substring(0, 16)}',
      );

      if (sessionId != null) {
        setState(() {
          _currentSessionId = sessionId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation saved successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving conversation: $e'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TraverseAI'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isVerified && _messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveConversation,
              tooltip: 'Save conversation',
            ),
          if (!_isVerified)
            IconButton(
              icon: const Icon(Icons.verified_user_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verify your email to unlock full AI features and chat saving'),
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                );
              },
              tooltip: 'Verification required',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Theme.of(context).primaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m['text'] ?? '',
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Ask TraverseAI...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _isLoading ? null : _send,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
