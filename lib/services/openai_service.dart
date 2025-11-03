import 'package:openai_dart/openai_dart.dart';
import '../utils/logger.dart';
import 'ai_data_service.dart';

class OpenAIService {
  static OpenAIService? _instance;
  static OpenAIService get instance => _instance ??= OpenAIService._();
  
  OpenAIService._();
  
  late OpenAIClient _client;
  final AIDataService _aiDataService = AIDataService.instance;
  
  // Initialize OpenAI client
  void initialize(String apiKey) {
    _client = OpenAIClient(
      apiKey: apiKey,
    );
  }
  
  // Generate AI response for travel-related conversations with database context
  Future<String> generateTravelResponse(String userMessage, {List<String>? conversationHistory, String? userId}) async {
    try {
      // Check if query requires database lookup and get context
      String databaseContext = '';
      if (_aiDataService.requiresDataLookup(userMessage)) {
        databaseContext = await _aiDataService.generateContextString(userMessage, userId: userId);
      }

      final messages = <ChatCompletionMessage>[
        ChatCompletionMessage.system(
          content: '''
You are TraverseAI, the intelligent assistant for the Traverse app - your ultimate travel companion! 

I'm here to help you with everything travel-related:
🌍 **Trip Planning**: Destinations, itineraries, best times to visit
🏨 **Bookings**: Hotels, flights, activities, car rentals
💰 **Budget Planning**: Cost estimates, money-saving tips
🎯 **Personalized Recommendations**: Based on your preferences and travel style
📱 **App Features**: Navigate through Traverse's booking system, wallet, profile management
🌟 **Local Insights**: Culture, customs, hidden gems, safety tips
📊 **Travel Analytics**: Track your trips, expenses, and travel patterns
💬 **Social Features**: Connect with fellow travelers, share experiences

I represent the entire Traverse ecosystem and can guide you through:
- Hotel & flight bookings
- Activity reservations
- Car rental services
- Wallet and payment management
- Travel community features
- Trip planning and organization

I'm friendly, knowledgeable, and always excited to help you explore the world! 
Keep responses engaging and helpful (2-4 sentences unless detailed info is requested).

${databaseContext.isNotEmpty ? '\n\nCURRENT DATABASE CONTEXT:\n$databaseContext\n\nUse this real-time data to provide accurate, up-to-date information in your responses. Reference specific places, events, or bookings when relevant.' : ''}
''',
        ),
      ];
      
      // Add conversation history if provided
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        for (int i = 0; i < conversationHistory.length; i++) {
          if (i % 2 == 0) {
            messages.add(ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(conversationHistory[i]),
            ));
          } else {
            messages.add(ChatCompletionMessage.assistant(content: conversationHistory[i]));
          }
        }
      }
      
      // Add current user message
      messages.add(ChatCompletionMessage.user(
        content: ChatCompletionUserMessageContent.string(userMessage),
      ));
      
      final response = await _client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: const ChatCompletionModel.modelId('gpt-3.5-turbo'),
          messages: messages,
          maxTokens: 250, // Increased for more detailed responses with context
          temperature: 0.7,
        ),
      );
      
      final content = response.choices.first.message.content;
      if (content is String) {
        return content.trim();
      }
      return 'I\'m here to help with your travel plans! What would you like to know?';
    } catch (e) {
      Logger.error('Error generating AI response', e);
      return 'I\'m having trouble connecting right now. Please try again later!';
    }
  }
  
  // Generate travel recommendations based on user preferences with database context
  Future<String> generateTravelRecommendations({
    required String destination,
    required String budget,
    required String interests,
    required int duration,
    String? userId,
  }) async {
    try {
      // Get relevant database context for the destination
      final databaseContext = await _aiDataService.generateContextString(
        'recommendations for $destination $interests', 
        userId: userId
      );

      final prompt = '''
Generate travel recommendations for:
Destination: $destination
Budget: $budget
Interests: $interests
Duration: $duration days

${databaseContext.isNotEmpty ? 'Use this current data about the destination:\n$databaseContext\n' : ''}

Provide 3-4 specific recommendations with brief descriptions.''';
      
      final response = await _client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: const ChatCompletionModel.modelId('gpt-3.5-turbo'),
          messages: [
            ChatCompletionMessage.system(
              content: 'You are a travel expert providing personalized recommendations based on real-time data.',
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(prompt),
            ),
          ],
          maxTokens: 300, // Increased for more detailed recommendations
          temperature: 0.8,
        ),
      );
      
      final content = response.choices.first.message.content;
      if (content is String) {
        return content.trim();
      }
      return 'I\'d be happy to help you plan your trip! Please provide more details.';
    } catch (e) {
      Logger.error('Error generating travel recommendations', e);
      return 'Unable to generate recommendations at the moment. Please try again later.';
    }
  }
  
  // Generate travel itinerary with database context
  Future<String> generateItinerary({
    required String destination,
    required int days,
    required String interests,
    String? userId,
  }) async {
    try {
      // Get relevant database context for the destination
      final databaseContext = await _aiDataService.generateContextString(
        'itinerary for $destination $interests', 
        userId: userId
      );

      final prompt = '''
Create a $days-day travel itinerary for $destination.
Interests: $interests

${databaseContext.isNotEmpty ? 'Use this current data about the destination:\n$databaseContext\n' : ''}

Format as a day-by-day plan with activities and timing.''';
      
      final response = await _client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: const ChatCompletionModel.modelId('gpt-3.5-turbo'),
          messages: [
            ChatCompletionMessage.system(
              content: 'You are a travel planner creating detailed itineraries based on real-time data and current attractions.',
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(prompt),
            ),
          ],
          maxTokens: 400, // Increased for detailed itineraries
          temperature: 0.7,
        ),
      );
      
      final content = response.choices.first.message.content;
      if (content is String) {
        return content.trim();
      }
      return 'I can help you create an amazing itinerary! Please share your preferences.';
    } catch (e) {
      Logger.error('Error generating itinerary', e);
      return 'Unable to create itinerary right now. Please try again later.';
    }
  }
}