import 'package:flutter/material.dart';

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

  void _send([String? preset]) {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _messages.add(_ChatMessage(text: _replyFor(text), fromUser: false));
      _ctrl.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 96,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _replyFor(String input) {
    final text = input.toLowerCase();
    final summary = widget.analysisData?['summary']?.toString();
    final scopeNote = widget.analysisData?['search_scope_note']?.toString();
    final products = (widget.analysisData?['products'] as List<dynamic>?) ?? const [];
    final lowCount = _countToxicity(products, 'low');
    final moderateCount = _countToxicity(products, 'moderate');
    final highCount = _countToxicity(products, 'high');

    if (text.contains('help') || text.contains('what can you do')) {
      return 'I can explain the latest search, summarize analysis, help you reach Home for a new search, or point you to Profile and Scan.';
    }
    if (text.contains('last search') || text.contains('analysis') || text.contains('summary')) {
      if (summary == null) {
        return 'No search summary is available yet. Open Home, run a product search, and I will summarize the results here.';
      }
      final extra = scopeNote == null ? '' : ' Scope: $scopeNote.';
      return '$summary$extra';
    }
    if (text.contains('safe') || text.contains('low risk') || text.contains('low toxicity')) {
      if (products.isEmpty) {
        return 'I do not have any product results yet. Search first and I can help sort them by risk level.';
      }
      return 'From the latest results I see $lowCount low-risk, $moderateCount moderate-risk, and $highCount high-risk products. The best starting point is usually the low-risk group.';
    }
    if (text.contains('scan')) {
      return 'The Scan tab is ready for the future product scanner. For now, use Home to search by name or brand.';
    }
    if (text.contains('profile') || text.contains('condition') || text.contains('disease')) {
      return 'Your Profile tab lets you update email, date of birth, gender, and health conditions so search results can be personalized.';
    }
    if (text.contains('search')) {
      return 'Go to Home, type a product name or brand, and tap search. You can also open filters to narrow the category.';
    }
    if (text.contains('hello') || text.contains('hi')) {
      return 'Hello. Ask me about your latest search, safe products, profile, or where to find the analysis tab.';
    }

    return 'I can answer based on the app context. Try asking about the latest search, safer products, your profile, or how to start a new search.';
  }

  int _countToxicity(List<dynamic> products, String target) {
    return products.where((raw) {
      final item = raw as Map<String, dynamic>;
      final label = item['toxicity_label']?.toString().trim().toLowerCase() ?? '';
      return label == target;
    }).length;
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
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
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
                onPressed: _send,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18)),
                child: const Icon(Icons.send_rounded),
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
