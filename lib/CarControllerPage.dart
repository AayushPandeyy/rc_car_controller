import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:async';

import 'package:bluetooth_rc_controller/BluetoothDevicesScreen.dart';
import 'package:bluetooth_rc_controller/JoyStickController.dart';
import 'package:bluetooth_rc_controller/TerminalPage.dart';
import 'package:bluetooth_rc_controller/UserManualPage.dart';
import 'package:bluetooth_rc_controller/VoiceControlPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class CarControllerPage extends StatefulWidget {
  final BluetoothConnection? connection;
  final BluetoothDevice? device;

  const CarControllerPage({
    super.key,
    required this.connection,
    this.device,
  });

  @override
  _CarControllerPageState createState() => _CarControllerPageState();
}

class _CarControllerPageState extends State<CarControllerPage>
    with SingleTickerProviderStateMixin {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothDevice? _connectedDevice;
  BluetoothConnection? _connection;
  bool isConnected = false;
  double _x = 0.0;
  double _y = 0.0;

  Timer? _connectionCheckTimer;

  String currentDirection = "NONE";

  double carSpeed = 50.0;
  bool headlightsOn = false;
  bool isHornPressed = false;
  bool emergencyOn = false;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Set initial orientation to landscape
    _setLandscapeOrientation();

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

  void _setLandscapeOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _connectionCheckTimer?.cancel();

    // Allow all orientations again
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  void _sendJoystickData(double x, double y) {
    if (_connection != null && _connection!.isConnected) {
      // Convert joystick values to appropriate format
      // You can customize this based on your device's expected format

      // Option 1: Send as JSON
      Map<String, dynamic> data = {
        'x': (x * 100).round(), // Scale to -100 to 100
        'y': (y * 100).round(),
        'timestamp': DateTime.now().millisecondsSinceEpoch
      };
      String jsonData = '${json.encode(data)}\n';

      try {
        _connection!.output.add(Uint8List.fromList(jsonData.codeUnits));
        _connection!.output.allSent;
      } catch (e) {
        print('Error sending data: $e');
      }
    }
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

  Future<void> _sendSpeedCommand(double speed) async {
    if (!isConnected || _connection == null) return;

    try {
      int speedByte = (speed * 2.55).round();
      Uint8List bytes = Uint8List.fromList([87, speedByte]);

      _connection!.output.add(bytes);
      await _connection!.output.allSent;
      print('Sent speed command: $speed%');
    } catch (e) {
      print('Error sending speed: $e');
    }
  }

  Future<void> _sendHeadlightCommand(bool isOn) async {
    if (!isConnected || _connection == null) return;

    try {
      Uint8List bytes = Uint8List.fromList([isOn ? 72 : 104]);

      _connection!.output.add(bytes);
      await _connection!.output.allSent;
      print('Sent headlight command: ${isOn ? "ON" : "OFF"}');
    } catch (e) {
      print('Error sending headlight command: $e');
    }
  }

  Future<void> _sendHornCommand(bool isPressed) async {
    if (!isConnected || _connection == null) return;

    try {
      Uint8List bytes = Uint8List.fromList([isPressed ? 79 : 111]);

      _connection!.output.add(bytes);
      await _connection!.output.allSent;
      print('Sent horn command: ${isPressed ? "ON" : "OFF"}');
    } catch (e) {
      print('Error sending horn command: $e');
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                height: constraints.maxHeight * 0.3,
                                child: _buildCarControls(),
                              ),
                              SizedBox(
                                height: constraints.maxHeight * 0.7,
                                child: _buildControlPanel(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isConnected
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isConnected
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color: isConnected ? Colors.blue[300] : Colors.grey[400],
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      isConnected ? "Connected" : "Disconnected",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color:
                            isConnected ? Colors.blue[300] : Colors.grey[400],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Text(
              "RC MASTER",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
              flex: 1,
              child: IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UserManualPage()));
                  },
                  icon: Icon(Icons.info))),
        ],
      ),
    );
  }

  Widget _buildCarControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Speed section - made more compact
                Row(
                  children: [
                    Icon(
                      Icons.speed,
                      color: Colors.blue[300],
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "SPEED",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 6),
                    Container(
                      width: 40,
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${carSpeed.round()}%",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[300],
                        ),
                      ),
                    ),
                  ],
                ),

                // Speed slider - fixed width
                SizedBox(
                  width: 150,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blue[400],
                      inactiveTrackColor: Colors.grey[700],
                      thumbColor: Colors.blue[300],
                      overlayColor: Colors.blue.withOpacity(0.2),
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
                      trackHeight: 5,
                    ),
                    child: Slider(
                      value: carSpeed,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: (value) {
                        setState(() {
                          carSpeed = value;
                        });
                        _sendSpeedCommand(value);
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8),

                // Headlights button - compact
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          headlightsOn = !headlightsOn;
                        });
                        _sendHeadlightCommand(headlightsOn);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: headlightsOn
                              ? LinearGradient(
                                  colors: [
                                    Colors.yellow[600]!,
                                    Colors.yellow[400]!
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey[800]!,
                                    Colors.grey[700]!
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: headlightsOn
                              ? [
                                  BoxShadow(
                                    color: Colors.yellow.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              headlightsOn
                                  ? Icons.lightbulb
                                  : Icons.lightbulb_outline,
                              color: headlightsOn
                                  ? Colors.black
                                  : Colors.grey[400],
                              size: 18,
                            ),
                            SizedBox(height: 2),
                            Text(
                              "LIGHTS",
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: headlightsOn
                                    ? Colors.black
                                    : Colors.grey[400],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          emergencyOn = !emergencyOn;
                        });
                        _sendHeadlightCommand(emergencyOn);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: emergencyOn
                              ? LinearGradient(
                                  colors: [
                                    Colors.orange[600]!,
                                    Colors.orange[400]!
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey[800]!,
                                    Colors.grey[700]!
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: emergencyOn
                              ? [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              emergencyOn
                                  ? Icons.emergency
                                  : Icons.emergency_outlined,
                              color:
                                  emergencyOn ? Colors.black : Colors.grey[400],
                              size: 18,
                            ),
                            SizedBox(height: 2),
                            Text(
                              "EMERGENCY",
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: emergencyOn
                                    ? Colors.black
                                    : Colors.grey[400],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),

                    // Horn button - compact
                    GestureDetector(
                      onTapDown: (_) {
                        setState(() {
                          isHornPressed = true;
                        });
                        _sendHornCommand(true);
                      },
                      onTapUp: (_) {
                        setState(() {
                          isHornPressed = false;
                        });
                        _sendHornCommand(false);
                      },
                      onTapCancel: () {
                        setState(() {
                          isHornPressed = false;
                        });
                        _sendHornCommand(false);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: isHornPressed
                              ? LinearGradient(
                                  colors: [Colors.red[600]!, Colors.red[400]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey[800]!,
                                    Colors.grey[700]!
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isHornPressed
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.campaign,
                              color: isHornPressed
                                  ? Colors.white
                                  : Colors.grey[400],
                              size: 18,
                            ),
                            SizedBox(height: 2),
                            Text(
                              "HORN",
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: isHornPressed
                                    ? Colors.white
                                    : Colors.grey[400],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    _buildActionButton(
                      Icons.bluetooth,
                      isConnected ? "CHANGE" : "PAIR",
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
                    if (isConnected) ...[
                      SizedBox(width: 4),
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
                    SizedBox(width: 8),
                    _buildActionButton(
                      Icons.terminal,
                      "Terminal",
                      Colors.blue[400]!,
                      backgroundColor: Colors.blue.withOpacity(0.15),
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TerminalPage(
                                    connection: _connection,
                                    device: _connectedDevice,
                                  )),
                        ).then((_) {
                          // This runs after TerminalPage is popped (back button included)
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.landscapeLeft,
                            DeviceOrientation.landscapeRight,
                          ]);
                        });
                      },
                    ),
                    SizedBox(width: 8),
                    _buildActionButton(
                      Icons.voice_chat,
                      "Voice Control",
                      Colors.blue[400]!,
                      backgroundColor: Colors.blue.withOpacity(0.15),
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => VoiceControlPage(
                                    connection: _connection,
                                    device: _connectedDevice,
                                  )),
                        ).then((_) {
                          // This runs after TerminalPage is popped (back button included)
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.landscapeLeft,
                            DeviceOrientation.landscapeRight,
                          ]);
                        });
                      },
                    ),
                  ],
                )
              ],
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
    return Container(
      padding: EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1D2340), Color(0xFF151A30)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(-2, 0),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDirectionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          JoystickController(
            size: 200,
            baseColor: Colors.grey.shade600,
            knobColor: Colors.blue,
            onChanged: (x, y) {
              setState(() {
                _x = x;
                _y = y;
              });
              _sendJoystickData(_x, _y);
            },
          ),
          SizedBox(width: 12),
          // Left side - Forward/Backward buttons
          Column(
            children: [
              _buildLargeDirectionButton(
                "UP",
                Icons.keyboard_arrow_up,
                "FORWARD",
              ),
              SizedBox(height: 8),
              _buildLargeDirectionButton(
                "DOWN",
                Icons.keyboard_arrow_down,
                "BACKWARD",
              ),
            ],
          ),

          SizedBox(width: 24), // Reduced spacing

          // Center - Original direction pad
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDirectionButton(
                    "LEFT",
                    Alignment.centerLeft,
                    Icons.keyboard_arrow_left,
                  ),
                  Container(
                    margin: EdgeInsets.all(2),
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[900]?.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.gps_fixed,
                      color: Colors.grey[600],
                      size: 16,
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
                mainAxisSize: MainAxisSize.min,
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
          ),

          SizedBox(width: 24), // Reduced spacing

          // Right side - Left/Right buttons
          Column(
            children: [
              _buildLargeDirectionButton(
                "LEFT",
                Icons.keyboard_arrow_left,
                "LEFT",
              ),
              SizedBox(height: 8),
              _buildLargeDirectionButton(
                "RIGHT",
                Icons.keyboard_arrow_right,
                "RIGHT",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeDirectionButton(
      String direction, IconData icon, String label) {
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
        width: 95,
        height: 95,
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 3,
                    spreadRadius: 0,
                    offset: Offset(0, 1),
                  )
                ],
          border: Border.all(
            color: isActive
                ? Colors.blue.withOpacity(0.6)
                : Colors.grey[700]!.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[400],
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey[400],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
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
        margin: EdgeInsets.all(2),
        width: 60,
        height: 60,
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 3,
                    spreadRadius: 0,
                    offset: Offset(0, 1),
                  )
                ],
          border: Border.all(
            color: isActive
                ? Colors.blue.withOpacity(0.6)
                : Colors.grey[700]!.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[400],
          size: 20,
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
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.grey[850],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: iconColor.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[300],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < size.height; i += 10) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }

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
