# frozen_string_literal: true
module Decidim
  module Admin
    # This command deals with destroying a Feature from the admin panel.
    class DestroyFeature < Rectify::Command
      # Public: Initializes the command.
      #
      # feature - The Feature to be destroyed.
      def initialize(feature)
        @feature = feature
      end

      # Public: Executes the command.
      #
      # Broadcasts :ok if it got destroyed, raises an exception otherwise.
      def call
        destroy_feature
        broadcast(:ok)
      end

      private

      def destroy_feature
        transaction do
          @feature.destroy!
          run_hooks
        end
      end

      def run_hooks
        @feature.manifest.run_hooks(:destroy, @feature)
      end
    end
  end
end
