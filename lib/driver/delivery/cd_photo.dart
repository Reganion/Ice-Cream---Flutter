import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'cd_success.dart';

/// Photo / submit screen shown after tapping "Complete delivery".
/// Matches design: delivery overview, customer & order, received amount,
/// payment method (GCash / Cash), Take Photo + image display, Submit button.
class CompleteDeliveryPhotoPage extends StatefulWidget {
  const CompleteDeliveryPhotoPage({super.key});

  @override
  State<CompleteDeliveryPhotoPage> createState() =>
      _CompleteDeliveryPhotoPageState();
}

class _CompleteDeliveryPhotoPageState extends State<CompleteDeliveryPhotoPage> {
  final TextEditingController _receivedAmountController =
      TextEditingController();
  int _selectedPaymentMethod = -1; // -1 = none, 0 = GCash, 1 = Cash
  bool _hasPhoto = false;
  String? _photoPath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (!mounted || file == null) return;

    setState(() {
      _photoPath = file.path;
      _hasPhoto = true;
    });
  }

  @override
  void dispose() {
    _receivedAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   elevation: 0,
      //   leading: IconButton(
      //     onPressed: () => Navigator.pop(context),
      //     icon: const Icon(
      //       Symbols.arrow_back,
      //       color: Color(0xFF1C1B1F),
      //       size: 24,
      //       fill: 1,
      //       weight: 200,
      //       grade: 200,
      //       opticalSize: 24,
      //     ),
      //   ),
      //   title: const Text(
      //     'Complete delivery',
      //     style: TextStyle(
      //       fontSize: 18,
      //       fontWeight: FontWeight.w600,
      //       color: Color(0xFF1C1B1F),
      //     ),
      //   ),
      //   centerTitle: true,
      // ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewPadding.bottom;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 14, 18, bottomInset > 0 ? 6 : 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (bottomInset > 0 ? 6 : 8),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            // Delivery date, Time, Delivered time
            Row(
              children: [
                _buildLabelValue('21 Nov 2025', 'Delivery date'),
                const SizedBox(width: 16),
                _buildLabelValue('12:30 PM', 'Time'),
                const SizedBox(width: 16),
                _buildLabelValue('12:00 NN', 'Delivered time'),
              ],
            ),
            const SizedBox(height: 4),
            // Transaction ID, Distance, Travel time (with package icon)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Symbols.inventory_2,
                    size: 18,
                    color: const Color(0xFF1C1B1F),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildLabelValueColumn(
                          '#32456124',
                          'Transaction ID',
                        ),
                      ),
                      Expanded(
                        child: _buildLabelValueColumn('30 km', 'Distance'),
                      ),
                      Expanded(
                        child: _buildLabelValueColumn('20 min', 'Travel time'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
            const SizedBox(height: 4),
            const Text(
              'Customer',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF606060),
                fontWeight: FontWeight.w400,
              ),
            ),
            const Text(
              'kyle Reganion',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1B1F),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Delivery address:',
              style: TextStyle(
                fontSize: 13.67,
                color: Color(0xFF606060),
                fontWeight: FontWeight.w400,
              ),
            ),
            const Text(
              'ACLC College of Mandaue, Briones St., Maguikay, Mandaue City, Cebu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1B1F),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderRow('Quantity:', '1'),
                  _buildOrderRow('Size:', '2 Gal'),
                  _buildOrderRow('Order:', 'Strawberry'),
                  _buildOrderRow('Order Type:', 'Special Flavor'),
                  _buildOrderRow('Cost:', '₱1,900'),
                  _buildOrderRow('Down Payment:', '₱500'),
                  _buildOrderRow('Balance:', '₱1,400'),
                  _buildOrderRow('Customer Number:', '09123456789'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Received Amount (label and field vertically aligned in a row)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Received\nAmount',
                  style: TextStyle(
                    fontSize: 13.67,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1B1F),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _receivedAmountController,
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      hintStyle: const TextStyle(
                        fontSize: 13.67,
                        color: Color(0xFF8B8B8B),
                        fontWeight: FontWeight.w400,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(
                            0xFFCECECE,
                          ), // Set border color to #CECECE
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFCECECE),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFCECECE),
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Payment Method
            // Payment Method (label and buttons vertically aligned in a row)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Payment\nMethod',
                  style: TextStyle(
                    fontSize: 13.67,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1B1F),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _PaymentMethodButton(
                          label: 'GCash',
                          iconWidget: Image.asset(
                            "lib/client/order/images/gcsh.png",
                            width: 26,
                            height: 26,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 22,
                              color: Color(0xFF002CB8),
                            ),
                          ),
                          iconColor: const Color(0xFF002CB8),

                          isSelected: _selectedPaymentMethod == 0,
                          onTap: () =>
                              setState(() => _selectedPaymentMethod = 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PaymentMethodButton(
                          label: 'Cash',
                          iconWidget: Image.asset(
                            "lib/driver/delivery/images/cod.png",
                            width: 28,
                            height: 28,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.payments_rounded,
                              size: 22,
                              color: Color(0xFF00AE2A),
                            ),
                          ),
                          iconColor: const Color(0xFF00AE2A),
                          isSelected: _selectedPaymentMethod == 1,
                          onTap: () =>
                              setState(() => _selectedPaymentMethod = 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Take Photo + Image display
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: _PhotoCard(
                    icon: Icons.camera_alt,
                    label: 'Take Photo',
                    backgroundColor: const Color(0xFFF2F2F2),
                    iconColor: Colors.black,
                    height: 110,
                    onTap: () {
                      _takePhoto();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _PhotoCard(
                      icon: null,
                      label: '',
                      showPlaceholder: !_hasPhoto,
                      imagePath: _photoPath,
                      onTap: () {
                        _takePhoto();
                      },
                    ),
                  ),
                ),
              ],
            ),
                    const SizedBox(height: 8),
                    const Spacer(),

                    // Submit button (green) – onTap shows CompleteDeliverySuccessPage
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const CompleteDeliverySuccessPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00AE2A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabelValue(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1B1F),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8B8B8B),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelValueColumn(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1B1F),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8B8B8B),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF606060),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1B1F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodButton({
    required this.label,
    required this.iconWidget,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F2F2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? iconColor : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool showPlaceholder;
  final String? imagePath;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? height;
  final VoidCallback onTap;

  const _PhotoCard({
    this.icon,
    required this.label,
    this.showPlaceholder = true,
    this.imagePath,
    this.backgroundColor,
    this.iconColor,
    this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.white;
    final contentColor = iconColor ?? const Color(0xFF606060);
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height ?? 72,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: backgroundColor != null
                ? null
                : Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: showPlaceholder && imagePath == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 24, color: contentColor),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: contentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                )
              : imagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 36, color: contentColor),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          color: contentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
