import 'package:flutter/material.dart';

class Skeleton extends StatelessWidget {
  final double? height, width;

  const Skeleton({super.key, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class SkeletonLoader extends StatelessWidget {
  final double? height, width;
  const SkeletonLoader({super.key, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Skeleton(height: height, width: width);
  }
}


class ChatSkeleton extends StatelessWidget {
  const ChatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Skeleton(height: 50, width: 50),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: MediaQuery.of(context).size.width * 0.6, height: 15),
                  const SizedBox(height: 8),
                  Skeleton(width: MediaQuery.of(context).size.width * 0.4, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
