import 'dart:ui';

import 'package:bluetooth_rc_controller/CarControllerPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RobotConfigHomePage extends StatefulWidget {
  @override
  _RobotConfigHomePageState createState() => _RobotConfigHomePageState();
}

class _RobotConfigHomePageState extends State<RobotConfigHomePage>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    ));
    _headerAnimationController.forward();
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
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a0a0a),
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: AnimatedBuilder(
                  animation: _headerAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF4ecdc4).withOpacity(0.3 * _headerAnimation.value),
                            Color(0xFF45b7d1).withOpacity(0.2 * _headerAnimation.value),
                            Color(0xFF96ceb4).withOpacity(0.1 * _headerAnimation.value),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.scale(
                              scale: _headerAnimation.value,
                              child: Icon(
                                Icons.smart_toy,
                                size: 60,
                                color: Color(0xFF4ecdc4),
                              ),
                            ),
                            SizedBox(height: 16),
                            Opacity(
                              opacity: _headerAnimation.value,
                              child: Text(
                                'RoboControl Hub',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Opacity(
                              opacity: _headerAnimation.value,
                              child: Text(
                                'Choose Your Robot Configuration',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildListDelegate([
                  RobotConfigCard(
                    title: 'RC Car',
                    description: 'Four-wheel drive remote control vehicle',
                    icon: Icons.directions_car,
                    gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
                    onTap: () => _navigateToConfig('RC Car'),
                  ),
                  RobotConfigCard(
                    title: 'Quadruped',
                    description: 'Four-legged walking robot',
                    icon: Icons.pets,
                    gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
                    onTap: () => _navigateToConfig('Quadruped'),
                  ),
                  RobotConfigCard(
                    title: 'Drone',
                    description: 'Multi-rotor flying vehicle',
                    icon: Icons.flight,
                    gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    onTap: () => _navigateToConfig('Drone'),
                  ),
                  RobotConfigCard(
                    title: 'Humanoid',
                    description: 'Bipedal humanoid robot',
                    icon: Icons.android,
                    gradient: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                    onTap: () => _navigateToConfig('Humanoid'),
                  ),
                  RobotConfigCard(
                    title: 'Tank',
                    description: 'Tracked vehicle platform',
                    icon: Icons.local_shipping,
                    gradient: [Color(0xFFfa709a), Color(0xFFfee140)],
                    onTap: () => _navigateToConfig('Tank'),
                  ),
                  RobotConfigCard(
                    title: 'Spider Bot',
                    description: 'Six-legged crawler robot',
                    icon: Icons.bug_report,
                    gradient: [Color(0xFFa8edea), Color(0xFFfed6e3)],
                    onTap: () => _navigateToConfig('Spider Bot'),
                  ),
                  RobotConfigCard(
                    title: 'Arm Robot',
                    description: 'Multi-joint robotic arm',
                    icon: Icons.back_hand,
                    gradient: [Color(0xFFffecd2), Color(0xFFfcb69f)],
                    onTap: () => _navigateToConfig('Arm Robot'),
                  ),
                  RobotConfigCard(
                    title: 'Custom',
                    description: 'Build your own configuration',
                    icon: Icons.build,
                    gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
                    onTap: () => _navigateToConfig('Custom'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToConfig(String robotType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => robotType=="RC Car" ? CarControllerPage(connection: null):  RobotControlPage(robotType: robotType),
      ),
    );
  }
}

class RobotConfigCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  RobotConfigCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  _RobotConfigCardState createState() => _RobotConfigCardState();
}

class _RobotConfigCardState extends State<RobotConfigCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) {
              _animationController.reverse();
              widget.onTap();
            },
            onTapCancel: () => _animationController.reverse(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.gradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient[0].withOpacity(0.3 + 0.2 * _glowAnimation.value),
                    blurRadius: 20 + 10 * _glowAnimation.value,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        size: 48,
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class RobotControlPage extends StatelessWidget {
  final String robotType;

  RobotControlPage({required this.robotType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$robotType Control'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a0a0a),
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.settings,
                size: 100,
                color: Color(0xFF4ecdc4),
              ),
              SizedBox(height: 20),
              Text(
                '$robotType Configuration',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Control interface coming soon...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }}