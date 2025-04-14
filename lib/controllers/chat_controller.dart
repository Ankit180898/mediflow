import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mediflow/models/chat_report_model.dart';
import 'package:mediflow/models/message_model.dart';

class ChatController extends GetxController {
  final String _geminiApiKey = dotenv.env['API_KEY'] ?? '';
  final String _geminiEndpoint =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

  final List<Map<String, dynamic>> _conversationHistory = [];

  // Observable variables to track conversation state
  final RxBool isProcessing = false.obs;
  final RxString currentStage = "".obs;
  final RxList<String> collectedInfo = <String>[].obs;

  // Stages of information collection
  final List<String> _stages = [
    "introduction",
    "primary_concern",
    "symptoms_details",
    "medical_history",
    "medications",
    "patient_goals",
    "conclusion",
  ];

  int _currentStageIndex = 0;

  // Initializes conversation with the system prompt
  void initializeConversation(
    String promptType,
    Map<String, dynamic>? patientData,
  ) {
    _conversationHistory.clear();
    _currentStageIndex = 0;
    currentStage.value = _stages[_currentStageIndex];
    collectedInfo.clear();

    final systemPrompt = _getSystemPrompt(promptType, patientData);

    _conversationHistory.add({
      "role": "user",
      "parts": [
        {"text": systemPrompt},
      ],
    });

    // Add specific instructions for one-question-at-a-time approach
    _conversationHistory.add({
      "role": "user",
      "parts": [
        {
          "text": """
Important instructions:
1. Ask ONLY ONE question at a time.
2. Wait for the patient to answer before asking the next question.
3. Address patients respectfully and professionally.
4. Provide nominal diagnosis or medical advice & prompt for doctor's assistance.
5. Follow a structured conversation flow to collect information about:
   - Chief complaint/reason for visit
   - Symptom details (duration, severity, triggers)
   - Relevant medical history
   - Current medications
   - Patient's concerns and goals

Start by introducing yourself briefly and asking ONLY about their primary concern or reason for the visit.
""",
        },
      ],
    });
  }

