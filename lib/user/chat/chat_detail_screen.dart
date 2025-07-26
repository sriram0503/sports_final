import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import 'chat_widgets/chat_bubble.dart';
import 'chat_widgets/chat_input_field.dart';

class ChatDetailScreen extends StatelessWidget {
  final String chatId;
  const ChatDetailScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatBloc()..add(LoadMessages(chatId)),
      child: Scaffold(
        appBar: AppBar(title: Text(chatId)),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ChatMessagesLoaded) {
                    return ListView.builder(
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final msg = state.messages[index];
                        return ChatBubble(
                          text: msg["text"]!,
                          isMe: msg["sender"] == "me",
                        );
                      },
                    );
                  }
                  return const Center(child: Text("No messages"));
                },
              ),
            ),
            ChatInputField(
              onSend: (message) {
                context.read<ChatBloc>().add(SendMessage(chatId, message));
              },
            ),
          ],
        ),
      ),
    );
  }
}
