/// Enum representing different types of content that can be rendered
enum ContentType {
  text,
  math,
  table,
  svg,
  image,
}

/// Model representing a block of content with its type and rendering capabilities
class ContentBlock {
  final ContentType type;
  final String content;
  final Map<String, dynamic>? metadata;

  const ContentBlock({
    required this.type,
    required this.content,
    this.metadata,
  });

  /// Factory constructor for creating text content blocks
  factory ContentBlock.text(String content) {
    return ContentBlock(
      type: ContentType.text,
      content: content,
    );
  }

  /// Factory constructor for creating math content blocks
  factory ContentBlock.math(String content, {Map<String, dynamic>? metadata}) {
    return ContentBlock(
      type: ContentType.math,
      content: content,
      metadata: metadata,
    );
  }

  /// Factory constructor for creating table content blocks
  factory ContentBlock.table(String content, {Map<String, dynamic>? metadata}) {
    return ContentBlock(
      type: ContentType.table,
      content: content,
      metadata: metadata,
    );
  }

  /// Factory constructor for creating SVG content blocks
  factory ContentBlock.svg(String content, {Map<String, dynamic>? metadata}) {
    return ContentBlock(
      type: ContentType.svg,
      content: content,
      metadata: metadata,
    );
  }

  /// Factory constructor for creating image content blocks
  factory ContentBlock.image(String content, {Map<String, dynamic>? metadata}) {
    return ContentBlock(
      type: ContentType.image,
      content: content,
      metadata: metadata,
    );
  }

  /// Renders the content block to a string representation
  String render() {
    switch (type) {
      case ContentType.text:
        return content;
      case ContentType.math:
        return _renderMathFallback();
      case ContentType.table:
        return _renderTableFallback();
      case ContentType.svg:
        return _renderSvgFallback();
      case ContentType.image:
        return _renderImageFallback();
    }
  }

  /// Fallback rendering for math content when advanced rendering is not available
  String _renderMathFallback() {
    return '[Math: $content]';
  }

  /// Fallback rendering for table content when advanced rendering is not available
  String _renderTableFallback() {
    return '[Table: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}]';
  }

  /// Fallback rendering for SVG content when advanced rendering is not available
  String _renderSvgFallback() {
    return '[SVG Image]';
  }

  /// Fallback rendering for image content when advanced rendering is not available
  String _renderImageFallback() {
    return '[Image: ${metadata?['alt'] ?? 'Image'}]';
  }

  @override
  String toString() {
    return 'ContentBlock(type: $type, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentBlock &&
        other.type == type &&
        other.content == content &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return type.hashCode ^ content.hashCode ^ metadata.hashCode;
  }

  /// Helper method to compare maps for equality
  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) {
        return false;
      }
    }
    return true;
  }
}
