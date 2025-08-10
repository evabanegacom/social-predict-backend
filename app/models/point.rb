class Point < ApplicationRecord
  belongs_to :user
  belongs_to :prediction
  validates :points, presence: true
  validates :choice, inclusion: { in: %w[Yes No Maybe] }
  validates :result, inclusion: { in: %w[Yes No Maybe] }
  validates :user_id, uniqueness: { scope: :prediction_id, message: "has already been awarded points for this prediction" }
end
