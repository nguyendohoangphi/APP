// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'package:coffeeapp/constants/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final bool? isDark;
  const ChatScreen({super.key, this.isDark});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text;
    setState(() {
      _messages.add({"role": "user", "content": userMessage});
      _isLoading = true;
    });
    _controller.clear();

    // Call AI API
    final response = await _chatService.sendMessage(userMessage);

    setState(() {
      _messages.add({"role": "ai", "content": response});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determines theme based on passed isDark parameter or System Theme
    final bool useDark =
        widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final theme = useDark ? AppTheme.darkTheme : AppTheme.lightTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("PhiNoM AI"),
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == "user";
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? theme.primaryColor.withOpacity(0.1)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isUser
                            ? Border.all(
                                color: theme.primaryColor.withOpacity(0.2),
                              )
                            : Border.all(color: theme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: Text(
                        msg['content'] ?? "",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.primaryColor,
                    ),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor, // Blend with background
                border: Border(
                  top: BorderSide(color: theme.dividerColor, width: 0.5),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: TextField(
                          controller: _controller,
                          style: theme.textTheme.bodyLarge,
                          cursorColor: theme.primaryColor,
                          cursorWidth: 2,
                          cursorRadius: const Radius.circular(2),
                          decoration: InputDecoration(
                            hintText: "Hỏi AI về menu...",
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF2C3035)
                                : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: isDark
                                  ? BorderSide.none
                                  : BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: theme.primaryColor,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: theme.primaryColor,
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: theme.primaryColor.withOpacity(0.4),
                      child: InkWell(
                        onTap: _sendMessage,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
