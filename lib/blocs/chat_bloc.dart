import 'package:chat_ai/Chat.dart';
import 'package:chat_ai/models/chat_model.dart';
import 'package:chat_ai/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_ai/database/database_helper.dart';
import 'dart:async';

// Events
abstract class ChatEvent {}

class LoadChatsEvent extends ChatEvent {}

class SearchChatsEvent extends ChatEvent {
  final String query;
  SearchChatsEvent(this.query);
}

class DeleteChatEvent extends ChatEvent {
  final String chatId;
  DeleteChatEvent(this.chatId);
}

// States
abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatModel> chats;
  final List<ChatModel> filteredChats;
  final String searchQuery;

  ChatLoaded({
    required this.chats,
    required this.filteredChats,
    this.searchQuery = '',
  });

  ChatLoaded copyWith({
    List<ChatModel>? chats,
    List<ChatModel>? filteredChats,
    String? searchQuery,
  }) {
    return ChatLoaded(
      chats: chats ?? this.chats,
      filteredChats: filteredChats ?? this.filteredChats,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  ChatBloc() : super(ChatInitial()) {
    on<LoadChatsEvent>((event, emit) async {
      emit(ChatLoading());
      try {
        print("start loading chats");
        final chats = await _databaseHelper.getChatsWithLastMessages();
        print("chat loaded");
        emit(ChatLoaded(chats: chats, filteredChats: chats));
        print("chat emitted");
      } catch (e) {
        print('Error loading chats: $e');
        emit(ChatLoaded(chats: [], filteredChats: []));
      }
    });

    on<SearchChatsEvent>((event, emit) {
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        final query = event.query.toLowerCase();

        final filteredChats = query.isEmpty
            ? currentState.chats
            : currentState.chats.where((chat) {
                return chat.name.toLowerCase().contains(query) ||
                    chat.lastMessage.toLowerCase().contains(query);
              }).toList();

        emit(currentState.copyWith(
          filteredChats: filteredChats,
          searchQuery: query,
        ));
      }
    });

    on<DeleteChatEvent>((event, emit) async {
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;

        await _databaseHelper.deleteChat(event.chatId);

        final updatedChats = currentState.chats
            .where((chat) => chat.id != event.chatId)
            .toList();

        emit(ChatLoaded(
          chats: updatedChats,
          filteredChats: updatedChats,
          searchQuery: currentState.searchQuery,
        ));
      }
    });
  }

  @override
  Future<void> close() {
    return super.close();
  }

  String _getMessagePreview(Message message) {
    switch (message.type) {
      case MessageType.text:
        return message.text;
      case MessageType.image:
        return '📷 Photo';
      case MessageType.audio:
        return '🎵 Voice message';
      case MessageType.file:
        return '📎 ${message.fileName ?? 'File'}';
      default:
        return message.text;
    }
  }
}
