import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceControlPage extends StatefulWidget {
  final BluetoothConnection? connection;
  final BluetoothDevice? device;

  const VoiceControlPage({
    super.key,
    this.connection,
    this.device,
  });

  @override
  State<VoiceControlPage> createState() => _VoiceControlPageState();
}

class _VoiceControlPageState extends State<VoiceControlPage> {
  BluetoothConnection? connection;
  BluetoothDevice? selectedDevice;
  bool isConnected = false;
  String _spokenText = '';
  bool _isListening = false;

  final List<String> _outputLog = [];
  final ScrollController _scrollController = ScrollController();
  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    connection = widget.connection;
    selectedDevice = widget.device;
    _speech = stt.SpeechToText();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lockPortraitOrientation();
      _validateConnectionAndSetup();
    });
  }

    void _lockPortraitOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _validateConnectionAndSetup() {
    if (connection == null || selectedDevice == null) {
      _logToScreen("Error: No connection or device provided");
      return;
    }

    if (connection!.isConnected) {
      setState(() => isConnected = true);
      _setupConnectionListener();
      _logToScreen("Voice Terminal ready. Connected to ${selectedDevice!.name}");
    } else {
      _logToScreen("Error: Connection is not active");
    }
  }

  void _setupConnectionListener() {
    connection!.input?.listen(
      (Uint8List data) {
        final String received = String.fromCharCodes(data);
        _logToScreen("<<< $received");
      },
      onDone: () {
        _logToScreen("Connection closed");
        setState(() => isConnected = false);
      },
      onError: (error) {
        _logToScreen("Connection error: $error");
        setState(() => isConnected = false);
      },
    );
  }

  void _logToScreen(String text) {
    setState(() {
      _outputLog.add("${DateTime.now().toString().substring(11, 19)} $text");
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTextOverBluetooth(String text) {
    if (text.trim().isEmpty || connection == null || !isConnected) return;
    connection!.output.add(Uint8List.fromList(utf8.encode('$text\n')));
    _logToScreen(">>> $text");
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => _logToScreen("Speech error: ${error.errorMsg}"),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _spokenText = result.recognizedWords;
          });
          if (result.finalResult) {
            _sendTextOverBluetooth(_spokenText);
            _speech.stop();
            setState(() => _isListening = false);
          }
        },
      );
    } else {
      _logToScreen("Speech recognition not available.");
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _clearLog() {
    setState(() {
      _outputLog.clear();
      _spokenText = '';
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Voice Control", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: isConnected ? Colors.blue : Colors.red,
            ),
            onPressed: null,
            tooltip: isConnected ? 'Connected' : 'Disconnected',
          ),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.orange),
            onPressed: _clearLog,
            tooltip: 'Clear Log',
          ),
        ],
      ),
      body: Column(
        children: [
          // Output Log
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _outputLog.length,
                itemBuilder: (context, index) {
                  final line = _outputLog[index];
                  Color color = Colors.white;

                  if (line.contains('>>>')) {
                    color = Colors.cyan;
                  } else if (line.contains('<<<')) {
                    color = Colors.yellow;
                  } else if (line.contains('Error') || line.contains('Connection')) {
                    color = Colors.red;
                  }

                  return Text(line, style: TextStyle(color: color, fontFamily: 'monospace'));
                },
              ),
            ),
          ),

          // Recognized Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: double.infinity,
            color: Colors.grey[900],
            child: Text(
              'You said: $_spokenText',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
            ),
          ),

          // Microphone Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: FloatingActionButton.extended(
              backgroundColor: _isListening ? Colors.red : Colors.blue,
              icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
              label: Text(_isListening ? "Stop Listening" : "Start Voice Command"),
              onPressed: _isListening ? _stopListening : _startListening,
            ),
          ),
        ],
      ),
    );
  }
}
