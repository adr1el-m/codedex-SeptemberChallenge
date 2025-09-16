import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'config.dart';
import 'widgets/fireplace_simulator_widget.dart';

// Optimized scatter leaf class for better physics
class ScatterLeaf {
  final String emoji;
  final double size;
  final Offset initialPosition;
  late Offset position;
  late Offset velocity;
  late double rotation;
  late double rotationSpeed;
  late double opacity;
  final double mass;
  final int id;
  
  ScatterLeaf({
    required this.emoji,
    required this.size,
    required this.initialPosition,
    required this.mass,
    required this.id,
  }) {
    position = initialPosition;
    velocity = Offset.zero;
    rotation = 0.0;
    rotationSpeed = 0.0;
    opacity = 1.0;
  }
  
  // Apply force from tap with realistic physics
  void applyScatterForce(Offset tapPosition, double intensity) {
    final distance = (position - tapPosition).distance;
    if (distance < 120) { // Scatter range
      final direction = position - tapPosition;
      final normalizedDirection = distance > 0 
          ? direction / distance 
          : Offset(math.Random().nextDouble() - 0.5, -1);
      
      // Inverse square law for realistic force falloff
      final forceMagnitude = intensity * (120 - distance) / distance.clamp(10, 120);
      final force = normalizedDirection * forceMagnitude;
      
      // Apply force considering mass (F = ma)
      velocity += force / mass;
      
      // Add spin based on force
      rotationSpeed += (force.dx * 0.02) / mass;
    }
  }
  
  // Update physics with air resistance and gravity
  void updatePhysics(double deltaTime) {
    // Air resistance (drag)
    final drag = 0.98;
    velocity *= drag;
    rotationSpeed *= 0.99;
    
    // Gravity
    velocity += const Offset(0, 50) * deltaTime;
    
    // Update position
    position += velocity * deltaTime;
    rotation += rotationSpeed * deltaTime;
    
    // Fade out over time
    opacity = (opacity - deltaTime * 0.5).clamp(0.0, 1.0);
  }
  
  bool get isExpired => opacity <= 0.1 || position.dy > 1000;
}

void main() {
  runApp(const SeptemberVibesApp());
}

class SeptemberVibesApp extends StatelessWidget {
  const SeptemberVibesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'September Vibes ✨',
      theme: ThemeData(
        fontFamily: 'Georgia',
        useMaterial3: true,
      ),
      home: const SeptemberHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SeptemberHomePage extends StatefulWidget {
  const SeptemberHomePage({super.key});

  @override
  State<SeptemberHomePage> createState() => _SeptemberHomePageState();
}

class _SeptemberHomePageState extends State<SeptemberHomePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _parallaxController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  // Enhanced tap to scatter effect with optimized physics
  late AnimationController _scatterController;
  final List<ScatterLeaf> _scatterLeaves = [];
  Offset? _lastTapPosition;

  final List<String> _cozyQuotes = [
    "September whispers autumn's sweet hello 🍂",
    "Cozy sweaters and golden memories ✨",
    "Dancing leaves tell stories of change 🍁",
    "Warm coffee, cool breeze, perfect vibes ☕",
    "September sunsets paint the sky in dreams 🌅",
  ];

  final List<Map<String, String>> _septemberTrivia = [
    {
      'question': 'Why do leaves change color in autumn?',
      'answer': 'Chlorophyll breaks down, revealing hidden yellow and orange pigments called carotenoids! 🍂',
      'fact': 'Did you know? Red leaves get their color from anthocyanins, which are produced fresh each fall!'
    },
    {
      'question': 'What\'s special about the September equinox?',
      'answer': 'Day and night are nearly equal in length all around the world! 🌍',
      'fact': 'Fun fact: The word "equinox" comes from Latin meaning "equal night"!'
    },
    {
      'question': 'Which spice is harvested in September?',
      'answer': 'Saffron! It\'s harvested from crocus flowers and is worth more than gold! ✨',
      'fact': 'Amazing fact: It takes 150 flowers to produce just 1 gram of saffron!'
    },
    {
      'question': 'What happens to birds in September?',
      'answer': 'Many birds begin their incredible migration journeys south! 🐦',
      'fact': 'Mind-blowing: Arctic Terns migrate 44,000 miles annually - the longest migration!'
    },
    {
      'question': 'Why is September called "Harvest Moon"?',
      'answer': 'The full moon rises earlier, giving farmers extra light for harvesting! 🌕',
      'fact': 'Cool fact: The Harvest Moon can appear orange due to atmospheric particles!'
    },
    {
      'question': 'What fruit is traditionally picked in September?',
      'answer': 'Apples! Peak apple season runs from September to November! 🍎',
      'fact': 'Sweet fact: There are over 7,500 varieties of apples grown worldwide!'
    },
    {
      'question': 'Why do we feel cozy in autumn?',
      'answer': 'Cooler temps trigger our nesting instincts and boost serotonin! 🧡',
      'fact': 'Science says: Autumn colors actually make us feel more creative and focused!'
    },
    {
      'question': 'What makes pumpkin spice so popular?',
      'answer': 'The blend of cinnamon, nutmeg, and cloves triggers happy memories! ☕',
      'fact': 'Nostalgic fact: These spices have been used together for over 400 years!'
    }
  ];

