class UserReward < ApplicationRecord
  belongs_to :user
  belongs_to :reward
  validates :code, uniqueness: true, allow_nil: true
end