import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:jar_weight/jar_weight.dart';
import 'package:jar_weight_example/setting/setting_screen.dart';
import 'package:jar_weight_example/storage/jar_storage.dart';
import 'package:jar_weight_example/ui/alerts_dialog.dart';
import 'package:jar_weight_example/utils/colors.dart';
import 'package:jar_weight_example/utils/text.dart';
import 'package:jar_weight_example/ui/add_jar_card.dart';
import 'package:jar_weight_example/ui/pantry_card.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'jar/add_new_jar.dart';
import 'jar_details_dialog.dart';
import 'model/jar_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel("jar_weight");

  List<JarModel> jarList = [];

  /*----------Bluetooth State-----------*/
  List<Map<dynamic, dynamic>> paired = [];
  List<Map<dynamic, dynamic>> available = [];
  bool isConnected = JarWeight.isDeviceConnected;
  String status = JarWeight.isDeviceConnected ? "Connected" : "Not Connected";
  StreamSubscription? _scanSubscription;
  // Timer? _sleepTimer;

  Future<void> loadJars() async {
    jarList = await JarStorage.getJars();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadJars();
    _checkPermissions();
    _setupListener();
    WakelockPlus.enable();

  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    // _sleepTimer?.cancel();
    super.dispose();
  }

  // void _resetSleepTimer() {
  //   _sleepTimer?.cancel();
  //   _sleepTimer = Timer(const Duration(minutes: 100), () {
  //     if (isConnected) {
  //       JarWeight.isDeviceConnected = false;
  //       if (mounted) {
  //         setState(() {
  //           isConnected = false;
  //           status = "Not Connected";
  //         });
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text("Scale went to sleep. Bluetooth disconnected."),
  //             backgroundColor: Colors.orange, // Orange for warning
  //           ),
  //         );
  //       }
  //     }
  //   });
  // }

  void _setupListener() {
    _scanSubscription = JarWeight.scanStream.listen((event) {
      if (event == null) return;

      if (event['type'] == 'device') {
        setState(() {
          if (!available.any((d) => d['address'] == event['address'])) {
            available.add(event);
          }
        });
      } else if (event['type'] == 'disconnected') {
        JarWeight.isDeviceConnected = false;
        // _sleepTimer?.cancel();

        if (mounted) {
          setState(() {
            isConnected = false;
            status = "Not Connected";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Device disconnected! Please reconnect."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (event['type'] == 'message') {
        // 👇 4. EVERY TIME WE GET DATA, RESET THE SLEEP TIMER!
        if (isConnected) {
          // _resetSleepTimer();
        }
      }
    });
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    _refreshPaired();
  }

  Future<void> _refreshPaired() async {
    final list = await JarWeight.getPairedDevices();
    setState(() => paired = list);
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    // var width = MediaQuery.of(context).size.width;

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
        title: Text(
          TextString.APP_BAR_TITLE,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingScreen(),
                  ),
                );
              },
              child: const Icon(Icons.settings, color: Colors.white),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TextString.HOME_PAGE_JAR_CONNECT,
              style: const TextStyle(fontSize: 16, color: Color(0xFF2F3E46)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                itemCount: jarList.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.10,
                ),
                itemBuilder: (context, index) {
                  if (index == jarList.length) {
                    return AddJarCard(
                      onTap: () async {
                        bool? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddNewJar(),
                          ),
                        );

                        if (result == true) {
                          loadJars();
                        }
                      },
                    );
                  }

                  /// user will connect then click add to jar

                  /*   if (index == jarList.length) {
                    return AddJarCard(
                      onTap: () async {
                        // 👇 1. The Bluetooth Connection Lock
                        if (!isConnected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Please connect to your Smart Jar via Bluetooth first!",
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior
                                  .floating, // Makes it pop up nicely
                            ),
                          );
                          return;
                        }

                        bool? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddNewJar(),
                          ),
                        );

                        if (result == true) {
                          loadJars();
                        }
                      },
                    );
                  }     */

                  final jar = jarList[index];
                  double percent = jar.currentWeight / jar.capacity;

                  /// 🔥 Convert expiry string to DateTime
                  DateTime expiry = DateFormat(
                    'dd MMM yyyy',
                  ).parse(jar.expiryDate);
                  DateTime today = DateTime.now();

                  /// 🔥 Remove time part to avoid wrong difference
                  DateTime cleanToday = DateTime(
                    today.year,
                    today.month,
                    today.day,
                  );
                  int daysLeft = expiry.difference(cleanToday).inDays;

                  return GestureDetector(
                    onTap: () async {

                      // ///    not connect Bluetooth not open jar code
                      // if (!isConnected) {
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     const SnackBar(
                      //       content: Text(
                      //         "Please connect to Bluetooth to view live jar details!",
                      //       ),
                      //       backgroundColor: Color(0xFFff5757),
                      //       behavior: SnackBarBehavior.floating,
                      //     ),
                      //   );
                      //   return;
                      // }

                      // 👇 2. If connected, open the popup dialog normally
                      bool? updated = await showDialog(
                        context: context,
                        builder: (context) => JarDetailsDialog(jar: jar),
                      );
                      if (updated == true) {
                        loadJars();
                      }
                    },
                    onDoubleTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertsDialog(jar: jar),
                      );
                    },
                    child: PantryCard(
                      title: jar.name,
                      weight: "${jar.currentWeight.toStringAsFixed(2)} Kg",
                      percent: percent.clamp(0.0, 1.0),
                      expiryDays: daysLeft,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      /// ================= BLUETOOTH CONNECTION BUTTON =================
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 15, right: 15),
        child: InkWell(
          onTap: isConnected ? null : _openBluetoothDialog,
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isConnected ? Colors.green : const Color(0xFF1F7A63),
                width: 1.5,
              ),
              color: isConnected ? Colors.green.withOpacity(0.1) : Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: isConnected ? Colors.green : const Color(0xFF1F7A63),
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  isConnected ? "Bluetooth Connected" : "Bluetooth Connection",
                  style: TextStyle(
                    color: isConnected ? Colors.green : const Color(0xFF1F7A63),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openBluetoothDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 400, // Reduced height since we removed the scan button
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Select Bluetooth Device",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  /* ================= HIDING SCAN BUTTON =================
                  ElevatedButton(
                    onPressed: () async {
                      available.clear();
                      await JarWeight.startScan();
                      setModalState(() {});
                    },
                    child: const Text("Scan Devices"),
                  ),
                  const SizedBox(height: 10),
                  ======================================================= */
                  Expanded(
                    child: ListView(
                      children: [
                        /// 🔵 Paired Devices
                        const Text(
                          "Paired Devices",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Add a friendly message if the list is empty
                        if (paired.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 15.0),
                            child: Text(
                              "No paired devices found.\nPlease pair your scale in your phone's Bluetooth settings first.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),

                        ...paired.map(
                          (device) => ListTile(
                            leading: const Icon(Icons.bluetooth),
                            title: Text(device['name'] ?? "Unknown Device"),
                            subtitle: Text(device['address']),
                            onTap: () async {
                              Navigator.pop(context);
                              setState(() {
                                status = "Connecting...";
                              });
                              try {
                                await JarWeight.connectToDevice(
                                  device['address'],
                                );
                                setState(() {
                                  isConnected = true;
                                  status = "Connected";
                                });

                                // _resetSleepTimer();

                              } catch (e) {
                                setState(() {
                                  isConnected = false;
                                  status = "Connection Failed";
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Failed to connect to scale.",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        /* ================= HIDING AVAILABLE DEVICES =================
                        const Text(
                          "Available Devices",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...available.map(
                          (device) => ListTile(
                            leading: const Icon(Icons.bluetooth_searching),
                            title: Text(device['name'] ?? "Unknown Device"),
                            subtitle: Text(device['address']),
                            onTap: () async {
                              Navigator.pop(context);
                              setState(() {
                                status = "Connecting...";
                              });
                              try {
                                await JarWeight.connectToDevice(device['address']);
                                setState(() {
                                  isConnected = true;
                                  status = "Connected";
                                });
                              } catch (e) {
                                setState(() {
                                  isConnected = false;
                                  status = "Connection Failed";
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Failed to connect to scale."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        ============================================================= */
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
