import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jar_weight/jar_weight.dart';
import 'package:jar_weight_example/storage/jar_storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../model/jar_model.dart';
import '../utils/colors.dart';
import '../utils/text.dart';

class WeightScale extends StatefulWidget {
  final String jarName;
  final double capacity;
  final DateTime expiryDate;
  final double tareOffset;
  final double? manualWeight;

  const WeightScale({
    super.key,
    required this.jarName,
    required this.capacity,
    required this.expiryDate,
    required this.tareOffset,
    this.manualWeight,
  });

  @override
  State<WeightScale> createState() => _WeightScaleState();
}

class _WeightScaleState extends State<WeightScale> {
  double currentWeight = 0.0;

  bool isDateError = false;
  bool isDateError1 = false;
  bool isWeightError = false;

  DateTime? selectedDate; // Added On
  DateTime? selectedDate1; // Expiry Date

  bool isOverload = false;

  final TextEditingController weightController = TextEditingController();

  // Create a subscription to listen to Bluetooth data
  StreamSubscription? _weightSubscription;

  @override
  void initState() {
    super.initState();

    selectedDate = DateTime.now();

    if (widget.manualWeight != null) {
      currentWeight = widget.manualWeight!;
      weightController.text = currentWeight.toStringAsFixed(3);
    }

    _startListeningToWeight();

    WakelockPlus.enable();
  }

  void _startListeningToWeight() {
    try {
      debugPrint("🔵 STARTING BLUETOOTH LISTENER...");

      _weightSubscription = JarWeight.scanStream.listen((event) {
        if (event['type'] == 'message') {
          String text = event['text'].toString();

          // 1. Get only the weight part before the '|'
          String weightPart = text.split('|')[0];

          // 2. Keep numbers and decimals
          String digits = weightPart.replaceAll(RegExp(r'[^0-9.]'), '');

          if (digits.isNotEmpty) {
            setState(() {
              // Convert grams to Kg
              currentWeight = (double.tryParse(digits) ?? 0.0) / 1000.0;
              weightController.text = currentWeight.toStringAsFixed(2);
            });
          }
        }
      });
    } catch (e) {
      debugPrint("🔴 STREAM ERROR: $e");
    }
  }

