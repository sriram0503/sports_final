import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

const Color appPrimaryColor = Color(0xFF1994DD);
const Color appSecondaryColor = Color(0xFF22C493);

class ChatListPage extends StatefulWidget {
  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _buildChatList(),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          print('Chat Stream Error: ${snapshot.error}');
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final chats = snapshot.data!.docs;
        print('Found ${chats.length} chat rooms');

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: chats.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chatDoc = chats[index];
            final chatData = chatDoc.data() as Map<String, dynamic>? ?? {};

            print('Chat ${index + 1} data: $chatData');

            return _buildChatListItem(chatDoc.id, chatData);
          },
        );
      },
    );
  }

  Widget _buildChatListItem(String chatId, Map<String, dynamic> chatData) {
    try {
      // Get participants list
      final participants = _getParticipantsList(chatData['participants']);
      if (participants.isEmpty) {
        return _buildErrorChatItem('Invalid chat data');
      }

      // Find the other user's ID
      final otherUserId = participants.firstWhere(
            (id) => id != currentUser.uid,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) {
        return _buildErrorChatItem('No other user found');
      }

      // Get participant names
      final participantNames = _getParticipantNames(chatData['participantNames']);
      final otherUserName = participantNames[otherUserId] ?? 'Unknown User';
      final lastMessage = _getString(chatData['lastMessage'] ?? 'No messages yet');
      final lastMessageTime = chatData['lastMessageTime'] ?? chatData['createdAt'];
      final lastMessageSender = _getString(chatData['lastMessageSender']);

      // Check if unread
      final isUnread = lastMessageSender != currentUser.uid &&
          chatData['isRead'] != true;

      return ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: appPrimaryColor,
            child: Text(
              otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          otherUserName,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          lastMessage,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTimestamp(lastMessageTime),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
            if (isUnread) ...[
              const SizedBox(height: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: appPrimaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullChatPage(
                chatId: chatId,
                otherUserId: otherUserId,
                otherUserName: otherUserName,
                otherUserType: chatData['otherUserType'],
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('Error building chat item: $e');
      return _buildErrorChatItem('Error loading chat');
    }
  }

  Widget _buildErrorChatItem(String error) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.red,
        child: Icon(Icons.error, color: Colors.white, size: 20),
      ),
      title: const Text(
        'Error loading chat',
        style: TextStyle(color: Colors.red),
      ),
      subtitle: Text(
        error,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.grey),
          title: Container(
            height: 16,
            width: 120,
            color: Colors.grey.shade300,
          ),
          subtitle: Container(
            height: 12,
            width: 180,
            color: Colors.grey.shade300,
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          const Text(
            'Unable to load messages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error.length > 100 ? '${error.substring(0, 100)}...' : error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: appPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text(
            'No Messages Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Start a conversation by searching for players or coaches and sending them a message.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: appPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Find People to Chat',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getParticipantsList(dynamic participantsData) {
    if (participantsData is List) {
      return participantsData.map((item) => item.toString()).toList();
    }
    return [];
  }

  Map<String, String> _getParticipantNames(dynamic namesData) {
    if (namesData is Map) {
      final Map<String, String> result = {};
      namesData.forEach((key, value) {
        result[key.toString()] = value.toString();
      });
      return result;
    }
    return {};
  }

  String _getString(dynamic value) {
    if (value is String) {
      return value;
    }
    return value?.toString() ?? 'No messages yet';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return '';
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 6) {
        return DateFormat('MMM dd').format(date);
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return '';
    }
  }
}

class FullChatPage extends StatefulWidget {
  final String? chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserType;

  const FullChatPage({
    Key? key,
    this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserType,
  }) : super(key: key);

  @override
  _FullChatPageState createState() => _FullChatPageState();
}

class _FullChatPageState extends State<FullChatPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String? _chatId;

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId;
    if (_chatId == null) {
      _findOrCreateChat();
    }
  }

  Future<void> _findOrCreateChat() async {
    try {
      // Try to find existing chat
      final chatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      for (var doc in chatQuery.docs) {
        final participants = List<String>.from(doc['participants'] ?? []);
        if (participants.contains(widget.otherUserId)) {
          setState(() {
            _chatId = doc.id;
          });
          return;
        }
      }

      // Create new chat if not found
      final newChatId = _firestore.collection('chats').doc().id;
      await _firestore.collection('chats').doc(newChatId).set({
        'participants': [currentUser.uid, widget.otherUserId],
        'participantNames': {
          currentUser.uid: currentUser.displayName ?? 'User',
          widget.otherUserId: widget.otherUserName
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': '',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'otherUserType': widget.otherUserType,
      });

      setState(() {
        _chatId = newChatId;
      });
    } catch (e) {
      print('Error finding/creating chat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: appPrimaryColor,
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (widget.otherUserType != null)
                  Text(
                    widget.otherUserType == 'coach' ? 'Coach' : 'Player',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _chatId == null
          ? const Center(child: CircularProgressIndicator())
          : _buildChatScreen(),
    );
  }

  Widget _buildChatScreen() {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading messages: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyChatState();
                }

                final docs = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};

                    final messageText = _getString(data['text']);
                    final senderId = _getString(data['senderId']);
                    final isMe = senderId == currentUser.uid;
                    final timestamp = data['timestamp'];

                    return MessageBubble(
                      message: messageText,
                      isMe: isMe,
                      timestamp: timestamp,
                    );
                  },
                );
              },
            ),
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.grey.shade600),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 100),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: "Message...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    _sendMessage(text.trim());
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: appPrimaryColor,
            radius: 24,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: () {
                if (_messageController.text.trim().isNotEmpty) {
                  _sendMessage(_messageController.text.trim());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (_chatId == null || text.trim().isEmpty) return;

    final timestamp = Timestamp.now();

    final messageData = {
      'messageId': '${timestamp.seconds}_${currentUser.uid}',
      'senderId': currentUser.uid,
      'receiverId': widget.otherUserId,
      'text': text.trim(),
      'timestamp': timestamp,
      'type': 'text',
      'isRead': false,
    };

    try {
      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .doc(messageData['messageId'] as String)
          .set(messageData);

      // Update chat document with latest message info
      await _firestore.collection('chats').doc(_chatId!).set({
        'participants': [currentUser.uid, widget.otherUserId],
        'participantNames': {
          currentUser.uid: currentUser.displayName ?? 'User',
          widget.otherUserId: widget.otherUserName
        },
        'lastMessage': text.trim(),
        'lastMessageTime': timestamp,
        'lastMessageSender': currentUser.uid,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'otherUserType': widget.otherUserType,
      }, SetOptions(merge: true));

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _getString(dynamic value) {
    if (value is String) {
      return value;
    }
    return value?.toString() ?? '';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final dynamic timestamp;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 12, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? appPrimaryColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 12,
              backgroundColor: appPrimaryColor,
              child: Icon(Icons.person, size: 12, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}