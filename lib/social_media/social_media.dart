import 'package:flutter/material.dart';

import 'create_post_sheet.dart';
import 'post.dart';
import 'post_card.dart';

class SocialMediaPage extends StatefulWidget {
  final String username;

  const SocialMediaPage({super.key, required this.username});

  @override
  State<SocialMediaPage> createState() => _SocialMediaPageState();
}

class _SocialMediaPageState extends State<SocialMediaPage> {
  final List<Post> posts = [
    const Post(
      username: 'JohnDoe',
      caption: 'Enjoying the sunny weather!',
      imageUrl: 'https://picsum.photos/id/1015/600/400',
    ),
    const Post(
      username: 'JaneSmith',
      caption: 'Just finished a great book!',
      imageUrl: 'https://picsum.photos/id/24/600/400',
    ),
  ];

  Future<void> openCreatePostSheet() async {
    final Post? newPost = await showModalBottomSheet<Post>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CreatePostSheet(username: widget.username),
    );
    if (!mounted || newPost == null) return;
    setState(() => posts.insert(0, newPost));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Social Media')),
      body: posts.isEmpty
          ? const Center(child: Text('No posts yet. Create one!'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: posts.length,
              // Let the lazy list find a card's new index after insertion.
              findChildIndexCallback: (key) {
                final index = posts.indexOf((key as ObjectKey).value as Post);
                return index < 0 ? null : index;
              },
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(key: ObjectKey(post), post: post);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: openCreatePostSheet,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        tooltip: 'Create Post',
        child: const Icon(Icons.add),
      ),
    );
  }
}
