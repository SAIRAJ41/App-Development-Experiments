import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  File? _imageFile;
  bool _isLoading = false;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final birthCtrl = TextEditingController();

  Map<String, dynamic> userData = {};

  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final List<String> countryOptions = ['India', 'USA', 'UK', 'Australia'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        userData = doc.data()!;
      } else {
        userData = {
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'photoURL': user.photoURL ?? '',
          'gender': '',
          'country': '',
          'birthdate': '',
          'createdAt': FieldValue.serverTimestamp(),
        };
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userData);
      }

      nameCtrl.text = userData['name'] ?? '';
      phoneCtrl.text = userData['phone'] ?? '';
      genderCtrl.text = userData['gender'] ?? '';
      countryCtrl.text = userData['country'] ?? '';
      birthCtrl.text = userData['birthdate'] ?? '';
    } catch (e) {
      _showSnack('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() => _imageFile = File(pickedFile.path));
    await _uploadProfileImage();
  }

  Future<void> _uploadProfileImage() async {
    if (_imageFile == null) return;
    setState(() => _isLoading = true);
    try {
      final ref = FirebaseStorage.instance.ref('profile_pics/${user.uid}.jpg');
      await ref.putFile(_imageFile!);
      final url = await ref.getDownloadURL();

      await user.updatePhotoURL(url);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'photoURL': url});
      _showSnack('Profile picture updated');
      await _loadUserData();
    } catch (e) {
      _showSnack('Failed to upload image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final upd = {
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'gender': genderCtrl.text.trim(),
        'country': countryCtrl.text.trim(),
        'birthdate': birthCtrl.text.trim(),
      };
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(upd);
      await user.updateDisplayName(upd['name']!);
      await user.reload();
      _showSnack('Profile updated successfully');
      await _loadUserData();
    } catch (e) {
      _showSnack('Error updating profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  void _showSnack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = userData['photoURL'] ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.teal.shade600,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : const AssetImage('assets/default_avatar.png'))
                                  as ImageProvider,
                        ),
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildField(nameCtrl, "Full Name"),
                  const SizedBox(height: 15),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: user.email),
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFECECEC),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Phone number - numeric only
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Gender dropdown
                  DropdownButtonFormField<String>(
                    value: genderCtrl.text.isNotEmpty ? genderCtrl.text : null,
                    decoration: const InputDecoration(
                      labelText: "Gender",
                      border: OutlineInputBorder(),
                    ),
                    items: genderOptions
                        .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        genderCtrl.text = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  // Country dropdown
                  DropdownButtonFormField<String>(
                    value: countryCtrl.text.isNotEmpty ? countryCtrl.text : null,
                    decoration: const InputDecoration(
                      labelText: "Country",
                      border: OutlineInputBorder(),
                    ),
                    items: countryOptions
                        .map((country) => DropdownMenuItem(value: country, child: Text(country)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        countryCtrl.text = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: birthCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Birth Date",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(birthCtrl.text) ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) {
                        birthCtrl.text =
                            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                      }
                    },
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: _updateProfile,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Changes"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text("Sign Out"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
