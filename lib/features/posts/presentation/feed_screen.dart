import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/adaptive_glass_card.dart';
import '../../../core/widgets/adaptive_glass_pill_button.dart';
import '../../map/providers/map_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/post_models.dart';
import '../data/posts_service.dart';
import '../providers/posts_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  Future<void> _refresh() async {
    ref.invalidate(feedPostsProvider);
    ref.invalidate(locationFeedPostsProvider);
    await ref.read(feedPostsProvider.future);
  }

  void _openMapForPost(FeedPost post) {
    if (!post.hasLocation || !mounted) {
      return;
    }

    ref
        .read(mapFocusTargetProvider.notifier)
        .setTarget(
          MapFocusTarget(
            requestId:
                '${post.postId}:${DateTime.now().microsecondsSinceEpoch}',
            point: LatLng(post.lat!, post.lon!),
            zoom: _zoomFor(post.locationRadiusM ?? 200),
          ),
        );
    context.go(AppRoutes.map);
  }

  Future<void> _deletePost(String postId) async {
    try {
      await ref.read(postsServiceProvider).deletePost(postId);
      ref.invalidate(feedPostsProvider);
      ref.invalidate(locationFeedPostsProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post deleted.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  static double _zoomFor(int radiusM) {
    if (radiusM >= 1000) {
      return 12.8;
    }
    if (radiusM >= 500) {
      return 13.5;
    }
    if (radiusM >= 200) {
      return 14.4;
    }
    return 15.3;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final feedAsync = ref.watch(feedPostsProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Timeline'),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Refresh timeline',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: feedAsync.when(
            data: (posts) => ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 108),
              itemCount: posts.isEmpty ? 1 : posts.length,
              separatorBuilder: (context, index) {
                return Divider(
                  height: 1,
                  indent: 68,
                  endIndent: 16,
                  color: colors.outlineVariant.withValues(alpha: 0.45),
                );
              },
              itemBuilder: (context, index) {
                if (posts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _EmptyTimeline(onRefresh: _refresh),
                  );
                }

                final post = posts[index];
                return _PostCard(
                  post: post,
                  onDelete: post.isAuthor
                      ? () => _deletePost(post.postId)
                      : null,
                  onOpenMap: post.hasLocation
                      ? () => _openMapForPost(post)
                      : null,
                );
              },
            ),
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 108),
              children: const [Center(child: CircularProgressIndicator())],
            ),
            error: (error, stackTrace) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 108),
              children: [
                AdaptiveGlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Could not load timeline',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$error',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AdaptiveGlassPillButton(
                        onPressed: _refresh,
                        label: 'Retry',
                        compact: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No posts yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the bottom-right post button to start the timeline.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          AdaptiveGlassPillButton(
            onPressed: onRefresh,
            label: 'Refresh',
            compact: false,
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post, this.onDelete, this.onOpenMap});

  final FeedPost post;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenMap;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final post = widget.post;
    final body = _bodyFor(post);
    final authorName =
        post.authorDisplayName ?? post.authorUsername ?? post.authorId;
    final authorHandle =
        post.authorUsername != null &&
            post.authorUsername != post.authorDisplayName
        ? '@${post.authorUsername}'
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, ref, child) {
              final profile = ref.watch(userProfileProvider(post.authorId));
              return _AvatarBubble(
                label: authorName,
                avatarUrl: profile.asData?.value?.avatarUrl,
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            authorName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (authorHandle != null)
                            Text(
                              authorHandle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          Text(
                            _formatTime(post.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          if (post.hasLocation)
                            Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: colors.primary,
                            ),
                        ],
                      ),
                    ),
                    if (post.isAuthor)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.tertiaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'You',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onTertiaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (body != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    body,
                    maxLines: _expanded
                        ? null
                        : post.imageUrl == null
                        ? 4
                        : 3,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _bodyColor(colors, post.viewerTier),
                      height: 1.35,
                    ),
                  ),
                ],
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 1.22,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (post.viewerTier == PostViewerTier.partial)
                            ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(
                                sigmaX: 14,
                                sigmaY: 14,
                              ),
                              child: Image.network(
                                post.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: colors.surfaceContainerHighest,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                    ),
                              ),
                            )
                          else
                            Image.network(
                              post.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: colors.surfaceContainerHighest,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                    ),
                                  ),
                            ),
                          if (post.viewerTier == PostViewerTier.partial)
                            Container(
                              color: colors.scrim.withValues(alpha: 0.18),
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.inverseSurface.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Partial image',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colors.onInverseSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _TimelineAction(
                      icon: _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      label: _expanded ? 'Hide' : 'Details',
                      active: _expanded,
                      onTap: _toggleExpanded,
                    ),
                    if (widget.onOpenMap != null)
                      _TimelineAction(
                        icon: Icons.place_outlined,
                        label: 'Map',
                        onTap: widget.onOpenMap!,
                      ),
                    if (_expanded && widget.onDelete != null)
                      _TimelineAction(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        onTap: widget.onDelete!,
                        destructive: true,
                      ),
                  ],
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _FeedChip(label: _tierLabel(post.viewerTier)),
                              _FeedChip(label: 'Open ${post.visibilityValue}'),
                              _FeedChip(
                                label:
                                    'Expires ${_formatExpiry(post.expiresAt)}',
                              ),
                              if (post.hasLocation)
                                _FeedChip(
                                  label:
                                      'Location ${post.locationRadiusM}m / ${_blurLabel(post.locationBlurLevel ?? 0)}',
                                ),
                            ],
                          ),
                          if (post.viewerTier != PostViewerTier.full) ...[
                            const SizedBox(height: 8),
                            Text(
                              switch (post.viewerTier) {
                                PostViewerTier.partial =>
                                  'This post is softened for you at the current intimacy.',
                                PostViewerTier.hidden =>
                                  'You can sense the post, but not inspect it yet.',
                                PostViewerTier.full => '',
                              },
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (widget.onOpenMap != null) ...[
                            const SizedBox(height: 8),
                            AdaptiveGlassPillButton(
                              onPressed: widget.onOpenMap,
                              icon: const Icon(Icons.map_outlined),
                              label: 'Open attached place',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _bodyFor(FeedPost post) {
    return switch (post.viewerTier) {
      PostViewerTier.full => post.text,
      PostViewerTier.partial =>
        post.text == null || post.text!.isEmpty ? 'Partial view' : post.text,
      PostViewerTier.hidden =>
        post.imageUrl != null || (post.text != null && post.text!.isNotEmpty)
            ? post.text ?? 'Presence only'
            : 'Presence only',
    };
  }

  static Color? _bodyColor(ColorScheme colors, PostViewerTier tier) {
    return switch (tier) {
      PostViewerTier.full => null,
      PostViewerTier.partial => colors.onSurface,
      PostViewerTier.hidden => colors.onSurfaceVariant,
    };
  }

  static String _tierLabel(PostViewerTier tier) {
    return switch (tier) {
      PostViewerTier.full => 'Full',
      PostViewerTier.partial => 'Partial',
      PostViewerTier.hidden => 'Hidden',
    };
  }

  static String _formatTime(DateTime value) {
    final delta = DateTime.now().difference(value);
    if (delta.inMinutes < 1) {
      return 'just now';
    }
    if (delta.inHours < 1) {
      return '${delta.inMinutes}m ago';
    }
    if (delta.inDays < 1) {
      return '${delta.inHours}h ago';
    }
    return '${delta.inDays}d ago';
  }

  static String _formatExpiry(DateTime value) {
    final delta = value.difference(DateTime.now());
    if (delta.inMinutes <= 0) {
      return 'soon';
    }
    if (delta.inHours < 1) {
      return '${delta.inMinutes}m';
    }
    if (delta.inDays < 1) {
      return '${delta.inHours}h';
    }
    return '${delta.inDays}d';
  }

  static String _blurLabel(int level) {
    return switch (level) {
      0 => 'exact',
      1 => 'soft',
      2 => 'area',
      _ => 'wide',
    };
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({required this.label, this.avatarUrl});

  final String label;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = [
      colors.primaryContainer,
      colors.secondaryContainer,
      colors.tertiaryContainer,
    ];
    final background = palette[label.hashCode.abs() % palette.length];
    final foreground = background == colors.primaryContainer
        ? colors.onPrimaryContainer
        : background == colors.secondaryContainer
        ? colors.onSecondaryContainer
        : colors.onTertiaryContainer;
    final trimmed = label.trim();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null && avatarUrl!.trim().isNotEmpty
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}

class _TimelineAction extends StatelessWidget {
  const _TimelineAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = destructive
        ? colors.onErrorContainer
        : active
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;
    final background = destructive
        ? colors.errorContainer
        : active
        ? colors.primaryContainer
        : colors.surfaceContainerLowest;

    return Tooltip(
      message: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

class _FeedChip extends StatelessWidget {
  const _FeedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AdaptiveGlassCard(
      borderRadius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      glassAlpha: 0.18,
      borderAlpha: 0.26,
      tintColor: colors.surfaceContainerHighest,
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class PostComposerSheet extends ConsumerStatefulWidget {
  const PostComposerSheet({super.key});

  @override
  ConsumerState<PostComposerSheet> createState() => _PostComposerSheetState();
}

class _PostComposerSheetState extends ConsumerState<PostComposerSheet> {
  static const _expiryOptions = <_ExpiryOption>[
    _ExpiryOption(label: '1 hour', duration: Duration(hours: 1)),
    _ExpiryOption(label: '6 hours', duration: Duration(hours: 6)),
    _ExpiryOption(label: '24 hours', duration: Duration(hours: 24)),
    _ExpiryOption(label: '3 days', duration: Duration(days: 3)),
    _ExpiryOption(label: '7 days', duration: Duration(days: 7)),
  ];

  final _textController = TextEditingController();
  final _picker = ImagePicker();
  bool _attachLocation = false;
  double _visibilityValue = 45;
  _ExpiryOption _expiryOption = _expiryOptions[2];
  _LocationRadiusOption _locationRadius = _locationRadiusOptions[1];
  _LocationBlurOption _locationBlur = _locationBlurOptions[1];
  bool _submitting = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  static const _locationRadiusOptions = <_LocationRadiusOption>[
    _LocationRadiusOption(label: '50 m', meters: 50),
    _LocationRadiusOption(label: '200 m', meters: 200),
    _LocationRadiusOption(label: '500 m', meters: 500),
    _LocationRadiusOption(label: '1 km', meters: 1000),
  ];

  static const _locationBlurOptions = <_LocationBlurOption>[
    _LocationBlurOption(label: 'Exact', level: 0),
    _LocationBlurOption(label: 'Soft', level: 1),
    _LocationBlurOption(label: 'Area', level: 2),
    _LocationBlurOption(label: 'Wide', level: 3),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 88,
    );
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImage = image;
      _selectedImageBytes = bytes;
    });
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(postsServiceProvider)
          .createPost(
            text: _textController.text,
            visibilityValue: _visibilityValue.round(),
            expiresAt: DateTime.now().add(_expiryOption.duration),
            imageBytes: _selectedImageBytes,
            imageName: _selectedImage?.name,
            attachSharedLocation: _attachLocation,
            locationRadiusM: _locationRadius.meters,
            locationBlurLevel: _locationBlur.level,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Post failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final insets = MediaQuery.viewInsetsOf(context);
    final fullThreshold = (100 - _visibilityValue.round()).clamp(0, 100);
    final partialThreshold = (70 - _visibilityValue.round()).clamp(0, 100);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + insets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create post',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Higher visibility lowers the intimacy threshold for full access.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Attach shared location'),
                      subtitle: const Text(
                        'Use your current shared point from the map as a location-aware post.',
                      ),
                      value: _attachLocation,
                      onChanged: _submitting
                          ? null
                          : (value) => setState(() => _attachLocation = value),
                    ),
                    if (_attachLocation) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child:
                                DropdownButtonFormField<_LocationRadiusOption>(
                                  value: _locationRadius,
                                  decoration: const InputDecoration(
                                    labelText: 'Radius',
                                  ),
                                  items: _locationRadiusOptions
                                      .map(
                                        (option) =>
                                            DropdownMenuItem<
                                              _LocationRadiusOption
                                            >(
                                              value: option,
                                              child: Text(option.label),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: (option) {
                                    if (option == null) {
                                      return;
                                    }
                                    setState(() => _locationRadius = option);
                                  },
                                ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<_LocationBlurOption>(
                              value: _locationBlur,
                              decoration: const InputDecoration(
                                labelText: 'Blur',
                              ),
                              items: _locationBlurOptions
                                  .map(
                                    (option) =>
                                        DropdownMenuItem<_LocationBlurOption>(
                                          value: option,
                                          child: Text(option.label),
                                        ),
                                  )
                                  .toList(),
                              onChanged: (option) {
                                if (option == null) {
                                  return;
                                }
                                setState(() => _locationBlur = option);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The post will use the point you last shared on the map. Share there first if this fails.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_selectedImageBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Image.memory(
                            _selectedImageBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedImage?.name ?? 'Selected image',
                              style: theme.textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AdaptiveGlassPillButton(
                            onPressed: _removeImage,
                            label: 'Remove',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _textController,
                      minLines: 4,
                      maxLines: 8,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Post text',
                        hintText: 'Write a short update',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Visibility ${_visibilityLabel(_visibilityValue.round())}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      value: _visibilityValue,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${_visibilityValue.round()}',
                      onChanged: (value) =>
                          setState(() => _visibilityValue = value),
                    ),
                    Text(
                      'Full access from intimacy $fullThreshold+, partial from $partialThreshold+.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    AdaptiveGlassPillButton(
                      onPressed: _submitting ? null : _pickImage,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: _selectedImageBytes == null
                          ? 'Add image'
                          : 'Replace image',
                      compact: false,
                      expanded: true,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Text is optional when an image is attached. Full viewers see the image, lower tiers do not.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<_ExpiryOption>(
                      value: _expiryOption,
                      decoration: const InputDecoration(
                        labelText: 'Expires in',
                      ),
                      items: _expiryOptions
                          .map(
                            (option) => DropdownMenuItem<_ExpiryOption>(
                              value: option,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: (option) {
                        if (option == null) {
                          return;
                        }
                        setState(() => _expiryOption = option);
                      },
                    ),
                    const SizedBox(height: 20),
                    AdaptiveGlassPillButton(
                      onPressed: _submitting ? null : _submit,
                      icon: Icon(
                        _submitting ? Icons.hourglass_top : Icons.send,
                      ),
                      label: _submitting ? 'Posting...' : 'Post',
                      compact: false,
                      expanded: true,
                      tintColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
            ),
        ),
      ),
    );
  }

  static String _visibilityLabel(int value) {
    if (value >= 85) {
      return 'Wide';
    }
    if (value >= 65) {
      return 'Open';
    }
    if (value >= 45) {
      return 'Soft';
    }
    if (value >= 25) {
      return 'Narrow';
    }
    return 'Close';
  }
}

class _ExpiryOption {
  const _ExpiryOption({required this.label, required this.duration});

  final String label;
  final Duration duration;
}

class _LocationRadiusOption {
  const _LocationRadiusOption({required this.label, required this.meters});

  final String label;
  final int meters;
}

class _LocationBlurOption {
  const _LocationBlurOption({required this.label, required this.level});

  final String label;
  final int level;
}
