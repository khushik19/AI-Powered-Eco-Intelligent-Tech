class AppConstants {
  static const String appName = 'Clean Cosmos';

  // Facts — no emojis
  static const List<String> sustainabilityFacts = [
    'Recycling one aluminum can saves enough energy to run a TV for 3 hours.',
    'A 5-minute shower uses 10 gallons less water than a bath.',
    'One tree absorbs around 48 lbs of CO₂ per year.',
    'Glass can be recycled endlessly without losing purity.',
    'Cycling 10 km instead of driving saves about 2.6 kg of CO₂.',
    'LEDs use 75% less energy than incandescent bulbs.',
    '80% of ocean pollution comes from land-based activities.',
    'Solar panels on 1% of the Sahara could power all of Europe.',
    'Composting diverts 30% of household waste from landfills.',
    'The fashion industry produces 10% of global carbon emissions.',
  ];

  static const List<Map<String, dynamic>> categories = [
    {
      'id': 'cut_waste',
      'title': 'Cut Waste',
      'icon': '♻️',
      'color': 0xFF839958,
      'activities': [
        'Started composting at home',
        'Reduced single-use plastic usage',
        'Donated old electronics for recycling',
        'Used reusable bags for shopping',
        'Repaired instead of replaced a product',
        'Organised a waste collection drive',
      ],
    },
    {
      'id': 'optimize_resources',
      'title': 'Optimize Resources',
      'icon': '💧',
      'color': 0xFF105666,
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
      'color': 0xFF0A3323,
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

  // Role-based suggestions
  static const Map<String, List<Map<String, String>>> roleChatSuggestions = {
    'individual': [
      {'q': 'How do I start composting at home?'},
      {'q': 'What is the easiest way to reduce plastic use?'},
      {'q': 'How much CO₂ does cycling save vs driving?'},
      {'q': 'Tips for saving water at home?'},
      {'q': 'How to properly recycle e-waste?'},
      {'q': 'What are the best sustainable swaps for daily life?'},
    ],
    'student_employee': [
      {'q': 'How can I make my campus more sustainable?'},
      {'q': 'What eco habits can I build at my workplace?'},
      {'q': 'How do I convince my institution to go green?'},
      {'q': 'What is a carbon footprint and how do I reduce mine?'},
      {'q': 'Best ways to reduce food waste at a canteen?'},
      {'q': 'How can student clubs drive environmental change?'},
    ],
    'college_org': [
      {'q': 'How can our organisation reduce its carbon footprint?'},
      {'q': 'What sustainability certifications should we pursue?'},
      {'q': 'How to set up a campus recycling programme?'},
      {'q': 'Best ways to track institutional sustainability metrics?'},
      {'q': 'How to engage students in sustainability initiatives?'},
      {'q': 'What are the best green energy options for institutions?'},
    ],
  };

  // Fallback suggestions if role is unknown
  static const List<Map<String, String>> chatSuggestions = [
    {'q': 'How do I start composting at home?'},
    {'q': 'What is the easiest way to reduce plastic use?'},
    {'q': 'How much CO₂ does cycling save vs driving?'},
    {'q': 'Tips for saving water at home?'},
    {'q': 'How to properly recycle e-waste?'},
    {'q': 'What are the best sustainable swaps for daily life?'},
  ];

  static List<Map<String, String>> suggestionsForRole(String? role) {
    return roleChatSuggestions[role] ?? chatSuggestions;
  }
}