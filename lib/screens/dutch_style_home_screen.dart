import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// GOLF.NL-Inspired Design Demo
/// 
/// This is a standalone demo screen showing an alternative design inspired by
/// the Dutch GOLF.NL app. It demonstrates:
/// - Large visual header with curved bottom
/// - Quick action icons in floating white card
/// - Welcome/CTA card
/// - News feed with image overlays
/// - Bottom navigation bar
/// 
/// Note: This is a static demo - buttons and navigation are non-functional.
class DutchStyleHomeScreen extends StatefulWidget {
  const DutchStyleHomeScreen({super.key});

  @override
  State<DutchStyleHomeScreen> createState() => _DutchStyleHomeScreenState();
}

class _DutchStyleHomeScreenState extends State<DutchStyleHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Get player name from auth provider
    final authProvider = Provider.of<AuthProvider>(context);
    final playerName = authProvider.currentPlayer?.name ?? 'Golfspiller';
    
    // DGU farve
    const dguGreen = Color(0xFF1B5E20); 
    const lightBg = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text('🇳🇱 GOLF.NL Design Demo'),
        backgroundColor: dguGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. STOR HEADER MED KURVE (Inspireret af GOLF.NL)
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Den grønne baggrund
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        dguGreen,
                        dguGreen.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.settings, color: Colors.white70),
                            Icon(Icons.notifications_none, color: Colors.white70),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Hej $playerName,",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Klar til at spille golf?",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 2. DE 3 STORE GENVEJE (Inspireret af GOLF.NL)
                // Ligger "ovenpå" headeren
                Positioned(
                  bottom: -50,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickAction(Icons.calendar_today, "Bestil tid", dguGreen),
                        _buildDivider(),
                        _buildQuickAction(Icons.edit_note, "Scorekort", dguGreen),
                        _buildDivider(),
                        _buildQuickAction(Icons.qr_code, "DGU Kort", dguGreen),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 70), // Plads til den "svævende" boks

            // 3. VELKOMST / NEXT STEP BOKS (Inspireret af GOLF.NL)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Velkommen i klubben! 🇩🇰",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Er du klar til at tage næste skridt med dit handicap? Dine venner venter.",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          // Demo only - no action
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Demo knap - ingen funktion')),
                          );
                        },
                        child: const Text("Se mine venner"),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. FEED / NYHEDER (Inspireret af GOLF.NL)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Nyheder", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("Se alle", style: TextStyle(color: dguGreen, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            // Dummy News Cards
            _buildNewsCard("Bane lukket pga. vand", "Greenkeeperne arbejder på højtryk...", "2 timer siden"),
            _buildNewsCard("Ny Danmarksturnering", "Se hvem der skal spille i weekenden", "4 timer siden"),
            _buildNewsCard("Handicap-opdatering", "Tjek dit nye handicap efter sidste runde", "1 dag siden"),
            
            const SizedBox(height: 40),
            
            // Info box om demo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dette er en demo af GOLF.NL-inspireret design. Knapper og navigation er ikke funktionelle.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
      
      // 5. BUND NAVIGATION (Inspireret af GOLF.NL strukturen)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Demo navigation - ingen funktion'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: dguGreen,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Start"),
            BottomNavigationBarItem(icon: Icon(Icons.sports_golf), label: "Mit spil"),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: "Venner"),
            BottomNavigationBarItem(icon: Icon(Icons.school), label: "Træning"),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Demo: $label'), duration: const Duration(seconds: 1)),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.shade200);
  }

  Widget _buildNewsCard(String title, String subtitle, String time) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: const NetworkImage("https://picsum.photos/400/200"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
          onError: (exception, stackTrace) {
            // Graceful fallback if image fails to load
          },
        ),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

