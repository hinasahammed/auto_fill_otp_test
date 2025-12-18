import 'dart:developer';

import 'package:auto_fill_otp_test/sample_strategy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp_autofill/otp_autofill.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late OTPTextEditController _otpController;

  @override
  void initState() {
    _otpController =
        OTPTextEditController(
          codeLength: 5,
          onCodeReceive: (code) => log('Your Application receive code - $code'),
        )..startListenUserConsent((code) {
          final exp = RegExp(r'(\d{5})');
          return exp.stringMatch(code ?? '') ?? '';
        }, strategies: [SampleStrategy()]);
    super.initState();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Otp Test")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _otpController,
              maxLength: 6,
              autofillHints: [AutofillHints.oneTimeCode],
              keyboardType: TextInputType.visiblePassword,
              autofocus: true,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
            ),
          ],
        ),
      ),
    );
  }
}
