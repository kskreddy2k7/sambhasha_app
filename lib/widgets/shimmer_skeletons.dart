import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerLoader.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerLoader.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: shapeBorder,
        ),
      ),
    );
  }
}

class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 8,
      padding: const EdgeInsets.symmetric(vertical: 16),
      separatorBuilder: (context, index) => const Divider(indent: 80),
      itemBuilder: (context, index) => ListTile(
        leading: const ShimmerLoader.circular(width: 56, height: 56),
        title: const ShimmerLoader.rectangular(height: 16),
        subtitle: const ShimmerLoader.rectangular(height: 12),
      ),
    );
  }
}

class DiscoverGridSkeleton extends StatelessWidget {
  const DiscoverGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: const Column(
          children: [
            ShimmerLoader.circular(width: 80, height: 80),
            SizedBox(height: 16),
            ShimmerLoader.rectangular(height: 16),
            SizedBox(height: 8),
            ShimmerLoader.rectangular(height: 32),
          ],
        ),
      ),
    );
  }
}

class StoryBarSkeleton extends StatelessWidget {
  const StoryBarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(right: 16),
          child: ShimmerLoader.circular(width: 70, height: 70),
        ),
      ),
    );
  }
}
