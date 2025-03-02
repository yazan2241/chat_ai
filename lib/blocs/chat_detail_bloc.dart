import 'package:chat_ai/models/message_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:chat_ai/database/database_helper.dart';

// Events
abstract class ChatDetailEvent {}

class LoadMessages extends ChatDetailEvent {
  final String chatId;
  LoadMessages(this.chatId);
}

class SendMessageEvent extends ChatDetailEvent {
  final String text;
  final String? fileUrl;
  final String? fileName;
  final MessageType type;

  SendMessageEvent({
    required this.text,
    this.fileUrl,
    this.fileName,
    required this.type,
  });
}

class SendAudioMessageEvent extends ChatDetailEvent {
  final String audioPath;
  SendAudioMessageEvent({required this.audioPath});
}

// States
abstract class ChatDetailState {}

class ChatDetailInitial extends ChatDetailState {}

class ChatDetailLoading extends ChatDetailState {}

class ChatDetailLoaded extends ChatDetailState {
  final List<MessageGroup> messageGroups;
  ChatDetailLoaded(this.messageGroups);
}

class ChatDetailBloc extends Bloc<ChatDetailEvent, ChatDetailState> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final String chatId;

  ChatDetailBloc(this.chatId) : super(ChatDetailInitial()) {
    on<LoadMessages>((event, emit) async {
      emit(ChatDetailLoading());

      try {
        final messages = await _databaseHelper.getMessages(chatId);
        final groupedMessages = _groupMessagesByDate(messages);
        emit(ChatDetailLoaded(groupedMessages));
      } catch (e) {
        print('Error loading messages: $e');
        emit(ChatDetailLoaded([]));
      }
    });

    on<SendMessageEvent>((event, emit) async {
      if (state is ChatDetailLoaded) {
        final currentState = state as ChatDetailLoaded;

        final newMessage = Message(
          id: DateTime.now().toString(),
          text: event.text,
          fileUrl: event.fileUrl,
          fileName: event.fileName,
          time: DateFormat('HH:mm').format(DateTime.now()),
          isFromMe: true,
          timestamp: DateTime.now(),
          type: event.type,
        );

        // Save message to database
        await _databaseHelper.insertMessage(chatId, newMessage);

        final allMessages = [
          ...currentState.messageGroups.expand((group) => group.messages),
          newMessage,
        ];

        final updatedGroups = _groupMessagesByDate(allMessages);
        emit(ChatDetailLoaded(updatedGroups));
      }
    });

    on<SendAudioMessageEvent>((event, emit) async {
      if (state is ChatDetailLoaded) {
        final currentState = state as ChatDetailLoaded;

        final newMessage = Message(
          id: DateTime.now().toString(),
          text: 'Audio Message',
          fileUrl: event.audioPath,
          fileName: 'audio_message.m4a',
          time: DateFormat('HH:mm').format(DateTime.now()),
          isFromMe: true,
          timestamp: DateTime.now(),
          type: MessageType.audio,
        );

        // Save message to database
        await _databaseHelper.insertMessage(chatId, newMessage);

        final allMessages = [
          ...currentState.messageGroups.expand((group) => group.messages),
          newMessage,
        ];

        final updatedGroups = _groupMessagesByDate(allMessages);
        emit(ChatDetailLoaded(updatedGroups));
      }
    });
  }

  List<MessageGroup> _groupMessagesByDate(List<Message> messages) {
    // Sort messages by timestamp in ascending order (oldest first)
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final groups = <MessageGroup>[];
    DateTime? currentDate;
    List<Message> currentMessages = [];

    for (final message in messages) {
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );

      if (currentDate != messageDate) {
        if (currentMessages.isNotEmpty) {
          groups.add(MessageGroup(
            date: currentDate!,
            messages: List.from(currentMessages),
            showDate: true,
          ));
          currentMessages.clear();
        }
        currentDate = messageDate;
      }
      currentMessages.add(message);
    }

    if (currentMessages.isNotEmpty) {
      groups.add(MessageGroup(
        date: currentDate!,
        messages: currentMessages,
        showDate: true,
      ));
    }

    return groups;
  }
}
