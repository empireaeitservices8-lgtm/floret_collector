import 'package:floret_collector/features/home/screen/widgets/card_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget buildHomeShimmer() {
  const baseColor = Color(0xFFE2E8F0);
  const highlightColor = Color(0xFFF8FAFC);

  return SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Location Shimmer Row
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 70,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Greeting
          Container(
            width: 180,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          const SizedBox(height: 20),

          // 3 Summary KPI Cards Shimmer Row
          Row(
            children: [
              Expanded(child: buildMetricCardShimmer()),
              const SizedBox(width: 12),
              Expanded(child: buildMetricCardShimmer()),
              const SizedBox(width: 12),
              Expanded(child: buildMetricCardShimmer()),
            ],
          ),

          const SizedBox(height: 28),

          // Schedule Header Shimmer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 220,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Schedule Card Shimmer
          Container(
            width: double.infinity,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          const SizedBox(height: 28),

          // Overview Header Shimmer
          Container(
            width: 210,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),

          const SizedBox(height: 14),

          // Overview Container Shimmer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
