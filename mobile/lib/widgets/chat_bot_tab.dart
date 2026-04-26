import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatBotTab extends StatefulWidget {
  const ChatBotTab({
    super.key,
    required this.userName,
    required this.analysisData,
    required this.lastQuery,
    required this.onOpenSearch,
  });

  final String userName;
  final Map<String, dynamic>? analysisData;
  final String? lastQuery;
  final VoidCallback onOpenSearch;

  @override
  State<ChatBotTab> createState() => _ChatBotTabState();
}

class _ChatBotTabState extends State<ChatBotTab> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final ChatService _chatService = ChatService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text: 'Hi ${widget.userName}. I can help with product search, analysis, profile guidance, and quick safety questions.',
        fromUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? preset]) async {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _isLoading = true;
      _ctrl.clear();
    });

    try {
      // Get products list for context
      final products = (widget.analysisData?['products'] as List<dynamic>?) ?? [];
      final productsAsMap = products.map((p) => p as Map<String, dynamic>).toList();

      // Call API
      final response = await _chatService.sendMessage(
        message: text,
        lastQuery: widget.lastQuery ?? '',
        products: productsAsMap,
      );

      final botResponse = response['bot_response'] ?? 'I encountered an error. Please try again.';

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: botResponse, fromUser: false));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: 'Error: ${e.toString()}. Please try again.',
            fromUser: false,
          ));
          _isLoading = false;
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 96,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Chat Bot',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: widget.onOpenSearch,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Search'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.lastQuery == null ? 'Ask me anything about the app.' : 'Context is ready for "${widget.lastQuery}".',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickChip('Summarize my last search'),
              _quickChip('How do I find safe products?'),
              _quickChip('What does analysis show?'),
              _quickChip('How do I update my profile?'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return Align(
                alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.fromUser ? const Color(0xFF2563EB) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(message.fromUser ? 18 : 4),
                      bottomRight: Radius.circular(message.fromUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.fromUser ? Colors.white : const Color(0xFF1A1A1A),
                      height: 1.35,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _isLoading ? null : (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Ask the bot...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _isLoading ? null : _send,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18)),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickChip(String text) {
    return ActionChip(
      label: Text(text),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      onPressed: () => _send(text),
    );
  }
}

class _ChatMessage {
  _ChatMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}