  @override
  void dispose() {
    // Cancel the subscription to prevent memory leaks when leaving the screen
    _weightSubscription?.cancel();
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double percent = (currentWeight / widget.capacity);
    double remainingPercent =
        ((widget.capacity - currentWeight) / widget.capacity);

    percent = percent.clamp(0.0, 1.0);
    remainingPercent = remainingPercent.clamp(0.0, 1.0);

    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: ColorString.BACKGROUND_COLOR,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: height / 9,
        backgroundColor: ColorString.APP_BAR_COLOR,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        titleSpacing: 0,
        title: Text(
          widget.jarName,
          style: const TextStyle(
            // fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!JarWeight.isDeviceConnected)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50, // Light red background
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.bluetooth_disabled, color: Colors.red),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Bluetooth disconnected. Please return to the Home Screen to connect.",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.bluetooth_connected, color: Colors.green),
                          SizedBox(width: 10),
                          Text(
                            "Scale Connected",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  /// ================= CIRCLE =================
                  Center(
                    child: SizedBox(
                      height: 180,
                      width: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 160,
                            width: 160,
                            child: CircularProgressIndicator(
                              value: 1,
                              strokeWidth: 22,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey.shade300,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 160,
                            width: 160,
                            child: CircularProgressIndicator(
                              value: percent,
                              strokeWidth: 22,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOverload
                                    ? Colors.red
                                    : const Color(0xFF1F7A63),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${currentWeight.toStringAsFixed(2)} Kg",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2F3E46),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "of ${widget.capacity.toStringAsFixed(1)} Kg",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "${(remainingPercent * 100).toInt()}% Remaining",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),

                  /// ================= CURRENT WEIGHT =================
                  const SizedBox(height: 15),
                  const Text(
                    "Current Weight",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF949494),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFCACACA),
                          blurRadius: 2,
                          offset: Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Color(0xFFCACACA),
                          blurRadius: 1,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),

                    ///  Bluetooth Connected and not connected
                    child: Center(
                      child: TextField(
                        controller: weightController,
                        // readOnly: true,

                        readOnly: false,
                        onChanged: (value) {
                          setState(() {
                            currentWeight = double.tryParse(value) ?? 0.0;
                            isOverload = currentWeight > widget.capacity;
                          });
                        },
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          color: Color(0xFF2F3E46),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintStyle: TextStyle(
                            color: Color(0xFFB2B2B2),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          hintText: "Waiting for scale...",
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  if (isOverload)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        "Weight is Overload",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  /// ================= ADDED DATE =================
                  const SizedBox(height: 15),
                  const Text(
                    "Added On",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF949494),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );

                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                          isDateError = false; // Hide error when picked
                        });
                      }
                    },
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFFCACACA),
                            blurRadius: 2,
                            offset: Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Color(0xFFCACACA),
                            blurRadius: 1,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate == null
                                ? "dd MM yyyy"
                                : DateFormat(
                                    'dd MMM yyyy',
                                  ).format(selectedDate!),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: selectedDate == null
                                  ? const Color(0xFFB2b2b2)
                                  : const Color(0xFF2F3E46),
                            ),
                          ),
                          const Icon(Icons.calendar_month, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  // 👇 2. ADD THIS ERROR TEXT BLOCK
                  if (isDateError)
                    const Padding(
                      padding: EdgeInsets.only(top: 6, left: 8),
                      child: Text(
                        "Please select the added date",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  /// ================= EXPIRY DATE =================
                  const SizedBox(height: 15),
                  const Text(
                    "Expiry Date",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF949494),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFCACACA),
                          blurRadius: 2,
                          offset: Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Color(0xFFCACACA),
                          blurRadius: 1,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(widget.expiryDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2F3E46),
                          ),
                        ),
                        const Icon(Icons.calendar_month, color: Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      /// ================= SAVE =================
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 15, right: 15),
        child: GestureDetector(
          onTap: () async {
            // 👇 1. CHECK BLUETOOTH CONNECTION FIRST!
            // if (!JarWeight.isDeviceConnected) {
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     const SnackBar(
            //       content: Text(
            //         "Cannot save! Please connect to Bluetooth first.",
            //       ),
            //       backgroundColor: Colors.red,
            //     ),
            //   );
            //   return; // 🛑 Stops the button from doing anything else!
            // }

            // 👇 2. Trigger the date validation UI
            setState(() {
              isDateError = selectedDate == null;
            });

            // 👇 3. Stop if the date is missing
            if (isDateError) {
              return;
            }

            // 👇 4. Stop if the scale hasn't sent a weight yet
            if (weightController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Waiting for scale to send weight data..."),
                ),
              );
              return;
            }

            if (currentWeight < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Cannot save a negative weight. Please recalibrate the scale."),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return; // 🛑 Stops the save!
            }

            // 👇 5. Stop if it's overloaded
            if (currentWeight > widget.capacity) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Cannot save! Weight exceeds capacity."),
                ),
              );
              return;
            }

            // If everything is perfect, save the jar!
            List<JarModel> jars = await JarStorage.getJars();

            JarModel newJar = JarModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: widget.jarName,
              capacity: widget.capacity,
              currentWeight: currentWeight,
              expiryDate: DateFormat('dd MMM yyyy').format(widget.expiryDate),
              addedDate: DateFormat('dd MMM yyyy').format(selectedDate!),
            );

            jars.add(newJar);
            await JarStorage.saveJars(jars);

            if (context.mounted) Navigator.pop(context, true);
          },
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Color(0xFF2F3E46), offset: Offset(0, 2)),
              ],
              color: const Color(0xFF1F7A63),
            ),
            child: const Center(
              child: Text(
                "Back to Home",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
