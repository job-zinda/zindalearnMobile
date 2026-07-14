import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../providers/enrollment_provider.dart';
import '../providers/message_provider.dart';
import 'home_screen.dart';
import 'browse_courses_screen.dart';
import 'my_learning_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Warm up the catalog + enrollments once so tabs feel instant, and
    // connect the messaging socket so unread badges work app-wide.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courses = context.read<CourseProvider>();
      if (courses.state == LoadState.idle) {
        courses.loadCourses(refresh: true);
      }
      final enrollments = context.read<EnrollmentProvider>();
      if (enrollments.state == LoadState.idle) {
        enrollments.loadEnrollments(refresh: true);
      }
      final messages = context.read<MessageProvider>();
      messages.connect();
      if (messages.conversationsState == LoadState.idle) {
        messages.loadConversations(refresh: true);
      }
    });
  }

  void _onNavTap(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(onNavTap: _onNavTap),
      BrowseCoursesScreen(onNavTap: _onNavTap, currentIndex: 1),
      MyLearningScreen(onNavTap: _onNavTap, currentIndex: 2),
      MessagesScreen(onNavTap: _onNavTap),
      ProfileScreen(onNavTap: _onNavTap),
    ];
    return IndexedStack(
      index: _index,
      children: [
        for (var i = 0; i < tabs.length; i++)
          TickerMode(enabled: i == _index, child: tabs[i]),
      ],
    );
  }
}
