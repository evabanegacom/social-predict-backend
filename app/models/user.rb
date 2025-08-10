class User < ApplicationRecord
  has_secure_password
  has_many :votes, dependent: :destroy
  has_many :predictions, dependent: :destroy
  has_many :points, dependent: :destroy
  has_many :user_rewards
  has_many :rewards, through: :user_rewards
  validates :username, uniqueness: true, allow_blank: true
  validates :phone, uniqueness: true, allow_blank: true
  has_many :activities
  validates :xp, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :username_or_phone_required
  before_create :generate_jti

  def username_or_phone_required
    errors.add(:base, 'Either username or phone must be provided') unless username.present? || phone.present?
  end

  def generate_jti
    self.jti = SecureRandom.uuid
  end

    def admin?
      admin
    end

  def self.find_by_identifier(identifier)
    where('username = ? OR phone = ?', identifier, identifier).first
  end

  def update_streak
    now = Time.now.utc
    if last_active_at.nil? || last_active_at < 1.day.ago.beginning_of_day
      # Reset streak if last activity was before yesterday's start
      if last_active_at.nil? || last_active_at < 2.days.ago.end_of_day
        update!(streak: 1, last_active_at: now)
      else
        update!(streak: streak + 1, last_active_at: now)
      end
    elsif last_active_at > 1.day.ago.beginning_of_day
      # Already active today, no streak change
      update!(last_active_at: now)
    end
  end

  def voting_history
    votes.includes(:prediction).map do |vote|
      {
        prediction_id: vote.prediction_id,
        topic: vote.prediction.topic,
        category: vote.prediction.category,
        choice: vote.choice,
        result: vote.prediction.result,
        correct: vote.prediction.result && vote.choice == vote.prediction.result,
        voted_at: vote.created_at
      }
    end
  end
end