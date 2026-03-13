import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jar_weight/jar_weight.dart';
import 'package:jar_weight_example/storage/jar_storage.dart';
import 'package:jar_weight_example/ui/edit_jar_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'model/jar_model.dart';

class JarDetailsDialog extends StatefulWidget {
  final JarModel jar;

  const JarDetailsDialog({super.key, required this.jar});

  @override
  State<JarDetailsDialog> createState() => _JarDetailsDialogState();
}

class _JarDetailsDialogState extends State<JarDetailsDialog> {
  double currentWeight = 0.0;
  double currentRawWeight = 0.0;
  double tareOffset = 0.0;
  StreamSubscription? _weightSubscription;

  @override
  void initState() {
    super.initState();
    // Start with the last saved weight so it never flashes 0.0
    currentWeight = widget.jar.currentWeight;

    // Only listen if Bluetooth is actually connected
    if (JarWeight.isDeviceConnected) {
      _startListeningToWeight();
    }

    WakelockPlus.enable();
  }

  void _startListeningToWeight() {
    try {
      _weightSubscription = JarWeight.scanStream.listen((event) {
        if (event != null &&
            event['type'] == 'message' &&
            event['text'] != null) {
          // Make it lowercase to easily check for 'kg' or 'g'
          String rawText = event['text'].toString().toLowerCase().replaceAll(
            ',',
            '.',
          );
          List<String> parts = rawText.split('|');

          if (parts.isNotEmpty) {
            String weightPart = parts[0];
            String cleanNumbersOnly = weightPart.replaceAll(
              RegExp(r'[^0-9.-]'),
              '',
            );

            if (cleanNumbersOnly.isNotEmpty) {
              double parsedWeight = double.tryParse(cleanNumbersOnly) ?? 0.0;

              // 👇 THE FIX: Smart Unit Conversion!
              // If the scale sends "1.00|kg", don't divide!
              // If it sends "1000|g", divide by 1000!
              if (rawText.contains('kg')) {
                currentRawWeight = parsedWeight;
              } else {
                currentRawWeight = parsedWeight / 1000.0;
              }

              double weightInKg = currentRawWeight - tareOffset;

              // Optional: Prevent the scale from showing negative numbers if it bounces
              if (weightInKg < 0) weightInKg = 0.0;

              setState(() {
                currentWeight = weightInKg;
              });
            }
          }
        }
      });
    } catch (e) {
      debugPrint("Dialog Stream Error: $e");
    }
  }

