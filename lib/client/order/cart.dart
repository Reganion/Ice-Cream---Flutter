import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class CartItem {
  final String name;
  final String image;
  final int price;
  int qty;
  bool selected;

  CartItem({
    required this.name,
    required this.image,
    required this.price,
    this.qty = 1,
    this.selected = true,
  });
}

class _CartPageState extends State<CartPage> {
  /// Saved copy of items before "Delete all", so empty-cart back can restore.
  List<CartItem>? _itemsBeforeClear;

  List<CartItem> items = [
    CartItem(
      name: "Fun Cakes",
      image: "lib/client/order/images/sb.png",
      price: 300,
    ),
    CartItem(
      name: "Vanilla",
      image: "lib/client/order/images/sb.png",
      price: 100,
    ),
    CartItem(
      name: "Strawberry",
      image: "lib/client/order/images/sb.png",
      price: 400,
    ),
    CartItem(
      name: "Matcha",
      image: "lib/client/order/images/sb.png",
      price: 800,
      selected: false,
    ),
    CartItem(
      name: "Cookies & Cream",
      image: "lib/client/order/images/sb.png",
      price: 200,
      selected: false,
    ),
    CartItem(
      name: "Matcha",
      image: "lib/client/order/images/sb.png",
      price: 800,
      selected: false,
    ),
    CartItem(
      name: "Cookies & Cream",
      image: "lib/client/order/images/sb.png",
      price: 200,
      selected: false,
    ),
    CartItem(
      name: "Matcha",
      image: "lib/client/order/images/sb.png",
      price: 800,
      selected: false,
    ),
    CartItem(
      name: "Cookies & Cream",
      image: "lib/client/order/images/sb.png",
      price: 200,
      selected: false,
    ),
  ];

  bool get allSelected => items.every((e) => e.selected);
  double get total =>
      items.where((e) => e.selected).fold(0, (sum, e) => sum + e.qty * e.price);

  void toggleSelectAll(bool value) {
    setState(() {
      for (var item in items) {
        item.selected = value;
      }
    });
  }

  void incrementQty(int index) {
    setState(() {
      items[index].qty++;
    });
  }

  void decrementQty(int index) {
    if (items[index].qty > 1) {
      setState(() {
        items[index].qty--;
      });
    }
  }

  void removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _showDeleteAllModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red trash icon at top center
              Icon(
                Symbols.delete,
                size: 45,
                color: const Color(0xFFE3001B),
                fill: 1,
                weight: 400,
                grade: 0,
                opticalSize: 48,
              ),
              const SizedBox(height: 10),
              const Text(
                "Delete all",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1B1F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Are you sure you want to delete all the cart?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.50,
                  color: Color(0xFF747474),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11.45),
                          border: Border.all(
                            color: const Color(0xFF969696),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "No, cancel",
                          style: TextStyle(
                            fontSize: 14.36,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF434343),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _itemsBeforeClear = List<CartItem>.from(items);
                          items.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3001B),
                          borderRadius: BorderRadius.circular(11.45),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Yes, I'm sure",
                          style: TextStyle(
                            fontSize: 14.36,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: items.isEmpty
          ? null
          : AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              centerTitle: true,
              leadingWidth: 56,
              leading: Transform.translate(
                offset: const Offset(15, 0),
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 43,
                      height: 43,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F2F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              title: Container(
                height: 43,
                width: 140,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "My Cart",
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 15.69),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: Center(
                    child: GestureDetector(
                      onTap: allSelected ? () => _showDeleteAllModal(context) : null,
                      child: Icon(
                        Symbols.delete,
                        size: 22,
                        color: allSelected
                            ? const Color(0xFF171717)
                            : const Color(0xFFA8A8A8),
                        fill: 0,
                        weight: 400,
                        grade: 0,
                        opticalSize: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),

      body: items.isEmpty
          ? _buildEmptyCartBody()
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Check circle outside the box, on the left, vertically centered
                    SizedBox(
                      height: 97,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              item.selected = !item.selected;
                            });
                          },
                          child: item.selected
                              ? Container(
                                  width: 15,
                                  height: 15,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE3001B),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 15,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF434343),
                                      width: 1,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.05),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Transform.translate(
                                  offset: const Offset(2, 2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      item.image,
                                      width: 65,
                                      height: 65,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "4 gal",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                    color: Color(0xFF505050),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₱${item.price}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Move qty buttons to top-right corner
                      Positioned(
                        bottom: 0, // adjust vertical position
                        right: 3, // adjust horizontal position
                        child: Row(
                          children: [
                            _qtyButton(Icons.remove, () => decrementQty(index)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                item.qty.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _qtyButton(Icons.add, () => incrementQty(index)),
                          ],
                        ),
                      ),

                      // Delete icon at top-right corner
                      Positioned(
                        top: 0,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => removeItem(index),
                          child: Icon(
                            Symbols.delete,
                            size: 16,
                            color: Color(0xFFE3001B),
                            fill: 1,
                            weight: 700,
                            grade: 200,
                            opticalSize: 48,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                    ),
                  ],
                );
              },
            ),
          ),
          // FOOTER
          Padding(
            padding: const EdgeInsets.only(
    left: 20,   // horizontal padding
    right: 20,  // horizontal padding
    bottom: 10, // vertical padding only at bottom
  ),// horizontal margin

            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ), // horizontal margin
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // --- CUSTOM CIRCLE (Select All) ---
                  GestureDetector(
                    onTap: () => toggleSelectAll(!allSelected),
                    child: allSelected
                        ? Container(
                            width: 15,
                            height: 15,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE3001B),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          )
                        : Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF434343),
                                width: 1,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Select All",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF434343),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Spacer(),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 38,
                        ), // move "Total" slightly left
                        child: const Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF767676),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        "₱${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16.54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 23),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE3001B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20, // adds small padding around text
                        vertical: 8,
                      ),
                      minimumSize: const Size(
                        0,
                        45,
                      ), // keep height, width will shrink
                    ),
                    child: const Text(
                      "Checkout",
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Arrow back + My Cart design applied to empty cart body (same as app bar).
  Widget _buildEmptyCartBody() {
    return Column(
      children: [
        // Same design as app bar: arrow_back (left), My Cart (center)
        SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // My Cart pill (center)
                Center(
                  child: Container(
                    height: 43,
                    width: 140,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      "My Cart",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 15.69,
                      ),
                    ),
                  ),
                ),
                // Arrow back (left, same position)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          if (_itemsBeforeClear != null) {
                            items.addAll(_itemsBeforeClear!);
                            _itemsBeforeClear = null;
                          }
                        });
                      },
                      child: Container(
                        width: 43,
                        height: 43,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF2F2F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "lib/client/order/images/no_cart.png",
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "You have no cart today!",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE9E9E9), // background color
        ),
        child: Icon(icon, size: 11),
      ),
    );
  }
}
