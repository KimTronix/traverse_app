import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_input.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> bookingDetails;
  final double totalAmount;
  final String currency;

  const PaymentScreen({
    super.key,
    required this.bookingDetails,
    required this.totalAmount,
    required this.currency,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = 'card';
  bool isProcessing = false;
  bool savePaymentMethod = false;
  
  // Card details controllers
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController cardHolderController = TextEditingController();
  
  // PayPal controllers
  final TextEditingController paypalEmailController = TextEditingController();
  
  // Apple Pay / Google Pay (simulated)
  final List<Map<String, dynamic>> savedCards = [
    {
      'id': '1',
      'type': 'visa',
      'lastFour': '4242',
      'expiryMonth': '12',
      'expiryYear': '25',
      'holderName': 'John Doe',
    },
    {
      'id': '2',
      'type': 'mastercard',
      'lastFour': '8888',
      'expiryMonth': '08',
      'expiryYear': '26',
      'holderName': 'John Doe',
    },
  ];
  
  String? selectedSavedCard;

  @override
  void dispose() {
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    cardHolderController.dispose();
    paypalEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(IconStandards.getUIIcon('back')),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookingSummary(),
            const SizedBox(height: 24),
            _buildPaymentMethods(),
            const SizedBox(height: 24),
            _buildPaymentForm(),
            const SizedBox(height: 24),
            _buildSecurityInfo(),
            const SizedBox(height: 32),
            _buildPayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.bookingDetails['type'] ?? 'Booking',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '${widget.currency} ${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.currency} ${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodOption(
              'card',
              'Credit/Debit Card',
              IconStandards.getPaymentMethodIcon('credit_card'),
            ),
            _buildPaymentMethodOption(
              'paypal',
              'PayPal',
              IconStandards.getPaymentMethodIcon('paypal'),
            ),
            _buildPaymentMethodOption(
              'apple_pay',
              'Apple Pay',
              IconStandards.getPaymentMethodIcon('apple_pay'),
            ),
            _buildPaymentMethodOption(
              'google_pay',
              'Google Pay',
              IconStandards.getPaymentMethodIcon('google_pay'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String title, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: selectedPaymentMethod,
      onChanged: (String? newValue) {
        setState(() {
          selectedPaymentMethod = newValue!;
        });
      },
      title: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPaymentForm() {
    switch (selectedPaymentMethod) {
      case 'card':
        return _buildCardForm();
      case 'paypal':
        return _buildPayPalForm();
      case 'apple_pay':
      case 'google_pay':
        return _buildDigitalWalletForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCardForm() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Card Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (savedCards.isNotEmpty) ...[
              const Text(
                'Saved Cards',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...savedCards.map((card) => _buildSavedCardOption(card)),
              const SizedBox(height: 16),
              const Text(
                'Or add a new card',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
            ],
            CustomInput(
              controller: cardNumberController,
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              keyboardType: TextInputType.number,
              prefixIcon: IconStandards.getPaymentMethodIcon('credit_card'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomInput(
                    controller: expiryController,
                    labelText: 'Expiry Date',
                    hintText: 'MM/YY',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomInput(
                    controller: cvvController,
                    labelText: 'CVV',
                    hintText: '123',
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: cardHolderController,
              labelText: 'Cardholder Name',
              hintText: 'John Doe',

            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: savePaymentMethod,
              onChanged: (bool? value) {
                setState(() {
                  savePaymentMethod = value ?? false;
                });
              },
              title: const Text('Save this card for future payments'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedCardOption(Map<String, dynamic> card) {
    return RadioListTile<String>(
      value: card['id'],
      groupValue: selectedSavedCard,
      onChanged: (String? value) {
        setState(() {
          selectedSavedCard = value;
        });
      },
      title: Row(
        children: [
          Icon(
              IconStandards.getPaymentMethodIcon('credit_card'),
              size: 24,
            ),
          const SizedBox(width: 12),
          Text('**** **** **** ${card['lastFour']}'),
          const Spacer(),
          Text('${card['expiryMonth']}/${card['expiryYear']}'),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPayPalForm() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PayPal Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: paypalEmailController,
              labelText: 'PayPal Email',
              hintText: 'your.email@example.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: IconStandards.getUIIcon('email'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(IconStandards.getUIIcon('info'), color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will be redirected to PayPal to complete your payment securely.',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalWalletForm() {
    String walletName = selectedPaymentMethod == 'apple_pay' ? 'Apple Pay' : 'Google Pay';
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              walletName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    IconStandards.getPaymentMethodIcon('digital_wallet'),
                    color: Colors.green,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pay with $walletName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Quick, secure, and convenient payment',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(IconStandards.getUIIcon('security'), color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Secure Payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Your payment information is encrypted and secure. We use industry-standard SSL encryption to protect your data.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SSL Secured',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PCI Compliant',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        onPressed: isProcessing ? null : _processPayment,
        isLoading: isProcessing,
        child: Text(
          'Pay ${widget.currency} ${widget.totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_validatePaymentForm()) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Create the booking
      final bookingId = await bookingProvider.createBooking(
        type: widget.bookingDetails['type'],
        details: widget.bookingDetails,
        totalAmount: widget.totalAmount,
        currency: widget.currency,
      );
      
      if (mounted) {
        // Get the created booking
        final booking = bookingProvider.bookings.firstWhere(
          (b) => b['id'] == bookingId,
        );
        
        // Navigate to confirmation screen
        context.go('/booking-confirmation', extra: booking);
      }
    } catch (e) {
      if (mounted) {
        _showPaymentErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  bool _validatePaymentForm() {
    switch (selectedPaymentMethod) {
      case 'card':
        if (selectedSavedCard != null) {
          return true;
        }
        if (cardNumberController.text.isEmpty ||
            expiryController.text.isEmpty ||
            cvvController.text.isEmpty ||
            cardHolderController.text.isEmpty) {
          _showErrorSnackBar('Please fill in all card details');
          return false;
        }
        break;
      case 'paypal':
        if (paypalEmailController.text.isEmpty) {
          _showErrorSnackBar('Please enter your PayPal email');
          return false;
        }
        break;
      case 'apple_pay':
      case 'google_pay':
        // Digital wallets are always valid if selected
        break;
    }
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }



  void _showPaymentErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(IconStandards.getUIIcon('error'), color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text('Payment Failed'),
            ],
          ),
          content: Text(
            'There was an error processing your payment: $error\n\nPlease try again or use a different payment method.',
          ),
          actions: [
            CustomButton(
              onPressed: () => Navigator.of(context).pop(),
              isOutlined: true,
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }
}