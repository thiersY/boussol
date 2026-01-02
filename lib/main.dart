import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  // Verrouiller l'orientation en portrait pour plus de stabilité
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CompassScreen(),
  ));
}

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  double? _direction;
  double _lastHeading = 0;
  double _magneticStrength = 0.0;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  bool _isCalibrated = false;

  @override
  void initState() {
    super.initState();

    // 1. BOUSSOLE AVEC FILTRE DE LISSAGE (60 FPS)
    FlutterCompass.events?.listen((event) {
      if (mounted && event.heading != null) {
        setState(() {
          // Filtre passe-bas : on mélange 15% de la nouvelle valeur avec 85% de l'ancienne
          // Cela élimine les micro-tremblements du capteur
          _direction = _lastHeading + (event.heading! - _lastHeading) * 0.15;
          _lastHeading = _direction!;

          if (event.accuracy != null && event.accuracy! < 15) {
            _isCalibrated = true;
          }
        });
      }
    });

    // 2. MAGNÉTOMÈTRE (µT)
    magnetometerEvents.listen((MagnetometerEvent event) {
      if (mounted) {
        setState(() {
          _magneticStrength = math.sqrt(
            math.pow(event.x, 2) + math.pow(event.y, 2) + math.pow(event.z, 2)
          );
        });
      }
    });

    // 3. ACCÉLÉROMÈTRE (NIVEAU À BULLE)
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          // Normalisation pour le mouvement de la bulle
          _tiltX = event.x.clamp(-5.0, 5.0) * 8;
          _tiltY = event.y.clamp(-5.0, 5.0) * 8;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: !_isCalibrated ? _buildCalibrationUI() : _buildMainUI(),
      ),
    );
  }

  Widget _buildMainUI() {
    double heading = _direction ?? 0;

    return Column(
      children: [
        const SizedBox(height: 60),
        const Spacer(),
        
        // Affichage numérique des degrés
        Text(
          "${heading.round()}° ${_getCardinal(heading)}",
          style: const TextStyle(
            fontSize: 65, 
            fontWeight: FontWeight.w200, 
            color: Colors.white,
            letterSpacing: -2
          ),
        ),
        
        const SizedBox(height: 20),

        // ZONE CENTRALE (Boussole + Niveau)
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Indicateur fixe (Chevron)
              Transform.translate(
                offset: const Offset(0, -155),
                child: const Icon(Icons.keyboard_arrow_down, size: 55, color: Colors.white),
              ),
              
              // 2. CADRAN ROTATIF (Optimisé GPU)
              AnimatedRotation(
                turns: -heading / 360,
                duration: const Duration(milliseconds: 150), // Très court pour la réactivité
                curve: Curves.linear,
                child: RepaintBoundary( // Empêche de redessiner tout l'écran
                  child: SizedBox(
                    width: 320,
                    height: 320,
                    child: CustomPaint(painter: CompassPainter()),
                  ),
                ),
              ),
              
              // 3. CROIX DE NIVEAU (Statique)
              Container(width: 80, height: 1, color: Colors.white12),
              Container(width: 1, height: 80, color: Colors.white12),
              
              // 4. BULLE DE NIVEAU (Dynamique)
              AnimatedContainer(
                duration: const Duration(milliseconds: 40),
                transform: Matrix4.translationValues(_tiltX, _tiltY, 0),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: (_tiltX.abs() < 2 && _tiltY.abs() < 2) 
                        ? Colors.greenAccent 
                        : Colors.white70,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),
        _buildFooter(),
      ],
    );
  }

  // --- WIDGETS COMPOSANTS ---


  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "RÉSISTANCE  ${_magneticStrength.toStringAsFixed(1)} µT",
                style: TextStyle(
                  color: _magneticStrength > 110 ? Colors.redAccent : Colors.orangeAccent, 
                  fontSize: 14, 
                  fontWeight: FontWeight.bold
                ),
              ),
              if (_magneticStrength > 110)
                const Text("PERTURBATION MÉTALLIQUE", style: TextStyle(color: Colors.red, fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  String _getCardinal(double angle) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
    return directions[((angle + 22.5) % 360 / 45).floor()];
  }

  Widget _buildCalibrationUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("ÉTALONNAGE", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 5)),
          const SizedBox(height: 60),
          const Icon(Icons.vibration_outlined, size: 80, color: Color(0xFFC4B5FD)),
          const SizedBox(height: 60),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () => setState(() => _isCalibrated = true),
            child: const Text("COMMENCER", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

// --- PAINTER : DESSIN DU CADRAN AVEC CHIFFRES COURBÉS ---
class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..color = Colors.white..strokeWidth = 1.3;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    for (int i = 0; i < 360; i += 2) {
      double angle = (i - 90) * math.pi / 180;
      double tickLen = i % 10 == 0 ? 16 : 8;
      
      // Traits
      canvas.drawLine(
        Offset(math.cos(angle) * (radius - tickLen), math.sin(angle) * (radius - tickLen)),
        Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        paint..color = i % 10 == 0 ? Colors.white : Colors.white38,
      );

      // Chiffres et Lettres courbés
      if (i % 30 == 0) {
        String label = (i == 0) ? "N" : (i == 90) ? "E" : (i == 180) ? "S" : (i == 270) ? "W" : i.toString();
        
        final tp = TextPainter(
          text: TextSpan(
            text: label, 
            style: TextStyle(
              color: (i % 90 == 0) ? const Color(0xFFC4B5FD) : Colors.white, 
              fontSize: (i % 90 == 0) ? 24 : 13, 
              fontWeight: FontWeight.bold
            )
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        double labelRad = (i % 90 == 0) ? radius - 45 : radius + 25;
        
        canvas.save();
        canvas.translate(math.cos(angle) * labelRad, math.sin(angle) * labelRad);
        canvas.rotate(angle + math.pi / 2); // Suit la courbe de l'arc
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}