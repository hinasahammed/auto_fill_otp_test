import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:permission_handler/permission_handler.dart';

class OTPAutoFillScreen extends StatefulWidget {
  const OTPAutoFillScreen({super.key});

  @override
  State createState() => _OTPAutoFillScreenState();
}

class _OTPAutoFillScreenState extends State<OTPAutoFillScreen>
    with CodeAutoFill {
  String? _code;
  final int _otpLength = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _requestPermissions();
      _initSmsListener();
    });
  }

  // Request SMS permission
  Future<void> _requestPermissions() async {
    final status = await Permission.sms.request();
    if (status == PermissionStatus.granted) {
      log("SMS permission granted");
    } else {
      log("SMS permission denied");
    }
  }

  // Initialize SMS listener
  void _initSmsListener() async {
    // Start listening for SMS
    await SmsAutoFill().listenForCode();

    // Get app signature for SMS (optional - for better SMS detection)
    String? signature = await SmsAutoFill().getAppSignature;
    log("App Signature: $signature");
  }

  @override
  void codeUpdated() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _code = code;
        });
      }
    });
    log("OTP Code received: $code");
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Auto Fill'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter OTP',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'We have sent you a 6-digit code',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            // Method 1: Using PinFieldAutoFill widget
            PinFieldAutoFill(
              decoration: UnderlineDecoration(
                textStyle: const TextStyle(fontSize: 20, color: Colors.black),
                colorBuilder: FixedColorBuilder(
                  Colors.black.withValues(alpha: .3),
                ),
              ),
              currentCode: _code,
              onCodeSubmitted: (code) {
                log("Code submitted: $code");
              },
              onCodeChanged: (code) {
                if (code!.length == _otpLength) {
                  log("OTP Complete: $code");
                  _verifyOTP(code);
                }
              },
            ),

            const SizedBox(height: 30),

            // Method 2: Using TextFieldPinAutoFill
            TextFieldPinAutoFill(
              currentCode: _code,
              codeLength: _otpLength,
              decoration: const InputDecoration(),
              onCodeChanged: (code) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _code = code;
                    });
                  }
                });
                if (code.length == _otpLength) {
                  _verifyOTP(code);
                }
              },
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                if (_code != null && _code!.length == _otpLength) {
                  _verifyOTP(_code!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter complete OTP')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
              ),
              child: const Text('Verify OTP'),
            ),

            const SizedBox(height: 20),

            TextButton(onPressed: _resendOTP, child: const Text('Resend OTP')),
          ],
        ),
      ),
    );
  }

  void _verifyOTP(String otp) {
    // Implement your OTP verification logic here
    log("Verifying OTP: $otp");

    // Example verification
    if (otp == "123456") {
      // Replace with actual verification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP Verified Successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resendOTP() {
    // Implement resend OTP logic
    setState(() {
      _code = null;
    });

    // Restart SMS listener
    _initSmsListener();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('OTP Resent')));
  }
}

// Alternative implementation using native autofill hints
class NativeOTPAutoFill extends StatefulWidget {
  const NativeOTPAutoFill({super.key});

  @override
  State createState() => _NativeOTPAutoFillState();
}

class _NativeOTPAutoFillState extends State<NativeOTPAutoFill> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Native OTP Auto Fill')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: AutofillGroup(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 45,
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  autofillHints: const [AutofillHints.oneTimeCode],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    if (value.length == 1 && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }

                    // Check if all fields are filled
                    String otp = _controllers.map((c) => c.text).join();
                    if (otp.length == 6) {
                      log("Complete OTP: $otp");
                      TextInput.finishAutofillContext();
                    }
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
