import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../storage/jar_storage.dart';
import '../utils/colors.dart';
import '../model/jar_model.dart';

class EditJarScreen extends StatefulWidget {
  final JarModel jar;

  const EditJarScreen({super.key, required this.jar});

  @override
  State<EditJarScreen> createState() => _EditJarScreenState();
}

class _EditJarScreenState extends State<EditJarScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _customCapacityController = TextEditingController(); // 👈 Added Custom Controller
  final List<String> capacities = ["500g", "1 kg", "2 kg"];

  int selectedIndex = -1; // Default to -1 until we check the jar's capacity
  bool isItemError = false;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    // 1. Pre-fill the item name
    _itemController.text = widget.jar.name;

    WakelockPlus.enable();


    // 2. Pre-select the correct capacity button, OR pre-fill the custom box!
    if (widget.jar.capacity == 0.5) {
      selectedIndex = 0;
    } else if (widget.jar.capacity == 1.0) {
      selectedIndex = 1;
    } else if (widget.jar.capacity == 2.0) {
      selectedIndex = 2;
    } else {
      // It was a custom capacity! Pre-fill the text box instead.
      selectedIndex = -1;

      // Format it nicely (e.g., turn 5.0 into "5")
      String capStr = widget.jar.capacity.toString();
      if (capStr.endsWith('.0')) capStr = capStr.substring(0, capStr.length - 2);
      _customCapacityController.text = capStr;
    }

    // 3. Pre-fill the expiry date
    try {
      selectedDate = DateFormat('dd MMM yyyy').parse(widget.jar.expiryDate);
    } catch (e) {
      selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _itemController.dispose();
    _customCapacityController.dispose(); // 👈 Dispose custom controller
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  /// 🔥 Read custom input first, then fallback to buttons
  double getSelectedCapacity() {
    if (_customCapacityController.text.trim().isNotEmpty) {
      double? custom = double.tryParse(_customCapacityController.text.trim());
      if (custom != null && custom > 0) {
        return custom;
      }
    }

    switch (selectedIndex) {
      case 0: return 0.5;
      case 1: return 1.0;
      case 2: return 2.0;
      default: return 0.5;
    }
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
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        titleSpacing: 0,
        title: const Text(
          "Edit Smart Jar",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              /// ================= ITEM NAME =================
              const Text("Item Name", style: TextStyle(fontSize: 16, color: Color(0xFF2F3E46), fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [BoxShadow(color: Color(0xFFCACACA), blurRadius: 2, offset: Offset(0, 2))],
                ),
                child: TextField(
                  controller: _itemController,
                  onChanged: (value) => setState(() => isItemError = false),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (isItemError)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 8),
                  child: Text("Please enter item name", style: TextStyle(color: Colors.red, fontSize: 12)),
                ),

              const SizedBox(height: 25),

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

              const SizedBox(height: 10),

              // CUSTOM CAPACITY TEXT FIELD
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFFCACACA), blurRadius: 2, offset: Offset(0, 2)),
                    BoxShadow(color: Color(0xFFCACACA), blurRadius: 1, offset: Offset(0, 0)),
                  ],
                ),
                child: TextField(
                  controller: _customCapacityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() => selectedIndex = -1); // Unselect buttons if typing
                    } else {
                      setState(() => selectedIndex = 0); // Default back to first button if empty
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: "(e.g. 5 for 5 Kg)",
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// ================= EXPIRY DATE =================
              const Text("Expiry Date", style: TextStyle(fontSize: 16, color: Color(0xFF2F3E46), fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [BoxShadow(color: Color(0xFFCACACA), blurRadius: 2, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate == null ? "dd / mm / yyyy" : DateFormat('dd MMM yyyy').format(selectedDate!),
                        style: const TextStyle(fontSize: 18, color: Color(0xFF2F3E46)),
                      ),
                      const Icon(Icons.calendar_month, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      /// ================= SAVE CHANGES BUTTON =================
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 35, left: 15, right: 15),
        child: GestureDetector(
          onTap: () async {
            // 1. Check if name is empty
            if (_itemController.text.trim().isEmpty) {
              setState(() => isItemError = true);
              return;
            }

            // 👇 2. NEW CHECK: Prevent capacity from being less than current weight!
            double newCapacity = getSelectedCapacity();

            if (newCapacity < widget.jar.currentWeight) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Capacity cannot be less than current weight (${widget.jar.currentWeight.toStringAsFixed(2)} Kg).",
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return; // 🛑 Stops the code from saving!
            }

            // 3. Get existing jars
            List<JarModel> jars = await JarStorage.getJars();

            // 4. Find this exact jar and update its details
            int index = jars.indexWhere((j) => j.id == widget.jar.id);
            if (index != -1) {
              jars[index].name = _itemController.text.trim();
              jars[index].capacity = newCapacity; // 👈 Uses the validated capacity
              jars[index].expiryDate = DateFormat('dd MMM yyyy').format(selectedDate!);

              // 5. Save it back to storage
              await JarStorage.saveJars(jars);
            }

            // 6. Return true to trigger the Home Screen refresh
            if (context.mounted) Navigator.pop(context, true);
          },
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Color(0xFF2F3E46), offset: Offset(0, 2))],
              color: const Color(0xFF1F7A63),
            ),
            child: const Center(
              child: Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }
}