import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class TerminalPage extends StatefulWidget {
  final BluetoothConnection? connection;
  final BluetoothDevice? device;
  
  const TerminalPage({
    super.key,
    
    this.connection,
    this.device,
  });

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  BluetoothConnection? connection;
  BluetoothDevice? selectedDevice;
  bool isConnected = false;

  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _terminalOutput = [];

  @override
  void initState() {
    super.initState();
    connection = widget.connection;
    selectedDevice = widget.device;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lockPortraitOrientation();
      _validateConnectionAndSetup();
    });
  }

  void _validateConnectionAndSetup() {
    if (connection == null || selectedDevice == null) {
      _addToTerminal("Error: No connection or device provided");
      _showNoConnectionDialog();
      return;
    }
    
    // Check if connection is actually connected
    if (connection!.isConnected) {
      setState(() {
        isConnected = true;
      });
      _setupConnectionListener();
      _addToTerminal("Terminal ready. Connected to ${selectedDevice!.name ?? 'Unknown Device'}");
    } else {
      _addToTerminal("Error: Connection is not active");
      _showConnectionErrorDialog();
    }
  }

  void _lockPortraitOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _setupConnectionListener() {
    if (connection?.input == null) {
      _addToTerminal("Error: Connection input stream is null");
      setState(() {
        isConnected = false;
      });
      return;
    }

    // Listen for incoming data
    connection!.input!.listen(
      (Uint8List data) {
        String received = String.fromCharCodes(data);
        _addToTerminal("<<< $received");
      },
      onError: (error) {
        _addToTerminal("Connection error: $error");
        setState(() {
          isConnected = false;
        });
      },
      onDone: () {
        _addToTerminal("Connection closed");
        setState(() {
          isConnected = false;
        });
        _showConnectionLostDialog();
      },
    );
  }

  void _addToTerminal(String text) {
    setState(() {
      _terminalOutput
          .add("${DateTime.now().toString().substring(11, 19)} $text");
    });
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _disconnect() async {
    if (connection == null) {
      _addToTerminal("No connection to disconnect");
      return;
    }

    try {
      await connection!.close();
      setState(() {
        isConnected = false;
      });
      _addToTerminal("Disconnected");
      // Navigate back to previous screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _addToTerminal("Error disconnecting: $e");
    }
  }

  void _sendCommand(String command) {
    if (connection == null) {
      _addToTerminal("No connection available. Cannot send command.");
      return;
    }

    if (!isConnected) {
      _addToTerminal("Connection lost. Cannot send command.");
      return;
    }

    if (command.trim().isEmpty) return;

    try {
      connection!.output.add(Uint8List.fromList(utf8.encode('$command\n')));
      _addToTerminal(">>> $command");
      _commandController.clear();
    } catch (e) {
      _addToTerminal("Error sending command: $e");
      setState(() {
        isConnected = false;
      });
    }
  }

  void _clearTerminal() {
    setState(() {
      _terminalOutput.clear();
    });
  }

  void _showNoConnectionDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('No Connection', style: TextStyle(color: Colors.red)),
          content: const Text(
            'No Bluetooth connection or device was provided. Please establish a connection first.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _showConnectionErrorDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Connection Error', style: TextStyle(color: Colors.red)),
          content: const Text(
            'The provided Bluetooth connection is not active. Please reconnect and try again.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _showConnectionLostDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Connection Lost', style: TextStyle(color: Colors.red)),
          content: Text(
            'Connection to ${selectedDevice?.name ?? 'Unknown Device'} has been lost.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Don't close the connection here as it might be managed by parent
    // Just dispose controllers
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Bluetooth Terminal', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: isConnected ? Colors.blue : Colors.red,
              ),
              onPressed: isConnected ? _disconnect : null,
              tooltip: isConnected ? 'Disconnect' : 'Disconnected',
            ),
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.orange),
              onPressed: _clearTerminal,
              tooltip: 'Clear',
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B132B), Color(0xFF090F24)],
              stops: [0.2, 1.0],
            ),
          ),
          child: Column(
            children: [
              // Status Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                color: Colors.grey[900],
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.circle : Icons.circle_outlined,
                      color: isConnected ? Colors.blue : Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected
                          ? 'Connected: ${selectedDevice?.name ?? 'Unknown'}'
                          : connection == null 
                              ? 'No Connection' 
                              : 'Connection Lost',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      selectedDevice?.address ?? 'No Address',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Terminal Output
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _terminalOutput.length,
                    itemBuilder: (context, index) {
                      final line = _terminalOutput[index];
                      Color textColor = Colors.blue;

                      if (line.contains('>>>')) {
                        textColor = Colors.cyan;
                      } else if (line.contains('<<<')) {
                        textColor = Colors.yellow;
                      } else if (line.contains('Error') ||
                          line.contains('Failed') ||
                          line.contains('Connection Lost') ||
                          line.contains('No connection')) {
                        textColor = Colors.red;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.0),
                        child: Text(
                          line,
                          style: TextStyle(
                            color: textColor,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Command Input
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border(top: BorderSide(color: Colors.grey[700]!)),
                ),
                child: Row(
                  children: [
                    Text(
                      '\$ ',
                      style: const TextStyle(
                          color: Colors.blue, fontFamily: 'monospace'),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _commandController,
                        style: const TextStyle(
                            color: Colors.white, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: connection == null 
                              ? 'No connection available...'
                              : isConnected 
                                  ? 'Enter command...' 
                                  : 'Connection lost...',
                          hintStyle: TextStyle(
                            color: connection == null || !isConnected 
                                ? Colors.red[300] 
                                : Colors.grey,
                          ),
                        ),
                        onSubmitted: _sendCommand,
                        enabled: connection != null && isConnected,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: connection != null && isConnected 
                            ? Colors.blue 
                            : Colors.grey,
                      ),
                      onPressed: connection != null && isConnected
                          ? () => _sendCommand(_commandController.text)
                          : null,
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
}