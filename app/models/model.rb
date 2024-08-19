# == Schema Information
#
# Table name: models
#
#  id               :bigint           not null, primary key
#  apma_accepted    :boolean          not null
#  discontinued     :boolean          not null
#  handle           :string           not null
#  heel_to_toe_drop :integer          not null
#  name             :string           not null
#  tags             :jsonb            not null
#  weight           :float            not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  collection_id    :bigint           not null
#
# Indexes
#
#  index_models_on_collection_id           (collection_id)
#  index_models_on_name_and_collection_id  (name,collection_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id)
#
class Model < ApplicationRecord
  include DataFormatting
  include AllowedTags
  # Weight in grams.
  # Heel to toe drop in millimiters.
  belongs_to :collection
  has_one :brand, through: :collection

  serialize :tags, coder: HashSerializer

  validates :handle, format: { with: DataFormatting::HANDLE_FORMAT }
  validates :heel_to_toe_drop, :name, :weight, presence: true
  validates :name, uniqueness: { scope: :collection, case_sensitive: false }
  validates :apma_accepted, :discontinued, inclusion: [ true, false ]
  validates :heel_to_toe_drop, numericality: { greater_than_or_equal_to: 0 }
  validates :weight, numericality: { greater_than_or_equal_to: 0.1 }
  validates_presence_of :collection

  before_validation :assign_handle

  validate :tags_validity

  scope :order_by_cushioning, ->(order = :asc) { order(Arel.sql("tags ->> 'cushioning' #{ order == :desc ? 'DESC' : 'ASC' }, name")) }
  scope :order_by_weight, ->(order = :asc) { order(weight: order) }
  scope :order_by_heel_to_toe_drop, ->(order = :asc) { order(heel_to_toe_drop: order) }

  # scope :tagged_with_high_cushioning, -> { where("tags -> 'cushioning' ? 'High'") }
  # scope :tagged_with_mid_cushioning, -> { where("tags -> 'cushioning' ? 'Mid'") }
  # scope :tagged_with_low_cushioning, -> { where("tags -> 'cushioning' ? 'Low'") }
  # scope :tagged_with_stability_support, -> { where("tags -> 'support' ? 'Stability'") }
  # scope :tagged_with_neutral_support, -> { where("tags -> 'support' ? 'Neutral'") }

  def weight(to_oz = false)
    if to_oz
      (super() * 0.035274).round(2)
    else
      super()
    end
  end

  def cushioning_name
    AllowedTags::CUSHIONING_OPTIONS[self.tags[:cushioning].to_i]
  end

  private
  def tags_validity
    if tags[:activities].nil?
      errors.add(:activities, "must exist")
      else
        errors.add(:activities, "must have at least one type") if self.tags[:activities].size < 1
        self.tags[:activities].each do |tag|
          errors.add(:activities, "can't include #{tag}") if AllowedTags::ACTIVITY_OPTIONS.exclude?(tag)
        end
    end

    if tags[:cushioning].nil?
      errors.add(:cushioning, "must exist")
    elsif !tags[:cushioning].to_i.between?(0, AllowedTags::CUSHIONING_OPTIONS.size-1)
      errors.add(:cushioning, "must be between 0 and #{AllowedTags::CUSHIONING_OPTIONS.size-1}")
    end

    if tags[:support].nil?
      errors.add(:support, "must exist")
    elsif AllowedTags::SUPPORT_OPTIONS.exclude?(self.tags[:support])
      errors.add(:support, "can't include #{self.tags[:support]}")
    end
  end
end
