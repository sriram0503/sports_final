import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker picker = ImagePicker();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  User? user;
  Map<String, dynamic> userData = {};
  List<String> achievements = [];

  File? _profileImage;
  File? _backgroundImage;
  List<Map<String, dynamic>> userPosts = [];

  @override
  void initState() {
    super.initState();
    user = auth.currentUser;
    if (user != null) {
      fetchUserData();
      fetchUserPosts();
    }
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await firestore.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>;
          if (userData.containsKey('achievements')) {
            achievements = List<String>.from(userData['achievements']);
          }
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> fetchUserPosts() async {
    try {
      QuerySnapshot postsSnapshot = await firestore
          .collection('posts')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        userPosts = postsSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'imageUrl': data['imageUrl'],
            'caption': data['caption'],
            'timestamp': data['timestamp'],
          };
        }).toList();
      });
    } catch (e) {
      print("Error fetching posts: $e");
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Image Source"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text("Camera")),
          TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text("Gallery")),
        ],
      ),
    );
    if (source == null) return;
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedFile.path);
          // In a real app, you would upload this to storage and update user profile
        } else {
          _backgroundImage = File(pickedFile.path);
          // In a real app, you would upload this to storage
        }
      });
    }
  }

  Future<void> _pickMediaPost() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Media Source"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text("Camera")),
          TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text("Gallery")),
        ],
      ),
    );
    if (source == null) return;
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      await _showPostDialog(File(pickedFile.path));
    }
  }

  Future<void> _showPostDialog(File image) async {
    TextEditingController captionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Post"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(image, height: 200, fit: BoxFit.cover),
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
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _uploadPost(image, captionController.text);
              },
              child: const Text("Post")),
        ],
      ),
    );
  }

  Future<void> _uploadPost(File image, String caption) async {
    try {
      // Check if the file exists
      if (!await image.exists()) {
        throw Exception('Image file does not exist');
      }

      // Create a unique filename for the image
      String imageName = 'posts/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = storage.ref().child(imageName);

      // Upload the file to Firebase Storage
      final UploadTask uploadTask = storageRef.putFile(image);

      // Wait for the upload to complete
      final TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});

      // Check if the upload was successful
      if (taskSnapshot.state == TaskState.success) {
        // Get the download URL
        final String imageUrl = await storageRef.getDownloadURL();

        // Add post to Firestore
        await firestore.collection('posts').add({
          'userId': user!.uid,
          'userName': '${userData['first_name']} ${userData['last_name']}',
          'userImage': userData['profileImage'] ?? '',
          'imageUrl': imageUrl,
          'caption': caption,
          'timestamp': FieldValue.serverTimestamp(),
          'likes': 0,
          'comments': [],
        });

        // Refresh posts
        fetchUserPosts();

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post uploaded successfully!'))
        );
      } else {
        throw Exception('Upload failed with state: ${taskSnapshot.state}');
      }
    } catch (e) {
      print("Error uploading post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading post: $e'))
      );
    }
  }

  void _editInfoPopup() {
    TextEditingController firstNameCtrl = TextEditingController(
        text: userData['first_name'] ?? '');
    TextEditingController lastNameCtrl = TextEditingController(
        text: userData['last_name'] ?? '');
    TextEditingController bioCtrl = TextEditingController(text: userData['bio'] ?? '');
    TextEditingController phoneCtrl = TextEditingController(text: userData['phone'] ?? '');
    TextEditingController emailCtrl = TextEditingController(text: user?.email ?? '');
    TextEditingController locCtrl = TextEditingController(text: userData['location_address'] ?? '');
    TextEditingController ageCtrl = TextEditingController(text: userData['age']?.toString() ?? '');
    TextEditingController heightCtrl = TextEditingController(text: userData['height']?.toString() ?? '');
    TextEditingController weightCtrl = TextEditingController(text: userData['weight']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile Info"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameCtrl,
                  decoration: const InputDecoration(labelText: "First Name", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: lastNameCtrl,
                  decoration: const InputDecoration(labelText: "Last Name", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bioCtrl,
                  decoration: const InputDecoration(labelText: "Bio", border: OutlineInputBorder()),
                  maxLines: 2,
                  minLines: 2,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: "Phone", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                  readOnly: true,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(labelText: "Location", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ageCtrl,
                  decoration: const InputDecoration(labelText: "Age", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: heightCtrl,
                  decoration: const InputDecoration(labelText: "Height (cm)", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: weightCtrl,
                  decoration: const InputDecoration(labelText: "Weight (kg)", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              // Update user data in Firestore
              firestore.collection('users').doc(user!.uid).update({
                'first_name': firstNameCtrl.text,
                'last_name': lastNameCtrl.text,
                'bio': bioCtrl.text,
                'phone': phoneCtrl.text,
                'location_address': locCtrl.text,
                'age': int.tryParse(ageCtrl.text),
                'height': int.tryParse(heightCtrl.text),
                'weight': int.tryParse(weightCtrl.text),
              }).then((_) {
                setState(() {
                  userData['first_name'] = firstNameCtrl.text;
                  userData['last_name'] = lastNameCtrl.text;
                  userData['bio'] = bioCtrl.text;
                  userData['phone'] = phoneCtrl.text;
                  userData['location_address'] = locCtrl.text;
                  userData['age'] = int.tryParse(ageCtrl.text);
                  userData['height'] = int.tryParse(heightCtrl.text);
                  userData['weight'] = int.tryParse(weightCtrl.text);
                });
                Navigator.pop(context);
              });
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String fullName = '';
    if (userData['first_name'] != null && userData['last_name'] != null) {
      fullName = '${userData['first_name']} ${userData['last_name']}';
    } else {
      fullName = user?.displayName ?? 'User';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamed(context, '/');
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: _backgroundImage != null
                            ? FileImage(_backgroundImage!)
                            : const AssetImage("assets/bg_placeholder.jpg") as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 160,
                    left: MediaQuery.of(context).size.width / 2 - 60,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : const AssetImage("assets/profile_placeholder.png") as ImageProvider,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _pickImage(false),
                          child: _editIcon(),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _pickImage(true),
                          child: _editIcon(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 70),
              _infoCard(fullName),
              _physicalAttributesCard(),
              if (userData['role'] == 'Player') _playerInfoCard(),
              if (userData['role'] == 'Coach') _coachInfoCard(),
              _buildEditableChips(achievements, "Achievements"),
              _postGallery(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String fullName) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(fullName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                IconButton(onPressed: _editInfoPopup, icon: const Icon(Icons.edit))
              ],
            ),
            const SizedBox(height: 8),
            if (userData['role'] != null)
              Text("Role: ${userData['role']}", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(userData['bio'] ?? 'No bio provided'),
            const SizedBox(height: 12),
            if (userData['location_address'] != null)
              Text("📍 ${userData['location_address']}"),
            const SizedBox(height: 6),
            Text("📧 ${user?.email ?? 'No email'}"),
            const SizedBox(height: 6),
            if (userData['phone'] != null) Text("📞 ${userData['phone']}"),
          ],
        ),
      ),
    );
  }

  Widget _physicalAttributesCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Physical Information",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 20,
                runSpacing: 15,
                children: [
                  if (userData['age'] != null)
                    Column(
                      children: [
                        Text("${userData['age']}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text("Age"),
                      ],
                    ),
                  if (userData['height'] != null)
                    Column(
                      children: [
                        Text("${userData['height']} cm",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text("Height"),
                      ],
                    ),
                  if (userData['weight'] != null)
                    Column(
                      children: [
                        Text("${userData['weight']} kg",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text("Weight"),
                      ],
                    ),
                  if (userData['gender'] != null)
                    Column(
                      children: [
                        Text("${userData['gender']}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text("Gender"),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Player Information",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 20,
                runSpacing: 15,
                children: [
                  if (userData['sport'] != null)
                    Column(
                      children: [
                        Text("${userData['sport']}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Text("Sport"),
                      ],
                    ),
                  if (userData['position'] != null)
                    Column(
                      children: [
                        Text("${userData['position']}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Text("Position"),
                      ],
                    ),
                  if (userData['level'] != null)
                    Column(
                      children: [
                        Text("${userData['level']}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Text("Level"),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coachInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Coach Information",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 20,
                runSpacing: 15,
                children: [
                  if (userData['min_fee'] != null && userData['max_fee'] != null)
                    Column(
                      children: [
                        Text("\$${userData['min_fee']} - \$${userData['max_fee']}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Text("Fee Range"),
                      ],
                    ),
                  if (userData['experience'] != null)
                    Column(
                      children: [
                        Text("${userData['experience']} yrs",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Text("Experience"),
                      ],
                    ),
                  if (userData['specialization'] != null)
                    Column(
                      children: [
                        Text("${userData['specialization']}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Text("Specialization"),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableChips(List<String> list, String title) {
    TextEditingController ctrl = TextEditingController();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Add $title"),
                      content: TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(
                          labelText: "Enter value",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                        ElevatedButton(
                          onPressed: () {
                            if (ctrl.text.trim().isNotEmpty) {
                              setState(() => list.add(ctrl.text.trim()));
                              // Update in Firestore
                              firestore.collection('users').doc(user!.uid).update({
                                'achievements': FieldValue.arrayUnion([ctrl.text.trim()])
                              });
                            }
                            Navigator.pop(context);
                          },
                          child: const Text("Add"),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
            Wrap(
              spacing: 6,
              children: list
                  .map((item) => Chip(
                label: Text(item),
                deleteIcon: const Icon(Icons.close),
                onDeleted: () {
                  setState(() => list.remove(item));
                  // Update in Firestore
                  firestore.collection('users').doc(user!.uid).update({
                    'achievements': FieldValue.arrayRemove([item])
                  });
                },
              ))
                  .toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _postGallery() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Media Posts",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: _pickMediaPost, icon: const Icon(Icons.add_a_photo))
            ],
          ),
          const SizedBox(height: 8),
          userPosts.isEmpty
              ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No posts yet. Add your first post!",
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ))
              : GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: userPosts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _showPostDetails(userPosts[i]),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(userPosts[i]['imageUrl']),
                    fit: BoxFit.cover,
                  ),
                ),
                child: userPosts[i]['caption'] != null && userPosts[i]['caption'].isNotEmpty
                    ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        userPosts[i]['caption'],
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                )
                    : null,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showPostDetails(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              post['imageUrl'],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
            if (post['caption'] != null && post['caption'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(post['caption']),
              ),
            if (post['timestamp'] != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _formatTimestamp(post['timestamp']),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }

  Widget _editIcon() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
      child: const Icon(Icons.edit, color: Colors.white, size: 20),
    );
  }
}