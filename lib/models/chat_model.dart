import 'package:flutter/material.dart';

class ChatModel {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final String avatarText;
  final Color avatarColor;
  final String? avatarUrl;
  final DateTime timestamp;

  ChatModel({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatarText,
    required this.avatarColor,
    this.avatarUrl,
    required this.timestamp,
  });

  ChatModel copyWith({
    String? id,
    String? name,
    String? lastMessage,
    String? time,
    String? avatarText,
    Color? avatarColor,
    String? avatarUrl,
    DateTime? timestamp,
  }) {
    return ChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      avatarText: avatarText ?? this.avatarText,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
