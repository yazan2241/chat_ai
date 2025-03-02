import 'package:chat_ai/models/message_model.dart';
import 'package:chat_ai/widgets/audio_message.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:chat_ai/utils/storage_util.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final StorageUtil _storageUtil = StorageUtil();

  MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isFromMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildMessageContent(context),
            const SizedBox(height: 2),
            Text(
              message.time,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: message.isFromMe ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: message.isFromMe ? Colors.white : Colors.black,
              fontSize: 16,
            ),
          ),
        );

      case MessageType.image:
        return FutureBuilder<bool>(
          future: _storageUtil.fileExists(message.fileUrl ?? ''),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.transparent,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(message.fileUrl!),
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width * 0.7,
                  ),
                ),
              );
            } else {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.broken_image),
              );
            }
          },
        );

      case MessageType.audio:
        return FutureBuilder<bool>(
          future: _storageUtil.fileExists(message.fileUrl ?? ''),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return AudioMessage(
                audioPath: message.fileUrl!,
                isFromMe: message.isFromMe,
              );
            } else {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Audio file not found'),
              );
            }
          },
        );

      case MessageType.file:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: message.isFromMe ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file,
                color: message.isFromMe ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.fileName!,
                      style: TextStyle(
                        color: message.isFromMe ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (message.text.isNotEmpty)
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isFromMe
                              ? Colors.white70
                              : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}
