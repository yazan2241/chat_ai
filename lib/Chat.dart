import 'package:chat_ai/blocs/chat_bloc.dart';
import 'package:chat_ai/blocs/chat_detail_bloc.dart';
import 'package:chat_ai/models/chat_model.dart';
import 'package:chat_ai/screens/chat_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh chat list when app comes to foreground
      context.read<ChatBloc>().add(LoadChatsEvent());
    }
  }

  void _onSearchChanged() {
    context.read<ChatBloc>().add(SearchChatsEvent(_searchController.text));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Чаты',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Chat List
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ChatLoaded) {
                    if (state.filteredChats.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No chats found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: state.filteredChats.length,
                      itemBuilder: (context, index) {
                        final chat = state.filteredChats[index];
                        return ChatListItem(chat: chat);
                      },
                    );
                  }
                  return const Center(child: Text('No chats found'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatListItem extends StatelessWidget {
  final ChatModel chat;

  const ChatListItem({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Chat'),
              content: Text(
                  'Are you sure you want to delete chat with ${chat.name}?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        context.read<ChatBloc>().add(DeleteChatEvent(chat.id));
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) =>
                    ChatDetailBloc(chat.id)..add(LoadMessages(chat.id)),
                child: ChatDetailScreen(chat: chat),
              ),
            ),
          );
          if (context.mounted) {
            context.read<ChatBloc>().add(LoadChatsEvent());
          }
        },
        leading: CircleAvatar(
          backgroundColor: chat.avatarColor,
          backgroundImage:
              chat.avatarUrl != null ? NetworkImage(chat.avatarUrl!) : null,
          child: chat.avatarUrl == null
              ? Text(
                  chat.avatarText,
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chat.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chat.time.isNotEmpty)
              Text(
                chat.time,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        subtitle: chat.lastMessage.isNotEmpty
            ? Text(
                chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              )
            : null,
      ),
    );
  }
}
