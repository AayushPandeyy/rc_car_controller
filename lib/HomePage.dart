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
      duration: Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuint,
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
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.fromLTRB(15, 5, 15, 15),
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
            backgroundColor: Color(0xFF1E88E5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.fromLTRB(15, 5, 15, 15),
          ),
        );
      }
    } catch (e) {
      print('Error disconnecting from device: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disconnecting: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.fromLTRB(15, 5, 15, 15),
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
            colors: [Color(0xFF0B132B), Color(0xFF090F24)],
            stops: [0.2, 1.0],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
      ),
    );
  }

  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isConnected
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: isConnected ? Colors.blue[300] : Colors.grey[400],
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  isConnected ? "Connected" : "Disconnected",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isConnected ? Colors.blue[300] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Text(
            "RC MASTER",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildCarDisplay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background animated circles
        ...List.generate(3, (index) {
          return Positioned(
            top: 100 + (index * 30),
            left: 0,
            right: 0,
            child: Center(
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(seconds: 8),
                curve: Curves.easeInOut,
                builder: (_, double value, __) {
                  return Container(
                    width: 150 + (index * 100),
                    height: 150 + (index * 100),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isConnected
                            ? Colors.blue.withOpacity(0.1 - (index * 0.02))
                            : Colors.grey.withOpacity(0.1 - (index * 0.02)),
                        width: 1,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
        
        // Glow effect
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isConnected
                    ? [
                        Colors.blue.withOpacity(0.15),
                        Colors.transparent,
                      ]
                    : [
                        Colors.grey.withOpacity(0.1),
                        Colors.transparent,
                      ],
                stops: [0.4, 1.0],
              ),
            ),
          ),
        ),

        // Car display
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Car container with shadow
              Container(
                width: 280,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF232842),
                      Color(0xFF1A1E33),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: CustomPaint(
                          painter: GridPainter(),
                        ),
                      ),
                    ),
                    
                    // Car icon with glow
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[850]?.withOpacity(0.8),
                        boxShadow: isConnected
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                      child: Icon(
                        Icons.directions_car,
                        size: 70,
                        color: isConnected ? Colors.blue[300] : Colors.grey[500],
                      ),
                    ),
                    
                    // Movement indicator
                    if (currentDirection != "" && currentDirection != "NONE")
                      Positioned(
                        top: currentDirection.contains("UP") ? 20 : null,
                        bottom: currentDirection.contains("DOWN") ? 20 : null,
                        left: currentDirection.contains("LEFT") ? 20 : null,
                        right: currentDirection.contains("RIGHT") ? 20 : null,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue[400],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Device info
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.blue.withOpacity(0.12)
                      : Colors.grey[800]!.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isConnected
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: isConnected
                      ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isConnected)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.2),
                        ),
                        child: Icon(
                          Icons.bluetooth_connected,
                          size: 14,
                          color: Colors.blue[300],
                        ),
                      ),
                    if (isConnected) SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                          Text(
                            "${_connectedDevice!.address}",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Direction indicator
        AnimatedPositioned(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedOpacity(
              opacity: currentDirection == "" || currentDirection == "NONE" ? 0 : 1,
              duration: Duration(milliseconds: 200),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.7),
                      Colors.blue.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getDirectionIcon(),
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      currentDirection,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getDirectionIcon() {
    switch (currentDirection) {
      case "UP":
        return Icons.arrow_upward;
      case "DOWN":
        return Icons.arrow_downward;
      case "LEFT":
        return Icons.arrow_back;
      case "RIGHT":
        return Icons.arrow_forward;
      case "UP-LEFT":
        return Icons.arrow_back_ios;
      case "UP-RIGHT":
        return Icons.arrow_forward_ios;
      case "DOWN-LEFT":
        return Icons.arrow_back_ios;
      case "DOWN-RIGHT":
        return Icons.arrow_forward_ios;
      default:
        return Icons.stop;
    }
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1D2340), Color(0xFF151A30)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 50,
              height: 4,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Control panel header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? Colors.blue : Colors.grey,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "CONTROL PANEL",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            _buildDirectionButtons(),
            SizedBox(height: 24),
            
            // Action buttons
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    Icons.bluetooth,
                    isConnected ? "CHANGE DEVICE" : "PAIR DEVICE",
                    Colors.blue[400]!,
                    backgroundColor: Colors.blue.withOpacity(0.15),
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
                      backgroundColor: Colors.red.withOpacity(0.15),
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
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[850]?.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "DIRECTION",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDirectionButton(
              "UP-LEFT",
              Alignment.topLeft,
              Icons.north_west,
            ),
            _buildDirectionButton(
              "UP",
              Alignment.topCenter,
              Icons.keyboard_arrow_up,
            ),
            _buildDirectionButton(
              "UP-RIGHT",
              Alignment.topRight,
              Icons.north_east,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDirectionButton(
              "LEFT",
              Alignment.centerLeft,
              Icons.keyboard_arrow_left,
            ),
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.grey[900]?.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.gps_fixed,
                color: Colors.grey[600],
                size: 22,
              ),
            ),
            _buildDirectionButton(
              "RIGHT",
              Alignment.centerRight,
              Icons.keyboard_arrow_right,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDirectionButton(
              "DOWN-LEFT",
              Alignment.bottomLeft,
              Icons.south_west,
            ),
            _buildDirectionButton(
              "DOWN",
              Alignment.bottomCenter,
              Icons.keyboard_arrow_down,
            ),
            _buildDirectionButton(
              "DOWN-RIGHT",
              Alignment.bottomRight,
              Icons.south_east,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDirectionButton(
      String direction, Alignment alignment, IconData icon) {
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
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withOpacity(0.8),
                    Colors.blue.withOpacity(0.6),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[850]!.withOpacity(0.8),
                    Colors.grey[900]!.withOpacity(0.8),
                  ],
                ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.35),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    spreadRadius: 0,
                    offset: Offset(0, 2),
                  )
                ],
          border: Border.all(
            color: isActive
                ? Colors.blue.withOpacity(0.6)
                : Colors.grey[700]!.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[400],
          size: 30,
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
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.grey[850],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: iconColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[300],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Grid painter for background pattern
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    for (int i = 0; i < size.height; i += 10) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }

    // Draw vertical lines
    for (int i = 0; i < size.width; i += 10) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}