import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jar_weight/jar_weight.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen>
    with SingleTickerProviderStateMixin {
  static const MethodChannel platform = MethodChannel("jar_weight");

  List<Map<dynamic, dynamic>> paired = [];
  List<Map<dynamic, dynamic>> available = [];
  List<Map<String, dynamic>> messages = [];

  bool isConnected = false;
  String status = "Not Connected";

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _setupListener();
  }

  void _setupListener() {
    JarWeight.scanStream.listen((event) {
      if (event['type'] == 'message') {
        setState(() {
          messages.add({"text": event['text'], "isMe": false});
        });
      } else if (event['type'] == 'device') {
        setState(() {
          if (!available.any((d) => d['address'] == event['address'])) {
            available.add(event);
          }
        });
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(

          automaticallyImplyLeading: false,
          leading: InkWell(
              onTap: (){
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back_ios_new)),

          title: Text("BT: $status"),
          bottom: !isConnected
              ? TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Paired Devices"),
              Tab(text: "Available Devices"),
            ],
          )
              : null,
          actions: [
            IconButton(
              icon:  Icon(Icons.refresh),
              onPressed: _refreshPaired,
            ),
            IconButton(
              icon:  Icon(Icons.sensors),
              onPressed: () async {
                setState(() => status = "Waiting...");
                await JarWeight.startServer();
                setState(() {
                  isConnected = true;
                  status = "Connected";
                });
              },
            ),
          ],
        ),
        body: isConnected
            ? Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (c, i) {
                  final msg = messages[i];
                  return ListTile(
                    title: Align(
                      alignment: msg['isMe']
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: msg['isMe']
                              ? Colors.blue
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(
                            color: msg['isMe']
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _chatInput(),
          ],
        )
            : TabBarView(
          children: [
            // 🔵 Paired Devices Tab
            _deviceList(paired),
            Column(
              children: [
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => JarWeight.startScan(),
                  child: const Text("Scan for Devices"),
                ),
                const SizedBox(height: 10),
                Expanded(child: _deviceList(available)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _deviceList(List<Map<dynamic, dynamic>> devices) {
    if (devices.isEmpty) {
      return const Center(
        child: Text(
          "No Devices Found",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (c, i) {
        final device = devices[i];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.bluetooth, color: Colors.blue),
            title: Text(device['name'] ?? "Unknown Device"),
            subtitle: Text(device['address']),
            onTap: () async {
              setState(() => status = "Connecting...");
              await JarWeight.connectToDevice(device['address']);
              setState(() {
                isConnected = true;
                status = "Connected";
              });
            },
          ),
        );
      },
    );
  }

  Widget _chatInput() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Type message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: () {
              if (_controller.text.trim().isEmpty) return;

              JarWeight.sendMessage(_controller.text);

              setState(() {
                messages.add({
                  "text": _controller.text,
                  "isMe": true,
                });
              });

              _controller.clear();
            },
          ),
        ],
      ),
    );
  }
}



