import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserManualPage extends StatefulWidget {
  const UserManualPage({super.key});

  @override
  _UserManualPageState createState() => _UserManualPageState();
}

class _UserManualPageState extends State<UserManualPage> {
  String selectedCategory = 'Direction';

  final Map<String, List<CommandInfo>> commandCategories = {
    'Direction': [
      CommandInfo(
        action: 'Move Forward',
        button: 'UP button / Forward button',
        byteValue: '70',
        hexValue: '0x46',
        description: 'Moves the RC car forward',
        additionalInfo: 'Sent when UP button is pressed down',
      ),
      CommandInfo(
        action: 'Move Backward',
        button: 'DOWN button / Backward button',
        byteValue: '66',
        hexValue: '0x42',
        description: 'Moves the RC car backward',
        additionalInfo: 'Sent when DOWN button is pressed down',
      ),
      CommandInfo(
        action: 'Turn Left',
        button: 'LEFT button',
        byteValue: '76',
        hexValue: '0x4C',
        description: 'Turns the RC car left',
        additionalInfo: 'Sent when LEFT button is pressed down',
      ),
      CommandInfo(
        action: 'Turn Right',
        button: 'RIGHT button',
        byteValue: '82',
        hexValue: '0x52',
        description: 'Turns the RC car right',
        additionalInfo: 'Sent when RIGHT button is pressed down',
      ),
      CommandInfo(
        action: 'Move Forward-Left',
        button: 'UP-LEFT diagonal button',
        byteValue: '71',
        hexValue: '0x47',
        description: 'Moves the RC car forward while turning left',
        additionalInfo: 'Diagonal movement command',
      ),
      CommandInfo(
        action: 'Move Forward-Right',
        button: 'UP-RIGHT diagonal button',
        byteValue: '73',
        hexValue: '0x49',
        description: 'Moves the RC car forward while turning right',
        additionalInfo: 'Diagonal movement command',
      ),
      CommandInfo(
        action: 'Move Backward-Left',
        button: 'DOWN-LEFT diagonal button',
        byteValue: '72',
        hexValue: '0x48',
        description: 'Moves the RC car backward while turning left',
        additionalInfo: 'Diagonal movement command',
      ),
      CommandInfo(
        action: 'Move Backward-Right',
        button: 'DOWN-RIGHT diagonal button',
        byteValue: '74',
        hexValue: '0x4A',
        description: 'Moves the RC car backward while turning right',
        additionalInfo: 'Diagonal movement command',
      ),
      CommandInfo(
        action: 'Stop Movement',
        button: 'Released any direction button',
        byteValue: '83',
        hexValue: '0x53',
        description: 'Stops all movement of the RC car',
        additionalInfo: 'Sent when any direction button is released',
      ),
    ],
    'Speed Control': [
      CommandInfo(
        action: 'Set Speed',
        button: 'Speed slider',
        byteValue: '87 + [SPEED_BYTE]',
        hexValue: '0x57 + [SPEED_HEX]',
        description: 'Sets the motor speed of the RC car',
        additionalInfo:
            'Two-byte command: First byte (87) indicates speed command, second byte is speed value (0-255)',
        example: 'For 50% speed: [87, 128] or [0x57, 0x80]',
      ),
    ],
    'Lighting': [
      CommandInfo(
        action: 'Turn Headlights ON',
        button: 'LIGHTS button (when OFF)',
        byteValue: '72',
        hexValue: '0x48',
        description: 'Turns on the RC car headlights',
        additionalInfo: 'Same byte value as backward-left movement',
      ),
      CommandInfo(
        action: 'Turn Headlights OFF',
        button: 'LIGHTS button (when ON)',
        byteValue: '104',
        hexValue: '0x68',
        description: 'Turns off the RC car headlights',
        additionalInfo: 'Lowercase \'h\' ASCII value',
      ),
      CommandInfo(
        action: 'Emergency Lights ON',
        button: 'EMERGENCY button (when OFF)',
        byteValue: '72',
        hexValue: '0x48',
        description: 'Activates emergency/hazard lights',
        additionalInfo: 'Currently uses same command as headlights ON',
      ),
      CommandInfo(
        action: 'Emergency Lights OFF',
        button: 'EMERGENCY button (when ON)',
        byteValue: '104',
        hexValue: '0x68',
        description: 'Deactivates emergency/hazard lights',
        additionalInfo: 'Currently uses same command as headlights OFF',
      ),
    ],
    'Audio': [
      CommandInfo(
        action: 'Horn ON',
        button: 'HORN button (pressed)',
        byteValue: '79',
        hexValue: '0x4F',
        description: 'Activates the RC car horn/buzzer',
        additionalInfo: 'Uppercase \'O\' ASCII value',
      ),
      CommandInfo(
        action: 'Horn OFF',
        button: 'HORN button (released)',
        byteValue: '111',
        hexValue: '0x6F',
        description: 'Deactivates the RC car horn/buzzer',
        additionalInfo: 'Lowercase \'o\' ASCII value',
      ),
    ],
    'Joystick': [
      CommandInfo(
        action: 'Joystick Control',
        button: 'Analog joystick',
        byteValue: 'JSON Data',
        hexValue: 'Variable',
        description: 'Sends precise analog control data',
        additionalInfo:
            'Sends JSON: {"x": -100 to 100, "y": -100 to 100, "timestamp": [milliseconds]}',
        example: '{"x": 45, "y": -67, "timestamp": 1640995200000}',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B132B),
      appBar: AppBar(
        title: Text(
          'RC Controller - User Manual',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF1A1E33),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B132B), Color(0xFF090F24)],
            stops: [0.2, 1.0],
          ),
        ),
        child: Row(
          children: [
            // Sidebar
            Container(
              width: 200,
              decoration: BoxDecoration(
                color: Color(0xFF1A1E33).withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Command Categories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: commandCategories.keys.map((category) {
                        bool isSelected = selectedCategory == category;
                        return Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: Colors.blue.withOpacity(0.5))
                                : null,
                          ),
                          child: ListTile(
                            title: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.blue[300]
                                    : Colors.grey[300],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                            leading: Icon(
                              _getCategoryIcon(category),
                              color: isSelected
                                  ? Colors.blue[300]
                                  : Colors.grey[400],
                              size: 20,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF232842), Color(0xFF1A1E33)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(selectedCategory),
                            color: Colors.blue[300],
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            '$selectedCategory Commands',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${commandCategories[selectedCategory]!.length} Commands',
                              style: TextStyle(
                                color: Colors.blue[300],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Command list
                    Expanded(
                      child: ListView.builder(
                        itemCount: commandCategories[selectedCategory]!.length,
                        itemBuilder: (context, index) {
                          final command =
                              commandCategories[selectedCategory]![index];
                          return _buildCommandCard(command);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandCard(CommandInfo command) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF232842).withOpacity(0.9),
            Color(0xFF1A1E33).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.blue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: Colors.blue[300],
        collapsedIconColor: Colors.grey[400],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    command.action,
                    style: TextStyle(
                      color: Colors.blue[300],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    command.byteValue,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 12,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              command.button,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
              ),
            ),
          ],
        ),
        children: [
          Divider(color: Colors.grey.withOpacity(0.3)),
          SizedBox(height: 12),

          // Description
          _buildInfoRow('Description', command.description),

          // Byte values
          Row(
            children: [
              Expanded(
                child: _buildInfoRow('Decimal', command.byteValue),
              ),
              SizedBox(width: 20),
              Expanded(
                child: _buildInfoRow('Hexadecimal', command.hexValue),
              ),
            ],
          ),

          // Additional info
          if (command.additionalInfo.isNotEmpty)
            _buildInfoRow('Additional Info', command.additionalInfo),

          // Example
          if (command.example != null)
            _buildInfoRow('Example', command.example!, isCode: true),

          // Copy button
          SizedBox(height: 16),
          Row(
            children: [
              _buildCopyButton('Copy Decimal', command.byteValue),
              SizedBox(width: 12),
              _buildCopyButton('Copy Hex', command.hexValue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isCode = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.blue[300],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCode
                  ? Colors.grey[900]?.withOpacity(0.5)
                  : Colors.grey[850]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[200],
                fontSize: 11,
                fontFamily: isCode ? 'Courier' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(String label, String value) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied to clipboard'),
            backgroundColor: Colors.blue[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.fromLTRB(15, 5, 15, 15),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.copy,
              color: Colors.blue[300],
              size: 14,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.blue[300],
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Direction':
        return Icons.navigation;
      case 'Speed Control':
        return Icons.speed;
      case 'Lighting':
        return Icons.lightbulb;
      case 'Audio':
        return Icons.volume_up;
      case 'Joystick':
        return Icons.gamepad;
      default:
        return Icons.help;
    }
  }
}

class CommandInfo {
  final String action;
  final String button;
  final String byteValue;
  final String hexValue;
  final String description;
  final String additionalInfo;
  final String? example;

  CommandInfo({
    required this.action,
    required this.button,
    required this.byteValue,
    required this.hexValue,
    required this.description,
    this.additionalInfo = '',
    this.example,
  });
}
