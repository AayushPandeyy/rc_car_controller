import 'package:bluetooth_rc_controller/CarControllerPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

class BluetoothDevicesScreen extends StatefulWidget {
  const BluetoothDevicesScreen({super.key});

  @override
  _BluetoothDevicesScreenState createState() => _BluetoothDevicesScreenState();
}

class _BluetoothDevicesScreenState extends State<BluetoothDevicesScreen> {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDiscoveryResult> _deviceResults = [];
  Set<String> _discoveredAddresses = {};
  bool _isDiscovering = false;
  BluetoothConnection? _connection;
  String _connectionStatus = 'Disconnected';
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStreamSubscription;
  StreamSubscription<Uint8List>? _dataStreamSubscription;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lockPortraitOrientation();
    });
  }

  void _lockPortraitOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _discoveryStreamSubscription?.cancel();

    _dataStreamSubscription?.cancel();

    super.dispose();
  }

  Future<void> _checkBluetoothState() async {
    try {
      BluetoothState state = await _bluetooth.state;

      if (state == BluetoothState.STATE_OFF) {
        await _bluetooth.requestEnable();
        state = await _bluetooth.state;

        if (state != BluetoothState.STATE_ON) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Bluetooth must be enabled to proceed')),
            );
          }
          return;
        }
      }

      
      bool? isAllowed = await _bluetooth.requestEnable();
      if (isAllowed != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bluetooth permissions are required')),
          );
        }
        return;
      }

      _startDiscovery();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking Bluetooth state: $e')),
        );
      }
    }
  }

  void _startDiscovery() async {
    if (_isDiscovering) {
      
      await _cancelDiscovery();
    }

    setState(() {
      _isDiscovering = true;
      _deviceResults = [];
      _discoveredAddresses = {};
    });

    try {
      _discoveryStreamSubscription = _bluetooth.startDiscovery().listen((r) {
        
        if (!_discoveredAddresses.contains(r.device.address)) {
          setState(() {
            _deviceResults.add(r);
            _discoveredAddresses.add(r.device.address);
          });
        }
      });

      _discoveryStreamSubscription?.onDone(() {
        setState(() {
          _isDiscovering = false;
        });
      });

      _discoveryStreamSubscription?.onError((e) {
        setState(() {
          _isDiscovering = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Discovery error: $e')),
          );
        }
      });

      
      Timer(const Duration(seconds: 30), () {
        _cancelDiscovery();
      });
    } catch (e) {
      setState(() {
        _isDiscovering = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during discovery: $e')),
        );
      }
    }
  }

  Future<void> _cancelDiscovery() async {
    if (_isDiscovering) {
      await _discoveryStreamSubscription?.cancel();
      await _bluetooth.cancelDiscovery();

      if (mounted) {
        setState(() {
          _isDiscovering = false;
        });
      }
    }
  }




  Future<void> _connectToBluetoothDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });

    try {
      
      await Future.delayed(Duration(seconds: 1));

      final BluetoothConnection connection =
          await BluetoothConnection.toAddress(
        device.address,
      );

      setState(() {
        _connection = connection;
        _connectionStatus = 'Connected to ${device.name}';
      });

      print("Connected to ${device.name}");

      
      connection.input?.listen((Uint8List data) {
        print('Data incoming: ${ascii.decode(data)}');
      }, onDone: () {
        print('Disconnected by remote device');
        
        
      });

      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CarControllerPage(
            connection: connection,
            device: device, 
          ),
        ),
      );
    } catch (e) {
      print("Error connecting to device: $e");
      setState(() {
        _connectionStatus = 'Failed to connect';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      }
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Serial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                (_isDiscovering || _isConnecting) ? null : _startDiscovery,
            tooltip: 'Refresh Devices',
          ),
        ],
      ),
      body: Column(
        children: [
          
          Expanded(
            child: _buildDeviceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return Column(
      children: [
        Expanded(
          child: _deviceResults.isEmpty
              ? Center(
                  child: _isDiscovering
                      ? const CircularProgressIndicator()
                      : const Text('No devices found'),
                )
              : ListView.builder(
                  itemCount: _deviceResults.length,
                  itemBuilder: (context, index) {
                    BluetoothDiscoveryResult result = _deviceResults[index];
                    BluetoothDevice device = result.device;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(device.isBonded
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth),
                            Text('${result.rssi} dBm',
                                style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                        title: Text(device.name ?? 'Unknown Device'),
                        subtitle: Text(device.address),
                        trailing: ElevatedButton(
                          onPressed: _isConnecting
                              ? null
                              : () => _connectToBluetoothDevice(device),
                          child: _isConnecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Connect'),
                        ),
                        onTap: _isConnecting
                            ? null
                            : () => _connectToBluetoothDevice(device),
                      ),
                    );
                  },
                ),
        ),
        if (_isDiscovering)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Scanning for devices...'),
              ],
            ),
          ),
      ],
    );
  }
}
