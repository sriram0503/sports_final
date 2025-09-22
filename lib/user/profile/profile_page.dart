import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryPublic _cloudinary = CloudinaryPublic('dboltoh0q', 'flutter_present', cache: false);

  User? _user;
  Map<String, dynamic> _userData = {};
  List<String> _achievements = [];
  List<Map<String, dynamic>> _userPosts = [];

  bool _isUploadingProfile = false;
  bool _isUploadingBackground = false;
  bool _isUploadingPost = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    setState(() {
      _user = _auth.currentUser;
    });

    if (_user != null) {
      await _fetchUserData();
      await _fetchUserPosts();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(_user!.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
          _achievements = List<String>.from(_userData['achievements'] ?? []);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading profile: $e');
    }
  }

  Future<void> _fetchUserPosts() async {
    try {
      if (_user == null) return;

      final QuerySnapshot postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: _user!.uid)
          .get();

      final List<Map<String, dynamic>> posts = postsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'userId': data['userId'],
          'caption': data['caption'] ?? '',
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
          'mediaUrl': data['mediaUrl'],
          'mediaType': data['mediaType'] ?? 'image',
        };
      }).toList();

      posts.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      setState(() {
        _userPosts = posts;
      });

    } catch (e) {
      debugPrint('Posts loading issue: $e');
      setState(() {
        _userPosts = [];
      });
    }
  }

  // ✅ Enhanced Cloudinary upload for both images and videos
  Future<String?> _uploadMediaToCloudinary(File file, {String? mediaType}) async {
    try {
      // Determine if it's a video based on file extension or provided mediaType
      final isVideo = mediaType == 'video' ||
          file.path.toLowerCase().endsWith('.mp4') ||
          file.path.toLowerCase().endsWith('.mov') ||
          file.path.toLowerCase().endsWith('.avi');

      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: 'user_media/${_user!.uid}',
          resourceType: isVideo ? CloudinaryResourceType.Video : CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }

  // ✅ Video player widget for video posts
  Widget _buildVideoPlayer(String videoUrl) {
    return FutureBuilder<VideoPlayerController>(
      future: _initializeVideoController(videoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final controller = snapshot.data!;
          return AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(controller),
                Positioned.fill(
                  child: IconButton(
                    icon: Icon(
                      controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 50,
                    ),
                    onPressed: () {
                      setState(() {
                        if (controller.value.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            height: 300,
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  Future<VideoPlayerController> _initializeVideoController(String videoUrl) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    await controller.initialize();
    return controller;
  }

  Future<void> _pickImage(bool isProfile) async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Image Source"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text("Camera"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text("Gallery"),
          ),
        ],
      ),
    );

    if (source == null) return;

    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      await _uploadImageToCloudinary(File(pickedFile.path), isProfile);
    }
  }

  Future<void> _uploadImageToCloudinary(File image, bool isProfile) async {
    if (_user == null) return;

    try {
      setState(() {
        if (isProfile) {
          _isUploadingProfile = true;
        } else {
          _isUploadingBackground = true;
        }
      });

      final String? imageUrl = await _uploadMediaToCloudinary(image);

      if (imageUrl == null) {
        throw Exception('Failed to upload image to Cloudinary');
      }

      final String fieldName = isProfile ? 'profileImageUrl' : 'backgroundImageUrl';
      await _firestore.collection('users').doc(_user!.uid).update({
        fieldName: imageUrl,
      });

      setState(() {
        _userData[fieldName] = imageUrl;
        if (isProfile) {
          _isUploadingProfile = false;
        } else {
          _isUploadingBackground = false;
        }
      });

      _showSuccessSnackBar('${isProfile ? 'Profile' : 'Background'} image updated!');
    } catch (e) {
      setState(() {
        if (isProfile) {
          _isUploadingProfile = false;
        } else {
          _isUploadingBackground = false;
        }
      });
      _showErrorSnackBar('Upload failed: $e');
    }
  }

  // ✅ Enhanced create post with video support
  Future<void> _createPost() async {
    final String? mediaType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Media Type"),
        content: const Text("Choose what you want to post"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'image'),
            child: const Text("Image"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'video'),
            child: const Text("Video"),
          ),
        ],
      ),
    );

    if (mediaType == null) return;

    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Media Source"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text("Camera"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text("Gallery"),
          ),
        ],
      ),
    );

    if (source == null) return;

    XFile? pickedFile;
    if (mediaType == 'image') {
      pickedFile = await _picker.pickImage(source: source);
    } else {
      pickedFile = await _picker.pickVideo(source: source);
    }

    if (pickedFile != null) {
      await _showPostDialog(File(pickedFile.path), mediaType);
    }
  }

  // ✅ Enhanced post dialog for both images and videos
  Future<void> _showPostDialog(File mediaFile, String mediaType) async {
    final TextEditingController captionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create ${mediaType == 'image' ? 'Image' : 'Video'} Post"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mediaType == 'image')
              Image.file(mediaFile, height: 200, fit: BoxFit.cover)
            else
              Container(
                height: 200,
                color: Colors.black,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam, color: Colors.white, size: 50),
                    SizedBox(height: 10),
                    Text("Video Selected", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: captionController,
              decoration: const InputDecoration(
                labelText: "Caption",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _savePost(mediaFile, captionController.text.trim(), mediaType);
            },
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }

  // ✅ Enhanced save post for both images and videos
  Future<void> _savePost(File mediaFile, String caption, String mediaType) async {
    if (_user == null) return;

    try {
      setState(() => _isUploadingPost = true);

      // Show upload progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text("Uploading ${mediaType == 'image' ? 'Image' : 'Video'}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text("Please wait while your ${mediaType == 'image' ? 'image' : 'video'} is being uploaded..."),
            ],
          ),
        ),
      );

      final String? mediaUrl = await _uploadMediaToCloudinary(mediaFile, mediaType: mediaType);

      // Close progress dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (mediaUrl == null) {
        throw Exception('Failed to upload media to Cloudinary');
      }

      final postData = {
        'userId': _user!.uid,
        'caption': caption,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'timestamp': Timestamp.now(),
        'likes': 0,
        'comments': [],
      };

      await _firestore.collection('posts').add(postData);

      await _fetchUserPosts();
      _showSuccessSnackBar('${mediaType == 'image' ? 'Image' : 'Video'} posted successfully!');

    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog on error
      }
      _showErrorSnackBar('Error saving post: $e');
    } finally {
      setState(() => _isUploadingPost = false);
    }
  }

  void _editProfileInfo() {
    final TextEditingController firstNameCtrl = TextEditingController(text: _userData['first_name'] ?? '');
    final TextEditingController lastNameCtrl = TextEditingController(text: _userData['last_name'] ?? '');
    final TextEditingController bioCtrl = TextEditingController(text: _userData['bio'] ?? '');
    final TextEditingController phoneCtrl = TextEditingController(text: _userData['phone'] ?? '');
    final TextEditingController locationCtrl = TextEditingController(text: _userData['location_address'] ?? '');
    final TextEditingController ageCtrl = TextEditingController(text: _userData['age']?.toString() ?? '');
    final TextEditingController heightCtrl = TextEditingController(text: _userData['height']?.toString() ?? '');
    final TextEditingController weightCtrl = TextEditingController(text: _userData['weight']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile Info"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: "First Name")),
              const SizedBox(height: 10),
              TextField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: "Last Name")),
              const SizedBox(height: 10),
              TextField(controller: bioCtrl, decoration: const InputDecoration(labelText: "Bio"), maxLines: 2),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone")),
              const SizedBox(height: 10),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: "Location")),
              const SizedBox(height: 10),
              TextField(controller: ageCtrl, decoration: const InputDecoration(labelText: "Age"), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              TextField(controller: heightCtrl, decoration: const InputDecoration(labelText: "Height (cm)"), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              TextField(controller: weightCtrl, decoration: const InputDecoration(labelText: "Weight (kg)"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => _updateProfileInfo(
              firstNameCtrl.text,
              lastNameCtrl.text,
              bioCtrl.text,
              phoneCtrl.text,
              locationCtrl.text,
              ageCtrl.text,
              heightCtrl.text,
              weightCtrl.text,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfileInfo(
      String firstName, String lastName, String bio, String phone,
      String location, String age, String height, String weight,
      ) async {
    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'first_name': firstName,
        'last_name': lastName,
        'bio': bio,
        'phone': phone,
        'location_address': location,
        'age': int.tryParse(age),
        'height': int.tryParse(height),
        'weight': int.tryParse(weight),
      });

      setState(() {
        _userData['first_name'] = firstName;
        _userData['last_name'] = lastName;
        _userData['bio'] = bio;
        _userData['phone'] = phone;
        _userData['location_address'] = location;
        _userData['age'] = int.tryParse(age);
        _userData['height'] = int.tryParse(height);
        _userData['weight'] = int.tryParse(weight);
      });

      Navigator.pop(context);
      _showSuccessSnackBar('Profile updated successfully!');
    } catch (e) {
      _showErrorSnackBar('Error updating profile: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message, {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: duration),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildUserNotLoggedIn() {
    return const Center(child: Text("Please log in to view your profile"));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: _buildLoadingIndicator());
    }

    if (_user == null) {
      return Scaffold(body: _buildUserNotLoggedIn());
    }

    final String fullName = '${_userData['first_name'] ?? ''} ${_userData['last_name'] ?? ''}'.trim();
    final String userEmail = _user?.email ?? _userData['email'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Background and Profile Image
            _buildHeaderSection(),
            SizedBox(height: 60),

            // User Information Cards
            _buildInfoCard(fullName),
            _buildPhysicalAttributesCard(),

            // Role-specific cards
            if (_userData['role'] == 'Player') _buildPlayerInfoCard(),
            if (_userData['role'] == 'Coach') _buildCoachInfoCard(),

            // Achievements
            _buildEditableChipsSection(),

            // Posts Gallery
            _buildPostsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background Image
        Container(
          height: 200,
          width: double.infinity,
          child: Stack(
            children: [
              _userData['backgroundImageUrl'] != null && _userData['backgroundImageUrl']!.isNotEmpty
                  ? Image.network(
                _userData['backgroundImageUrl']!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey[300]);
                },
              )
                  : Container(color: Colors.grey[300]),
              if (_isUploadingBackground) ...[
                Container(color: Colors.black54),
                const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
              ],
            ],
          ),
        ),

        // Profile Image
        Positioned(
          top: 155,
          bottom: -75,
          left: MediaQuery.of(context).size.width / 2 - 60,
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            padding: const EdgeInsets.all(4),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _userData['profileImageUrl'] != null && _userData['profileImageUrl']!.isNotEmpty
                      ? NetworkImage(_userData['profileImageUrl']!)
                      : const AssetImage("assets/profile_placeholder.png") as ImageProvider,
                ),
                if (_isUploadingProfile) ...[
                  Positioned.fill(child: Container(color: Colors.black54)),
                  const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                ],
              ],
            ),
          ),
        ),

        // Edit Buttons
        Positioned(
          top: 10,
          right: 10,
          child: Column(
            children: [
              _buildEditIcon(onTap: () => _pickImage(false), tooltip: 'Edit Background'),
              const SizedBox(height: 8),
              _buildEditIcon(onTap: () => _pickImage(true), tooltip: 'Edit Profile'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditIcon({required VoidCallback onTap, required String tooltip}) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
          child: const Icon(Icons.edit, color: Colors.white, size: 20),
        ),
      ),
    );
  }


  Widget _buildInfoCard(String fullName) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                IconButton(onPressed: _editProfileInfo, icon: const Icon(Icons.edit)),
              ],
            ),
            if (_userData['role'] != null) Text("Role: ${_userData['role']}"),
            if (_userData['bio'] != null && _userData['bio']!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_userData['bio']!),
            ],
            const SizedBox(height: 12),
            if (_userData['location_address'] != null && _userData['location_address']!.isNotEmpty)
              Text("📍 ${_userData['location_address']}"),
            Text("📧 ${_user?.email ?? 'No email'}"),
            if (_userData['phone'] != null && _userData['phone']!.isNotEmpty)
              Text("📞 ${_userData['phone']}"),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalAttributesCard() {
    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Physical Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    if (_userData['age'] != null) _buildInfoItem("${_userData['age']}", "Age"),
                    if (_userData['height'] != null) _buildInfoItem("${_userData['height']} cm", "Height"),
                    if (_userData['weight'] != null) _buildInfoItem("${_userData['weight']} kg", "Weight"),
                    if (_userData['gender'] != null) _buildInfoItem("${_userData['gender']}", "Gender"),
                  ],
                ),
              ],
            ),
          ),

        )
    );
  }

  Widget _buildInfoItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildPlayerInfoCard() {
    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Player Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    if (_userData['sport'] != null) _buildInfoItem("${_userData['sport']}", "Sport"),
                    if (_userData['position'] != null) _buildInfoItem("${_userData['position']}", "Position"),
                    if (_userData['level'] != null) _buildInfoItem("${_userData['level']}", "Level"),
                  ],
                ),

              ],
            ),
          ),
        )
    );

  }

  Widget _buildCoachInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Coach Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: [
                  if (_userData['min_fee'] != null && _userData['max_fee'] != null)
                    _buildInfoItem(
                      "\$${_userData['min_fee']} - \$${_userData['max_fee']}",
                      "Fee Range",
                    ),
                  if (_userData['experience'] != null)
                    _buildInfoItem("${_userData['experience']} yrs", "Experience"),
                  if (_userData['specialization'] != null)
                    _buildInfoItem("${_userData['specialization']}", "Specialization"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableChipsSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Achievements",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _achievements
                      .map((achievement) => Chip(
                    label: Text(achievement),
                    onDeleted: () => _removeAchievement(achievement),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _addAchievement,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Achievement"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _addAchievement() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Achievement"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Enter achievement")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _saveAchievement(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAchievement(String achievement) async {
    setState(() => _achievements.add(achievement));

    await _firestore.collection('users').doc(_user!.uid).update({
      'achievements': FieldValue.arrayUnion([achievement])
    });
  }

  Future<void> _removeAchievement(String achievement) async {
    setState(() => _achievements.remove(achievement));

    await _firestore.collection('users').doc(_user!.uid).update({
      'achievements': FieldValue.arrayRemove([achievement])
    });
  }

  Widget _buildPostsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Posts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: _createPost,
                  icon: const Icon(Icons.add_a_photo)
              ),
            ],
          ),

          if (_isUploadingPost) const LinearProgressIndicator(),

          _userPosts.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No posts yet. Add your first post!",
                  style: TextStyle(color: Colors.grey)),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _userPosts.length,
            itemBuilder: (context, index) => _buildPostItem(_userPosts[index]),
          ),
        ],
      ),
    );
  }

  // ✅ Enhanced post item to handle both images and videos
  Widget _buildPostItem(Map<String, dynamic> post) {
    final bool isVideo = post['mediaType'] == 'video';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media (Image or Video)
          Container(
            width: double.infinity,
            height: 300,
            child: isVideo
                ? _buildVideoPlayer(post['mediaUrl'])
                : Image.network(
              post['mediaUrl'],
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 50, color: Colors.red),
                      SizedBox(height: 10),
                      Text('Failed to load media'),
                    ],
                  ),
                );
              },
            ),
          ),

          // Media type indicator
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Row(
              children: [
                Icon(
                  isVideo ? Icons.videocam : Icons.photo,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  isVideo ? 'Video' : 'Image',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          // Caption
          if (post['caption']?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                post['caption'],
                style: const TextStyle(fontSize: 16),
              ),
            ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(post['timestamp']),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}