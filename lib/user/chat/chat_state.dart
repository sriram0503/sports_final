import 'package:equatable/equatable.dart';

abstract class ChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatListLoaded extends ChatState {
  final List<Map<String, String>> chats;
  ChatListLoaded(this.chats);
  @override
  List<Object?> get props => [chats];
}

class ChatMessagesLoaded extends ChatState {
  final List<Map<String, String>> messages;
  ChatMessagesLoaded(this.messages);
  @override
  List<Object?> get props => [messages];
}
