# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    class FileComponents
      SKIP_ANNOTATION_STRING = "# -*- SkipSchemaAnnotations"
      SOME_PATTERN = /\A(?<start>\s*).*?\n(?<end>\s*)\z/m # Unsure what this pattern is

      attr_reader :new_annotations

      def initialize(file_content, new_annotations, options)
        @file_content = file_content
        @diff = AnnotationDiffGenerator.new(file_content, new_annotations).generate
        @options = options
        @annotation_pattern = AnnotationPatternGenerator.call(options)
        @new_annotations = new_annotations
      end

      def current_file_content
        @file_content
      end

      # TODO: Rename method once it's clear what this actually does
      def space_before_annotation
        return @space_before_annotation if defined?(@space_before_annotation)

        match = current_annotations.match(SOME_PATTERN)
        @space_before_annotation = if match
          match[:start]
        end
      end

      # TODO: Rename method once it's clear what this actually does
      def space_after_annotation
        return @space_after_annotation if defined?(@space_after_annotation)

        match = current_annotations.match(SOME_PATTERN)
        @space_after_annotation = if match
          match[:end]
        end
      end

      def pure_file_content
        @pure_file_content ||=
          begin
            content_without_magic_comments = @file_content.gsub(FileParser::MagicCommentParser::MAGIC_COMMENTS_REGEX, "")
            content_without_annotations = content_without_magic_comments.sub(@annotation_pattern, "")

            content_without_annotations
          end
      end

      def magic_comments
        @magic_comments ||= FileParser::MagicCommentParser.call(@file_content)
      end

      def has_skip_string?
        @has_skip_string ||= @file_content.include?(SKIP_ANNOTATION_STRING)
      end

      def has_annotations?
        @has_annotations ||= @diff.current_columns.present?
      end

      def annotations_changed?
        @has_annotations_changed ||= @diff.changed?
      end

      def current_annotations
        @current_annotations ||=
          if has_annotations?
            # `#has_annotations?` uses a different regex pattern than the one in `@annotation_pattern`,
            # this could lead to unexpected behavior
            @file_content.match(@annotation_pattern).to_s
          else
            ""
          end
      end
    end
  end
end
