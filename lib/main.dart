import 'dart:io';

import 'package:flutter/material.dart';
import 'package:chat_ai/Chat.dart';
import 'package:chat_ai/blocs/chat_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:chat_ai/database/database_helper.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Delete existing database and rebcreate it
  final dbHelper = DatabaseHelper();
  //await dbHelper.deleteDatabase();
  await dbHelper.database; // This will trigger database creation

  runApp(
    BlocProvider(
      create: (context) => ChatBloc()..add(LoadChatsEvent()),
      child: const Chat(),
    ),
  );
}
