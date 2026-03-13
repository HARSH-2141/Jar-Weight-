import 'package:flutter/material.dart';
import 'package:jar_weight/jar_weight.dart';

import '../utils/colors.dart';
import '../utils/text.dart';
// 👇 IMPORTANT: Make sure this import matches where you saved the new screen!
import 'alerts_expiry_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool isConnected = JarWeight.isDeviceConnected;
  String deviceName = "Smart Jar Scale";

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: ColorString.BACKGROUND_COLOR,
      appBar: AppBar(
        toolbarHeight: height / 9,
        backgroundColor: ColorString.APP_BAR_COLOR,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1F7A63),
            child: const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/image/appbar_icon.png'),
            ),
          ),
        ),
        title: const Text(
          "Setting",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),

      // 👇 Wrapped in SingleChildScrollView to prevent overflow
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= ALERTS & EXPIRY SECTION =================
              const Text(
                "Notifications",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF949494),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFCACACA),
                      blurRadius: 2,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: const Icon(Icons.notifications_active_outlined, color: Colors.orange),
                  ),
                  title: const Text(
                    "Alerts & Expiry",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F3E46),
                    ),
                  ),
                  subtitle: const Text(
                    "Check low stock and expired items",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                  onTap: () {
                    // Navigate to the Alerts screen you just created!
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AlertsExpiryScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),


              /// ================= BLUETOOTH STATUS CARD =================
              const Text(
                "Bluetooth Status",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF949494),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFCACACA),
                      blurRadius: 2,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: isConnected ? Colors.green.shade50 : Colors.red.shade50,
                          child: Icon(
                            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                            color: isConnected ? Colors.green : Colors.red,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isConnected ? "Connected" : "Disconnected",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isConnected ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isConnected ? "Device: $deviceName" : "No scale paired",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (isConnected) ...[
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFEFEFEF)),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.red.shade200, width: 1),
                            ),
                          ),
                          onPressed: () async {
                            // 👇 1. THE CRITICAL FIX: Tell the physical hardware to disconnect!
                            // Note: If your specific package uses a slightly different command
                            // like 'stopScan()' or 'disconnectDevice()', use that here instead!
                            try {
                              await JarWeight.disconnect();
                            } catch (e) {
                              debugPrint("Disconnect error: $e");
                            }

                            // 👇 2. Update the global app state
                            JarWeight.isDeviceConnected = false;

                            // 👇 3. Update this screen's UI
                            setState(() {
                              isConnected = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Scale disconnected successfully."),
                                backgroundColor: Colors.green, // Added a nice success color!
                              ),
                            );
                          },
                          child: const Text(
                            "Disconnect Device",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),


              // You can easily add more ListTiles here later for "App Theme", "Privacy", etc.
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}