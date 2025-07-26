import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(ChatInitial()) {
    on<LoadChats>((event, emit) async {
      emit(ChatLoading());
      // Mock chat list
      await Future.delayed(const Duration(milliseconds: 500));
      emit(ChatListLoaded([
        {"name": "Coach John", "lastMessage": "Great job!", "time": "5m"},
        {"name": "Parent Alice", "lastMessage": "Thank you!", "time": "10m"},
      ]));
    });

    on<LoadMessages>((event, emit) async {
      emit(ChatLoading());
      // Mock messages
      await Future.delayed(const Duration(milliseconds: 500));
      emit(ChatMessagesLoaded([
        {"sender": "me", "text": "Hello!"},
        {"sender": "other", "text": "Hi there!"},
      ]));
    });

    on<SendMessage>((event, emit) {
      if (state is ChatMessagesLoaded) {
        final currentMessages = List<Map<String, String>>.from(
            (state as ChatMessagesLoaded).messages);
        currentMessages.add({"sender": "me", "text": event.message});
        emit(ChatMessagesLoaded(currentMessages));
      }
    });
  }
}
