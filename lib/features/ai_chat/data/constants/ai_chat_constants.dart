const volleyballAiSystemPrompt = '''
You are a professional volleyball strength and conditioning coach.

You ONLY provide:
- volleyball exercises
- workout routines
- warm-ups and cooldowns
- vertical jump training
- agility drills
- strength training
- recovery exercises
- simple fitness guidance for volleyball players

Rules:
- Do NOT answer unrelated questions
- Keep answers focused on volleyball training
- Give short, structured, actionable responses
- Use bullet points when helpful
- Include sets, reps, duration, and rest time when possible
- Keep advice safe for beginners and intermediate players
- Do not act like a general assistant

Always format responses in this structure when possible:

Workout Name:
Goal:
Exercises:
Rest:
Notes:
''';

const huggingFaceChatModel = 'openai/gpt-oss-20b';

const aiChatQuickSuggestions = <String>[
  'Leg workout for volleyball',
  'Improve vertical jump',
  'Warm-up before match',
  'Recovery after training',
  'Agility drills',
];

const volleyballExercisesWelcomeMessage = '''
Hi! I'm your Volleyball Exercises Assistant.
I can help you with:
- leg workouts for volleyball
- vertical jump drills
- warm-ups before matches
- recovery after training
- agility and strength exercises

Try asking:
- Give me a leg workout for volleyball
- How can I improve my vertical jump?
- Give me a warm-up before a match
''';

const exerciseOnlyRedirectMessage = '''
I can help with volleyball workouts, jump training, warm-ups, agility drills, strength sessions, recovery exercises, and simple fitness guidance for players.

- Try asking for a leg workout for volleyball
- Ask for a warm-up before a match
- Request a recovery routine after training
''';

const exerciseTopicKeywords = <String>[
  'volleyball',
  'exercise',
  'exercises',
  'workout',
  'workouts',
  'routine',
  'routines',
  'plan',
  'plans',
  'program',
  'programs',
  'warm-up',
  'warm up',
  'warmup',
  'cooldown',
  'cool-down',
  'cool down',
  'stretch',
  'stretches',
  'activation',
  'jump',
  'vertical',
  'agility',
  'drill',
  'drills',
  'strength',
  'recovery',
  'recover',
  'mobility',
  'conditioning',
  'plyometric',
  'plyometrics',
  'speed',
  'explosive',
  'power',
  'leg',
  'legs',
  'core',
  'shoulder',
  'ankle',
  'knee',
  'serve',
  'spike',
  'hitting',
  'hitter',
  'approach',
  'landing',
  'training',
  'practice',
  'session',
  'sessions',
  'fitness',
  'rest',
  'sets',
  'reps',
];
