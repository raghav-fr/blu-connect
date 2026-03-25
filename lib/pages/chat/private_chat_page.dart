
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/device_model.dart';
import '../../models/message_model.dart';
import '../../services/message_service.dart';
import '../../services/profile_service.dart';
import '../../services/location_service.dart';

class PrivateChatPage extends StatefulWidget {
  final DeviceInfo device;

  const PrivateChatPage({super.key, required this.device});

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

    await context.read<MessageService>().sendPrivateMessage(
      senderId: profile.id,
      senderName: profile.name.isNotEmpty ? profile.name : 'Anonymous',
      targetDeviceId: widget.device.id,
      content: text,
      routingPath: [profile.id, widget.device.id],
    );

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _shareLocation() async {
    final loc = context.read<LocationService>();
    await loc.getCurrentPosition();

    if (loc.hasPosition && mounted) {
      final profile = context.read<ProfileService>().profile;
      await context.read<MessageService>().sendPrivateMessage(
        senderId: profile.id,
        senderName: profile.name.isNotEmpty ? profile.name : 'Anonymous',
        targetDeviceId: widget.device.id,
        content: '📍 Current Location Shared\n${loc.coordinatesLabel}',
        latitude: loc.latitude,
        longitude: loc.longitude,
      );
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.device.name,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.meshActive,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ENCRYPTED TUNNEL ACTIVE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceContainerHigh,
            child: Icon(
              widget.device.deviceType == 'drone'
                  ? Icons.flight_rounded
                  : Icons.person_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Mesh Signal Path
          _buildSignalPath(),

          // Messages
          Expanded(
            child: Consumer<MessageService>(
              builder: (_, msgService, _) {
                final messages = msgService.getPrivateMessages(widget.device.id);
                return messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline, size: 40, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'Encrypted channel ready',
                              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                            ),
                            Text(
                              'Send your first secure message',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: messages.length,
                        itemBuilder: (_, i) => _PrivateMessageBubble(
                          message: messages[i],
                          deviceName: widget.device.name,
                        ),
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

  Widget _buildSignalPath() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MESH SIGNAL PATH',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PathNode(
                icon: Icons.person_rounded,
                label: 'You',
                color: AppColors.primary,
              ),
              _PathDash(),
              if (widget.device.hopCount > 0) ...[
                _PathNode(
                  icon: Icons.router_rounded,
                  label: 'Relay',
                  color: AppColors.onSurfaceVariant,
                  isRelay: true,
                ),
                _PathDash(),
              ],
              _PathNode(
                icon: Icons.location_on_rounded,
                label: widget.device.name.length > 8
                    ? widget.device.name.substring(0, 8)
                    : widget.device.name,
                color: AppColors.primaryFixed,
                bgColor: AppColors.primaryFixed.withValues(alpha: 0.3),
              ),
            ],
          ),
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
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: _shareLocation,
            color: AppColors.onSurfaceVariant,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a secure message...',
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
    );
  }
}

class _PathNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? bgColor;
  final bool isRelay;

  const _PathNode({
    required this.icon,
    required this.label,
    required this.color,
    this.bgColor,
    this.isRelay = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor ?? (isRelay ? AppColors.surfaceContainerLowest : color),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: isRelay ? color : AppColors.onPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PathDash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: List.generate(
            8,
            (_) => Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivateMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String deviceName;

  const _PrivateMessageBubble({
    required this.message,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Location card
          if (message.hasLocation && message.isMine)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              width: MediaQuery.of(context).size.width * 0.7,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Topographic pattern as map placeholder
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(
                      size: const Size(double.infinity, 160),
                      painter: _MapPatternPainter(),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Current Location Shared',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: message.isMine
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.content,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: message.isMine ? AppColors.onPrimary : AppColors.onSurface,
                height: 1.5,
              ),
            ),
          ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
                  message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (message.isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == MessageStatus.delivered
                        ? Icons.done_all
                        : Icons.done,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 12; i++) {
      paint.color = AppColors.onPrimaryContainer.withValues(alpha: 0.15 - (i * 0.01));
      final path = Path();
      final yOffset = (i * 14.0) + 10;
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.3, yOffset - 10 + (i * 2),
        size.width * 0.6, yOffset + 15 - (i * 1.5),
        size.width, yOffset - 5 + (i * 3),
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
