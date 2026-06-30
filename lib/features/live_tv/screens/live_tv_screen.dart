import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';
import 'package:organization_app_starter/features/live_tv/models/live_channel.dart';
import 'package:organization_app_starter/features/live_tv/providers/live_tv_providers.dart';
import 'package:organization_app_starter/shared/widgets/app_network_image.dart';
import 'package:organization_app_starter/shared/widgets/oiwi_logo.dart';

class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({super.key});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(liveChannelsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: channelsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            onRetry: () => ref.invalidate(liveChannelsProvider),
          ),
          data: (channels) {
            if (channels.isEmpty) {
              return const Center(
                child: Text(
                  'No live channels yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            final selected = _selected.clamp(0, channels.length - 1);
            final channel = channels[selected];
            final slots = channel.schedule;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand wordmark, top-left
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: OiwiLogo(height: 22),
                ),

                // Channel selector cards
                _ChannelSelector(
                  channels: channels,
                  selectedIndex: selected,
                  onSelect: (i) => setState(() => _selected = i),
                ),

                const SizedBox(height: 8),

                // Schedule list
                Expanded(
                  child: slots.isEmpty
                      ? const Center(
                          child: Text(
                            'No schedule available',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: slots.length,
                          separatorBuilder: (_, _) => Divider(
                            color: AppColors.gray300,
                            height: 28,
                          ),
                          itemBuilder: (context, i) => _ScheduleRow(
                            slot: slots[i],
                            nextSlot: i + 1 < slots.length ? slots[i + 1] : null,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChannelSelector extends StatelessWidget {
  final List<LiveChannel> channels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _ChannelSelector({
    required this.channels,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Two cards visible per row, like the reference design.
    final cardWidth = (screenWidth - 40 - 12) / 2;

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: channels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _ChannelCard(
          channel: channels[i],
          width: cardWidth,
          selected: i == selectedIndex,
          onTap: () => onSelect(i),
        ),
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final LiveChannel channel;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  const _ChannelCard({
    required this.channel,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: selected ? 1 : 0.55,
        child: Container(
          width: width,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (channel.imageUrl != null) AppNetworkImage(url: channel.imageUrl!),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.black.withValues(alpha: 0.35),
                      AppColors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    channel.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final LiveSlot slot;
  final LiveSlot? nextSlot;

  const _ScheduleRow({required this.slot, this.nextSlot});

  @override
  Widget build(BuildContext context) {
    final timeRange = _timeRange(slot.time, nextSlot?.time);
    final meta = _metaLine(slot, nextSlot?.time);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          timeRange,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        if (meta != null) ...[
          const SizedBox(height: 6),
          Text(
            meta,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          slot.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (slot.note != null) ...[
          const SizedBox(height: 4),
          Text(
            slot.note!,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  /// "9:30 AM - 9:40 AM" — end derived from the next slot's start time.
  String _timeRange(String start, String? end) {
    if (end == null || end.isEmpty) return start;
    return '$start - $end';
  }

  /// "Music • 30 Mins" — series + computed duration when both are available.
  String? _metaLine(LiveSlot slot, String? endTime) {
    final parts = <String>[];
    if (slot.series != null && slot.series!.isNotEmpty) parts.add(slot.series!);
    final dur = _durationMins(slot.time, endTime);
    if (dur != null) parts.add('$dur Mins');
    return parts.isEmpty ? null : parts.join(' • ');
  }

  int? _durationMins(String start, String? end) {
    final s = _toMinutes(start);
    final e = _toMinutes(end);
    if (s == null || e == null) return null;
    var diff = e - s;
    if (diff < 0) diff += 24 * 60; // wrap past midnight
    return diff == 0 ? null : diff;
  }

  /// Parses "6:00 AM" / "12:30 PM" into minutes since midnight.
  int? _toMinutes(String? t) {
    if (t == null) return null;
    final m = RegExp(r'(\d{1,2}):(\d{2})\s*([AaPp][Mm])').firstMatch(t.trim());
    if (m == null) return null;
    var h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final isPm = m.group(3)!.toLowerCase() == 'pm';
    if (h == 12) h = 0;
    if (isPm) h += 12;
    return h * 60 + min;
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.gray400),
          const SizedBox(height: 16),
          const Text(
            "Couldn't load live TV",
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
