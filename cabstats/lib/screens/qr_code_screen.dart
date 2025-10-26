import 'package:flutter/material.dart';

class QRCodeScreen extends StatelessWidget {
  const QRCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment QR Code',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: Color(0xFF202124),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        surfaceTintColor: const Color(0xFFE8EAED),
      ),
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // QR Code Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EAED)),
                  ),
                  child: Column(
                    children: [
                      // Thank you message above QR code
                      const Text(
                        'Thanks For Riding With Me!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF202124),
                          letterSpacing: 0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // QR Code Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/PaymentQR.png',
                          width: 250,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE8EAED)),
                              ),
                              child: const Icon(
                                Icons.qr_code,
                                size: 100,
                                color: Color(0xFF9AA0A6),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Tips message below QR code
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB84D),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          'Tips Are Highly Appreciated! 💝',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF202124),
                            letterSpacing: 0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          // TODO: Implement share functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share functionality coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share, size: 20),
                        label: const Text('Share QR'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4285F4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5F6368),
                          side: const BorderSide(color: Color(0xFFE8EAED)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
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
  }
}
