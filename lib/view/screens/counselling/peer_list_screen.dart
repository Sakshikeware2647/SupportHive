// ─────────────────────────────────────────────────────────────────────────────
// view/screens/peer_list_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:supporthive1/model/peer_user_model.dart';
import 'package:supporthive1/view/widgets/peer_widgets.dart';
import 'peer_chat_screen.dart';

class PeerListScreen extends StatelessWidget {
  final List<PeerUser> peers;       // initial snapshot
  final String myUserId;
  final Stream<List<PeerUser>> peersStream; // live updates

  const PeerListScreen({
    super.key,
    required this.peers,
    required this.myUserId,
    required this.peersStream,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PeerTheme.mist,
      appBar: AppBar(
        title: const Text('Available Peers',
            style: TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // Live peer count chip
          StreamBuilder<List<PeerUser>>(
            stream: peersStream,
            initialData: peers,
            builder: (_, snap) {
              final count = snap.data?.length ?? peers.length;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  label: Text('$count online',
                      style: const TextStyle(
                          fontSize: 11,
                          color: PeerTheme.sage,
                          fontWeight: FontWeight.w600)),
                  backgroundColor: PeerTheme.sageLight,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const AnonymityBanner(),
          Expanded(
            child: StreamBuilder<List<PeerUser>>(
              stream: peersStream,
              initialData: peers,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final livePeers = snap.data ?? peers;

                if (livePeers.isEmpty) return _buildEmpty();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: livePeers.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == livePeers.length) {
                      return _buildGuidelinesCard();
                    }
                    return _PeerCard(
                      peer: livePeers[i],
                      onChat: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => PeerChatScreen(
                            peer: livePeers[i],
                            myUserId: myUserId,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline,
                  size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('No peers available right now',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Check back in a few minutes, or consider being a peer supporter yourself.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      );

  Widget _buildGuidelinesCard() => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.gavel_outlined,
                  size: 15, color: Colors.orange.shade700),
              const SizedBox(width: 6),
              const Text('Community reminder',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            const GuidelineTile('Be kind and respectful at all times'),
            const GuidelineTile('Keep all conversations confidential'),
            const GuidelineTile('Do not share any personal information'),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
class _PeerCard extends StatelessWidget {
  final PeerUser peer;
  final VoidCallback onChat;

  const _PeerCard({required this.peer, required this.onChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
        leading: PeerAvatar(
            username: peer.username, radius: 22, showOnlineDot: true),
        title: Text(peer.username,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87)),
        subtitle: const Text('Here to listen · Active now',
            style: TextStyle(fontSize: 12, color: Colors.black45)),
        trailing: ElevatedButton(
          onPressed: onChat,
          style: ElevatedButton.styleFrom(
            backgroundColor: PeerTheme.seaBlue,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            textStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
          child: const Text('Chat'),
        ),
      ),
    );
  }
}