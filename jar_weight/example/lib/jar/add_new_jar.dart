import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jar_weight/jar_weight.dart';
import 'package:jar_weight_example/jar/weight_scale.dart';
import 'package:jar_weight_example/utils/text.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../utils/colors.dart';

class AddNewJar extends StatefulWidget {
  const AddNewJar({super.key});

  @override
  State<AddNewJar> createState() => _AddNewJarState();
}

class _AddNewJarState extends State<AddNewJar> {
  /*----------Select Weight-----------*/
  int selectedIndex = 0;
  final List<String> capacities = ["500g", "1 kg", "2 kg"];

  /*----------validation-----------*/
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _customCapacityController =
      TextEditingController();
  bool isItemError = false;
  bool isDateError = false;

  /*----------Date select-----------*/
  DateTime? selectedDate;

  double currentRawWeight = 0.0;
  double tareOffset = 0.0;

  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _setupListener();

    WakelockPlus.enable();

  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _itemController.dispose();
    _customCapacityController.dispose();
    super.dispose();
  }

  void _setupListener() {
    _scanSubscription = JarWeight.scanStream.listen((event) {
      if (event == null) return;

      if (event['type'] == 'disconnected') {
        JarWeight.isDeviceConnected = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Device disconnected! Please reconnect on the Home Screen.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (event['type'] == 'message' && event['text'] != null) {
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
          }
        }
      }
    });
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        isDateError = false;
      });
    }
  }

  /// 🔥 Convert selected capacity to grams or use custom input
  double getSelectedCapacity() {
    // 1. Check if they typed a custom capacity first!
    if (_customCapacityController.text.trim().isNotEmpty) {
      double? custom = double.tryParse(_customCapacityController.text.trim());
      if (custom != null && custom > 0) {
        return custom; // Returns exactly what they typed (e.g., 5.0)
      }
    }

    // 2. If the text box is empty, use the buttons
    switch (selectedIndex) {
      case 0:
        return 0.5; // 500g
      case 1:
        return 1.0; // 1kg
      case 2:
        return 2.0; // 2kg
      default:
        return 0.5;
    }
  }

  /// 🔥 Format expiry date
  String getFormattedExpiryDate() {
    if (selectedDate == null) return "";
    return "${selectedDate!.day.toString().padLeft(2, '0')}/"
        "${selectedDate!.month.toString().padLeft(2, '0')}/"
        "${selectedDate!.year}";
  }

  @override
  Widget build(BuildContext context) {
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
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        titleSpacing: 0,
        title: Text(
          TextString.NEW_BAR_TITLE,
          style: const TextStyle(color: Colors.white),
        ),
      ),

      /// ================= BODY =================
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              Text(
                TextString.EMPTY_JAR,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2F3E46),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                TextString.FLAT_SURFACE,
                style: const TextStyle(fontSize: 12, color: Color(0xFF949494)),
              ),

              const SizedBox(height: 15),

              /// Calibrate Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEEF9FF),
                    side: const BorderSide(
                      color: Color(0xFFD2E8F4),
                      width: 0.7,
                    ),
                    fixedSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    if (!JarWeight.isDeviceConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please connect to Bluetooth on the Home Screen first!",
                          ),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      tareOffset = currentRawWeight;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Scale calibrated to zero successfully!"),
                        backgroundColor: Color(0xFF1F7A63),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.balance_outlined, color: Color(0xFF2F3E46)),
                      SizedBox(width: 10),
                      Text(
                        "Calibrate Zero",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2F3E46),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// ================= ITEM NAME =================
              const Text(
                "Item Name",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2F3E46),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
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
                      child: TextField(
                        controller: _itemController,
                        onChanged: (value) {
                          if (value.trim().isNotEmpty) {
                            setState(() {
                              isItemError = false;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: "Enter item name",
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  if (isItemError)
                    const Padding(
                      padding: EdgeInsets.only(top: 6, left: 8),
                      child: Text(
                        "Please enter item name",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 20),

              /// ================= CAPACITY =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Capacity",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2F3E46),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "(Select or type below)",
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF2F3E46),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10),

              // CAPACITY BUTTONS
              Row(
                children: List.generate(capacities.length, (index) {
                  final isSelected = selectedIndex == index;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                            if (index == 0) {
                              _customCapacityController.text = "0.5";
                            } else if (index == 1) {
                              _customCapacityController.text = "1";
                            } else if (index == 2) {
                              _customCapacityController.text = "2";
                            }
                          });
                        },
                        child: Container(
                          height: 45,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEEF9FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFCACACA),
                                blurRadius: 2,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            capacities[index],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2F3E46),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(
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
                  child: TextField(
                    controller: _customCapacityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          selectedIndex = -1;
                        });
                      } else {
                        setState(() {
                          selectedIndex =
                              0;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: "(e.g. 5 for 5 Kg)",
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// ================= EXPIRY DATE =================
              const Text(
                "Expiry Date",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2F3E46),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
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
                                  ? "dd / mm / yyyy"
                                  : getFormattedExpiryDate(),
                              style: TextStyle(
                                fontSize: 18,
                                color: selectedDate == null
                                    ? Colors.grey
                                    : const Color(0xFF2F3E46),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_month,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (isDateError)
                    const Padding(
                      padding: EdgeInsets.only(top: 6, left: 8),
                      child: Text(
                        "Please select expiry date",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  SizedBox(height: 15),
                ],
              ),
            ],
          ),
        ),
      ),

      /// ================= COMPLETE BUTTON =================
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 15, right: 15),
        child: GestureDetector(
          onTap: () async {
            setState(() {
              isItemError = _itemController.text.trim().isEmpty;
              isDateError = selectedDate == null;
            });

            if (!isItemError && !isDateError) {
              bool? result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeightScale(
                    jarName: _itemController.text.trim(),
                    expiryDate: selectedDate!,
                    capacity: getSelectedCapacity(),
                    tareOffset: tareOffset,
                  ),
                ),
              );

              if (result == true) {
                if (context.mounted) Navigator.pop(context, true);
              }
            }
          },
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Color(0xFF2F3E46), offset: Offset(0, 1)),
              ],
              color: const Color(0xFF1F7A63),
            ),
            child: const Center(
              child: Text(
                "Complete",
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
