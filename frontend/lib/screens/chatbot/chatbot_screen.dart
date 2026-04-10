import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../services/api_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class ChatbotScreen extends StatefulWidget {
  final Map<String, dynamic>? userData; // optional — for role-based suggestions
  const ChatbotScreen({super.key, this.userData});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, String>> _history = [];
  bool _isTyping = false;

  String get _userRole =>
      widget.userData?['role'] as String? ?? 'individual';

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _messageController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      _history.add({'role': 'user', 'content': text});
      final reply =
          await ApiService.instance.sendChatMessage(text, _history);
      _history.add({'role': 'assistant', 'content': reply});
      setState(() {
        _isTyping = false;
        _messages.add({'role': 'bot', 'text': reply});
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'bot',
          'text':
              'Connection error. Nebula is currently unavailable. Please check backend logs.',
        });
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header — Nebula
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: AppColors.textPrimary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.tealBlue,
                            AppColors.forestGreen
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.auto_awesome,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nebula',   // renamed from EcoGPT
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Your cosmic sustainability guide',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Messages
              Expanded(
                child: _messages.isEmpty
                    ? _SuggestionsView(
                        onTap: _sendMessage,
                        role: _userRole,
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        itemCount:
                            _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == _messages.length && _isTyping) {
                            return _TypingIndicator();
                          }
                          final msg = _messages[i];
                          final isUser = msg['role'] == 'user';
                          return _MessageBubble(
                            text: msg['text'] as String,
                            isUser: isUser,
                          ).animate().fadeIn(delay: 100.ms);
                        },
                      ),
              ),
              // Input bar — arrow right
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  borderColor: AppColors.oliveGreen.withOpacity(0.3),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.textPrimary,
                              fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Ask Nebula anything...',
                            hintStyle: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.textMuted),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 8),
                          ),
                          onSubmitted: _sendMessage,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _sendMessage(_messageController.text),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.tealBlue,
                                AppColors.forestGreen,
                              ],
                            ),
                          ),
                          child: const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 18),
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _SuggestionsView extends StatelessWidget {
  final void Function(String) onTap;
  final String role;
  const _SuggestionsView({required this.onTap, required this.role});

  @override
  Widget build(BuildContext context) {
    final suggestions = AppConstants.suggestionsForRole(role);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'SUGGESTED QUESTIONS',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () => onTap(s['q']!),
              child: Row(
                children: [
                  // Star icon instead of chat bubble emoji
                  const Icon(Icons.star_outline,
                      color: AppColors.oliveGreen, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s['q']!,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: AppColors.textMuted, size: 14),
                ],
              ),
            ).animate().fadeIn(
                delay: Duration(milliseconds: 100 + i * 80));
          }),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight:
                isUser ? const Radius.circular(4) : null,
            bottomLeft:
                !isUser ? const Radius.circular(4) : null,
          ),
          gradient: isUser
              ? const LinearGradient(
                  colors: [AppColors.tealBlue, AppColors.forestGreen],
                )
              : null,
          color: isUser ? null : AppColors.glassWhiteStrong,
          border: isUser
              ? null
              : Border.all(color: AppColors.glassBorder),
        ),
        child: isUser
            ? Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.5,
                ),
              )
            : MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                  strong: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                  listBullet: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: AppColors.oliveGreen,
                  ),
                  h1: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  h2: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  h3: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.oliveGreen,
                  ),
                ),
              ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
          color: AppColors.glassWhiteStrong,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final opacity = (i == 0
                    ? _controller.value
                    : i == 1
                        ? 0.5 + _controller.value * 0.5
                        : 1.0 - _controller.value * 0.7);
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        AppColors.oliveGreen.withOpacity(opacity),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}