import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/message_service.dart';
import '../../services/profile_service.dart';
import '../../services/location_service.dart';
import '../../services/bluetooth_service.dart';
import '../../widgets/mesh_status_badge.dart';
import '../../models/message_model.dart';
import 'quick_message_templates.dart';

class CommunityChatPage extends StatefulWidget {
  const CommunityChatPage({super.key});

  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  MessageType _selectedTag = MessageType.info;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final profile = context.read<ProfileService>().profile;
    final loc = context.read<LocationService>();

    await context.read<MessageService>().sendCommunityMessage(
      senderId: profile.id,
      senderName: profile.name.isNotEmpty ? profile.name : 'Anonymous',
      content: text,
      type: _selectedTag,
      latitude: loc.latitude,
      longitude: loc.longitude,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  void _sendTemplate(String template) async {
    final profile = context.read<ProfileService>().profile;
    final loc = context.read<LocationService>();

    await context.read<MessageService>().sendCommunityMessage(
      senderId: profile.id,
      senderName: profile.name.isNotEmpty ? profile.name : 'Anonymous',
      content: template,
      type: MessageType.sos,
      latitude: loc.latitude,
      longitude: loc.longitude,
    );
    _scrollToBottom();
  }

  void _showTemplates() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickMessageTemplates(
        onSelect: (template) {
          Navigator.pop(context);
          _sendTemplate(template);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Blu Connect',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            fontStyle: FontStyle.italic,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Consumer<BluetoothService>(
              builder: (_, ble, _) => MeshStatusBadge(
                isActive: ble.isBluetoothOn && ble.connectedDeviceCount > 0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.cell_tower_rounded, size: 22),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
            ),
            child: Consumer<BluetoothService>(
              builder: (_, ble, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVE MESH NETWORK',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Community Broadcast',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time local communication via decentralized peer-to-peer nodes.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.meshActive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${ble.connectedDeviceCount} Nodes Active',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 16,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: AppColors.outlineVariant,
                        ),
                        Consumer<LocationService>(
                          builder: (_, loc, _) => Text(
                            loc.hasPosition ? 'GPS Active' : 'Acquiring GPS',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Messages
          Expanded(
            child: Consumer<MessageService>(
              builder: (_, msgService, _) {
                final messages = msgService.communityMessages;
                return messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.forum_outlined, size: 48, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'No messages yet',
                              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start broadcasting to the mesh network',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: messages.length,
                        itemBuilder: (_, i) => _MessageBubble(message: messages[i]),
                      );
              },
            ),
          ),

          // Input
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tag filters
          Row(
            children: [
              _TagChip(
                label: 'INFO',
                color: AppColors.meshActive,
                isSelected: _selectedTag == MessageType.info,
                onTap: () => setState(() => _selectedTag = MessageType.info),
              ),
              const SizedBox(width: 8),
              _TagChip(
                label: 'ALERT',
                color: const Color(0xFFF59E0B),
                isSelected: _selectedTag == MessageType.alert,
                onTap: () => setState(() => _selectedTag = MessageType.alert),
              ),
              const SizedBox(width: 8),
              _TagChip(
                label: 'SOS',
                color: AppColors.error,
                isSelected: _selectedTag == MessageType.sos,
                onTap: () => setState(() => _selectedTag = MessageType.sos),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.quickreply_rounded, size: 22),
                onPressed: _showTemplates,
                color: AppColors.onSurfaceVariant,
              ),
              IconButton(
                icon: const Icon(Icons.location_on_rounded, size: 22),
                onPressed: () async {
                  await context.read<LocationService>().getCurrentPosition();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location will be attached to next message')),
                    );
                  }
                },
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message to the mesh...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, size: 20, color: AppColors.onPrimary),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  Color get _tagColor {
    switch (message.type) {
      case MessageType.sos:
        return AppColors.error;
      case MessageType.alert:
        return const Color(0xFFF59E0B);
      case MessageType.info:
        return AppColors.meshActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSOS = message.type == MessageType.sos;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Tag header
          if (!message.isMine)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _tagColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      message.typeLabel,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _tagColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${message.senderName} • ${_timeAgo(message.timestamp)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSOS && !message.isMine
                  ? AppColors.tertiary
                  : message.isMine
                      ? AppColors.primaryFixed.withValues(alpha: 0.5)
                      : isSOS
                          ? AppColors.tertiary
                          : message.type == MessageType.alert
                              ? const Color(0xFFFFF8E1)
                              : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: isSOS && !message.isMine
                  ? null
                  : Border.all(
                      color: isSOS
                          ? AppColors.tertiary
                          : AppColors.outlineVariant.withValues(alpha: 0.15),
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: isSOS && !message.isMine ? Colors.white : AppColors.onSurface,
                    fontWeight: isSOS ? FontWeight.w600 : FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                if (message.hopCount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hub_rounded,
                        size: 14,
                        color: isSOS && !message.isMine
                            ? Colors.white70
                            : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'RELAYED VIA ${message.hopCount} NODES',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: isSOS && !message.isMine
                              ? Colors.white70
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (message.hasLocation) ...[
                        const Spacer(),
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: isSOS && !message.isMine
                              ? Colors.white70
                              : AppColors.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Status for sent messages
          if (message.isMine)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'You • Just now',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.statusLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (message.isBroadcast) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.cell_tower_rounded, size: 14, color: AppColors.onSurfaceVariant),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? color : AppColors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
