import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';

// Post Model with null safety
class Post {
  final String id;
  final String userId;
  final String caption;
  final DateTime timestamp;
  final String mediaUrl;
  final String mediaType;
  final int likes;
  final List<dynamic> comments;
  final String? userProfileImage;
  final String? userName;

  Post({
    required this.id,
    required this.userId,
    required this.caption,
    required this.timestamp,
    required this.mediaUrl,
    required this.mediaType,
    required this.likes,
    required this.comments,
    this.userProfileImage,
    this.userName,
  });

  factory Post.fromFirestore(DocumentSnapshot doc, Map<String, dynamic>? userData) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Safe data extraction with null checks
    final String userId = data['userId']?.toString() ?? 'unknown_user';
    final String caption = data['caption']?.toString() ?? '';
    final Timestamp timestamp = data['timestamp'] as Timestamp? ?? Timestamp.now();
    final String mediaUrl = data['mediaUrl']?.toString() ?? '';
    final String mediaType = data['mediaType']?.toString() ?? 'image';
    final int likes = (data['likes'] as num?)?.toInt() ?? 0;
    final List<dynamic> comments = data['comments'] as List<dynamic>? ?? [];

    // Safe user data extraction
    String? userProfileImage;
    String? userName;

    if (userData != null) {
      userProfileImage = userData['profileImageUrl']?.toString();
      final firstName = userData['first_name']?.toString() ?? '';
      final lastName = userData['last_name']?.toString() ?? '';
      userName = '$firstName $lastName'.trim();
      if (userName.isEmpty) {
        userName = userData['email']?.toString() ?? 'Unknown User';
      }
    }

    return Post(
      id: doc.id,
      userId: userId,
      caption: caption,
      timestamp: timestamp.toDate(),
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      likes: likes,
      comments: comments,
      userProfileImage: userProfileImage,
      userName: userName,
    );
  }
}

// Home Bloc with better error handling
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  HomeBloc() : super(HomeState()) {
    on<LoadPosts>(_onLoadPosts);
    on<LikePost>(_onLikePost);
    on<AddComment>(_onAddComment);
  }

  Future<void> _onLoadPosts(LoadPosts event, Emitter<HomeState> emit) async {
    try {
      emit(state.copyWith(isLoading: true, error: ''));

      // Get all posts with error handling for each post
      final postsSnapshot = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();

      List<Post> posts = [];

      // Fetch user data for each post with individual error handling
      for (var postDoc in postsSnapshot.docs) {
        try {
          final postData = postDoc.data();
          final String userId = postData['userId']?.toString() ?? 'unknown';

          Map<String, dynamic>? userData;
          try {
            if (userId != 'unknown') {
              final userDoc = await _firestore.collection('users').doc(userId).get();
              if (userDoc.exists) {
                userData = userDoc.data() as Map<String, dynamic>?;
              }
            }
          } catch (e) {
            debugPrint('Error fetching user data for user $userId: $e');
            // Continue with null user data
          }

          posts.add(Post.fromFirestore(postDoc, userData));
        } catch (e) {
          debugPrint('Error processing post ${postDoc.id}: $e');
          // Skip this post but continue with others
        }
      }

      emit(state.copyWith(
        posts: posts,
        isLoading: false,
        error: '',
      ));
    } catch (e) {
      debugPrint('HomeBloc error: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load posts. Please check your connection.',
      ));
    }
  }

  Future<void> _onLikePost(LikePost event, Emitter<HomeState> emit) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final postRef = _firestore.collection('posts').doc(event.postId);
      final postDoc = await postRef.get();

      if (postDoc.exists) {
        final data = postDoc.data() ?? {};
        final likes = (data['likes'] as num?)?.toInt() ?? 0;
        final likedBy = List<String>.from(data['likedBy'] as List<dynamic>? ?? []);

        if (likedBy.contains(currentUserId)) {
          // Unlike
          await postRef.update({
            'likes': likes - 1,
            'likedBy': FieldValue.arrayRemove([currentUserId])
          });
        } else {
          // Like
          await postRef.update({
            'likes': likes + 1,
            'likedBy': FieldValue.arrayUnion([currentUserId])
          });
        }

        // Reload posts to reflect the change
        add(LoadPosts());
      }
    } catch (e) {
      debugPrint('Error liking post: $e');
    }
  }

  Future<void> _onAddComment(AddComment event, Emitter<HomeState> emit) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      Map<String, dynamic>? userData;
      try {
        final userDoc = await _firestore.collection('users').doc(currentUserId).get();
        userData = userDoc.data() as Map<String, dynamic>?;
      } catch (e) {
        debugPrint('Error fetching user data for comment: $e');
      }

      final userName = userData != null
          ? '${userData['first_name']?.toString() ?? ''} ${userData['last_name']?.toString() ?? ''}'.trim()
          : 'Unknown User';

      final comment = {
        'userId': currentUserId,
        'userName': userName,
        'text': event.commentText,
        'timestamp': Timestamp.now(),
      };

      await _firestore.collection('posts').doc(event.postId).update({
        'comments': FieldValue.arrayUnion([comment])
      });

      // Reload posts to reflect the change
      add(LoadPosts());
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }
}