  Future<Message> startConversation() async {
    try {
      isProcessing.value = true;

      final response = await http.post(
        Uri.parse("$_geminiEndpoint?key=$_geminiApiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": _conversationHistory,
          "generationConfig": {
            "temperature": 0.5,
            "topK": 32,
            "topP": 0.95,
            "maxOutputTokens": 800, // Limiting tokens to keep responses shorter
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

        if (reply != null) {
          final cleanReply = _formatMarkdown(reply.trim());

          // Add model response to history
          _conversationHistory.add({
            "role": "model",
            "parts": [
              {"text": cleanReply},
            ],
          });

          return Message(
            content: cleanReply,
            sender: 'assistant',
            dateTime: DateTime.now(),
          );
        } else {
          throw Exception("Gemini response missing content.");
        }
      } else {
        final errMsg = _extractError(response.body);
        throw Exception("Gemini API error: $errMsg");
      }
    } catch (e) {
      throw Exception('Error starting conversation: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<Message> sendMessage({required String message}) async {
    try {
      isProcessing.value = true;

      // Process user message and track conversation progress
      _trackUserResponse(message);

      // Add user message to history
      _conversationHistory.add({
        "role": "user",
        "parts": [
          {"text": message},
        ],
      });

      // Add guidance for the AI based on current stage
      _addStageGuidance();

      final response = await http.post(
        Uri.parse("$_geminiEndpoint?key=$_geminiApiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": _conversationHistory,
          "generationConfig": {
            "temperature": 0.5,
            "topK": 32,
            "topP": 0.95,
            "maxOutputTokens": 800, // Limiting tokens for shorter responses
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

        if (reply != null) {
          final cleanReply = _formatMarkdown(reply.trim());

          // Add model response to history
          _conversationHistory.add({
            "role": "model",
            "parts": [
              {"text": cleanReply},
            ],
          });

          // Move to next stage if necessary
          _progressConversation(cleanReply);

          return Message(
            content: cleanReply,
            sender: 'assistant',
            dateTime: DateTime.now(),
          );
        } else {
          throw Exception("Gemini response missing content.");
        }
      } else {
        final errMsg = _extractError(response.body);
        throw Exception("Gemini API error: $errMsg");
      }
    } catch (e) {
      throw Exception('Error in Gemini chat service: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  void _trackUserResponse(String message) {
    // Store user response with the current stage
    collectedInfo.add("[$currentStage.value] $message");

    // Basic analysis can be added here to determine if response was sufficient
  }

  void _progressConversation(String aiResponse) {
    // Logic to determine if we should move to the next stage
    bool containsQuestion = aiResponse.contains('?');

    // Check if we're at the end of a stage and should move to the next
    if (_currentStageIndex < _stages.length - 1 &&
        _shouldAdvanceStage(aiResponse)) {
      _currentStageIndex++;
      currentStage.value = _stages[_currentStageIndex];
    }
  }

  bool _shouldAdvanceStage(String aiResponse) {
    // This is a simple implementation - in a real app, you'd want more sophisticated logic
    // For example, check if the AI is transitioning topics in its questions

    // Examples of transition phrases that might indicate moving to the next stage
    final List<String> transitionPhrases = [
      "Now I'd like to ask about",
      "Let's move on to",
      "Turning to",
      "Shifting focus to",
      "Let's discuss your medical history",
      "What medications are you currently taking",
      "What are your goals for this visit",
    ];

    return transitionPhrases.any((phrase) => aiResponse.contains(phrase));
  }

  void _addStageGuidance() {
    // Add specific guidance based on the current stage
    String guidance = '';

    switch (currentStage.value) {
      case "introduction":
        guidance =
            "Introduce yourself briefly and ask ONLY about their primary concern.";
        break;
      case "primary_concern":
        guidance =
            "Ask ONE focused question about their main symptom or concern.";
        break;
      case "symptoms_details":
        guidance =
            "Ask ONE question about duration, severity, or triggers of their symptoms.";
        break;
      case "medical_history":
        guidance = "Ask ONE question about relevant medical history.";
        break;
      case "medications":
        guidance = "Ask ONE question about current medications.";
        break;
      case "patient_goals":
        guidance =
            "Ask ONE question about what the patient hopes to achieve from their visit.";
        break;
      case "conclusion":
        guidance =
            "Summarize the information gathered and conclude the conversation.";
        break;
    }

    if (guidance.isNotEmpty) {
      _conversationHistory.add({
        "role": "user",
        "parts": [
          {
            "text":
                "GUIDANCE (invisible to user): $guidance. Remember to ask only ONE question.",
          },
        ],
      });
    }
  }

  // Format markdown properly
  String _formatMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'#([^ ])'), r'# $1')
        .replaceAll(RegExp(r'-([^ ])'), r'- $1')
        .replaceAll(RegExp(r'(\d+)\.([^ ])'), r'$1. $2');
  }

  // Extract error message
  String _extractError(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      return data['error']['message'] ?? 'Unknown error';
    } catch (_) {
      return 'Service unavailable';
    }
  }

  // Report generation via chat (using Gemini)
  Future<ChatReport> generateReport({
    required List<Message> chatHistory,
    required String promptType,
    required Map<String, dynamic> patientData,
  }) async {
    try {
      final systemPrompt = '''
You are a medical assistant generating a structured report based on a patient conversation.
Create a concise, professional medical report summarizing the key information.

The report should be in Markdown format and include:
1. Patient Information
2. Reason for Visit / Main Complaint
3. Reported Symptoms
4. Relevant Medical History
5. Current Medications
6. Patient's Concerns/Goals
7. Info about the reported symptoms
      ''';

      final historyText = chatHistory
          .map(
            (m) =>
                "${m.sender == 'User' ? 'Patient' : 'Assistant'}: ${m.content}",
          )
          .join("\n\n");

      final prompt = '''
Patient Data: ${jsonEncode(patientData)}

Conversation:
$historyText

Generate a structured report based on this.
      ''';

      final reportConversation = [
        {
          "role": "user",
          "parts": [
            {"text": systemPrompt},
          ],
        },
        {
          "role": "user",
          "parts": [
            {"text": prompt},
          ],
        },
      ];

      final response = await http.post(
        Uri.parse("$_geminiEndpoint?key=$_geminiApiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": reportConversation,
          "generationConfig": {
            "temperature": 0.3,
            "topK": 32,
            "topP": 0.9,
            "maxOutputTokens": 2048,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

        if (content != null) {
          return ChatReport(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: content,
            timestamp: DateTime.now(),
            type: promptType,
            patientId: patientData['id'],
            doctorId: patientData['doctorId'],
          );
        } else {
          throw Exception("No report generated.");
        }
      } else {
        throw Exception("Failed to generate report: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error generating report: $e");
    }
  }

  String _getSystemPrompt(
    String promptType,
    Map<String, dynamic>? patientData,
  ) {
    String basePrompt = '''
You are a healthcare assistant collecting information from patients.
IMPORTANT: Ask only ONE question at a time and wait for the patient to respond before continuing.
Be empathetic, professional, and clear.
Offer a bit of medical advice, diagnosis, or treatment suggestions when absolutely necessary.
Focus solely on gathering information in a structured way for the healthcare provider.
    ''';

    switch (promptType) {
      case 'acute_symptom':
        return '''
$basePrompt

You are specifically collecting information about acute symptoms.
Guide the conversation to cover:
- The primary symptom/complaint
- Duration and onset
- Intensity and patterns
- Triggers or alleviating factors
- Associated symptoms
        ''';

      case 'chronic_condition':
        return '''
$basePrompt

You are specifically checking in on a chronic condition.
Guide the conversation to cover:
- Recent changes in symptoms
- Adherence to treatment plan
- Impact on daily activities
- Emotional well-being
        ''';

      default:
        return basePrompt;
    }
  }
}
