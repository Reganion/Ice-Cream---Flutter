import 'package:flutter/material.dart';
import 'package:ice_cream/client/order/map_picker_page.dart';
import 'package:ice_cream/client/order/menu.dart';

class ManageAddressPage extends StatefulWidget {
  const ManageAddressPage({super.key});

  @override
  State<ManageAddressPage> createState() => _ManageAddressPageState();
}

class _ManageAddressPageState extends State<ManageAddressPage> {
  int selectedLabelIndex = -1;

  final TextEditingController firstNameController = TextEditingController(
    text: "Alma Fe",
  );
  final TextEditingController lastNameController = TextEditingController(
    text: "Pepania",
  );
  final TextEditingController contactController = TextEditingController(
    text: "09123456789",
  );
  final TextEditingController streetController = TextEditingController(
    text: "Briones st., ACLC College of Mandaue",
  );

  // --------------------- NEW VARIABLES ---------------------
  String selectedProvince = "Cebu";
  String selectedCity = "Mandaue";
  String selectedBarangay = "Maguikay";

  final Map<String, List<String>> barangaysByCity = {
    "Mandaue": [
      "Alang-Alang",
      "Bakilid",
      "Banilad",
      "Basak",
      "Cabancalan",
      "Cambaro",
      "Canduman",
      "Centro",
      "Guizo",
      "Ibabao-Estancia",
      "Jagobiao",
      "Labogon",
      "Looc",
      "Maguikay",
      "Mantuyong",
      "Opao",
      "Pagsabungan",
      "Subangdaku",
      "Tabok",
      "Tawason",
      "Tipolo",
      "Umapad",
    ],
    "Lapu-Lapu": [
      "Agus",
      "Babag",
      "Bankal",
      "Basak",
      "Buaya",
      "Canjulao",
      "Gun-ob",
      "Ibo",
      "Looc",
      "Mactan",
      "Maribago",
      "Marigondon",
      "Pajac",
      "Pajo",
      "Poblacion",
      "Punta Engaño",
      "Pusok",
      "Subabasbas",
      "Talima",
      "Tingo",
    ],
  };

  // Auto postal code
  String get postalCode => selectedCity == "Mandaue" ? "6014" : "6015";

  // --------------------- BUILD UI ---------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 43,
        leading: Transform.translate(
          offset: const Offset(20, 0),
          child: SizedBox(
            child: Material(
              color: const Color(0xFFF2F2F2),
              shape: const CircleBorder(),
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CheckoutPage(),
                    ),
                  );
                },
                child: const Center(
                  child: Icon(Icons.arrow_back, size: 20, color: Colors.black),
                ),
              ),
            ),
          ),
        ),
        title: Container(
          height: 43,
          width: 160,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            "Manage Address",
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 15.69,
              color: Colors.black,
            ),
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 10,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // FIRST + LAST NAME
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("First Name"),
                        _textField(firstNameController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("Last Name"),
                        _textField(lastNameController),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // CONTACT NUMBER
              _label("Contact Number"),
              _textField(contactController, keyboardType: TextInputType.phone),

              const SizedBox(height: 8),

              // PROVINCE + CITY
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("Province"),
                        _dropdown(
                          selectedProvince,
                          ["Cebu"],
                          (v) => setState(() => selectedProvince = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("City"),
                        _dropdown(selectedCity, ["Mandaue", "Lapu-Lapu"], (v) {
                          setState(() {
                            selectedCity = v!;
                            selectedBarangay = barangaysByCity[v]!.first;
                          });
                        }),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // BARANGAY + POSTAL
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("Barangay"),
                        _dropdown(
                          selectedBarangay,
                          barangaysByCity[selectedCity]!,
                          (v) => setState(() => selectedBarangay = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("Postal Code"),
                        _disabledField(postalCode),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // STREET
              _label("Street Name, Building, House No."),
              _textField(streetController),

              const SizedBox(height: 8),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapPickerPage()),
                  );
                },
                child: Container(
                  height: 114,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 18,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add, color: Color(0xff949494)),
                          SizedBox(width: 6),
                          Text(
                            "Add Location",
                            style: TextStyle(
                              color: Color(0xff949494),
                              fontSize: 12.55,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              _label("Label as:"),
              const SizedBox(height: 6),

              // LABEL BUTTONS
              Row(
                children: List.generate(3, (index) {
                  final labels = ["Home", "Work", "Other"];
                  final isSelected = selectedLabelIndex == index;

                  return Padding(
                    padding: EdgeInsets.only(right: index != 2 ? 10 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => selectedLabelIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? const Color(0xFFE3001B)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : const Color(0xFFDEDEDE),
                          ),
                        ),
                        child: Text(
                          labels[index],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1C1B1F),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 11),

              // SAVE BUTTON
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutPage()),
                  );
                },
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3001B),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: const Center(
                    child: Text(
                      "Save & Continue",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------- HELPERS ----------------------

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF1C1B1F),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: _boxDecoration(),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1C1B1F),
          fontWeight: FontWeight.w500,
        ),
        textAlignVertical: TextAlignVertical.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

Widget _disabledField(String value) {
  return Container(
    height: 46,
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12), // optional
      border: Border.all(color: Colors.transparent, width: 0), // removes border
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: const TextStyle(fontSize: 15, color: Colors.grey),
      ),
    ),
  );
}

  // ------------------ UPDATED DROPDOWN ------------------
  Widget _dropdown(
    String selectedValue,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      alignment: Alignment.center,
      decoration: _boxDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(selectedValue) ? selectedValue : null,
          isExpanded: true,

          // REMOVE DEFAULT ARROW
          iconSize: 0,

          // CUSTOM ARROW (GRAY + MOVE LEFT)
          icon: Transform.translate(
            offset: const Offset(6, 0), // adjust left position
            child: const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFFACACAC),
              size: 26,
            ),
          ),

          dropdownColor: Colors.white,

          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),

          items: items.map((value) {
            return DropdownMenuItem(
              value: value,
              child: Text(
                value,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            );
          }).toList(),

          onChanged: onChanged,
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration({Color color = Colors.white}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xffD9D9D9)),
    );
  }
}