  @override
  void dispose() {
    _weightSubscription?.cancel();
    // 👇 ADDED THIS: Don't forget to turn off the wakelock!
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Added a safety check just in case capacity is 0 to avoid dividing by zero
    double safeCapacity = widget.jar.capacity > 0 ? widget.jar.capacity : 1.0;
    double percent = (currentWeight / safeCapacity).clamp(0.0, 1.0);
    int remainingPercent = ((1.0 - percent) * 100).round();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title & Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LEFT SIDE: EDIT BUTTON
                InkWell(
                  onTap: () async {
                    bool? updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditJarScreen(jar: widget.jar),
                      ),
                    );
                    if (updated == true) {
                      if (context.mounted) Navigator.pop(context, true);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF9FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xFF1F7A63),
                      size: 20,
                    ),
                  ),
                ),

                // CENTER: JAR NAME
                Expanded(
                  child: Center(
                    child: Text(
                      widget.jar.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2F3E46),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // RIGHT SIDE: DELETE BUTTON
                InkWell(
                  onTap: () async {
                    bool? confirmDelete = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: const Text(
                            "Delete Jar",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: Text(
                            "Are you sure you want to delete '${widget.jar.name}'?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmDelete == true) {
                      List<JarModel> jars = await JarStorage.getJars();
                      jars.removeWhere((j) => j.id == widget.jar.id);
                      await JarStorage.saveJars(jars);
                      if (context.mounted) Navigator.pop(context, true);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Live Weight
            Text(
              "${currentWeight.toStringAsFixed(2)} Kg",
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F3E46),
              ),
            ),
            const SizedBox(height: 5),

            // Capacity & Remaining
            Text(
              "of ${widget.jar.capacity} Kg ($remainingPercent% Remaining)",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 15),

            // Progress Bar
            Builder(
              builder: (context) {
                Color getMainColor() {
                  if (percent <= 0.3) {
                    return const Color(0xFFE54245);
                  } else if (percent <= 0.60) {
                    return const Color(0xFFFDB532);
                  } else {
                    return const Color(0xFF3CB340);
                  }
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(getMainColor()),
                  ),
                );
              },
            ),
            const SizedBox(height: 25),

            // Calibrate Zero Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD2E8F4),
                elevation: 0,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                setState(() {
                  tareOffset = currentRawWeight;
                  currentWeight = 0.0;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Calibrated to Zero!")),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.balance_outlined,
                    color: Color(0xFF2F3E46),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Calibrate Zero",
                    style: TextStyle(
                      color: Color(0xFF2F3E46),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cancel / Save Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F7A63),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () async {
                    if (!JarWeight.isDeviceConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Cannot save! Please connect Bluetooth first.",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    List<JarModel> jars = await JarStorage.getJars();
                    int index = jars.indexWhere((j) => j.id == widget.jar.id);
                    if (index != -1) {
                      jars[index].currentWeight = currentWeight;
                      await JarStorage.saveJars(jars);
                    }
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/*import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jar_weight/jar_weight.dart';
import 'package:jar_weight_example/storage/jar_storage.dart';
import 'package:jar_weight_example/ui/edit_jar_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'model/jar_model.dart';

class JarDetailsDialog extends StatefulWidget {
  final JarModel jar;

  const JarDetailsDialog({super.key, required this.jar});

  @override
  State<JarDetailsDialog> createState() => _JarDetailsDialogState();
}

class _JarDetailsDialogState extends State<JarDetailsDialog> {
  double currentWeight = 0.0;
  double currentRawWeight = 0.0;
  double tareOffset = 0.0;
  StreamSubscription? _weightSubscription;

  @override
  void initState() {
    super.initState();
    // Start with the last saved weight
    currentWeight = widget.jar.currentWeight;
    _startListeningToWeight();
    WakelockPlus.enable();

  }

  void _startListeningToWeight() {
    try {
      _weightSubscription = JarWeight.scanStream.listen((event) {
        if (event != null &&
            event['type'] == 'message' &&
            event['text'] != null) {
          String rawText = event['text'].toString().replaceAll(',', '.');
          List<String> parts = rawText.split('|');

          if (parts.isNotEmpty) {
            String weightPart = parts[0];
            String cleanNumbersOnly = weightPart.replaceAll(
              RegExp(r'[^0-9.-]'),
              '',
            );

            if (cleanNumbersOnly.isNotEmpty) {
              double weightInGrams = double.tryParse(cleanNumbersOnly) ?? 0.0;
              currentRawWeight = weightInGrams / 1000.0;

              double weightInKg = currentRawWeight - tareOffset;

              setState(() {
                currentWeight = weightInKg;
              });
            }
          }
        }
      });
    } catch (e) {
      debugPrint("Dialog Stream Error: $e");
    }
  }

  @override
  void dispose() {
    _weightSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double percent = (currentWeight / widget.jar.capacity).clamp(0.0, 1.0);
    int remainingPercent = ((1.0 - percent) * 100).round();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            // Title & Edit Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 👇 1. LEFT SIDE: EDIT BUTTON
                InkWell(
                  onTap: () async {
                    bool? updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditJarScreen(jar: widget.jar),
                      ),
                    );
                    if (updated == true) {
                      if (context.mounted) Navigator.pop(context, true);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF9FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit, color: Color(0xFF1F7A63), size: 20),
                  ),
                ),

                // 👇 2. CENTER: JAR NAME
                Expanded(
                  child: Center(
                    child: Text(
                      widget.jar.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2F3E46),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // 👇 3. RIGHT SIDE: DELETE BUTTON
                InkWell(
                  onTap: () async {
                    // Show confirmation popup
                    bool? confirmDelete = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          title: const Text("Delete Jar", style: TextStyle(fontWeight: FontWeight.bold)),
                          content: Text("Are you sure you want to delete '${widget.jar.name}'?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false), // Cancel
                              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pop(context, true), // Confirm Delete
                              child: const Text("Delete", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        );
                      },
                    );

                    // If they clicked "Delete" on the popup...
                    if (confirmDelete == true) {
                      // 1. Get current jars
                      List<JarModel> jars = await JarStorage.getJars();

                      // 2. Remove this specific jar by its ID
                      jars.removeWhere((j) => j.id == widget.jar.id);

                      // 3. Save the updated list to storage
                      await JarStorage.saveJars(jars);

                      // 4. Close the main Dialog and tell the Home Screen to refresh!
                      if (context.mounted) Navigator.pop(context, true);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50, // Light red background
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Live Weight
            Text(
              "${currentWeight.toStringAsFixed(2)} Kg",
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F3E46),
              ),
            ),
            const SizedBox(height: 5),

            // Capacity & Remaining
            Text(
              "of ${widget.jar.capacity} Kg ($remainingPercent% Remaining)",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 15),

            // Progress Bar
            // Progress Bar
            Builder(
                builder: (context) {
                  // 👇 1. Your custom color logic!
                  Color getMainColor() {
                    if (percent <= 0.3) {
                      return const Color(0xFFE54245); // Red
                    } else if (percent <= 0.60) {
                      return const Color(0xFFFDB532); // Yellow/Orange
                    } else {
                      return const Color(0xFF3CB340); // Green
                    }
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      // 👇 2. Removed 'const' and called your function!
                      valueColor: AlwaysStoppedAnimation<Color>(
                        getMainColor(),
                      ),
                    ),
                  );
                }
            ),
            const SizedBox(height: 25),
            // Calibrate Zero Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD2E8F4),
                // Light blue from screenshot
                elevation: 0,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                setState(() {
                  tareOffset = currentRawWeight;
                  currentWeight = 0.0;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Calibrated to Zero!")),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.balance_outlined,
                    color: Color(0xFF2F3E46),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Calibrate Zero",
                    style: TextStyle(
                      color: Color(0xFF2F3E46),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cancel / Save Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F7A63),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () async {
                    // 👇 1. CHECK BLUETOOTH CONNECTION FIRST!
                    if (!JarWeight.isDeviceConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Cannot save! Please connect Bluetooth first."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return; // 🛑 Stops the code from saving
                    }

                    // 👇 2. If connected, proceed with saving normally
                    List<JarModel> jars = await JarStorage.getJars();
                    int index = jars.indexWhere((j) => j.id == widget.jar.id);
                    if (index != -1) {
                      jars[index].currentWeight = currentWeight;
                      await JarStorage.saveJars(jars);
                    }
                    if (context.mounted) {
                      Navigator.pop(context, true); // Tell HomeScreen to refresh
                    }
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
*/
