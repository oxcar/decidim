# frozen_string_literal: true

module Decidim
  module Admin
    module ContentBlocks
      # A command that reorders a collection of content blocks
      # the ones that might be missing.
      class ReorderContentBlocks < Decidim::Command
        # Public: Initializes the command.
        #
        # organization - the Organization where the content blocks reside
        # scope - the scope applied to the content blocks
        # order - an Array holding the order of IDs of published content blocks.
        # scoped_resource_id - (optional) The id of the resource the content blocks belongs to.
        def initialize(organization, scope, order, scoped_resource_id = nil)
          @organization = organization
          @scope = scope
          @order = order
          @scoped_resource_id = scoped_resource_id
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the data wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if order.blank?

          reorder_steps
          broadcast(:ok)
        end

        private

        attr_reader :organization, :scope, :scoped_resource_id

        def reorder_steps
          transaction do
            reset_weights
            collection.reload
            set_new_weights
            unpublish_removed_content_blocks
            publish_appearing_content_blocks
          end
        end

        def reset_weights
          # rubocop:disable Rails/SkipsModelValidations
          collection.where.not(weight: nil).update_all(weight: nil)
          # rubocop:enable Rails/SkipsModelValidations
        end

        def set_new_weights
          data = order.each_with_index.inject({}) do |hash, (id, index)|
            hash.update(id => index + 1)
          end

          data.each do |id, weight|
            content_block = collection.find_by(id:)
            content_block.update!(weight:) if content_block.present?
          end
        end

        # rubocop:disable Rails/SkipsModelValidations
        def unpublish_removed_content_blocks
          collection.where(weight: nil).update_all(published_at: nil)
        end

        def publish_appearing_content_blocks
          collection.where(published_at: nil).where.not(weight: nil).update_all(published_at: Time.current)
        end
        # rubocop:enable Rails/SkipsModelValidations

        def order
          return nil unless @order.is_a?(Array) && @order.present?

          @order
        end

        def collection
          @collection ||= Decidim::ContentBlock.for_scope(scope, organization:).where(scoped_resource_id:)
        end
      end
    end
  end
end
