class Point < ApplicationRecord
  belongs_to :user
  belongs_to :prediction, optional: true
  belongs_to :reward, optional: true
  validates :points, presence: true
  validates :choice, inclusion: { in: %w[Yes No Maybe], allow_nil: true }
  validates :result, inclusion: { in: %w[Yes No Maybe], allow_nil: true }
  validates :user_id, uniqueness: { scope: :prediction_id, message: "has already been awarded points for this prediction", if: -> { prediction_id.present? } }
  validates :user_id, uniqueness: { scope: :reward_id, message: "has already redeemed this reward", if: -> { reward_id.present? } }
  validates :prediction_id, presence: true, unless: -> { reward_id.present? }
  validates :reward_id, presence: true, unless: -> { prediction_id.present? }
end
