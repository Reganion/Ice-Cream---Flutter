import 'package:flutter/material.dart';
import 'package:ice_cream/driver/delivery/confirm_delivery.dart';
import 'package:ice_cream/driver/delivery/view_details.dart';
import 'package:ice_cream/driver/message/messages.dart';
import 'package:ice_cream/driver/profile/profile.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shipments',
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: null,
        scaffoldBackgroundColor: const Color(0xFFF6F6F6),
      ),
      home: const ShipmentsPage(),
    );
  }
}

class ShipmentsPage extends StatefulWidget {
  const ShipmentsPage({super.key});

  @override
  State<ShipmentsPage> createState() => _ShipmentsPageState();
}

class _ShipmentsPageState extends State<ShipmentsPage> {
  static const Color kRed = Color(0xFFE3001B);
  static const Color kText = Color(0xFF111111);
  static const Color kMuted = Color(0xFF000000);
  static const Color kCard = Color(0xFFF2F2F2);
  static const Color kBlue = Color(0xFF007CFF);

  int _selectedTabIndex = 0; // 0 = Incoming, 1 = Accepted, 2 = Completed
  int _bottomNavIndex = 0; // 0 = Shipments, 1 = Messages, 2 = Profile

  Widget _buildShipmentCard({
    required String transactionId,
    required String badge,
    required Color badgeColor,
    required String productName,
    required String price,
    required String expectedOn,
    required String location,
    bool showViewDetailsButton = false,
    bool showBadge = true,
    VoidCallback? onViewDetails,
    VoidCallback? onTap,
  }) {
    Widget card = Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Symbols.deployed_code,
                    size: 20,
                    color: Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transactionId,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Transaction ID",
                      style: TextStyle(
                        fontSize: 12,
                        color: kMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (showBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: kText,
                    ),
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              height: 1,
              color: const Color(0xFFD9D9D9),
            ),
            const SizedBox(height: 12),
            if (showViewDetailsButton)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onViewDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(221, 0, 123, 255),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    "View Details",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Expected on:",
                          style: TextStyle(
                            fontSize: 12,
                            color: kMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          expectedOn,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Location:",
                          style: TextStyle(
                            fontSize: 12,
                            color: kMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: !showViewDetailsButton && onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: card,
            )
          : card,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _bottomNavIndex,
                children: [
                  // 0: Shipments (fully scrollable when keyboard open to avoid overflow)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            // Top header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 13, 20, 0),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFD9C1A7),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        "lib/driver/profile/images/kyley.png",
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + phone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Kyley Reganion",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "+63 9123456789",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1F1F1F),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bell button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 42,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFE9EA),
                      ),
                      child: const Icon(Icons.notifications, color: kRed),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Search (same position and look as client home_page search bar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Color(0xFFD9D9D9), width: 1),
                ),
                child: Row(
                  children: [
                    Transform.translate(
                      offset: const Offset(15, 0),
                      child: const Icon(
                        Icons.search,
                        color: Color(0xFFAFAFAF),
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 26),
                    Expanded(
                      child: TextField(
                        cursorColor: Colors.black,
                        cursorHeight: 18,
                        style: const TextStyle(
                          fontSize: 14.18,
                          color: Color(0xFF848484),
                        ),
                        decoration: const InputDecoration(
                          hintText: "Search",
                          hintStyle: TextStyle(
                            color: Color(0xFF848484),
                            fontSize: 15.76,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Tabs (Incoming / Accepted / Completed)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _SegmentChip(
                      label: "Incoming",
                      selected: _selectedTabIndex == 0,
                      selectedColor: kRed,
                      onTap: () => setState(() => _selectedTabIndex = 0),
                    ),
                    _SegmentChip(
                      label: "Accepted",
                      selected: _selectedTabIndex == 1,
                      selectedColor: kRed,
                      onTap: () => setState(() => _selectedTabIndex = 1),
                    ),
                    _SegmentChip(
                      label: "Completed",
                      selected: _selectedTabIndex == 2,
                      selectedColor: kRed,
                      onTap: () => setState(() => _selectedTabIndex = 2),
                    ),
                  ],
                ),
              ),
            ),

            // Cards (scroll with header when keyboard open)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    if (_selectedTabIndex == 0) ...[
                      _buildShipmentCard(
                        transactionId: "#32456124",
                        badge: "New",
                        badgeColor: kBlue,
                        productName: "Strawberry",
                        price: "₱1,900",
                        expectedOn: "21 Nov, 12:30 PM",
                        location: "ACLC College",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ConfirmDeliveryPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildShipmentCard(
                        transactionId: "#32456124",
                        badge: "New",
                        badgeColor: kBlue,
                        productName: "Strawberry",
                        price: "₱1,900",
                        expectedOn: "21 Nov, 12:30 PM",
                        location: "ACLC College",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ConfirmDeliveryPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildShipmentCard(
                        transactionId: "#32456131",
                        badge: "New",
                        badgeColor: kBlue,
                        productName: "Ube Cheese",
                        price: "₱2,300",
                        expectedOn: "23 Nov, 9:00 AM",
                        location: "Cebu Doctors University",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ConfirmDeliveryPage(),
                            ),
                          );
                        },
                      ),
                    ] else if (_selectedTabIndex == 1) ...[
                      _buildShipmentCard(
                        transactionId: "#32456189",
                        badge: "Pending",
                        badgeColor: const Color(0xFFFF6805),
                        productName: "Chocolate",
                        price: "₱2,100",
                        expectedOn: "22 Nov, 2:00 PM",
                        location: "University of Cebu",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ConfirmDeliveryPage(
                                showDeliverNowOnly: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      _buildShipmentCard(
                        transactionId: "#32456001",
                        badge: "Completed",
                        badgeColor: const Color(0xFF00AE2A),
                        productName: "Vanilla",
                        price: "₱1,500",
                        expectedOn: "20 Nov, 10:00 AM",
                        location: "SM City Cebu",
                        showViewDetailsButton: true,
                        showBadge: false,
                        onViewDetails: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const DeliveryViewDetailsPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildShipmentCard(
                        transactionId: "#32455987",
                        badge: "Completed",
                        badgeColor: const Color(0xFF00AE2A),
                        productName: "Cookies & Cream",
                        price: "₱2,200",
                        expectedOn: "19 Nov, 4:30 PM",
                        location: "Ayala Center Cebu",
                        showViewDetailsButton: true,
                        showBadge: false,
                        onViewDetails: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const DeliveryViewDetailsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
                  ],
                ),
              ),
            ),
                    ],
                  ),
                  // 1: Messages / Chat
                  const messagesPage(),
                  // 2: Profile
                  const Center(
                    child: Text(
                      'Profile',
                      style: TextStyle(fontSize: 16, color: Color(0xFF747474)),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Nav (same padding & style as client home_page)
            Card(
              margin: const EdgeInsets.only(left: 18, right: 18, bottom: 12),
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
              child: SizedBox(
                height: 65,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _BottomItem(
                      icon: Symbols.deployed_code,
                      label: "Shipments",
                      selected: _bottomNavIndex == 0,
                      onTap: () => setState(() => _bottomNavIndex = 0),
                    ),
                    _BottomItem(
                      icon: Symbols.chat_bubble,
                      label: "Messages",
                      selected: _bottomNavIndex == 1,
                      onTap: () => setState(() => _bottomNavIndex = 1),
                    ),
                    _BottomItem(
                      icon: Symbols.account_circle,
                      label: "Profile",
                      selected: _bottomNavIndex == 2,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: selected ? Colors.white  : const Color(0xFF171717),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  static const Color _activeColor = Color(0xFFE3001B);
  static const Color _inactiveColor = Color(0xFF9D9D9D);

  @override
  Widget build(BuildContext context) {
    final color = selected ? _activeColor : _inactiveColor;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
            fill: selected ? 1 : 0,
            weight: 300,
            grade: 200,
            opticalSize: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }
    return content;
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF2F2F2),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 21,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _showDeleteAllNotificationsModal(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: const Icon(
                        Symbols.delete,
                        size: 22,
                        color: Colors.black,
                        fill: 0,
                        weight: 600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Notifications list — SingleChildScrollView so cards always layout and show
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NotificationCard(
                      showIndicator: true,
                      indicatorColor: const Color(0xFFE21B2D),
                      title: "New order is available!",
                      message: "Admin just assigned you. Click to see full details.",
                      time: "Just now",
                    ),
                    const SizedBox(height: 14),
                    _NotificationCard(
                      showIndicator: true,
                      indicatorColor: const Color(0xFFCFCFCF),
                      title: "Delivered Successfully",
                      message: "Booking has been delivered completely.",
                      time: "3hrs ago",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showDeleteAllNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Delete all notifications?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1B1F),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "You can't undo this later.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF747474),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  // TODO: clear all notifications
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3001B),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Delete All",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Keep Them",
                    style: TextStyle(
                      color: Color(0xFF414141),
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final bool showIndicator;
  final Color indicatorColor;
  final String title;
  final String message;
  final String time;

  const _NotificationCard({
    this.showIndicator = true,
    required this.indicatorColor,
    required this.title,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 4),
            color: Color(0x1A000000),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prominent red vertical bar (full left edge, like the photo)
            if (showIndicator)
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(showIndicator ? 16 : 18, 12, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7C7C7C),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF424242),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
