import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for clipboard
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lunaris/services/storage_service.dart';
import '../services/database_service.dart';
import '../theme_provider.dart';
import '../shared_widgets.dart';
// import 'package:intl/intl.dart'; // Uncomment if you need date formatting

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  final DatabaseService _dbService = DatabaseService();
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isUploading = false;

  // --- Image Picker Logic ---
  Future<void> _onEditImageTap() async {
    // Safer check: if _user is null OR anonymous, return
    if (_user == null || _user.isAnonymous) return;

    final File? imageFile = await _storageService.pickImage();
    if (imageFile == null) return; // User cancelled

    setState(() => _isUploading = true);

    try {
      // Upload image to Firebase Storage and update FirebaseAuth
      final String? downloadUrl =
          await _storageService.uploadProfileImage(imageFile);

      if (downloadUrl == null) {
        throw Exception("Failed to get download URL");
      }

      // Also save the photoURL to Firestore database
      await _dbService.updateUserData(photoURL: downloadUrl);

      // Reload the current user to get updated photoURL
      await FirebaseAuth.instance.currentUser?.reload();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Profile picture updated successfully!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // The StreamBuilder will automatically rebuild the avatar
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Image upload failed: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isUploading = false);
    }
  }

  // --- 1. MODIFIED THIS FUNCTION ---
  // It now ONLY handles editing the 'displayName'
  Future<void> _showEditNameDialog(
    BuildContext context,
    dynamic colors,
    String currentName,
  ) async {
    final TextEditingController controller =
        TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NeonText(
                      text: "Edit Name", // <-- Changed title
                      gradientColors: [colors.accent1, colors.accent2],
                      fontSize: 20,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.text, // <-- Changed
                      style: TextStyle(color: colors.text),
                      decoration: InputDecoration(
                        labelText: "Enter new name", // <-- Changed label
                        labelStyle:
                            TextStyle(color: colors.text.withOpacity(0.7)),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: colors.accent1, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: colors.text.withOpacity(0.3)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Name cannot be empty"; // <-- Changed message
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: "SAVE",
                      gradient: LinearGradient(
                        colors: [colors.accent1, colors.accent2],
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          // --- Call the database service to update ---
                          try {
                            // *** THIS IS THE FIX ***
                            // Changed 'name:' to 'displayName:' to match database_service.dart
                            await _dbService.updateUserData(
                              displayName: controller.text,
                            );
                            // *** END OF FIX ***

                            if (mounted)
                              Navigator.pop(context); // Close dialog
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Failed to save: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 2. NEW FUNCTION TO SHOW THE DATE PICKER ---
  Future<void> _pickBirthday(BuildContext context, dynamic colors) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      // Default to 18 years ago
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900), // Can't be born before 1900
      lastDate: DateTime.now(), // Can't be born in the future
      builder: (context, child) {
        // Style the date picker to match the app's theme
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: colors.accent1, // Header background, selected day
              onPrimary: Colors.white, // Header text, selected day text
              onSurface: colors.text, // Calendar day text
              surface: colors.bgEnd, // Main background of calendar
            ),
            dialogBackgroundColor: colors.bgStart,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: colors.accent1, // OK/Cancel button text
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    // If a date was picked, update it in Firestore
    if (picked != null) {
      try {
        await _dbService.updateUserData(birthday: picked);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to save birthday: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // --- 3. NEW HELPER FUNCTION TO CALCULATE AGE ---
  String _calculateAge(Timestamp? birthdayStamp) {
    if (birthdayStamp == null) return 'Not set';

    final birthday = birthdayStamp.toDate();
    final now = DateTime.now();
    int age = now.year - birthday.year;

    // Adjust age if birthday hasn't happened this year yet
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }

    return age.toString();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    // FIX: 'isDarkMode' is defined here
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark ||
        (themeNotifier.themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    final colors = isDarkMode
        ? (
            accent1: LunarisColorsDark.accentCyan,
            accent2: LunarisColorsDark.accentMagenta,
            text: LunarisColorsDark.text,
            bgStart: LunarisColorsDark.backgroundStart,
            bgEnd: LunarisColorsDark.backgroundEnd,
          )
        : (
            accent1: LunarisColorsLight.accentViolet,
            accent2: LunarisColorsLight.accentMagenta,
            text: LunarisColorsLight.text,
            bgStart: LunarisColorsLight.backgroundStart,
            bgEnd: LunarisColorsLight.backgroundEnd,
          );

    final bool isGuest = _user?.isAnonymous ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: NeonText(
              text: 'Profile',
              gradientColors: [colors.accent1, colors.accent2],
              fontSize: 22,
            ),
          ),
          // --- Use StreamBuilder to get real-time profile data ---
          // FIX: Changed to accept generic <Object?>
          StreamBuilder<DocumentSnapshot<Object?>>(
            stream: _dbService.getUserProfileStream(),
            builder: (context, snapshot) {
              // Get data from Auth and Firestore - get fresh user data
              final authData = FirebaseAuth.instance.currentUser;
              final String? uid = authData?.uid;

              // FIX: Safely cast the data - handle both converter and non-converter snapshots
              Map<String, dynamic>? firestoreData;
              if (snapshot.hasData && snapshot.data != null) {
                final data = snapshot.data!.data();
                if (data != null) {
                  firestoreData = data is Map<String, dynamic>
                      ? data
                      : data as Map<String, dynamic>;
                }
              }

              final String displayName = firestoreData?['displayName'] ??
                  authData?.displayName ??
                  'Guest User';

              // --- 4. MODIFIED: Fetch 'birthday' and calculate 'ageString' ---
              final Timestamp? birthday = firestoreData?['birthday'];
              final String ageString = _calculateAge(birthday);

              // Get photoURL from Firestore first, fallback to FirebaseAuth
              final String photoURL =
                  firestoreData?['photoURL'] ?? authData?.photoURL ?? '';
              final String email = authData?.email ?? 'Not provided';
              // --- PREMIUM FEATURE ---
              final bool isPremium = firestoreData?['isPremium'] ?? false;

              String getInitial() {
                if (displayName.isNotEmpty && displayName != 'Guest User') {
                  return displayName.substring(0, 1).toUpperCase();
                }
                if (isGuest) return 'G';
                return '?';
              }

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // --- User Header Section ---
                      // FIX: Pass 'isDarkMode' to the helper
                      _buildAvatar(photoURL, getInitial, colors, isGuest,
                          isPremium, isDarkMode),
                      const SizedBox(height: 16.0),
                      NeonText(
                        text: displayName,
                        gradientColors: [colors.accent1, colors.accent2],
                        fontSize: 24.0,
                        fontFamily: 'Poppins',
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        isGuest
                            ? "Exploring the cosmos anonymously 🌌"
                            : "Exploring the Aurora of Stories 🌌",
                        style: TextStyle(
                          color: colors.text.withOpacity(0.7),
                          fontSize: 16.0,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // --- UID Row ---
                      _buildUidRow(context, uid, colors),

                      const SizedBox(height: 32.0),

                      // --- Account Details Card ---
                      GlassContainer(
                        child: Column(
                          children: [
                            _buildEditableInfoTile(
                              icon: Icons.person,
                              title: 'Name',
                              subtitle: displayName,
                              colors: colors,
                              isGuest: isGuest,
                              onEditTap: () => _showEditNameDialog(
                                context,
                                colors,
                                displayName,
                              ),
                            ),
                            const CustomDivider(),
                            _buildEditableInfoTile(
                              icon: Icons.cake,
                              title: 'Age',
                              // --- 5. MODIFIED: Use the calculated ageString ---
                              subtitle: ageString,
                              colors: colors,
                              isGuest: isGuest,
                              // --- 6. MODIFIED: Call the new date picker ---
                              onEditTap: () => _pickBirthday(context, colors),
                            ),
                            const CustomDivider(),
                            _buildInfoTile(
                              icon: Icons.email,
                              title: 'Email',
                              subtitle: email,
                              colors: colors,
                            ),
                            const CustomDivider(),
                            // --- PREMIUM FEATURE ---
                            _buildInfoTile(
                              icon: Icons.star_border,
                              title: 'Membership',
                              // Show status based on 'isPremium' flag
                              subtitle:
                                  isPremium ? 'Premium Member' : 'Free Tier',
                              colors: colors,
                              trailing: Text(
                                isPremium ? '⭐' : '✨',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      // --- Settings Card ---
                      GlassContainer(
                        child: Column(
                          children: [
                            _buildThemeToggle(context, themeNotifier, colors),
                            const CustomDivider(),
                            _buildNavTile(
                              context: context,
                              icon: Icons.settings,
                              title: 'Settings & Preferences',
                              onTap: () {
                                // This route should be defined in your main.dart
                                Navigator.pushNamed(context, '/settings');
                              },
                              colors: colors,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100.0), // Spacer for Nav Bar
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets for Profile Page ---

  // FIX: Added 'isPremium' and 'isDarkMode' parameters
  Widget _buildAvatar(
    String photoURL,
    String Function() getInitial,
    dynamic colors,
    bool isGuest,
    bool isPremium,
    bool isDarkMode,
  ) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircularGlowAvatar(
          glowColor: colors.accent1,
          child: CircleAvatar(
            radius: 50.0,
            backgroundColor: Colors.white.withOpacity(0.1),
            backgroundImage:
                (photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
            child: (photoURL.isEmpty)
                ? Text(
                    getInitial(),
                    style: TextStyle(
                        fontSize: 40,
                        color: colors.text,
                        fontWeight: FontWeight.bold),
                  )
                : null,
          ),
        ),
        if (_isUploading)
          const CircularProgressIndicator(color: Colors.white),
        // --- Edit Button (hidden for guests) ---
        if (!_isUploading && !isGuest)
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: colors.accent1.withOpacity(0.8),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _onEditImageTap,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.edit, size: 20, color: Colors.white),
                ),
              ),
            ),
          ),

        // --- PREMIUM FEATURE: Checkmark ---
        if (isPremium)
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                // FIX: Use 'isDarkMode' to get correct background
                color: isDarkMode
                    ? LunarisColorsDark.backgroundStart
                    : LunarisColorsLight.backgroundStart,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: colors.accent1,
                size: 24,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required dynamic colors,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: colors.accent1),
      title: Text(
        title,
        style: TextStyle(
          color: colors.text.withOpacity(0.7),
          fontFamily: 'Poppins',
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: colors.text,
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing,
    );
  }

  Widget _buildEditableInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required dynamic colors,
    required bool isGuest,
    required VoidCallback onEditTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: colors.accent1),
      title: Text(
        title,
        style: TextStyle(
          color: colors.text.withOpacity(0.7),
          fontFamily: 'Poppins',
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: colors.text,
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: isGuest
          ? null
          : IconButton(
              icon: Icon(Icons.edit,
                  color: colors.text.withOpacity(0.5), size: 20),
              onPressed: onEditTap,
            ),
    );
  }

  Widget _buildNavTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required dynamic colors,
  }) {
    return ListTile(
      leading: Icon(icon, color: colors.accent1),
      title: Text(
        title,
        style: TextStyle(
          color: colors.text,
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios,
          color: colors.text.withOpacity(0.5), size: 16),
      onTap: onTap,
    );
  }

  Widget _buildThemeToggle(
      BuildContext context, ThemeNotifier notifier, dynamic colors) {
    bool isDark = notifier.themeMode == ThemeMode.dark;
    bool isLight = notifier.themeMode == ThemeMode.light;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.brightness_4, color: colors.accent1),
          Text(
            'Theme',
            style: TextStyle(
              color: colors.text,
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.wb_sunny,
                    color: isLight
                        ? colors.accent1
                        : colors.text.withOpacity(0.5)),
                onPressed: () => notifier.setThemeMode(ThemeMode.light),
              ),
              Switch(
                value: isDark,
                onChanged: (value) {
                  notifier.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light);
                },
                activeColor: colors.accent1,
                inactiveThumbColor: colors.text.withOpacity(0.7),
              ),
              IconButton(
                icon: Icon(Icons.nightlight_round,
                    color: isDark
                        ? colors.accent1
                        : colors.text.withOpacity(0.5)),
                onPressed: () => notifier.setThemeMode(ThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helper Widget for the UID Row ---
  Widget _buildUidRow(BuildContext context, String? uid, dynamic colors) {
    if (uid == null || uid.isEmpty) {
      return const SizedBox.shrink(); // Don't show if no UID
    }

    // Shorten the UID: e.g., "abcde...12345"
    final String shortUid = (uid.length > 10)
        ? '${uid.substring(0, 5)}...${uid.substring(uid.length - 5)}'
        : uid;

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Keep the row compact
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.vpn_key, color: colors.text.withOpacity(0.7), size: 16),
            const SizedBox(width: 8),
            Text(
              'UID: $shortUid',
              style: TextStyle(
                color: colors.text.withOpacity(0.7),
                fontSize: 14.0,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.content_copy, color: colors.accent1, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: uid));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Full UID copied to clipboard!"),
                    backgroundColor: colors.accent1,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}