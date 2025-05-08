import 'dart:typed_data';
import 'dart:ui';
import 'dart:async';

import 'package:bluetooth_rc_controller/BluetoothDevicesScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class HomePage extends StatefulWidget {
  final BluetoothConnection? connection;
  final BluetoothDevice? device;

  const HomePage({
    super.key,
    required this.connection,
    this.device,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothDevice? _connectedDevice;
  BluetoothConnection? _connection;
  bool isConnected = false;

  Timer? _connectionCheckTimer;

  String currentDirection = "NONE";

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();

    _connection = widget.connection;

    if (widget.device != null) {
      _connectedDevice = widget.device;
      print("Connected to device: ${widget.device!.name}");
    }

    isConnected = _connection != null && _connection!.isConnected;

    if (isConnected && _connectedDevice == null) {
      _checkConnectedDevice();
    }

    _startConnectionCheckTimer();
  }

  void _startConnectionCheckTimer() {
    _connectionCheckTimer?.cancel();

    _connectionCheckTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _checkConnectionStatus();
    });
  }

  void _checkConnectionStatus() {
    if (!mounted) return;

    if (_connection != null) {
      bool isStillConnected = _connection!.isConnected;

      if (isConnected != isStillConnected) {
        setState(() {
          isConnected = isStillConnected;
        });

        if (!isStillConnected) {
          print('Connection lost');
        }
      }
    } else if (isConnected) {
      setState(() {
        isConnected = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _connectionCheckTimer?.cancel();

    super.dispose();
  }

  Future<void> _checkConnectedDevice() async {
    try {
      List<BluetoothDevice> bondedDevices = await _bluetooth.getBondedDevices();

      if (bondedDevices.isNotEmpty) {
        for (var device in bondedDevices) {
          if (device.isConnected) {
            print("Connected to: ${device.name}");
            if (mounted) {
              setState(() {
                _connectedDevice = device;
                isConnected = true;
              });
            }
            break;
          }
        }
      }
    } catch (e) {
      print('Error checking connected device: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      if (_connection != null) {
        await _connection!.close();
        _connection = null;
      }

      print('Connecting to ${device.name}...');
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);

      print('Connected to ${device.name}');

      if (mounted) {
        setState(() {
          _connection = connection;
          _connectedDevice = device;
          isConnected = true;
        });
      }

      _startConnectionCheckTimer();

      _sendDirection(currentDirection);
    } catch (e) {
      print('Error connecting to device: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to connect to ${device.name}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectDevice() async {
    try {
      if (_connection != null) {
        await _connection!.finish();
        print('Disconnected from device');
      }

      if (mounted) {
        setState(() {
          _connection = null;
          isConnected = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device disconnected successfully'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Error disconnecting from device: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disconnecting: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendDirection(String direction) async {
    if (!isConnected || _connection == null) return;

    try {
      Uint8List bytes;
      switch (direction) {
        case "UP":
          bytes = Uint8List.fromList([70]);
          break;
        case "DOWN":
          bytes = Uint8List.fromList([66]);
          break;
        case "LEFT":
          bytes = Uint8List.fromList([76]);
          break;
        case "RIGHT":
          bytes = Uint8List.fromList([82]);
          break;
        case "UP-LEFT":
          bytes = Uint8List.fromList([71]);
          break;
        case "UP-RIGHT":
          bytes = Uint8List.fromList([73]);
          break;
        case "DOWN-LEFT":
          bytes = Uint8List.fromList([72]);
          break;
        case "DOWN-RIGHT":
          bytes = Uint8List.fromList([74]);
          break;
        case "STOP":
        default:
          bytes = Uint8List.fromList([83]);
          break;
      }

      _connection!.output.add(bytes);
      await _connection!.output.allSent;
      print('Sent command: $direction');
    } catch (e) {
      print('Error sending direction: $e');

      _checkConnectionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E2A), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildStatusBar(),
              Expanded(
                child: _buildCarDisplay(),
              ),
              _buildControlPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: isConnected ? Colors.blue : Colors.grey,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                isConnected ? "Connected" : "Disconnected",
                style: TextStyle(
                  fontSize: 12,
                  color: isConnected ? Colors.blue : Colors.grey,
                ),
              ),
            ],
          ),
          Text(
            "RC Master",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildCarDisplay() {
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 280,
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.directions_car,
                  size: 80,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isConnected
                        ? Colors.blue.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isConnected)
                      Icon(
                        Icons.bluetooth_connected,
                        size: 16,
                        color: Colors.blue,
                      ),
                    if (isConnected) SizedBox(width: 8),
                    Text(
                      isConnected && _connectedDevice != null
                          ? _connectedDevice!.name ?? 'Unknown Device'
                          : "No Device Connected",
                      style: TextStyle(
                        color: isConnected ? Colors.white : Colors.grey[400],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (isConnected && _connectedDevice != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          "(${_connectedDevice!.address})",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Direction: $currentDirection",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 1),
        end: Offset.zero,
      ).animate(_animation),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 30),
        decoration: BoxDecoration(
          color: Color(0xFF1E1E2A).withOpacity(0.8),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Control Panel",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 24),
            _buildDirectionButtons(),
            SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    Icons.bluetooth,
                    isConnected ? "CHANGE DEVICE" : "PAIR DEVICE",
                    Colors.blue[400]!,
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    onTap: () async {
                      final BluetoothDevice? selectedDevice =
                          await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BluetoothDevicesScreen(),
                        ),
                      );

                      if (selectedDevice != null) {
                        await _connectToDevice(selectedDevice);
                      }
                    },
                  ),
                  SizedBox(width: 16),
                  if (isConnected)
                    _buildActionButton(
                      Icons.bluetooth_disabled,
                      "DISCONNECT",
                      Colors.red[400]!,
                      backgroundColor: Colors.red.withOpacity(0.2),
                      onTap: () {
                        _disconnectDevice();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionButtons() {
    return Column(
      children: [
        Text(
          "DIRECTION",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDirectionButton(
              Icons.keyboard_arrow_up,
              "UP",
              Alignment.topCenter,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDirectionButton(
              Icons.keyboard_arrow_left,
              "LEFT",
              Alignment.centerLeft,
            ),
            SizedBox(
              height: 80,
              width: 80,
            ),
            _buildDirectionButton(
              Icons.keyboard_arrow_right,
              "RIGHT",
              Alignment.centerRight,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDirectionButton(
              Icons.keyboard_arrow_down,
              "DOWN",
              Alignment.bottomCenter,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDirectionButton(
      IconData icon, String direction, Alignment alignment) {
    bool isActive = currentDirection == direction;

    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          currentDirection = direction;
        });

        _sendDirection(direction);
      },
      onTapUp: (details) {
        setState(() {
          currentDirection = "";
        });

        _sendDirection("STOP");
      },
      onTapCancel: () {
        setState(() {
          currentDirection = "";
        });

        _sendDirection("STOP");
      },
      child: Container(
        margin: EdgeInsets.all(4),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.blue.withOpacity(0.6)
              : Colors.grey[850]!.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[400],
          size: 28,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color iconColor, {
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
