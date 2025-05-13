import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String name = '';
  String email = '';
  String carModel = '';
  String carNumber = '';
  String carColor = '';

  @override
  void initState() {
    super.initState();
    fetchDriverInfo();
  }

  void fetchDriverInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference ref = FirebaseDatabase.instance
          .ref()
          .child("Drivers")
          .child(user.uid);
      ref.once().then((snapshot) {
        final data = snapshot.snapshot.value as Map;
        setState(() {
          name = data['name'] ?? '';
          email = data['email'] ?? '';
          carModel = data['car_model'] ?? '';
          carNumber = data['car_number'] ?? '';
          carColor = data['car_color'] ?? '';
        });
      });
    }
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('islogin');
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/loginscreen');
  }

  void shareApp() {
    Share.share('Check out this awesome ride-sharing driver app!');
  }

  void rateApp() async {
    final url = Uri.parse(
      "https://play.google.com/store/apps/details?id=com.example.app",
    ); // Replace with your actual app URL
    if (await canLaunchUrl(url)) {
      launchUrl(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Could not open Play Store.")));
    }
  }

  Widget buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.yellow.shade100,
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(label, style: TextStyle(fontSize: 16)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey.shade100,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.yellow.shade700,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.black),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Driver Info
          buildInfoTile(
            icon: Icons.directions_car,
            title: 'Car Model',
            subtitle: carModel,
          ),
          buildInfoTile(
            icon: Icons.confirmation_number,
            title: 'Car Number',
            subtitle: carNumber,
          ),
          buildInfoTile(
            icon: Icons.color_lens,
            title: 'Car Color',
            subtitle: carColor,
          ),

          SizedBox(height: 16),
          Divider(),

          // Action Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "More Options",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          buildActionTile(
            icon: Icons.share,
            label: "Share App",
            onTap: shareApp,
          ),
          buildActionTile(
            icon: Icons.star_rate,
            label: "Rate App",
            onTap: rateApp,
          ),
          buildActionTile(icon: Icons.logout, label: "Logout", onTap: logout),

          Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "v1.0.0 • Garifo Driver",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