  int _currentQuoteIndex = 0;
  int _currentTriviaIndex = 0;
  bool _showTriviaAnswer = false;
  String _currentMood = '';
  List<Map<String, String>> _generatedRecipes = [];
  bool _isLoadingRecipes = false;
  final TextEditingController _moodController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];
  final ScrollController _chatScrollController = ScrollController();
  
  // Cozy Pomodoro Timer state
  bool _isTimerRunning = false;
  bool _isPomodoroMode = true; // true for work, false for break
  int _pomodoroMinutes = 25;
  int _breakMinutes = 5;
  int _remainingSeconds = 25 * 60;
  Timer? _pomodoroTimer;
  int _completedPomodoros = 0;
  String _currentTask = '';
  final TextEditingController _taskController = TextEditingController();
  
  final List<String> _cozyTimerSounds = [
    '🔥 Crackling Fire',
    '🌧️ Gentle Rain', 
    '🍂 Rustling Leaves',
    '☕ Coffee Shop',
    '🦌 Forest Sounds'
  ];
  String _selectedSound = '🔥 Crackling Fire';
  
  // Audio player for ambient sounds
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAmbientSound = false;
  double _ambientVolume = 0.7; // Increased volume for better audibility
  
  // Autumn Bucket List state
  List<Map<String, dynamic>> _bucketListItems = [
    {
      'id': 'apple_picking',
      'title': 'Go Apple Picking',
      'description': 'Visit an orchard and pick fresh autumn apples',
      'icon': '🍎',
      'points': 10,
      'completed': false,
      'category': 'outdoor',
    },
    {
      'id': 'pumpkin_patch',
      'title': 'Visit a Pumpkin Patch',
      'description': 'Find the perfect pumpkin for carving or decoration',
      'icon': '🎃',
      'points': 15,
      'completed': false,
      'category': 'outdoor',
    },
    {
      'id': 'autumn_leaves',
      'title': 'Make a Leaf Pile',
      'description': 'Jump into a pile of colorful autumn leaves',
      'icon': '🍂',
      'points': 8,
      'completed': false,
      'category': 'outdoor',
    },
    {
      'id': 'hot_chocolate',
      'title': 'Perfect Hot Chocolate',
      'description': 'Make the ultimate cozy hot chocolate with marshmallows',
      'icon': '☕',
      'points': 5,
      'completed': false,
      'category': 'cozy',
    },
    {
      'id': 'autumn_walk',
      'title': 'Golden Hour Nature Walk',
      'description': 'Take a peaceful walk during autumn golden hour',
      'icon': '🌅',
      'points': 7,
      'completed': false,
      'category': 'outdoor',
    },
    {
      'id': 'cozy_reading',
      'title': 'Read by the Fireplace',
      'description': 'Enjoy a good book with a warm blanket and fire',
      'icon': '📚',
      'points': 6,
      'completed': false,
      'category': 'cozy',
    },
    {
      'id': 'autumn_baking',
      'title': 'Bake Autumn Treats',
      'description': 'Make homemade pie, cookies, or seasonal pastries',
      'icon': '🥧',
      'points': 12,
      'completed': false,
      'category': 'cozy',
    },
    {
      'id': 'bonfire',
      'title': 'Cozy Bonfire Night',
      'description': 'Gather around a fire with friends and s\'mores',
      'icon': '🔥',
      'points': 15,
      'completed': false,
      'category': 'social',
    },
    {
      'id': 'autumn_photos',
      'title': 'Autumn Photo Session',
      'description': 'Capture the beauty of fall colors and vibes',
      'icon': '📸',
      'points': 8,
      'completed': false,
      'category': 'creative',
    },
    {
      'id': 'sweater_weather',
      'title': 'First Sweater Day',
      'description': 'Wear your coziest sweater on a crisp autumn day',
      'icon': '🧥',
      'points': 4,
      'completed': false,
      'category': 'cozy',
    },
  ];
  int _totalBucketListPoints = 0;
  String _currentBucketListFilter = 'all';

  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    
    // Initialize Gemini AI model
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: Config.geminiApiKey,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _parallaxController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _scatterController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _fadeController.forward();
    _slideController.forward();
    
    // Listen to scroll changes for parallax effect
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    // Cycle through quotes
    _startQuoteCycle();
    
    // Cycle through trivia
    _startTriviaCycle();
    
    // Initialize pomodoro timer
    _resetTimer();
    
    // Test Gemini API connection
    _testGeminiConnection();
  }

  Future<void> _testGeminiConnection() async {
    try {
      print('Testing Gemini API connection...');
      final testContent = [Content.text('Hello, just testing the connection. Please respond with "Connection successful!"')];
      final response = await _model.generateContent(testContent);
      
      if (response.text != null && response.text!.isNotEmpty) {
        print('✅ Gemini API connection successful: ${response.text}');
      } else {
        print('❌ Gemini API returned empty response');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Quota exceeded')) {
        print('⚠️ Gemini API rate limit exceeded. Wait a minute before trying again.');
      } else if (errorMessage.contains('API key')) {
        print('❌ Gemini API key invalid or not properly configured');
      } else {
        print('❌ Gemini API connection failed: $e');
      }
    }
  }

  void _startQuoteCycle() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentQuoteIndex = (_currentQuoteIndex + 1) % _cozyQuotes.length;
        });
        _startQuoteCycle();
      }
    });
  }

  void _startTriviaCycle() {
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _currentTriviaIndex = (_currentTriviaIndex + 1) % _septemberTrivia.length;
          _showTriviaAnswer = false; // Reset to show question
        });
        _startTriviaCycle();
      }
    });
  }

  void _onEnhancedTapScatter(TapDownDetails details) {
    final tapPosition = details.localPosition;
    _lastTapPosition = tapPosition;
    
    // Create new scatter leaves at tap location with variety
    final random = math.Random();
    final leafEmojis = ['🍂', '🍁', '🌿', '🍃'];
    
    // Add 8-12 leaves for rich effect but not too many for performance
    final leafCount = 8 + random.nextInt(5);
    
    for (int i = 0; i < leafCount; i++) {
      final emoji = leafEmojis[random.nextInt(leafEmojis.length)];
      final size = 16.0 + random.nextDouble() * 12;
      final mass = 0.8 + random.nextDouble() * 0.4;
      
      // Spawn leaves in a small area around tap
      final spawnOffset = Offset(
        (random.nextDouble() - 0.5) * 40,
        (random.nextDouble() - 0.5) * 40,
      );
      
      final leaf = ScatterLeaf(
        emoji: emoji,
        size: size,
        initialPosition: tapPosition + spawnOffset,
        mass: mass,
        id: DateTime.now().millisecondsSinceEpoch + i,
      );
      
      // Apply initial scatter force
      leaf.applyScatterForce(tapPosition, 80.0 + random.nextDouble() * 40);
      
      _scatterLeaves.add(leaf);
    }
    
    // Limit total leaves for performance (keep only most recent 50)
    if (_scatterLeaves.length > 50) {
      _scatterLeaves.removeRange(0, _scatterLeaves.length - 50);
    }
    
    // Start scatter animation
    _scatterController.reset();
    _scatterController.forward();
    
    setState(() {});
  }

  void _toggleTriviaAnswer() {
    setState(() {
      if (_showTriviaAnswer) {
        // Move to next trivia
        _currentTriviaIndex = (_currentTriviaIndex + 1) % _septemberTrivia.length;
        _showTriviaAnswer = false;
      } else {
        // Show answer
        _showTriviaAnswer = true;
      }
    });
  }

  // Cozy Pomodoro Timer Methods
  void _resetTimer() {
    _remainingSeconds = _isPomodoroMode ? _pomodoroMinutes * 60 : _breakMinutes * 60;
  }

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
    });

    // Auto-start ambient sounds when timer begins (if not already playing)
    if (!_isPlayingAmbientSound) {
      _playAmbientSound(_selectedSound);
    }

    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          // Timer completed
          _onTimerComplete();
          timer.cancel();
        }
      });
    });
  }

  void _pauseTimer() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _stopTimer() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _resetTimer();
    });
  }

  void _onTimerComplete() {
    setState(() {
      _isTimerRunning = false;
      
      if (_isPomodoroMode) {
        _completedPomodoros++;
        _isPomodoroMode = false; // Switch to break
        
        // Show completion celebration
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Cozy work session complete!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Time for a warm break ☕',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFFD2691E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        _isPomodoroMode = true; // Switch back to work
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Row(
                children: [
                  Text('🍂', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Break time over! Ready for another cozy focus session?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFF8B4513),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      _resetTimer();
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Audio methods for ambient sounds
  String _getSoundFileName(String soundName) {
    switch (soundName) {
      case '🔥 Crackling Fire':
        return 'crackling_fire.mp3';
      case '🌧️ Gentle Rain':
        return 'gentle_rain.mp3';
      case '🍂 Rustling Leaves':
        return 'rustling_leaves.mp3';
      case '☕ Coffee Shop':
        return 'coffee_shop.mp3';
      case '🦌 Forest Sounds':
        return 'forest_sounds.mp3';
      default:
        return 'crackling_fire.mp3';
    }
  }

  Future<void> _playAmbientSound(String soundName) async {
    try {
      print('🎵 Attempting to play: $soundName');
      await _audioPlayer.stop();
      final fileName = _getSoundFileName(soundName);
      print('🎵 File name: $fileName');
      print('🎵 Volume level: $_ambientVolume');
      
      await _audioPlayer.play(AssetSource('audio/$fileName'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(_ambientVolume);
      
      // Check if audio is actually playing
      final playerState = _audioPlayer.state;
      print('🎵 Player state after play: $playerState');
      
      setState(() {
        _isPlayingAmbientSound = true;
        _selectedSound = soundName;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.volume_up, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Now playing: $soundName'),
            ],
          ),
          backgroundColor: const Color(0xFFD2691E),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      print('Error playing sound: $e');
      // Show a clearer error message about missing audio files
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Audio file not found!')),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Add ${_getSoundFileName(soundName)} to assets/audio/ folder',
                style: const TextStyle(fontSize: 12, color: Color(0xE6FFFFFF)),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD32F2F),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      setState(() {
        _selectedSound = soundName;
        _isPlayingAmbientSound = false; // Make sure this is false when audio fails
      });
    }
  }

  Future<void> _stopAmbientSound() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlayingAmbientSound = false;
    });
  }

  Future<void> _toggleAmbientSound() async {
    if (_isPlayingAmbientSound) {
      await _stopAmbientSound();
    } else {
      await _playAmbientSound(_selectedSound);
    }
  }

  Future<void> _sendMoodMessage() async {
    final userMessage = _moodController.text.trim();
    if (userMessage.isEmpty) return;

    // Add user message to chat
    setState(() {
      _chatMessages.add({
        'isUser': true,
        'message': userMessage,
        'timestamp': DateTime.now(),
      });
      _isLoadingRecipes = true;
    });

    _moodController.clear();
    _scrollToBottom();

    try {
      final prompt = '''
You are Honey Hazel, a warm, nurturing AI assistant who specializes in cozy September recipes. You have a sweet, caring personality like warm honey and speak with gentle enthusiasm. You use endearing terms like "sweetie", "honey", "dear", and love to add honey/autumn emojis to your responses.

The user just shared their mood/feelings: "$userMessage"

Please respond with:
1. A warm, empathetic response to their mood in Honey Hazel's sweet, caring voice (2-3 sentences with endearing terms)
2. Exactly 3 cozy September/autumn recipes that match their feelings

For each recipe, provide:
- name: A cozy, autumn-themed recipe name (preferably with honey, maple, or warm spice themes)
- description: 2-3 lines describing the recipe in Honey Hazel's warm tone
- ingredients: 3-5 key ingredients (comma separated)
- cookingTime: How long it takes to make
- moodMatch: Why this recipe matches their mood (in Honey Hazel's caring voice)

Format your response EXACTLY like this:

RESPONSE: [Your warm Honey Hazel response here, sweetie! 🍯]

RECIPES:
[
  {
    "name": "Recipe Name 1",
    "description": "Description here in warm, caring tone",
    "ingredients": "ingredient1, ingredient2, ingredient3",
    "cookingTime": "30 minutes",
    "moodMatch": "Why it matches their mood, dear 🍯"
  },
  {
    "name": "Recipe Name 2", 
    "description": "Description here with Honey Hazel's warmth",
    "ingredients": "ingredient1, ingredient2, ingredient3",
    "cookingTime": "25 minutes",
    "moodMatch": "Caring explanation, honey ✨"
  },
  {
    "name": "Recipe Name 3",
    "description": "Sweet description with autumn vibes", 
    "ingredients": "ingredient1, ingredient2, ingredient3",
    "cookingTime": "20 minutes",
    "moodMatch": "Nurturing reason, sweetie 🧡"
  }
]

Focus on honey, maple, warm spices, and autumn flavors. Be nurturing and use Honey Hazel's sweet personality throughout.
      ''';

      print('Sending request to Gemini AI...');
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      print('Received response from Gemini AI: ${response.text?.substring(0, 100) ?? 'null'}...');
      
      if (response.text != null && response.text!.isNotEmpty) {
        final responseText = response.text!;
        
        // Extract the friendly response and recipes
        final parts = responseText.split('RECIPES:');
        String friendlyResponse = '';
        String recipesJson = '';
        
        if (parts.length >= 2) {
          friendlyResponse = parts[0].replaceAll('RESPONSE:', '').trim();
          recipesJson = parts[1].trim();
        } else {
          // Fallback parsing
          if (responseText.contains('RESPONSE:')) {
            friendlyResponse = responseText.split('RESPONSE:')[1].split('RECIPES:')[0].trim();
          } else {
            friendlyResponse = "I understand how you're feeling! Let me suggest some cozy recipes for you 🍂";
          }
          recipesJson = responseText.substring(responseText.indexOf('['));
        }

        // Add AI response to chat
        setState(() {
          _chatMessages.add({
            'isUser': false,
            'message': friendlyResponse,
            'timestamp': DateTime.now(),
          });
        });

        _scrollToBottom();

        // Parse recipes
        try {
          print('Parsing recipes JSON: $recipesJson');
          
          // Clean up the JSON
          recipesJson = recipesJson
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          
          // Find the JSON array
          int startIndex = recipesJson.indexOf('[');
          int endIndex = recipesJson.lastIndexOf(']') + 1;
          
          if (startIndex != -1 && endIndex > startIndex) {
            String cleanJson = recipesJson.substring(startIndex, endIndex);
            print('Clean JSON: $cleanJson');
            
            final List<dynamic> recipesData = json.decode(cleanJson);
            
            if (recipesData.isNotEmpty) {
              setState(() {
                _generatedRecipes = recipesData.map((recipe) => {
                  'name': recipe['name']?.toString() ?? 'Cozy September Treat',
                  'description': recipe['description']?.toString() ?? 'A warm and comforting recipe',
                  'ingredients': recipe['ingredients']?.toString() ?? 'Seasonal ingredients',
                  'cookingTime': recipe['cookingTime']?.toString() ?? '30 minutes',
                  'moodMatch': recipe['moodMatch']?.toString() ?? 'Perfect for your mood',
                }).toList();
              });
              print('Successfully parsed ${_generatedRecipes.length} recipes');
            } else {
              throw Exception('No recipes in response');
            }
          } else {
            throw Exception('No valid JSON array found');
          }
        } catch (parseError) {
          print('JSON Parse Error: $parseError');
          print('Raw response: $responseText');
          
          // Add error message to chat
          setState(() {
            _chatMessages.add({
              'isUser': false,
              'message': "I got some recipe ideas but had trouble formatting them. Let me try again with simpler recipes!",
              'timestamp': DateTime.now(),
            });
          });
          _scrollToBottom();
          
          _createFallbackRecipes(userMessage);
        }
      } else {
        print('Empty or null response from Gemini');
        setState(() {
          _chatMessages.add({
            'isUser': false,
            'message': "I'm having trouble connecting right now, but here are some lovely recipes for you! 🧡",
            'timestamp': DateTime.now(),
          });
        });
        _scrollToBottom();
        _createFallbackRecipes(userMessage);
      }
    } catch (e) {
      String errorMessage = e.toString();
      print('Error calling Gemini API: $e');
      
      String userFriendlyMessage;
      if (errorMessage.contains('Quota exceeded')) {
        userFriendlyMessage = "I'm getting too many requests right now! 😅 Please wait a minute and try again. The AI is popular today! 🤖✨";
      } else if (errorMessage.contains('API key')) {
        userFriendlyMessage = "I'm having trouble with my API connection. Let me give you some lovely recipes anyway! 🧡";
      } else {
        userFriendlyMessage = "I'm having some technical difficulties, but I still want to help! Here are some comforting recipes 🧡";
      }
      
      setState(() {
        _chatMessages.add({
          'isUser': false,
          'message': userFriendlyMessage,
          'timestamp': DateTime.now(),
        });
      });
      _scrollToBottom();
      _createFallbackRecipes(userMessage);
    }

    setState(() {
      _isLoadingRecipes = false;
    });
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _createFallbackRecipes(String userMood) {
    setState(() {
      _generatedRecipes = [
        {
          'name': 'Spiced Apple Cider',
          'description': 'Warm, fragrant cider with cinnamon and star anise. Perfect for cozy September evenings.',
          'ingredients': 'Apple cider, cinnamon sticks, star anise, orange peel, honey',
          'cookingTime': '15 minutes',
          'moodMatch': 'The warmth and spices will lift your spirits and complement how you\'re feeling',
        },
        {
          'name': 'Pumpkin Spice Muffins',
          'description': 'Fluffy muffins bursting with autumn spices and pumpkin goodness.',
          'ingredients': 'Pumpkin puree, flour, cinnamon, nutmeg, brown sugar',
          'cookingTime': '25 minutes',
          'moodMatch': 'Sweet comfort food that brings joy and matches your current mood',
        },
        {
          'name': 'Butternut Squash Soup',
          'description': 'Creamy, velvety soup with a hint of ginger and sage.',
          'ingredients': 'Butternut squash, vegetable broth, ginger, sage, cream',
          'cookingTime': '40 minutes',
          'moodMatch': 'Nourishing and warming, perfect for comfort and self-care',
        },
      ];
    });
  }

  void _toggleBucketListItem(String itemId) {
    setState(() {
      final index = _bucketListItems.indexWhere((item) => item['id'] == itemId);
      if (index != -1) {
        _bucketListItems[index]['completed'] = !_bucketListItems[index]['completed'];
        _calculateTotalPoints();
        
        // Show celebration animation for completion
        if (_bucketListItems[index]['completed']) {
          _showCompletionCelebration(
            _bucketListItems[index]['title'], 
            _bucketListItems[index]['points']
          );
        }
      }
    });
  }

  void _calculateTotalPoints() {
    _totalBucketListPoints = _bucketListItems
        .where((item) => item['completed'] == true)
        .map((item) => item['points'] as int)
        .fold(0, (sum, points) => sum + points);
  }

  void _showCompletionCelebration(String title, int points) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Woohoo! $title completed!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '+$points autumn points earned! 🍂',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFD2691E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _parallaxController.dispose();
    _scatterController.dispose();
    _moodController.dispose();
    _chatScrollController.dispose();
    _scrollController.dispose();
    _taskController.dispose();
    _pomodoroTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: _onEnhancedTapScatter,
        child: Stack(
          children: [
            // Parallax background layers
            _buildParallaxBackground(),
            
            // Main content with parallax scrolling
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF5E6D3), // Warm cream
                    Color(0xFFE8D5C4), // Soft beige
                    Color(0xFFD4B5A0), // Dusty rose
                    Color(0xFFC49A82), // Warm brown
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // September Trivia & Facts section
                      _buildSeptemberTrivia(),

                      const SizedBox(height: 30),
                      
                      // Header with animated title
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.brown.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Seasonal header decoration
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _fadeController,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: _fadeController.value * math.pi * 0.2,
                                          child: const Text('🌰', style: TextStyle(fontSize: 16)),
                                        );
                                      },
                                    ),
                                    AnimatedBuilder(
                                      animation: _slideController,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            math.sin(_slideController.value * 2 * math.pi) * 3,
                                            0,
                                          ),
                                          child: const Text('🍂', style: TextStyle(fontSize: 14)),
                                        );
                                      },
                                    ),
                                    AnimatedBuilder(
                                      animation: _fadeController,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: -_fadeController.value * math.pi * 0.3,
                                          child: const Text('🌲', style: TextStyle(fontSize: 12)),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'September',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w300,
                                    color: Color(0xFF8B4513),
                                    letterSpacing: 2,
                                  ),
                                ),
                                const Text(
                                  'Vibes ✨',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFD2691E),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 800),
                                  child: Text(
                                    _cozyQuotes[_currentQuoteIndex],
                                    key: ValueKey(_currentQuoteIndex),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF654321),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Cozy Pomodoro Timer section
                      _buildCozyPomodoroTimer(),

                      const SizedBox(height: 30),

                      // AI Mood Chat section
                      _buildMoodChat(),

                      const SizedBox(height: 30),

                      // Autumn Bucket List section
                      _buildAutumnBucketList(),

                      const SizedBox(height: 30),

                      // September activities grid
                      _buildActivitiesGrid(),
                      
                      const SizedBox(height: 30),

                      // Cozy Fireplace Simulator
                      const FireplaceSimulatorWidget(),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Foreground parallax floating leaves
          _buildFloatingParallaxLeaves(),
          
          // Enhanced scatter leaves
          _buildScatterLeaves(),
        ],
        ),
      ),
    );
  }

  Widget _buildParallaxBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Background layer - slowest movement
          Transform.translate(
            offset: Offset(0, -_scrollOffset * 0.1),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    const Color(0xFFFFE4B5).withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Mid background layer - medium movement
          Transform.translate(
            offset: Offset(0, -_scrollOffset * 0.2),
            child: _buildBackgroundElements(),
          ),
          
          // Far background layer - faster movement
          Transform.translate(
            offset: Offset(0, -_scrollOffset * 0.3),
            child: _buildBackgroundClouds(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        // Scattered autumn elements in background
        Positioned(
          top: 100,
          left: 50,
          child: AnimatedBuilder(
            animation: _parallaxController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _parallaxController.value * 2 * math.pi,
                child: Opacity(
                  opacity: 0.2,
                  child: Text(
                    '🍂',
                    style: TextStyle(
                      fontSize: 30,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.orange.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        Positioned(
          top: 300,
          right: 80,
          child: AnimatedBuilder(
            animation: _parallaxController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  math.sin(_parallaxController.value * 2 * math.pi) * 20,
                  math.cos(_parallaxController.value * 1.5 * math.pi) * 10,
                ),
                child: Opacity(
                  opacity: 0.15,
                  child: Text(
                    '🌰',
                    style: TextStyle(
                      fontSize: 25,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.brown.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        Positioned(
          top: 500,
          left: 30,
          child: AnimatedBuilder(
            animation: _parallaxController,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_parallaxController.value * 1.5 * math.pi,
                child: Opacity(
                  opacity: 0.18,
                  child: Text(
                    '🍁',
                    style: TextStyle(
                      fontSize: 28,
                      shadows: [
                        Shadow(
                          blurRadius: 12,
                          color: Colors.red.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        Positioned(
          top: 700,
          right: 40,
          child: AnimatedBuilder(
            animation: _parallaxController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  math.cos(_parallaxController.value * 2.5 * math.pi) * 15,
                  math.sin(_parallaxController.value * 2 * math.pi) * 8,
                ),
                child: Opacity(
                  opacity: 0.16,
                  child: Text(
                    '🌲',
                    style: TextStyle(
                      fontSize: 32,
                      shadows: [
                        Shadow(
                          blurRadius: 15,
                          color: Colors.green.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        Positioned(
          top: 900,
          left: 120,
          child: AnimatedBuilder(
            animation: _parallaxController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + math.sin(_parallaxController.value * 3 * math.pi) * 0.1,
                child: Opacity(
                  opacity: 0.12,
                  child: Text(
                    '🍄',
                    style: TextStyle(
                      fontSize: 24,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.red.withOpacity(0.15),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundClouds() {
    return Stack(
      children: [
        // Subtle cloud-like effects
        Positioned(
          top: 50,
          left: -50,
          child: AnimatedBuilder(
            animation: _parallaxController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _parallaxController.value * 100 - 50,
                  math.sin(_parallaxController.value * 2 * math.pi) * 5,
                ),
                child: Container(
                  width: 150,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              );
            },
          ),
        ),
        
        Positioned(
          top: 200,
          right: -100,
          child: AnimatedBuilder(
            animation: _parallaxController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -_parallaxController.value * 80 + 100,
                  math.cos(_parallaxController.value * 1.8 * math.pi) * 8,
                ),
                child: Container(
                  width: 200,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: const Color(0xFFD2691E).withOpacity(0.03),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingParallaxLeaves() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: List.generate(6, (index) { // Reduced to 6 leaves for better performance
            final random = math.Random(index + 42);
            final leafEmojis = ['🍂', '🍁', '🌿', '🍃'];
            final emoji = leafEmojis[index % leafEmojis.length];
            final size = 18.0 + random.nextDouble() * 8; // Consistent size range
            final startX = random.nextDouble() * 300; // Reduced range for better visibility
            final startY = random.nextDouble() * 150;
            
            // Natural physics parameters - simplified for better performance
            final windSensitivity = 0.5 + random.nextDouble() * 0.4;
            final driftAmplitude = 15 + random.nextDouble() * 10;
            
            // Parallax speed based on visual depth (closer leaves move faster)
            final baseParallaxSpeed = 0.2 + (index % 3) * 0.1;
            final scrollResponsiveness = (_scrollOffset * baseParallaxSpeed) % 600;
            
            return Positioned(
              left: startX,
              top: startY + scrollResponsiveness,
              child: AnimatedBuilder(
                animation: _parallaxController, // Only listening to parallax controller now
                builder: (context, child) {
                  final time = _parallaxController.value + (index * 0.3);
                  
                  // Natural floating movement with gentle wind effects
                  final windX = math.sin(time * 0.8 * math.pi) * windSensitivity * driftAmplitude;
                  final windY = math.cos(time * 0.4 * math.pi) * windSensitivity * 8;
                  final gentleDrift = math.sin(time * 1.2 * math.pi) * 6;
                  
                  // Enhanced: React to nearby taps
                  double tapInfluence = 0;
                  if (_lastTapPosition != null) {
                    final leafPosition = Offset(startX + windX + gentleDrift, startY + scrollResponsiveness + windY);
                    final distance = (leafPosition - _lastTapPosition!).distance;
                    if (distance < 100) {
                      final tapAge = _scatterController.value;
                      tapInfluence = (1.0 - tapAge) * (100 - distance) / 100 * 15;
                    }
                  }
                  
                  // Smooth rotation based on wind direction
                  final rotation = time * 0.5 * math.pi + (windX * 0.02) + (tapInfluence * 0.1);
                  
                  // Combined natural movement - no scatter physics
                  final finalOffsetX = windX + gentleDrift + tapInfluence;
                  final finalOffsetY = windY + math.sin(time * 0.6 * math.pi) * 4;
                  
                  // Subtle opacity variation for natural depth
                  final opacity = (0.4 + math.sin(time * 0.7 * math.pi) * 0.15).clamp(0.25, 0.6);
                  
                  // Gentle scale variation for breathing effect
                  final scale = 1.0 + math.sin(time * 0.9 * math.pi) * 0.05 + (tapInfluence * 0.01);
                  
                  return Transform.translate(
                    offset: Offset(finalOffsetX, finalOffsetY),
                    child: Transform.rotate(
                      angle: rotation,
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Text(
                            emoji,
                            style: TextStyle(
                              fontSize: size,
                              shadows: [
                                Shadow(
                                  blurRadius: 4.0,
                                  color: Colors.brown.withOpacity(0.3),
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSeptemberTrivia() {
    final currentTrivia = _septemberTrivia[_currentTriviaIndex];
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF8B4513).withOpacity(0.9),
              const Color(0xFFD2691E).withOpacity(0.8),
              const Color(0xFFFF8C00).withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B4513).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with rotating seasonal icons
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: AnimatedBuilder(
                    animation: _slideController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _slideController.value * math.pi * 0.5,
                        child: const Text('🧠', style: TextStyle(fontSize: 24)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'September Trivia & Facts',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black26,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Discover autumn\'s secrets! 🍂',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                // Trivia counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentTriviaIndex + 1}/${_septemberTrivia.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Question/Answer section with animated switcher
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_showTriviaAnswer ? 0.95 : 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question or Answer
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      key: ValueKey(_showTriviaAnswer),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _showTriviaAnswer 
                                    ? const Color(0xFF228B22).withOpacity(0.2)
                                    : const Color(0xFFD2691E).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _showTriviaAnswer ? '💡 ANSWER' : '❓ QUESTION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _showTriviaAnswer 
                                      ? const Color(0xFF228B22)
                                      : const Color(0xFFD2691E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _showTriviaAnswer 
                              ? currentTrivia['answer']! 
                              : currentTrivia['question']!,
                          style: TextStyle(
                            fontSize: _showTriviaAnswer ? 16 : 17,
                            fontWeight: _showTriviaAnswer ? FontWeight.w500 : FontWeight.w600,
                            color: const Color(0xFF2F4F4F),
                            height: 1.4,
                          ),
                        ),
                        
                        // Extra fact when showing answer
                        if (_showTriviaAnswer) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8DC).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD2691E).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('✨', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    currentTrivia['fact']!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF8B4513),
                                      fontStyle: FontStyle.italic,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action button
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton.icon(
                        onPressed: _toggleTriviaAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showTriviaAnswer 
                              ? const Color(0xFF228B22)
                              : const Color(0xFFD2691E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 4,
                        ),
                        icon: Icon(
                          _showTriviaAnswer ? Icons.quiz : Icons.lightbulb,
                          size: 18,
                        ),
                        label: Text(
                          _showTriviaAnswer ? 'Next Question' : 'Reveal Answer',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Progress dots
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_septemberTrivia.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _currentTriviaIndex ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentTriviaIndex 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodChat() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: Color(0xFFD2691E), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 800),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B4513),
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.orange.withOpacity(0.3),
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  child: const Text('Honey Hazel 🍯'),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD2691E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 1200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8DC).withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD2691E).withOpacity(0.3),
              ),
            ),
            child: Text(
              'Hey there, sweetie! 🍯 I\'m Honey Hazel, your cozy autumn recipe companion! Tell me how you\'re feeling and I\'ll whip up the most comforting seasonal recipes just for you! ✨',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF654321),
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          
          // Debug info
          if (Config.geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Text(
                '⚠️ Please add your Gemini API key in config.dart',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Chat messages with loading animation
          if (_chatMessages.isNotEmpty || _isLoadingRecipes) ...[
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8DC).withOpacity(0.4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFD2691E).withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                controller: _chatScrollController,
                itemCount: _chatMessages.length + (_isLoadingRecipes ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _chatMessages.length && _isLoadingRecipes) {
                    // Loading animation for Honey Hazel thinking
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFFFF8DC),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFFE4B5),
                                    const Color(0xFFFFF8DC),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Text('🍯', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFD2691E).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Honey Hazel is thinking',
                                    style: TextStyle(
                                      color: Color(0xFF8B4513),
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFD2691E),
                                      ),
                                    ),
                                  ),
                                  const Text(' 🍯', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final message = _chatMessages[index];
                  return _buildChatMessage(message);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Input field with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: TextField(
                      controller: _moodController,
                      decoration: InputDecoration(
                        hintText: 'How are you feeling today, sweetie? 🍯',
                        hintStyle: TextStyle(
                          color: const Color(0xFF8B4513).withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFFF8DC).withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Color(0xFFD2691E)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: const Color(0xFFD2691E).withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFD2691E), 
                            width: 2.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, 
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF8B4513),
                        fontSize: 15,
                      ),
                      maxLines: 3,
                      minLines: 1,
                      onSubmitted: (_) => _sendMoodMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFD2691E),
                        const Color(0xFFFF8C00),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD2691E).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _isLoadingRecipes ? null : _sendMoodMessage,
                    icon: _isLoadingRecipes
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded, 
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ],
            ),
          ),
          
          // Display generated recipes with animation
          if (_generatedRecipes.isNotEmpty) ...[
            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              child: Row(
                children: [
                  const Text('🍯', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Text(
                    'Sweet Recipes Just for You:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...(_generatedRecipes.asMap().entries.map((entry) {
              final index = entry.key;
              final recipe = entry.value;
              return AnimatedContainer(
                duration: Duration(milliseconds: 600 + (index * 200)),
                curve: Curves.easeOutBack,
                child: _buildRecipeCard(recipe),
              );
            }).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildAutumnBucketList() {
    final completedItems = _bucketListItems.where((item) => item['completed']).length;
    final totalItems = _bucketListItems.length;
    final progressPercentage = totalItems > 0 ? completedItems / totalItems : 0.0;
    
    // Filter items based on current filter
    final filteredItems = _currentBucketListFilter == 'all' 
        ? _bucketListItems 
        : _bucketListItems.where((item) => item['category'] == _currentBucketListFilter).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF8DC).withOpacity(0.9),
            const Color(0xFFFFE4B5).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFD2691E).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with progress
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD2691E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.checklist_rtl,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Autumn Bucket List 🍂',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    Text(
                      '$completedItems of $totalItems completed',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF8B4513).withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD2691E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD2691E).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$_totalBucketListPoints',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              height: 8,
              width: MediaQuery.of(context).size.width * progressPercentage * 0.8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD2691E),
                    const Color(0xFFFF8C00),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD2691E).withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '${(progressPercentage * 100).toInt()}% Complete',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF8B4513).withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Category filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All', '🍂'),
                const SizedBox(width: 8),
                _buildFilterChip('outdoor', 'Outdoor', '🌳'),
                const SizedBox(width: 8),
                _buildFilterChip('cozy', 'Cozy', '☕'),
                const SizedBox(width: 8),
                _buildFilterChip('social', 'Social', '👥'),
                const SizedBox(width: 8),
                _buildFilterChip('creative', 'Creative', '🎨'),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Bucket list items
          Column(
            children: [
              // Seasonal divider
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFD2691E).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _slideController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _slideController.value * 2 * math.pi,
                                child: const Text('🍁', style: TextStyle(fontSize: 14)),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          const Text('🌰', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          AnimatedBuilder(
                            animation: _fadeController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 0.8 + (_fadeController.value * 0.4),
                                child: const Text('🌲', style: TextStyle(fontSize: 10)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFD2691E).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bucket list items
              ...filteredItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  child: _buildBucketListItem(item),
                );
              }).toList(),
            ],
          ),
          
          // Motivational message based on progress
          if (completedItems > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD2691E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFD2691E).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Text(_getMotivationalEmoji(progressPercentage), 
                       style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getMotivationalMessage(progressPercentage),
                      style: const TextStyle(
                        color: Color(0xFF8B4513),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, String emoji) {
    final isSelected = _currentBucketListFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentBucketListFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFD2691E) 
              : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD2691E).withOpacity(0.3),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFD2691E).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF8B4513),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBucketListItem(Map<String, dynamic> item) {
    final isCompleted = item['completed'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isCompleted 
              ? const Color(0xFFD2691E).withOpacity(0.1)
              : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted 
                ? const Color(0xFFD2691E).withOpacity(0.5)
                : const Color(0xFFD2691E).withOpacity(0.2),
            width: isCompleted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted 
                  ? const Color(0xFFD2691E).withOpacity(0.2)
                  : Colors.brown.withOpacity(0.1),
              blurRadius: isCompleted ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _toggleBucketListItem(item['id']),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Checkbox with animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? const Color(0xFFD2691E)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFD2691E),
                        width: 2,
                      ),
                    ),
                    child: isCompleted 
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? const Color(0xFFD2691E).withOpacity(0.2)
                          : const Color(0xFFFFF8DC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item['icon'],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8B4513),
                            decoration: isCompleted 
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF8B4513).withOpacity(0.7),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Points badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? const Color(0xFFD2691E)
                          : const Color(0xFFD2691E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 12,
                          color: isCompleted 
                              ? Colors.white
                              : const Color(0xFFD2691E),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${item['points']}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCompleted 
                                ? Colors.white
                                : const Color(0xFFD2691E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getMotivationalEmoji(double progress) {
    if (progress >= 1.0) return '🎉';
    if (progress >= 0.75) return '🔥';
    if (progress >= 0.5) return '💪';
    if (progress >= 0.25) return '🌟';
    return '🍂';
  }

  String _getMotivationalMessage(double progress) {
    if (progress >= 1.0) {
      return 'Incredible! You\'ve completed your entire autumn bucket list! You\'re the ultimate fall adventurer! 🎉';
    } else if (progress >= 0.75) {
      return 'Amazing progress! You\'re almost there - just a few more autumn adventures to go! 🔥';
    } else if (progress >= 0.5) {
      return 'Fantastic! You\'re halfway through your autumn journey. Keep going, sweetie! 💪';
    } else if (progress >= 0.25) {
      return 'Great start! You\'re building wonderful autumn memories. Every activity counts! 🌟';
    } else {
      return 'Welcome to your autumn adventure! Each completed activity brings cozy rewards! 🍂';
    }
  }

  Widget _buildChatMessage(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    final messageText = message['message'] as String;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFF8DC),
              child: const Text('🍯', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser 
                    ? const Color(0xFFD2691E) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isUser 
                      ? Colors.transparent
                      : const Color(0xFFD2691E).withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? const Color(0xFFD2691E) : Colors.orange)
                        .withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                messageText,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF8B4513),
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF8B4513),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivitiesGrid() {
    final activities = [
      {'icon': '🎃', 'title': 'Pumpkin Spice', 'subtitle': 'Everything'},
      {'icon': '🍂', 'title': 'Leaf Peeping', 'subtitle': 'Nature walks'},
      {'icon': '📖', 'title': 'Cozy Reading', 'subtitle': 'By the fire'},
      {'icon': '🧶', 'title': 'Knitting Time', 'subtitle': 'Warm scarves'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'September Activities',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B4513),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    const Color(0xFFF5E6D3).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      activity['icon']!,
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      activity['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B4513),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity['subtitle']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF8B4513).withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReflectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF8B4513).withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_stories, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Daily Reflection',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'What made you smile today?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white30),
            ),
            child: const Text(
              'Tap to add your thoughts for September 15th...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, String> recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD2691E).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recipe['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD2691E).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recipe['cookingTime'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B4513),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recipe['description'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF654321),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.inventory_2_outlined, 
                size: 16, color: Color(0xFFD2691E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recipe['ingredients'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF654321),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, size: 16, color: Color(0xFFD2691E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recipe['moodMatch'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B4513),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCozyPomodoroTimer() {
    final progress = _isPomodoroMode 
        ? (_pomodoroMinutes * 60 - _remainingSeconds) / (_pomodoroMinutes * 60)
        : (_breakMinutes * 60 - _remainingSeconds) / (_breakMinutes * 60);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFE4B5).withOpacity(0.9),
            const Color(0xFFFFF8DC).withOpacity(0.9),
            const Color(0xFFDEB887).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD2691E).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFD2691E).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isPomodoroMode 
                      ? const Color(0xFFD2691E)
                      : const Color(0xFF228B22),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: AnimatedBuilder(
                  animation: _parallaxController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _parallaxController.value * math.pi * 0.2,
                      child: Icon(
                        _isPomodoroMode ? Icons.work : Icons.coffee,
                        color: Colors.white,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPomodoroMode ? 'Cozy Focus Time' : 'Autumn Break',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    Text(
                      _isPomodoroMode 
                          ? 'Stay focused, sweetie! 🍯' 
                          : 'Time to recharge! ☕',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF8B4513).withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              // Completed sessions counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD2691E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🍂', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$_completedPomodoros',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Main timer display
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    const Color(0xFFFFF8DC).withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD2691E).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress indicator
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isPomodoroMode 
                            ? const Color(0xFFD2691E)
                            : const Color(0xFF228B22),
                      ),
                    ),
                  ),
                  // Time display
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(_remainingSeconds),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isPomodoroMode ? 'Focus' : 'Break',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF8B4513).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Timer controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Start/Pause button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton.icon(
                  onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTimerRunning 
                        ? const Color(0xFFFF8C00)
                        : const Color(0xFFD2691E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                  icon: Icon(
                    _isTimerRunning ? Icons.pause : Icons.play_arrow,
                    size: 20,
                  ),
                  label: Text(
                    _isTimerRunning ? 'Pause' : 'Start',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              
              // Stop button
              ElevatedButton.icon(
                onPressed: _isTimerRunning ? _stopTimer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.stop, size: 20),
                label: const Text(
                  'Stop',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Ambient sound selector with play/pause
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD2691E).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Cozy Background Sounds 🎵',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    const Spacer(),
                    // Play/Pause button for ambient sounds
                    GestureDetector(
                      onTap: _toggleAmbientSound,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isPlayingAmbientSound 
                              ? const Color(0xFF228B22)
                              : const Color(0xFFD2691E),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (_isPlayingAmbientSound 
                                  ? const Color(0xFF228B22)
                                  : const Color(0xFFD2691E)).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPlayingAmbientSound ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _cozyTimerSounds.map((sound) {
                    final isSelected = _selectedSound == sound;
                    return GestureDetector(
                      onTap: () async {
                        if (_isPlayingAmbientSound) {
                          await _playAmbientSound(sound);
                        } else {
                          setState(() {
                            _selectedSound = sound;
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFFD2691E)
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFD2691E).withOpacity(0.3),
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: const Color(0xFFD2691E).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sound,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected 
                                    ? Colors.white 
                                    : const Color(0xFF8B4513),
                              ),
                            ),
                            if (isSelected && _isPlayingAmbientSound) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.volume_up,
                                size: 12,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_isPlayingAmbientSound) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF228B22).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF228B22).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.headphones,
                              size: 16,
                              color: Color(0xFF228B22),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Playing cozy sounds... 🎧',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF228B22),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Volume control
                        Row(
                          children: [
                            const Icon(
                              Icons.volume_down,
                              size: 16,
                              color: Color(0xFF8B4513),
                            ),
                            Expanded(
                              child: Slider(
                                value: _ambientVolume,
                                min: 0.0,
                                max: 1.0,
                                divisions: 20,
                                activeColor: const Color(0xFFD2691E),
                                inactiveColor: const Color(0xFFD2691E).withOpacity(0.3),
                                onChanged: (value) async {
                                  setState(() {
                                    _ambientVolume = value;
                                  });
                                  if (_isPlayingAmbientSound) {
                                    await _audioPlayer.setVolume(_ambientVolume);
                                  }
                                },
                              ),
                            ),
                            const Icon(
                              Icons.volume_up,
                              size: 16,
                              color: Color(0xFF8B4513),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Timer settings
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTimeSettingCard(
                isPomodoro: true,
                title: '🍂 Focus Time',
                minutes: _pomodoroMinutes,
                options: [15, 25, 45, 60],
                onChanged: (newMinutes) {
                  setState(() {
                    _pomodoroMinutes = newMinutes;
                    if (!_isTimerRunning) {
                      _resetTimer();
                    }
                  });
                },
              ),
              const SizedBox(width: 12),
              _buildTimeSettingCard(
                isPomodoro: false,
                title: '☕ Break Time',
                minutes: _breakMinutes,
                options: [5, 10, 15],
                onChanged: (newMinutes) {
                  setState(() {
                    _breakMinutes = newMinutes;
                    if (!_isTimerRunning) {
                      _resetTimer();
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSettingCard({
    required bool isPomodoro,
    required String title,
    required int minutes,
    required List<int> options,
    required ValueChanged<int> onChanged,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: PopupMenuButton<int>(
          onSelected: onChanged,
          itemBuilder: (context) => options.map((option) {
            return PopupMenuItem<int>(
              value: option,
              child: Text('$option minutes'),
            );
          }).toList(),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B4513),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$minutes min',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Color(0xFF8B4513)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScatterLeaves() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _scatterController,
          builder: (context, child) {
            // Update physics for all scatter leaves
            final deltaTime = 1.0 / 60.0; // Assume 60 FPS
            _scatterLeaves.removeWhere((leaf) {
              leaf.updatePhysics(deltaTime);
              return leaf.isExpired;
            });
            
            return Stack(
              children: _scatterLeaves.map((leaf) {
                return Positioned(
                  left: leaf.position.dx,
                  top: leaf.position.dy,
                  child: Transform.rotate(
                    angle: leaf.rotation,
                    child: Opacity(
                      opacity: leaf.opacity,
                      child: Text(
                        leaf.emoji,
                        style: TextStyle(
                          fontSize: leaf.size,
                          shadows: [
                            Shadow(
                              blurRadius: 3.0,
                              color: Colors.brown.withOpacity(0.4),
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
