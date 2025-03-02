import 'package:chat_ai/blocs/chat_detail_bloc.dart';
import 'package:chat_ai/models/chat_model.dart';
import 'package:chat_ai/models/message_model.dart';
import 'package:chat_ai/widgets/audio_recorder.dart';
import 'package:chat_ai/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:chat_ai/blocs/chat_bloc.dart';
import 'package:chat_ai/utils/storage_util.dart';
//import 'package:record/record.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatDetailScreen({super.key, required this.chat});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class ChatDetailScreenWrapper extends StatelessWidget {
  final ChatModel chat;

  const ChatDetailScreenWrapper({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatDetailBloc(chat.id)..add(LoadMessages(chat.id)),
      child: ChatDetailScreen(chat: chat),
    );
  }
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRecording = false;
  bool _hasText = false;
  final StorageUtil _storageUtil = StorageUtil();

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final hasText = _messageController.text.isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      context.read<ChatDetailBloc>().add(SendMessageEvent(
            text: text,
            type: MessageType.text,
          ));
      _messageController.clear();
      setState(() {
        _hasText = false;
      });

      // Refresh the chat list
      context.read<ChatBloc>().add(LoadChatsEvent());

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // void _handleRecordingPressed() async {
  //   setState(() {
  //     _isRecording = !_isRecording;
  //   });
  //   print("handle");
  //   // Add your recording logic here
  //   // final audio = AudioRecorder();

  //   // if(await audio.hasPermission()){
  //   //   await audio.start(const RecordConfig(), path: 'aFullPath/myFile.m4a');
  //   // }
  //   AudioRecorder record = AudioRecorder(
  //     onAudioSaved: (String path) {
  //       print(path);
  //       context.read<ChatDetailBloc>().add(
  //             SendAudioMessageEvent(audioPath: path),
  //           );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Refresh chat list when going back
        context.read<ChatBloc>().add(LoadChatsEvent());
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () async {
              // Refresh chat list when pressing back button
              context.read<ChatBloc>().add(LoadChatsEvent());
              Navigator.pop(context);
            },
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: widget.chat.avatarColor,
                backgroundImage: widget.chat.avatarUrl != null
                    ? NetworkImage(widget.chat.avatarUrl!)
                    : null,
                child: widget.chat.avatarUrl == null
                    ? Text(
                        widget.chat.avatarText,
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.chat.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatDetailBloc, ChatDetailState>(
                builder: (context, state) {
                  if (state is ChatDetailLoaded) {
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messageGroups.length,
                      itemBuilder: (context, index) {
                        final messageGroup = state.messageGroups[
                            state.messageGroups.length - 1 - index];

                        return Column(
                          children: [
                            if (messageGroup.showDate)
                              DateSeparator(date: messageGroup.date),
                            ...messageGroup.messages.map(
                              (message) => MessageBubble(message: message),
                            ),
                          ],
                        );
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Files Part
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () => _showAttachmentOptions(context),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Message Input Part
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Сообщение',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  border: InputBorder.none,
                                ),
                                maxLines: null,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Send/Record Button Part
                    _hasText
                        ? AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _hasText ? Colors.blue : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    _hasText ? Colors.blue : Colors.grey[300]!,
                              ),
                            ),
                            child: IconButton(
                                icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (Widget child,
                                        Animation<double> animation) {
                                      return RotationTransition(
                                        turns: animation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: const Icon(
                                      Icons.send,
                                      key: ValueKey('send'),
                                      color: Colors.white,
                                    )),
                                onPressed: _sendMessage),
                          )
                        : AudioRecorder(
                            onAudioSaved: (String path) {
                              print(path);
                              _handleAudioSaved(path);
                            },
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Галерея',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                AttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Камера',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                AttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Файл',
                  onTap: () => _pickFile(),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      Navigator.pop(context); // Close bottom sheet first

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70, // Reduce image quality to save space
      );

      if (image != null) {
        _handleImageSelected(image);
      }
    } catch (e) {
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      Navigator.pop(context); // Close bottom sheet first

      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        _handleFileSelected(result.files.first);
      }
    } catch (e) {
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleImageSelected(XFile image) async {
    try {
      final File imageFile = File(image.path);
      if (await imageFile.exists()) {
        // Save image to local storage
        final String localPath =
            await _storageUtil.saveFile(image.path, 'images');

        context.read<ChatDetailBloc>().add(
              SendMessageEvent(
                text: '',
                fileUrl: localPath,
                fileName: image.name,
                type: MessageType.image,
              ),
            );

        context.read<ChatBloc>().add(LoadChatsEvent());
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Image file not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error handling image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleFileSelected(PlatformFile file) {
    context.read<ChatDetailBloc>().add(
          SendMessageEvent(
            text: '${(file.size / 1024).round()} KB',
            fileUrl: file.path,
            fileName: file.name,
            type: MessageType.file,
          ),
        );
  }

  Future<void> _handleAudioSaved(String audioPath) async {
    try {
      if (!mounted) return;

      // Save audio to local storage
      final String localPath = await _storageUtil.saveFile(audioPath, 'audio');

      if (!mounted) return;

      context.read<ChatDetailBloc>().add(
            SendMessageEvent(
              text: 'Voice message',
              fileUrl: localPath,
              fileName: path.basename(localPath),
              type: MessageType.audio,
            ),
          );

      // Clean up the original temporary file
      try {
        await File(audioPath).delete();
      } catch (e) {
        print('Error deleting temporary audio file: $e');
      }

      if (!mounted) return;
      context.read<ChatBloc>().add(LoadChatsEvent());
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const AttachmentOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}

// class MessageBubble extends StatelessWidget {
//   final Message message;

//   MessageBubble({super.key, required this.message});

//   @override
//   Widget build(BuildContext context) {
//     final isMe = message.isFromMe;
//     print(message);
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.green : Colors.grey[200],
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Text(
//               message.text,
//               style: TextStyle(
//                 color: isMe ? Colors.white : Colors.black,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               message.time,
//               style: TextStyle(
//                 color: isMe ? Colors.white70 : Colors.grey[600],
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({super.key, required this.date});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Сегодня';
    } else if (messageDate == yesterday) {
      return 'Вчера';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.grey[300]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }
}