// Home Events
abstract class HomeEvent {}

class LoadPosts extends HomeEvent {}

class LikePost extends HomeEvent {
  final String postId;
  LikePost(this.postId);
}

class AddComment extends HomeEvent {
  final String postId;
  final String commentText;
  AddComment(this.postId, this.commentText);
}

// Home State
class HomeState {
  final List<Post> posts;
  final bool isLoading;
  final String error;

  HomeState({
    this.posts = const [],
    this.isLoading = false,
    this.error = '',
  });

  HomeState copyWith({
    List<Post>? posts,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Video Player Widget
class VideoPostPlayer extends StatefulWidget {
  final String videoUrl;

  const VideoPostPlayer({super.key, required this.videoUrl});

  @override
  State<VideoPostPlayer> createState() => _VideoPostPlayerState();
}

class _VideoPostPlayerState extends State<VideoPostPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..addListener(() {
          if (_controller.value.isInitialized && !_isInitialized) {
            setState(() => _isInitialized = true);
          }
        })
        ..initialize().then((_) {
          setState(() {});
        });
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          if (!_isInitialized)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          if (_isInitialized && !_controller.value.isPlaying)
            Container(
              color: Colors.black54,
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 50,
              ),
            ),
        ],
      ),
    );
  }
}

// Post Card Widget
class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final TextEditingController _commentController = TextEditingController();
  bool _showComments = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          _buildPostHeader(),

          // Media content
          _buildMediaContent(),

          // Action buttons
          _buildActionButtons(),

          // Likes and caption
          _buildPostInfo(),

          // Comments section
          _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.post.userProfileImage != null &&
                widget.post.userProfileImage!.isNotEmpty
                ? NetworkImage(widget.post.userProfileImage!)
                : const AssetImage("assets/profile_placeholder.png") as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.userName ?? 'Unknown User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat('MMM d, yyyy • hh:mm a').format(widget.post.timestamp),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    if (widget.post.mediaUrl.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.photo, size: 50, color: Colors.grey),
        ),
      );
    }

    return widget.post.mediaType == 'video'
        ? VideoPostPlayer(videoUrl: widget.post.mediaUrl)
        : Image.network(
      widget.post.mediaUrl,
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 300,
          color: Colors.grey[200],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 50, color: Colors.red),
              SizedBox(height: 10),
              Text('Failed to load image'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              context.read<HomeBloc>().add(LikePost(widget.post.id));
            },
            icon: Icon(
              Icons.favorite_border,
              color: Colors.grey[700],
              size: 28,
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showComments = !_showComments),
            icon: Icon(Icons.chat_bubble_outline, color: Colors.grey[700], size: 28),
          ),
          const Spacer(),
          Text(
            '${widget.post.likes} likes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: '${widget.post.userName} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: widget.post.caption),
                  ],
                ),
              ),
            ),
          if (widget.post.comments.isNotEmpty && !_showComments)
            TextButton(
              onPressed: () => setState(() => _showComments = true),
              child: Text(
                'View all ${widget.post.comments.length} comments',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (!_showComments) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ...widget.post.comments.map((comment) {
            final commentData = comment as Map<String, dynamic>? ?? {};
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: '${commentData['userName'] ?? 'User'} ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: commentData['text']?.toString() ?? ''),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          // Add comment input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final homeBloc = context.read<HomeBloc>();
                  if (_commentController.text.trim().isNotEmpty) {
                    homeBloc.add(AddComment(widget.post.id, _commentController.text.trim()));
                    _commentController.clear();
                  }
                },
                child: const Text('Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Home Page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load posts when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeBloc>().add(LoadPosts());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Sports connect',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.read<HomeBloc>().add(LoadPosts());
            },
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state.isLoading && state.posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading posts...'),
                ],
              ),
            );
          }

          if (state.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Posts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.read<HomeBloc>().add(LoadPosts()),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (state.posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'No posts yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Be the first to create a post!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<HomeBloc>().add(LoadPosts());
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.posts.length,
              itemBuilder: (context, index) {
                return PostCard(post: state.posts[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

// Main App with Bloc Provider
class SocialApp extends StatelessWidget {
  const SocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BlocProvider(
        create: (context) => HomeBloc(),
        child: const HomePage(),
      ),
    );
  }
}