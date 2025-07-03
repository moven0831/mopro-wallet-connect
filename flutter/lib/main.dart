import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reown_appkit/reown_appkit.dart';

import 'package:mopro_flutter/mopro_flutter.dart';
import 'deep_link_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ReownAppKitModal? _appKitModal;
  Uint8List? _noirProofResult;
  bool? _noirValid;
  final _moproFlutterPlugin = MoproFlutter();
  bool isProving = false;
  bool isInitializing = false;
  Exception? _error;

  // Controllers to handle user input
  final TextEditingController _controllerNoirA = TextEditingController();
  final TextEditingController _controllerNoirB = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controllerNoirA.text = "5";
    _controllerNoirB.text = "3";
  }

  Future<void> _ensureAppKitInitialized(BuildContext context) async {
    if (_appKitModal != null) return;

    setState(() {
      isInitializing = true;
      _error = null;
    });

    try {
      // Initialize AppKit with proper context that has MaterialLocalizations
      final appKitModal = ReownAppKitModal(
        context: context,
        projectId: const String.fromEnvironment('PROJECT_ID', defaultValue: 'c4f79cc821944d9680842e34466bfb44'), // Temporary test ID - replace with your actual Project ID
        metadata: const PairingMetadata(
          name: 'Mopro Wallet Connect',
          description: 'Zero-Knowledge Proof Generator with Wallet Connect',
          url: 'https://mopro.org/',
          icons: ['https://avatars.githubusercontent.com/u/37784886'],
          redirect: Redirect(
            native: 'moprowallet://',
            universal: 'https://mopro.org/moprowallet',
            linkMode: true, // Enable link mode for better mobile UX
          ),
        ),
        requiredNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:1', 'eip155:137'], // Ethereum and Polygon
            methods: [
              'eth_sendTransaction',
              'eth_signTransaction',
              'eth_sign',
              'personal_sign',
              'eth_signTypedData',
            ],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      // Wait for initialization with timeout
      await appKitModal.init().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout - please check your internet connection and try again');
        },
      );

      if (mounted) {
        setState(() {
          _appKitModal = appKitModal;
          isInitializing = false;
        });
        
        // Initialize deep link handler for wallet responses
        print('[MoproWallet] Initializing deep link handler...');
        DeepLinkHandler.init(_appKitModal!);
        
        // Open the modal after initialization
        print('[MoproWallet] Opening modal view...');
        _appKitModal!.openModalView();
      }
    } catch (e) {
      print('[MoproWallet] Error during initialization: $e');
      if (mounted) {
        setState(() {
          _error = Exception('Failed to initialize AppKit: $e');
          isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (BuildContext materialContext) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Mopro Wallet Connect'),
              actions: [
                // Wallet Connect button in upper right
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _appKitModal == null
                      ? ElevatedButton.icon(
                          onPressed: isInitializing ? null : () async {
                            await _ensureAppKitInitialized(materialContext);
                          },
                          icon: isInitializing 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.account_balance_wallet),
                          label: Text(isInitializing ? 'Connecting...' : 'Connect Wallet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInitializing ? Colors.grey : Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        )
                      : AppKitModalConnectButton(
                          appKit: _appKitModal!,
                          custom: ElevatedButton.icon(
                            onPressed: () {
                              _appKitModal!.openModalView();
                            },
                            icon: const Icon(Icons.account_balance_wallet),
                            label: const Text('Connect Wallet'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Wallet connection status
                    if (_appKitModal != null)
                      AppKitModalAccountButton(appKitModal: _appKitModal!),
                    const SizedBox(height: 20),
                  
                    const Text(
                      'Noir Zero-Knowledge Proof',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isProving) const CircularProgressIndicator(),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            _error.toString(),
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: _controllerNoirA,
                        decoration: const InputDecoration(
                          labelText: "Public input `a`",
                          hintText: "For example, 3",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: _controllerNoirB,
                        decoration: const InputDecoration(
                          labelText: "Public input `b`",
                          hintText: "For example, 5",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: (_controllerNoirA.text.isEmpty || 
                                          _controllerNoirB.text.isEmpty || 
                                          isProving) ? null : () async {
                                setState(() {
                                  _error = null;
                                  isProving = true;
                                });

                                FocusManager.instance.primaryFocus?.unfocus();
                                Uint8List? noirProofResult;
                                try {
                                  var inputs = [
                                    _controllerNoirA.text,
                                    _controllerNoirB.text
                                  ];
                                  noirProofResult =
                                      await _moproFlutterPlugin.generateNoirProof(
                                          "assets/noir_multiplier2.json",
                                          null,
                                          inputs);
                                } on Exception catch (e) {
                                  print("Error: $e");
                                  noirProofResult = null;
                                  setState(() {
                                    _error = e;
                                  });
                                }

                                if (!mounted) return;

                                setState(() {
                                  isProving = false;
                                  _noirProofResult = noirProofResult;
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text("Generate Proof"),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: (_controllerNoirA.text.isEmpty || 
                                          _controllerNoirB.text.isEmpty || 
                                          isProving ||
                                          _noirProofResult == null) ? null : () async {
                                setState(() {
                                  _error = null;
                                  isProving = true;
                                });

                                FocusManager.instance.primaryFocus?.unfocus();
                                bool? valid;
                                try {
                                  var proofResult = _noirProofResult;
                                  valid = await _moproFlutterPlugin.verifyNoirProof(
                                      "assets/noir_multiplier2.json",
                                      proofResult!);
                                } on Exception catch (e) {
                                  print("Error: $e");
                                  valid = false;
                                  setState(() {
                                    _error = e;
                                  });
                                } on TypeError catch (e) {
                                  print("Error: $e");
                                  valid = false;
                                  setState(() {
                                    _error = Exception(e.toString());
                                  });
                                }

                                if (!mounted) return;

                                setState(() {
                                  _noirValid = valid;
                                  isProving = false;
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text("Verify Proof"),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_noirProofResult != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Proof Results:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Proof is valid: ${_noirValid ?? "Not verified"}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Proof:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                _noirProofResult.toString(),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}
