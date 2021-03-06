# frozen_string_literal: true

module Gitlab
  module ImportExport
    class SnippetRepoRestorer < RepoRestorer
      attr_reader :snippet

      def initialize(snippet:, user:, shared:, path_to_bundle:)
        @snippet = snippet
        @user = user
        @repository = snippet.repository
        @path_to_bundle = path_to_bundle.to_s
        @shared = shared
      end

      def restore
        if File.exist?(path_to_bundle)
          create_repository_from_bundle
        else
          create_repository_from_db
        end

        true
      rescue => e
        shared.error(e)
        false
      end

      private

      def create_repository_from_bundle
        repository.create_from_bundle(path_to_bundle)
        snippet.track_snippet_repository(repository.storage)
      end

      def create_repository_from_db
        Gitlab::BackgroundMigration::BackfillSnippetRepositories.new.perform_by_ids([snippet.id])
      end
    end
  end
end
