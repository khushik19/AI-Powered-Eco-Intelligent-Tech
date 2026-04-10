class AppConstants {
  static const String appName = 'Clean Cosmos';
  
  static const List<String> sustainabilityFacts = [
    '🌿 Recycling one aluminum can saves enough energy to run a TV for 3 hours.',
    '💧 A 5-minute shower uses 10 gallons less water than a bath.',
    '🌳 One tree absorbs ~48 lbs of CO₂ per year.',
    '♻️ Glass can be recycled endlessly without losing purity.',
    '🚲 Cycling 10 km instead of driving saves ~2.6 kg of CO₂.',
    '💡 LEDs use 75% less energy than incandescent bulbs.',
    '🌊 80% of ocean pollution comes from land-based activities.',
    '☀️ Solar panels on 1% of the Sahara could power all of Europe.',
    '🍃 Composting diverts 30% of household waste from landfills.',
    '🌍 The fashion industry produces 10% of global carbon emissions.',
  ];
  
  static const List<Map<String, dynamic>> categories = [
    {
      'id': 'cut_waste',
      'title': 'Cut Waste',
      'icon': '♻️',
      'color': 0xFF06D6A0,
      'activities': [
        'Started composting at home',
        'Reduced single-use plastic usage',
        'Donated old electronics for recycling',
        'Used reusable bags for shopping',
        'Repaired instead of replaced a product',
        'Organized a waste collection drive',
      ],
    },
    {
      'id': 'optimize_resources',
      'title': 'Optimize Resources',
      'icon': '💧',
      'color': 0xFF4FC3F7,
      'activities': [
        'Installed water-saving fixtures',
        'Fixed a leaking tap',
        'Used rainwater harvesting',
        'Reduced shower time by 5 minutes',
        'Switched to LED lighting',
        'Used natural light during day',
      ],
    },
    {
      'id': 'lower_emissions',
      'title': 'Lower Emissions',
      'icon': '🌱',
      'color': 0xFF7B5EA7,
      'activities': [
        'Cycled to work or college',
        'Used public transport',
        'Planted a tree',
        'Switched to a plant-based meal',
        'Carpooled with friends',
        'Turned off devices when not in use',
      ],
    },
  ];

  static const List<Map<String, String>> chatSuggestions = [
    {'q': 'How do I start composting at home?'},
    {'q': 'What is the easiest way to reduce plastic use?'},
    {'q': 'How much CO₂ does cycling save vs driving?'},
    {'q': 'Tips for saving water at home?'},
    {'q': 'How to properly recycle e-waste?'},
    {'q': 'What are the best sustainable swaps for daily life?'},
  ];
}