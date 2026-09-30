import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'customer_api.dart';

class MobileAiApi {
  MobileAiApi({
    required this.token,
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://talegaon-fresh-ai-backend.onrender.com',
        )).replaceFirst(RegExp(r'/+$'), '');

  final String token;
  final http.Client _client;
  final String _baseUrl;

  Future<String> chat(String message) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/customers/me/ai/chat'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message.trim()}),
    );

    if (response.statusCode == 401) {
      throw const CustomerApiException('Session expired.', statusCode: 401);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'AI assistant is temporarily unavailable.';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['detail'] is String) {
          message = body['detail'] as String;
        }
      } catch (_) {}
      throw CustomerApiException(message, statusCode: response.statusCode);
    }

    final body = jsonDecode(response.body);
    if (body is! Map || body['reply'] is! String) {
      throw const CustomerApiException('AI assistant returned an invalid response.');
    }
    return (body['reply'] as String).trim();
  }
}

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key, required this.token});

  final String token;

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  final messages = <_AiMessage>[
    const _AiMessage(
      text: 'Hi! I’m your FRESHORA assistant. Ask me about your order, tracking status, products, or how to place an order.',
      fromUser: false,
    ),
  ];
  late final MobileAiApi api;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    api = MobileAiApi(token: widget.token);
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;

    controller.clear();
    setState(() {
      messages.add(_AiMessage(text: text, fromUser: true));
      sending = true;
    });
    _scrollToBottom();

    try {
      final reply = await api.chat(text);
      if (!mounted) return;
      setState(() {
        messages.add(_AiMessage(text: reply, fromUser: false));
      });
    } on CustomerApiException catch (e) {
      if (!mounted) return;
      setState(() {
        messages.add(_AiMessage(text: e.message, fromUser: false, isError: true));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        messages.add(const _AiMessage(
          text: 'I could not reach the assistant. Please try again.',
          fromUser: false,
          isError: true,
        ));
      });
    } finally {
      if (mounted) {
        setState(() => sending = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _sendQuickPrompt(String value) async {
    controller.text = value;
    await send();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Fresh AI Assistant'),
          actions: [
            IconButton(
              tooltip: 'New conversation',
              onPressed: sending
                  ? null
                  : () => setState(() {
                        messages
                          ..clear()
                          ..add(const _AiMessage(
                            text: 'Hi! I’m ready to help. Ask about your latest order, tracking, products, or checkout.',
                            fromUser: false,
                          ));
                      }),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (messages.length == 1 && !sending)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickPrompt(
                        label: 'Track my latest order',
                        onTap: () => _sendQuickPrompt('Track my latest order'),
                      ),
                      _QuickPrompt(
                        label: 'What is my order number?',
                        onTap: () => _sendQuickPrompt('What is my order number?'),
                      ),
                      _QuickPrompt(
                        label: 'How do I order?',
                        onTap: () => _sendQuickPrompt('How do I place an order?'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  itemCount: messages.length + (sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (sending && index == messages.length) {
                      return const _TypingBubble();
                    }
                    final item = messages[index];
                    return _MessageBubble(message: item);
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => send(),
                        decoration: const InputDecoration(
                          hintText: 'Ask about FRESHORA…',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Send',
                      onPressed: sending ? null : send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _AiMessage {
  const _AiMessage({
    required this.text,
    required this.fromUser,
    this.isError = false,
  });

  final String text;
  final bool fromUser;
  final bool isError;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _AiMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.fromUser ? Alignment.centerRight : Alignment.centerLeft;
    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: message.isError
              ? Theme.of(context).colorScheme.errorContainer
              : message.fromUser
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.fromUser ? 18 : 4),
            bottomRight: Radius.circular(message.fromUser ? 4 : 18),
          ),
          border: Border.all(
            color: message.fromUser
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFFE2E8E3),
          ),
        ),
        child: Text(message.text, style: TextStyle(color: message.fromUser ? Colors.white : Colors.black87, height: 1.35)),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const SizedBox(
            width: 24,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
}

class _QuickPrompt extends StatelessWidget {
  const _QuickPrompt({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        label: Text(label),
        avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
        onPressed: onTap,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFD7E0DA)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      );
}
