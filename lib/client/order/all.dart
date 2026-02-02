import 'package:flutter/material.dart';
import 'package:ice_cream/client/favorite/favorite.dart';
import 'package:ice_cream/client/home_page.dart';
import 'package:ice_cream/client/messages/messages.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  int selectedTab = 0;
  final tabs = ["All", "Completed", "Processing", "Cancelled"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      bottomNavigationBar: _bottomNavBar(context),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                "Order History",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final isActive = selectedTab == index;
                    Color activeColor;
                    switch (tabs[index]) {
                      case "Completed":
                        activeColor = const Color(0xFF22B345);
                        break;
                      case "Processing":
                        activeColor = const Color(0xFFFF6805);
                        break;
                      case "Cancelled":
                        activeColor = const Color(0xFFE3001B);
                        break;
                      default: // All
                        activeColor = const Color(0xFF007CFF);
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedTab = index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isActive ? activeColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              tabs[index],
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFFFAFAFA)
                                    : const Color(0xFF1C1B1F),
                                fontWeight: FontWeight.w500,
                                fontSize: 11.85,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(children: getOrderCards()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- GET ORDER CARDS PER TAB ----------------
  List<Widget> getOrderCards() {
    switch (selectedTab) {
      case 1: // Completed
        return [
          orderCard(
            img: "lib/client/order/images/mg.png",
            name: "Mango Graham",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            rateColor: const Color(0xFFFFD900),
            isCompletedTab: true, // only for Completed
          ),
          orderCard(
            img: "lib/client/order/images/ub.png",
            name: "Ube Cheese",
            size: "2 gal",
            price: "₱200",
            qty: "2",
            rateColor: const Color(0xFFFFD900),
            isCompletedTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/cc.png",
            name: "Cookies & Cream",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            rateColor: const Color(0xFFFFD900),
            isCompletedTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/vn.png",
            name: "Cookies & Cream",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            rateColor: const Color(0xFFFFD900),
            isCompletedTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/mg.png",
            name: "Mango Graham",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            rateColor: const Color(0xFFFFD900),
            isCompletedTab: true, // only for Completed
          ),
          orderCard(
            img: "lib/client/order/images/ub.png",
            name: "Ube Cheese",
            size: "2 gal",
            price: "₱200",
            qty: "2",
            rateColor: const Color(0xFFFFD900),
            isCompletedTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/cc.png",
            name: "Cookies & Cream",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            rateColor: const Color(0xFFFFD900),
            isCompletedTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/vn.png",
            name: "Cookies & Cream",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            rateColor: const Color(0xFFFFD900),
            isCompletedTab: true,
          ),
        ];
      case 2: // Processing
        return [
          orderCard(
            img: "lib/client/order/images/ub.png",
            name: "Ube Cheese",
            size: "2 gal",
            price: "₱200",
            qty: "2",
            isProcessingTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/cc.png",
            name: "Cookies & Cream",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            isProcessingTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/mg.png",
            name: "Mango Graham",
            size: "2 gal",
            price: "₱200",
            qty: "2",
            isProcessingTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/vn.png",
            name: "Cookies & Cream",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            isProcessingTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/ub.png",
            name: "Ube Cheese",
            size: "2 gal",
            price: "₱200",
            qty: "2",
            isProcessingTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/cc.png",
            name: "Cookies & Cream",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            isProcessingTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/mg.png",
            name: "Mango Graham",
            size: "2 gal",
            price: "₱200",
            qty: "2",
            isProcessingTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/cc.png",
            name: "Cookies & Cream",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            isProcessingTab: true,
          ),
        ];
      case 3: // Cancelled
        return [
          orderCard(
            img: "lib/client/order/images/cc.png",
            name: "Cookies & Cream",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            isCancelledTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/mg.png",
            name: "Mango Graham",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            isCancelledTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/ub.png",
            name: "Ube Cheese",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            isCancelledTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/cc.png",
            name: "Cookies & Cream",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            isCancelledTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/mg.png",
            name: "Mango Graham",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            isCancelledTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/ub.png",
            name: "Ube Cheese",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            isCancelledTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/cc.png",
            name: "Cookies & Cream",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            isCancelledTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/mg.png",
            name: "Mango Graham",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            isCancelledTab: true,
          ),
          orderCard(
            img: "lib/client/order/images/ub.png",
            name: "Ube Cheese",
            size: "4 gal",
            price: "₱300",
            qty: "1",
            isCancelledTab: true,
          ),
        ];
      default: // All
        return [
          orderCard(
            img: "lib/client/order/images/mg.png",
            name: "Mango Graham",
            size: "4 gal",
            price: "₱300",
            qty: "1",
          ),
          orderCard(
            img: "lib/client/order/images/ub.png",
            name: "Ube Cheese",
            size: "2 gal",
            price: "₱200",
            qty: "2",
          ),
          orderCard(
            img: "lib/client/order/images/cc.png",
            name: "Cookies & Cream",
            size: "4 gal",
            price: "₱300",
            qty: "1",
          ),
          orderCard(
            img: "lib/client/order/images/mg.png",
            name: "Mango Graham",
            size: "4 gal",
            price: "₱300",
            qty: "1",
          ),
          orderCard(
            img: "lib/client/order/images/ub.png",
            name: "Ube Cheese",
            size: "2 gal",
            price: "₱200",
            qty: "2",
          ),
          orderCard(
            img: "lib/client/order/images/cc.png",
            name: "Cookies & Cream",
            size: "4 gal",
            price: "₱300",
            qty: "1",
          ),
          orderCard(
            img: "lib/client/order/images/mg.png",
            name: "Mango Graham",
            size: "4 gal",
            price: "₱300",
            qty: "1",
          ),
          orderCard(
            img: "lib/client/order/images/ub.png",
            name: "Ube Cheese",
            size: "2 gal",
            price: "₱200",
            qty: "2",
          ),
          orderCard(
            img: "lib/client/order/images/cc.png",
            name: "Cookies & Cream",
            size: "4 gal",
            price: "₱300",
            qty: "1",
          ),
        ];
    }
  }

  /// ---------------- ORDER CARD ----------------
  Widget orderCard({
    required String img,
    required String name,
    required String size,
    required String price,
    required String qty,
    Color? rateColor,
    bool isCompletedTab = false,
    bool isProcessingTab = false, // new flag for Processing
    bool isCancelledTab = false,
  }) {
    // Determine left button text and style
    String leftText;
    Color leftBgColor;
    Color leftTextColor;
    Color leftBorderColor = Colors.transparent; // defa

    // Determine right button text and style
    bool showRightBtn = true;
    String rightText = "Buy Again";
    Color rightColor = const Color(0xFFF2F2F2);
    Color rightTextColor = Colors.black87;

    if (isCompletedTab) {
      // Completed tab → Rate button
      leftText = "Rate";
      leftBgColor = rateColor ?? const Color(0xFFFFD900);
      leftTextColor = Colors.black;

      rightText = "Buy Again";
      rightColor = const Color(0xFFF2F2F2);
      rightTextColor = Colors.black87;
      showRightBtn = true;
    } else if (isProcessingTab) {
      // Processing tab → Cancel + Track Order
      leftText = "Cancel";
      leftBgColor = Colors.white;
      leftTextColor = const Color(0xFFE3001B);
      leftBorderColor = const Color(0xFFE3001B);

      rightText = "Track Order";
      rightColor = const Color(0xFF007CFF);
      rightTextColor = Colors.white;
      showRightBtn = true;
    } else if (isCancelledTab) {
      // Cancelled tab → Details + Buy Again
      leftText = "Details";
      leftBgColor = const Color(0xFFF2F2F2);
      leftTextColor = Colors.black87;

      rightText = "Buy Again";
      rightColor = const Color(0xFF007CFF);
      rightTextColor = Color(0xFFFFFFFF);
      showRightBtn = true;
    } else {
      // Default All tab
      leftText = name == "Ube Cheese"
          ? "Cancel"
          : name == "Cookies & Cream"
          ? "Details"
          : "Rate";

      leftBgColor = name == "Ube Cheese"
          ? const Color(0xFFFCE8E9)
          : name == "Cookies & Cream"
          ? const Color(0xFFF2F2F2)
          : (rateColor ?? const Color(0xFFE3001B));

      leftTextColor = name == "Ube Cheese"
          ? const Color(0xFFE3001B)
          : name == "Cookies & Cream"
          ? Colors.black87
          : Colors.white;

      // Add border only for "Cancel" in All tab
      if (selectedTab == 0 && leftText == "Cancel") {
        leftBorderColor = const Color(0xFFE3001B);
      }

      // Right button logic
      if (selectedTab == 0 && name == "Ube Cheese") {
        showRightBtn = false; // hide "Buy Again" for Ube Cheese in All tab
      } else {
        showRightBtn = true;
      }

      rightText = "Buy Again";
      rightColor = name == "Cookies & Cream"
          ? const Color(0xFF007CFF)
          : const Color(0xFFF2F2F2);
      rightTextColor = name == "Cookies & Cream"
          ? Colors.white
          : Colors.black87;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(img, width: 60, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13.64,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Quantity: $qty",
                      style: const TextStyle(
                        fontSize: 12.79,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          size,
                          style: const TextStyle(
                            fontSize: 11.96,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 11.96,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE3001B),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (isProcessingTab && leftText == "Cancel") {
                              showCancelOrderDialog(context);
                              return;
                            }

                            if (leftText == "Rate") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RateOrderPage(
                                    imageAsset: img,
                                    itemName: name,
                                    status: 'Delivered',
                                    price: price,
                                    dateTimeLabel: 'Today, 12:30 PM',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            height: 32,
                            width: 81,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: leftBgColor,
                              border: Border.all(
                                color: leftBorderColor,
                                width: 1.3,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                leftText,
                                style: TextStyle(
                                  color: leftTextColor,
                                  fontSize: 11.96,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (showRightBtn) ...[
                          const SizedBox(width: 5),
                          Container(
                            height: 32,
                            width: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: rightColor,
                            ),
                            child: Center(
                              child: Text(
                                rightText,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11.96,
                                  color: rightTextColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- BOTTOM NAV ----------------
  Widget _bottomNavBar(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(left: 18, right: 18, bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 0,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomIcon(
              icon: Symbols.home,
              label: "Home",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              },
            ),
            _BottomIcon(
              icon: Symbols.local_mall,
              label: "Order",
              active: true,
              onTap: () {},
              fillColor: const Color(0xFFE3001B),
            ),
            _BottomIcon(
              icon: Symbols.favorite,
              label: "Favorite",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritePage()),
                );
              },
            ),
            _BottomIcon(
              icon: Symbols.chat,
              label: "Messages",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MessagesPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- RATE ORDER PAGE ----------------
}

class RateOrderPage extends StatefulWidget {
  const RateOrderPage({
    super.key,
    required this.imageAsset,
    required this.itemName,
    required this.price,
    this.status = 'Delivered',
    this.dateTimeLabel = 'Today, 12:30 PM',
  });

  final String imageAsset;
  final String itemName;
  final String price;
  final String status;
  final String dateTimeLabel;

  @override
  State<RateOrderPage> createState() => _RateOrderPageState();
}

class _RateOrderPageState extends State<RateOrderPage> {
  int _rating = 0; // start with no selection (all gray)
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // The continue button is now pushed even closer to the absolute bottom
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF3F3F3),
                          ),
                          child: const Icon(Icons.close, color: Colors.black),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Rate your order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40), // keep title centered
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: Image.asset(
                                  widget.imageAsset,
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.dateTimeLabel,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF5B5B5B),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.itemName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  widget.status,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5B5B5B),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.price,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Divider(height: 1, thickness: 1.3, color: Color(0xFFD2D2D2)),
                        const SizedBox(height: 22),
                        const Text(
                          'How was the ice cream?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700, 
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Please rate the store.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5B5B5B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final value = index + 1;
                              double availableWidth = constraints.maxWidth - 36; // account for padding
                              double starSize = (availableWidth / 5).clamp(34.0, 58.0);

                              Color starColor;
                              IconData starIcon;

                              if (_rating == 0) {
                                starIcon = Icons.star_rate;
                                starColor = const Color(0xFFD9D9D9);
                              } else {
                                if (value <= _rating) {
                                  starIcon = Icons.star_rate;
                                  starColor = const Color(0xFFFFD900);
                                } else {
                                  starIcon = Icons.star_rate;
                                  starColor = const Color(0xFFD9D9D9);
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () => setState(() => _rating = value),
                                  child: Icon(
                                    starIcon,
                                    size: starSize,
                                    color: starColor,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 38),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFC7C7C7)),
                          ),
                          child: TextField(
                            controller: _messageController,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Message here',
                              hintStyle: TextStyle(
                                color: Color(0xFF8C8C8C),
                                fontSize: 14,
                              ),
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        // The continue button is no longer here!
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        // Reduce the minimum padding to move the button even closer to the very bottom.
        minimum: EdgeInsets.zero,
        // Remove internal padding, only leave spacing at the left/right, and minimal bottom.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 12), // less space at bottom/top
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Submit rating/message if needed.
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE3001B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? fillColor;

  const _BottomIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = active ? const Color(0xFFE3001B) : const Color(0xFF969696);
    final double fillValue = (active && fillColor != null) ? 1 : 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 21,
              color: fillColor != null && active ? fillColor : iconColor,
              fill: fillValue,
              weight: 100,
              grade: 200,
              opticalSize: 24,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: iconColor,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showCancelOrderDialog(BuildContext context) {
  final otherReasonController = TextEditingController();

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      String? selectedReason;

      final reasons = <String>[
        'Changed my mind',
        'Ordered by mistake',
        'Want to update or change my order',
        'Payment issue (e.g., failed)',
        'Others (Please specify)',
      ];

      // Height of each default reason tile (for uniformity)
      const double defaultOptionHeight = 45;

      Widget reasonTile(String text, void Function(void Function()) setState) {
        final isSelected = selectedReason == text;
        // Special handling for "Others (Please specify)"
        if (text == 'Others (Please specify)') {
          return InkWell(
            onTap: () => setState(() => selectedReason = text),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: !isSelected ? defaultOptionHeight : null,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3), // #F3F3F3
                borderRadius: BorderRadius.circular(10),
                // NO border here for "Others" box
              ),
              child: !isSelected
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2F80ED)
                                  : const Color(0xFF828282),
                              width: 1,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF2F80ED),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            text,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5B5B5B),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2F80ED)
                                      : const Color(0xFF828282),
                                  width: 1,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF2F80ED),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF5B5B5B),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9E9E9), // New background color for box
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFC4C4C4)), // New border color
                            ),
                            child: TextField(
                              controller: otherReasonController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.all(12),
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: 'Write your message here',
                                hintStyle: TextStyle(
                                  color: Color(0xFF5B5B5B),
                                  fontSize: 11,
                                ),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF434343),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        }
        // All other reasons (default)
        return InkWell(
          onTap: () => setState(() => selectedReason = text),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: defaultOptionHeight,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2F80ED)
                          : const Color(0xFF828282),
                      width: 1,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2F80ED),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5B5B5B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.23),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.78,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top icon (cancel X, filled) on red circle
                      Padding(
                        padding: const EdgeInsets.all(1),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE3001B),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Symbols.close,
                            size: 26,
                            color: Colors.white,
                            fill: 1,
                            weight: 700,
                            grade: 0,
                            opticalSize: 24,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Cancel Order?",
                        style: TextStyle(
                          fontSize: 19.85,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Are you sure you want to cancel this order?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.23,
                          color: Color(0xFF5B5B5B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Reason options
                      ...reasons.expand((r) sync* {
                        yield reasonTile(r, setState);
                        yield const SizedBox(height: 10);
                      }),

                     

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 118.75,
                            height: 43.43,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF969696)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "No, cancel",
                                style: TextStyle(
                                  fontSize: 14.26,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF434343),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 118.75,
                            height: 43.43,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                showSuccessDialog(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE3001B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Center(
                                child: Text(
                                  "Yes, I'm sure",
                                  softWrap: false,
                                  maxLines: 1,
                                  overflow: TextOverflow.visible,
                                  style: TextStyle(
                                    fontSize: 14.26,
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
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(otherReasonController.dispose);
}

Future<void> showSuccessDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true, // allow dismiss by tapping outside
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.83),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              const SizedBox(height: 10),
              // Success icon (check circle, green)
              Icon(
                Symbols.check_circle,
                size: 44, // matches previous container size
                color: Color(0xFF22B345),
                fill: 1,
                weight: 400,
                grade: 0,
                opticalSize: 24,
              ),

              const SizedBox(height: 8),

              const Text(
                "Successfully Cancel",
                style: TextStyle(fontSize: 19.85, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                "Your order has been successfully cancel",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.23,
                  color: Color(0xFF5B5B5B),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}
