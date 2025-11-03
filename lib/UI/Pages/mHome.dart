import 'package:flutter/material.dart';
import '../../Constants/app_constants.dart';
import '../Components/splash_title.dart';
import '../Components/recommended_item.dart';

class MHomePage extends StatelessWidget {
  const MHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // This top header section remains OUTSIDE the scroll view.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SplashTitle(AppConstants.appName, screenWidth * 0.07),
                IconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white : Colors.black,
                    size: screenWidth * 0.060,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // We use Expanded + CustomScrollView to make the rest of the page scrollable
          Expanded(
            child: ScrollConfiguration(
              behavior: NoGlowScrollBehavior(), // This removes the overscroll effect
              child: CustomScrollView(
                slivers: [
                  // SLIVER 1: The 'Recently Played' section that scrolls away.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 🏆 Recently Played Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Recently Played', style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                              Container(
                                decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, shape: BoxShape.circle),
                                padding: const EdgeInsets.all(6),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () {},
                                  child: Icon(Icons.play_arrow_rounded, color: isDark ? Colors.white : Colors.black, size: screenWidth * 0.06),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: screenHeight * 0.22,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 6,
                              separatorBuilder: (_, __) => const SizedBox(width: 15),
                              itemBuilder: (context, index) {
                                return Container(
                                  width: screenWidth * 0.35,
                                  decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.music_note_rounded, size: screenWidth * 0.15, color: isDark ? Colors.white : Colors.grey[800]),
                                      const SizedBox(height: 10),
                                      Text('Track ${index + 1}', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),

                  // SLIVER 2: THE STICKY HEADER for 'Recommended For You'
                  SliverPersistentHeader(
                    pinned: true, // This is what makes it stick!
                    delegate: _StickyHeaderDelegate(
                      height: 56.0,
                      child: Container(
                        // Using the scaffold background color is more robust than hardcoding black/white
                        color: isDark ? Colors.black : Colors.white,
                        height: 56.0,
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recommended For You', style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                            Container(
                              decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, shape: BoxShape.circle),
                              padding: const EdgeInsets.all(6),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {},
                                child: Icon(Icons.play_arrow_rounded, color: isDark ? Colors.white : Colors.black, size: screenWidth * 0.06),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // SLIVER 3: The list of recommended items
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0, top: 2.0),
                            child: RecommendedItem(
                              title: 'Song Title ${index + 1}',
                              isDark: isDark,
                            ),
                          );
                        },
                        childCount: 15,
                      ),
                    ),
                  ),

                  // SLIVER 4: Padding at the bottom for the transparent navigation bar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 90),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A delegate for creating sticky headers in a CustomScrollView.
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

/// A custom scroll behavior that removes the overscroll glow/bounce effect.
class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}