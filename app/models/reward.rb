class Reward < ApplicationRecord
    has_many :user_rewards
    has_many :users, through: :user_rewards
    validates :name, presence: true
    validates :points_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :reward_type, presence: true, inclusion: { in: %w[airtime data badge] }
    validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }
  end