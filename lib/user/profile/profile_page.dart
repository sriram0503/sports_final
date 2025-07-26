import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker picker = ImagePicker();
  File? _profileImage;
  File? _backgroundImage;
  List<File> _mediaPosts = [];

  String userName = "John Doe";
  String bio = "Coach | Mentor | Athlete";
  String location = "New York, USA";
  String email = "john.doe@example.com";
  String phone = "+1 234 567 890";
  int followers = 350;
  int following = 180;

  List<String> achievements = ["National Level Player", "5+ Years Coaching", "MVP 2022"];
  List<String> skills = ["Basketball", "Leadership", "Strategy"];

  Future<void> _pickImage(bool isProfile) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Image Source"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.camera), child: const Text("Camera")),
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.gallery), child: const Text("Gallery")),
        ],
      ),
    );
    if (source == null) return;
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedFile.path);
        } else {
          _backgroundImage = File(pickedFile.path);
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
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.camera), child: const Text("Camera")),
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.gallery), child: const Text("Gallery")),
        ],
      ),
    );
    if (source == null) return;
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      bool confirm = await _showConfirmationDialog(File(pickedFile.path));
      if (confirm) {
        setState(() => _mediaPosts.add(File(pickedFile.path)));
      }
    }
  }

  Future<bool> _showConfirmationDialog(File image) async {
    bool? result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Post"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(image, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 20),
            const Text("Do you want to post this image?"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Post")),
        ],
      ),
    );
    return result ?? false;
  }

  void _editInfoPopup() {
    TextEditingController nameCtrl = TextEditingController(text: userName);
    TextEditingController bioCtrl = TextEditingController(text: bio);
    TextEditingController phoneCtrl = TextEditingController(text: phone);
    TextEditingController emailCtrl = TextEditingController(text: email);
    TextEditingController locCtrl = TextEditingController(text: location);

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
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bioCtrl,
                  decoration: const InputDecoration(
                    labelText: "Bio",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  minLines: 2,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: "Phone",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(
                    labelText: "Location",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                userName = nameCtrl.text;
                bio = bioCtrl.text;
                phone = phoneCtrl.text;
                email = emailCtrl.text;
                location = locCtrl.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
                        ],
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
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _pickImage(true),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 70),
              _infoCard(),
              _followersRow(),
              _buildEditableChips(achievements, "Achievements"),
              _buildEditableChips(skills, "Skills"),
              _postGallery(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
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
                  child: Text(userName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                IconButton(onPressed: _editInfoPopup, icon: const Icon(Icons.edit))
              ],
            ),
            Text(bio),
            const SizedBox(height: 6),
            Text("📍 $location"),
            Text("📧 $email"),
            Text("📞 $phone"),
          ],
        ),
      ),
    );
  }

  Widget _followersRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text("$followers", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("Followers"),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text("$following", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("Following"),
                ],
              ),
            ),
          ),
        ],
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
                onDeleted: () => setState(() => list.remove(item)),
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
              const Text("Media Posts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: _pickMediaPost, icon: const Icon(Icons.add_a_photo))
            ],
          ),
          const SizedBox(height: 8),
          _mediaPosts.isEmpty
              ? const Text("No posts yet.")
              : GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _mediaPosts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (_, i) => Stack(
              fit: StackFit.expand,
              children: [
                Image.file(_mediaPosts[i], fit: BoxFit.cover),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _mediaPosts.removeAt(i)),
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}