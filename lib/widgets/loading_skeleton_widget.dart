import 'package:flutter/material.dart';

class LoadingSkeletonWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeletonWidget({super.key, required this.width, required this.height, this.borderRadius = 8});

  @override
  State<LoadingSkeletonWidget> createState() => _LoadingSkeletonWidgetState();
}

class _LoadingSkeletonWidgetState extends State<LoadingSkeletonWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor = Theme.of(context).colorScheme.surface;

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(colors: [baseColor, highlightColor, baseColor], stops: [(_shimmerAnimation.value - 0.3).clamp(0.0, 1.0), _shimmerAnimation.value.clamp(0.0, 1.0), (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0)], begin: Alignment.centerLeft, end: Alignment.centerRight),
          ),
        );
      },
    );
  }
}

class ProductListSkeletonWidget extends StatelessWidget {
  const ProductListSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 110,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  LoadingSkeletonWidget(width: 48, height: 48, borderRadius: 12),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        LoadingSkeletonWidget(width: double.infinity, height: 14, borderRadius: 6),
                        LoadingSkeletonWidget(width: 100, height: 11, borderRadius: 5),
                        LoadingSkeletonWidget(width: double.infinity, height: 11, borderRadius: 5),
                        Row(children: [LoadingSkeletonWidget(width: 70, height: 18, borderRadius: 5), const Spacer(), LoadingSkeletonWidget(width: 80, height: 28, borderRadius: 8)]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileSkeletonWidget extends StatelessWidget {
  const ProfileSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Avatar
          const Center(child: LoadingSkeletonWidget(width: 100, height: 100, borderRadius: 50)),
          const SizedBox(height: 16),
          const Center(child: LoadingSkeletonWidget(width: 160, height: 20, borderRadius: 6)),
          const SizedBox(height: 8),
          const Center(child: LoadingSkeletonWidget(width: 100, height: 14, borderRadius: 5)),
          const SizedBox(height: 30),
          // Profile fields
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                height: 64,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const LoadingSkeletonWidget(width: 38, height: 38, borderRadius: 10),
                    const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [const LoadingSkeletonWidget(width: 80, height: 11, borderRadius: 5), const SizedBox(height: 6), LoadingSkeletonWidget(width: 180, height: 15, borderRadius: 5)]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const LoadingSkeletonWidget(width: double.infinity, height: 54, borderRadius: 16),
        ],
      ),
    );
  }
}

class DashboardSkeletonWidget extends StatelessWidget {
  const DashboardSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI grid skeleton
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: List.generate(4, (_) => const LoadingSkeletonWidget(width: double.infinity, height: 90, borderRadius: 12)),
          ),
          const SizedBox(height: 20),
          const LoadingSkeletonWidget(width: 140, height: 18, borderRadius: 6),
          const SizedBox(height: 12),
          const LoadingSkeletonWidget(width: double.infinity, height: 180, borderRadius: 12),
          const SizedBox(height: 20),
          const LoadingSkeletonWidget(width: 160, height: 18, borderRadius: 6),
          const SizedBox(height: 12),
          ...List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LoadingSkeletonWidget(width: double.infinity, height: 72, borderRadius: 12),
            ),
          ),
        ],
      ),
    );
  }
}
