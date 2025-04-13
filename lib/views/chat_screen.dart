import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../controllers/chat_controller.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatelessWidget {
  final ChatController chatController = Get.put(ChatController());
  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode inputFocusNode = FocusNode();

  ChatScreen({super.key});

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.health_and_safety, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              "Medical Assistant",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmClearChat(context),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            _buildInfoBanner(),
            Expanded(
              child: Obx(() {
                if (chatController.messages.isEmpty) {
                  return _buildWelcomeScreen();
                }
                _scrollToBottom();
                return ListView.builder(
                  controller: scrollController,
                  itemCount: chatController.messages.length,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 10,
                  ),
                  itemBuilder: (context, index) {
                    Message msg = chatController.messages[index];
                    return _buildMessageItem(msg, context, index);
                  },
                );
              }),
            ),
            _buildInputArea(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.red.shade50,
      child: Row(
        children: [
          Icon(Icons.medical_information, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Not a substitute for professional medical advice. Consult a doctor for diagnosis and treatment.",
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.health_and_safety,
                size: 80,
                color: Colors.teal.shade600,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Medical Assistant",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Ask health-related questions and get information about symptoms, conditions, and general medical advice",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "Try asking:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 20),
            _buildSuggestedQueries(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedQueries() {
    List<String> suggestions = [
      "What are symptoms of the flu?",
      "Should I see a doctor for my headache?",
      "How can I reduce fever at home?",
      // "What specialist treats back pain?",
      // "How can I prepare for my doctor appointment?",
      // "Are there home remedies for allergies?"
    ];

    return SizedBox(
      width: Get.width * 0.9,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children:
            suggestions.map((suggestion) {
              return InkWell(
                onTap: () {
                  inputController.text = suggestion;
                  chatController.sendMessage(suggestion);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildMessageItem(Message msg, BuildContext context, int index) {
    bool isUser = msg.sender == "user";
    String timeStr = DateFormat('h:mm a').format(msg.dateTime);

    return GestureDetector(
      onLongPress: () {
        if (!isUser && msg.content != "Typing...") {
          // _showMessageActions(context, msg);
        }
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Get.width * 0.8),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(2), // Thin border effect
            decoration: BoxDecoration(
              gradient:
                  isUser
                      ? LinearGradient(
                        colors: [Colors.teal.shade300, Colors.teal.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : null,
              color: isUser ? null : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
              border:
                  isUser
                      ? null
                      : Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color:
                    isUser
                        ? Colors.transparent
                        : (msg.content == "Typing..."
                            ? Colors.grey.shade100
                            : Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.content == "Typing...")
                      _buildTypingIndicator()
                    else
                      _buildMessageContent(msg, isUser, context),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isUser && msg.content != "Typing...")
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.more_horiz,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    isUser
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // void _showMessageActions(BuildContext context, Message msg) {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) => ActionSheet(
  //       message: msg,
  //       onSaveNote: () {
  //         chatController.saveToNotes(msg);
  //         Navigator.pop(context);
  //         Get.snackbar(
  //           "Saved to Notes",
  //           "The message has been saved to your notes",
  //           snackPosition: SnackPosition.BOTTOM,
  //           backgroundColor: Colors.teal.shade100,
  //           margin: EdgeInsets.all(16),
  //           duration: Duration(seconds: 2),
  //         );
  //       },
  //       onCreateReminder: () {
  //         Navigator.pop(context);
  //         _showReminderDialog(context, msg);
  //       },
  //       onCopy: () {
  //         chatController.copyToClipboard(msg.content);
  //         Navigator.pop(context);
  //         Get.snackbar(
  //           "Copied",
  //           "Text copied to clipboard",
  //           snackPosition: SnackPosition.BOTTOM,
  //           margin: EdgeInsets.all(16),
  //           duration: Duration(seconds: 2),
  //         );
  //       },
  //       onShare: () {
  //         chatController.shareContent(msg.content);
  //         Navigator.pop(context);
  //       },
  //     ),
  //   );
  // }

  void _showReminderDialog(BuildContext context, Message msg) {
    final titleController = TextEditingController(text: "Medical Reminder");
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay(hour: 9, minute: 0);

    dateController.text = DateFormat('MMM dd, yyyy').format(selectedDate);
    timeController.text = selectedTime.format(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Create Reminder"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (picked != null) {
                        selectedDate = picked;
                        dateController.text = DateFormat(
                          'MMM dd, yyyy',
                        ).format(picked);
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: dateController,
                        decoration: InputDecoration(
                          labelText: "Date",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        selectedTime = picked;
                        timeController.text = picked.format(context);
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: timeController,
                        decoration: InputDecoration(
                          labelText: "Time",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Reminder note (excerpt):",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      msg.content.length > 100
                          ? "${msg.content.substring(0, 100)}..."
                          : msg.content,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text("Add to Calendar"),
                onPressed: () {
                  DateTime reminderDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  // chatController.createCalendarEvent(
                  //   title: titleController.text,
                  //   description: msg.content,
                  //   startTime: reminderDateTime,
                  //   endTime: reminderDateTime.add(Duration(hours: 1)),
                  // );

                  Navigator.pop(context);

                  Get.snackbar(
                    "Reminder Created",
                    "Your medical reminder has been added to calendar",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.teal.shade100,
                    margin: EdgeInsets.all(16),
                    duration: Duration(seconds: 2),
                    mainButton: TextButton(
                      child: Text(
                        "VIEW",
                        style: TextStyle(color: Colors.teal.shade700),
                      ),
                      onPressed: () {
                        // chatController.openCalendarApp();
                      },
                    ),
                  );
                },
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Typing", style: TextStyle(color: Colors.grey)),
        const SizedBox(width: 8),
        _buildDot(0),
        _buildDot(1),
        _buildDot(2),
      ],
    );
  }

  Widget _buildDot(int index) {
    return Obx(() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        height: 8,
        width: 8,
        decoration: BoxDecoration(
          color:
              chatController.dotAnimationIndex.value == index
                  ? Colors.teal
                  : Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
      );
    });
  }

  Widget _buildMessageContent(Message msg, bool isUser, BuildContext context) {
    if (isUser) {
      // For user messages, use simple text
      return Text(
        msg.content,
        style: TextStyle(fontSize: 16, color: Colors.white),
      );
    } else {
      // For bot messages, use Markdown renderer
      return MarkdownBody(
        data: msg.content,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(fontSize: 16, height: 1.4),
          h1: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
          h2: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
          h3: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
          strong: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
          em: TextStyle(fontStyle: FontStyle.italic),
          listBullet: TextStyle(fontSize: 16, color: Colors.teal.shade800),
          blockquote: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade700,
          ),
        ),
        onTapLink: (text, href, title) async {
          if (href != null) {
            final url = Uri.parse(href);
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          }
        },
      );
    }
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: inputController,
                    focusNode: inputFocusNode,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        chatController.sendMessage(text);
                        inputController.clear();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "Type your health question...",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.mic, color: Colors.grey.shade600),
                        onPressed: () {
                          // Voice input functionality could be added here
                          Get.snackbar(
                            "Voice Input",
                            "Voice input feature coming soon",
                            snackPosition: SnackPosition.BOTTOM,
                            margin: EdgeInsets.all(16),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade300, Colors.teal.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () {
                      String text = inputController.text.trim();
                      if (text.isNotEmpty) {
                        chatController.sendMessage(text);
                        inputController.clear();
                        inputFocusNode.requestFocus();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => SizedBox(
            width: double.infinity,
            child: AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.teal),
                  SizedBox(width: 10),
                  Text("How to Use Medical \nAssistant"),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHelpItem(
                      Icons.question_answer_outlined,
                      "Ask Questions",
                      "Describe your symptoms or ask health-related questions",
                    ),
                    _buildHelpItem(
                      Icons.medical_services_outlined,
                      "Get Information",
                      "Learn about potential causes and general health information",
                    ),
                    _buildHelpItem(
                      Icons.calendar_today_outlined,
                      "Create Reminders",
                      "Long-press on any assistant response to create calendar reminders",
                    ),
                    _buildHelpItem(
                      Icons.note_outlined,
                      "Save Notes",
                      "Long-press on responses to save important information to notes",
                    ),
                    _buildHelpItem(
                      Icons.warning_amber_outlined,
                      "Not For Emergencies",
                      "If you have a medical emergency, call 911 or your local emergency number",
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Close", style: TextStyle(color: Colors.teal)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearChat(BuildContext context) {
    if (chatController.messages.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Clear Conversation"),
            content: Text(
              "Are you sure you want to clear the entire conversation history?",
            ),
            actions: [
              TextButton(
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text(
                  "Clear",
                  style: TextStyle(color: Colors.red.shade700),
                ),
                onPressed: () {
                  chatController.clearMessages();
                  Navigator.of(context).pop();
                },
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );
  }
}
