# == Schema Information
#
# Table name: posts
#
#  id          :bigint           not null, primary key
#  handle      :string           not null
#  overview_en :string           not null
#  overview_es :string           not null
#  published   :boolean          not null
#  tags        :string           default([]), not null, is an Array
#  title_en    :string           not null
#  title_es    :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_posts_on_handle  (handle) UNIQUE
#
class Post < ApplicationRecord
  include DataFormatting
  include AllowedTags
  extend Mobility

  has_rich_text :content_en
  has_rich_text :content_es
  translates :overview
  translates :title

  validates :title_en, :title_es, :content_en, :content_es, :overview_en, :overview_es, :handle, :tags, presence: true
  validates :handle, format: { with: DataFormatting::HANDLE_FORMAT }
  validates :published, inclusion: { in: AllowedTags::BOOLEAN_OPTIONS }
  validates :handle, :title_en, :title_es, uniqueness: true

  validate :tags_validity

  before_validation :assign_handle

  scope :published, -> { where(published: true) }

  def content
    self.send("content_#{I18n.locale.to_s}")
  end

  private

  def tags_validity
    forbidden_tags = self.tags - AllowedTags::POSTS_OPTIONS
    if forbidden_tags.any?
      errors.add(:tags, "#{forbidden_tags} tags not allowed")
    end
  end

  def assign_handle
    if self.title_en && self.title_en_changed?
      # .parameterize[0..50] get first 50 chars of parameterized title
      self.handle = self.title_en.parameterize[0..50]

      # If the handle is longer than 50 chars, remove the last words
      # .split('-') create array by separating by minus sign
      # [..-2] take out last element
      # .join('-') rejoin the array by separating by minus sign
      while self.handle.length > 50
        self.handle = self.handle.split('-')[..-2].join('-')
      end

      if Post.find_by(handle: self.handle).present?
        # self.handle = self.handle + '-' + index.to_s

        original_handle = self.handle.dup
        handle_index = 2

        while Post.find_by(handle: self.handle).present? do
          self.handle = original_handle + '-' + handle_index.to_s
          handle_index += 1
        end
      end
    end
  end
end
