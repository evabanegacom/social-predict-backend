class Activity < ApplicationRecord
  belongs_to :user
  belongs_to :target, polymorphic: true, optional: true

  validates :action, presence: true, inclusion: { in: %w[voted created_prediction redeemed_reward] }
  validates :target_type, inclusion: { in: %w[Prediction Reward], allow_nil: true }
end
