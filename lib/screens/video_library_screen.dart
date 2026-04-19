import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class VideoLibraryScreen extends StatefulWidget {
  const VideoLibraryScreen({super.key});
  @override
  State<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends State<VideoLibraryScreen> {
  String _selected = 'All';

  final _categories = ['All', 'HIIT', 'Yoga', 'Strength', 'Cardio', 'Stretching'];

  final _videos = const [
    _VideoData(
      title: '20-Min Full Body HIIT',
      category: 'HIIT',
      duration: '20 min',
      difficulty: 'Intermediate',
      emoji: '🔥',
      color: Color(0xFFFF6B35),
      url: 'https://www.youtube.com/watch?v=ml6cT4AZdqI',
    ),
    _VideoData(
      title: 'Morning Yoga Flow',
      category: 'Yoga',
      duration: '15 min',
      difficulty: 'Beginner',
      emoji: '🧘',
      color: Color(0xFF9B6DFF),
      url: 'https://www.youtube.com/watch?v=v7AYKMP6rOE',
    ),
    _VideoData(
      title: 'Upper Body Strength',
      category: 'Strength',
      duration: '30 min',
      difficulty: 'Intermediate',
      emoji: '💪',
      color: AppColors.brandBlue,
      url: 'https://www.youtube.com/watch?v=vc1E5CfRfos',
    ),
    _VideoData(
      title: '10-Min Abs Blast',
      category: 'HIIT',
      duration: '10 min',
      difficulty: 'Beginner',
      emoji: '⚡',
      color: Color(0xFFFF6B35),
      url: 'https://www.youtube.com/watch?v=DHD1-2P4QtQ',
    ),
    _VideoData(
      title: 'Fat Burning Cardio',
      category: 'Cardio',
      duration: '25 min',
      difficulty: 'Intermediate',
      emoji: '🏃',
      color: AppColors.brandGreen,
      url: 'https://www.youtube.com/watch?v=UItWltVZZmE',
    ),
    _VideoData(
      title: 'Full Body Stretch',
      category: 'Stretching',
      duration: '12 min',
      difficulty: 'Beginner',
      emoji: '🤸',
      color: Color(0xFF29B6F6),
      url: 'https://www.youtube.com/watch?v=L_xrDAtykMI',
    ),
    _VideoData(
      title: 'Leg Day Workout',
      category: 'Strength',
      duration: '35 min',
      difficulty: 'Advanced',
      emoji: '🦵',
      color: AppColors.brandBlue,
      url: 'https://www.youtube.com/watch?v=HaF5D3ORcBo',
    ),
    _VideoData(
      title: 'Evening Yoga & Relax',
      category: 'Yoga',
      duration: '20 min',
      difficulty: 'Beginner',
      emoji: '🌙',
      color: Color(0xFF9B6DFF),
      url: 'https://www.youtube.com/watch?v=BiWDsfZ3zbo',
    ),
    _VideoData(
      title: '30-Min Run Intervals',
      category: 'Cardio',
      duration: '30 min',
      difficulty: 'Intermediate',
      emoji: '🏅',
      color: AppColors.brandGreen,
      url: 'https://www.youtube.com/watch?v=Ex4dKBJhWFo',
    ),
    _VideoData(
      title: 'Post-Workout Stretch',
      category: 'Stretching',
      duration: '8 min',
      difficulty: 'Beginner',
      emoji: '🌿',
      color: Color(0xFF29B6F6),
      url: 'https://www.youtube.com/watch?v=qULTwquOuT4',
    ),
  ];

  List<_VideoData> get _filtered =>
      _selected == 'All' ? _videos : _videos.where((v) => v.category == _selected).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfDark : AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Video Library',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18,
                color: isDark ? AppColors.textPriDark : AppColors.textPri)),
      ),
      body: Column(children: [
        _CategoryChips(
          categories: _categories,
          selected: _selected,
          isDark: isDark,
          onSelect: (c) => setState(() => _selected = c),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: _filtered.length,
            itemBuilder: (context, i) =>
                _VideoCard(video: _filtered[i], isDark: isDark),
          ),
        ),
      ]),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final bool isDark;
  final void Function(String) onSelect;
  const _CategoryChips({
    required this.categories, required this.selected,
    required this.isDark, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.surfDark : AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: categories.map((c) {
            final active = c == selected;
            return GestureDetector(
              onTap: () => onSelect(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? AppColors.brandBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? AppColors.brandBlue
                        : isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: Text(c,
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: active ? Colors.white
                          : isDark ? AppColors.textSecDark : AppColors.textSec,
                    )),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final _VideoData video;
  final bool isDark;
  const _VideoCard({required this.video, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final diffColors = {
      'Beginner': AppColors.brandGreen,
      'Intermediate': AppColors.amber,
      'Advanced': AppColors.accent,
    };
    final diffColor = diffColors[video.difficulty] ?? AppColors.textSec;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 80, height: 80,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: video.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(video.emoji, style: const TextStyle(fontSize: 36))),
        ),
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(video.title,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPriDark : AppColors.textPri)),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(video.difficulty,
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: diffColor)),
              ),
              const SizedBox(width: 6),
              Icon(Icons.access_time, size: 12, color: isDark ? AppColors.textSecDark : AppColors.textSec),
              const SizedBox(width: 3),
              Text(video.duration,
                  style: GoogleFonts.inter(fontSize: 12,
                      color: isDark ? AppColors.textSecDark : AppColors.textSec)),
            ]),
          ]),
        )),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(video.url);
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Watch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: video.color,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _VideoData {
  final String title, category, duration, difficulty, emoji, url;
  final Color color;
  const _VideoData({
    required this.title, required this.category, required this.duration,
    required this.difficulty, required this.emoji, required this.color, required this.url,
  });
}
